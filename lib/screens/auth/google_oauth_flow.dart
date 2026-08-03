import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../services/api_service.dart';
import '../../services/providers.dart';
import '../../utils/web_url_helper.dart';

class PendingAuthNavigation {
  const PendingAuthNavigation({
    required this.route,
    this.action,
    this.parameters = const {},
  });

  final String route;
  final String? action;
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toJson() => {
        'route': route,
        'action': action,
        'parameters': parameters,
      };

  factory PendingAuthNavigation.fromJson(Map<String, dynamic> json) {
    return PendingAuthNavigation(
      route: json['route']?.toString() ?? '/home',
      action: json['action']?.toString(),
      parameters: Map<String, dynamic>.from(
        json['parameters'] is Map ? json['parameters'] : const {},
      ),
    );
  }
}

class GoogleOAuthConfig {
  static const String callbackPath = '/auth/callback';
  static const String defaultBackendBaseUrl = ApiService.baseUrl;
  static const String mobileCallbackScheme = 'findfood://oauth/callback';

  static String buildLoginUrl({
    required String backendBaseUrl,
    required String redirectUri,
    String? returnTo,
  }) {
    final normalizedBackendBaseUrl = backendBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final encodedRedirectUri = Uri.encodeComponent(redirectUri);
    final queryParts = ['redirect_uri=$encodedRedirectUri'];
    if (returnTo != null && returnTo.isNotEmpty) {
      queryParts.add('return_to=${Uri.encodeComponent(returnTo)}');
    }
    return '$normalizedBackendBaseUrl/auth/google/login?${queryParts.join('&')}';
  }

  static String resolveRedirectUri() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      return origin.isEmpty ? mobileCallbackScheme : '$origin$callbackPath';
    }

    return mobileCallbackScheme;
  }

  static bool isBackendCallbackUrl(String url) {
    final normalized = url.trim();
    return normalized.isNotEmpty && normalized.startsWith('http://localhost:8000/auth/google/callback');
  }
}

class GoogleOAuthResult {
  const GoogleOAuthResult({
    required this.token,
    required this.role,
    required this.userId,
    required this.email,
    required this.name,
  });

  final String token;
  final String role;
  final int userId;
  final String? email;
  final String? name;

  factory GoogleOAuthResult.fromJson(Map<String, dynamic> payload) {
    return GoogleOAuthResult(
      token: payload['access_token']?.toString() ?? payload['token']?.toString() ?? '',
      role: payload['role']?.toString() ?? 'customer',
      userId: payload['user_id'] is int
          ? payload['user_id'] as int
          : int.tryParse(payload['user_id']?.toString() ?? '0') ?? 0,
      email: payload['email']?.toString(),
      name: payload['name']?.toString(),
    );
  }

  factory GoogleOAuthResult.fromResponse(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      return const GoogleOAuthResult(token: '', role: 'customer', userId: 0, email: null, name: null);
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return GoogleOAuthResult.fromJson(decoded);
      }
    } catch (_) {}

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final token = uri.queryParameters['token'] ?? uri.queryParameters['access_token'];
      if (token != null && token.isNotEmpty) {
        return GoogleOAuthResult(
          token: token,
          role: (uri.queryParameters['role'] ?? 'customer').toLowerCase(),
          userId: int.tryParse(uri.queryParameters['user_id'] ?? uri.queryParameters['userId'] ?? '0') ?? 0,
          email: uri.queryParameters['email'],
          name: uri.queryParameters['name'],
        );
      }
    }

    return const GoogleOAuthResult(token: '', role: 'customer', userId: 0, email: null, name: null);
  }
}

class GoogleOAuthFlowService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _pendingNavigationKey = 'pending_oauth_navigation';

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;

  static Future<void> startGoogleAuth({
    required BuildContext context,
    String? route,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    final pendingNavigation = PendingAuthNavigation(
      route: route ?? '/home',
      action: action ?? 'google_oauth',
      parameters: parameters ?? const {},
    );

    await _persistPendingNavigation(pendingNavigation);

    final redirectUri = GoogleOAuthConfig.resolveRedirectUri();
    final loginUrl = GoogleOAuthConfig.buildLoginUrl(
      backendBaseUrl: GoogleOAuthConfig.defaultBackendBaseUrl,
      redirectUri: redirectUri,
      returnTo: pendingNavigation.route,
    );

    final launched = await launchUrlString(
      loginUrl,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : '_blank',
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the browser for Google sign-in.')),
      );
    }
  }

  static Future<void> initializeDeepLinkHandling({
    required AuthProvider authProvider,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (kIsWeb) {
      await handleCallbackUri(
        Uri.base,
        authProvider: authProvider,
        navigatorKey: navigatorKey,
      );
      return;
    }

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await handleCallbackUri(
        initialUri,
        authProvider: authProvider,
        navigatorKey: navigatorKey,
      );
    }

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      handleCallbackUri(
        uri,
        authProvider: authProvider,
        navigatorKey: navigatorKey,
      );
    });
  }

  static Future<void> handleCallbackUri(
    Uri uri, {
    required AuthProvider authProvider,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    final errorMessage = uri.queryParameters['error_description'] ??
        uri.queryParameters['error'] ??
        uri.queryParameters['message'];

    if (errorMessage != null && errorMessage.isNotEmpty) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_displayErrorMessage(errorMessage))),
        );
      }
      return;
    }

    final authCode = uri.queryParameters['code'];
    if (authCode != null && authCode.isNotEmpty) {
      try {
        final result = await _exchangeCode(authCode);
        if (result.token.isEmpty) {
          await _showInvalidCallbackMessage(navigatorKey);
          return;
        }

        await _completeLogin(
          authProvider: authProvider,
          result: result,
          navigatorKey: navigatorKey,
          returnRoute: uri.queryParameters['return_to'],
        );
        return;
      } catch (error) {
        await _showExchangeErrorMessage(navigatorKey, error);
        return;
      }
    }

    final token = uri.queryParameters['token'] ?? uri.queryParameters['access_token'] ?? uri.queryParameters['jwt'];
    if (token == null || token.isEmpty) {
      final payload = uri.queryParameters['response'] ?? uri.queryParameters['payload'];
      if (payload != null && payload.isNotEmpty) {
        final result = GoogleOAuthResult.fromResponse(payload);
        if (result.token.isEmpty) {
          await _showInvalidCallbackMessage(navigatorKey);
          return;
        }
        await _completeLogin(
          authProvider: authProvider,
          result: result,
          navigatorKey: navigatorKey,
          returnRoute: uri.queryParameters['return_to'],
        );
        return;
      }

      await _showInvalidCallbackMessage(navigatorKey);
      return;
    }

    final result = GoogleOAuthResult(
      token: token,
      role: (uri.queryParameters['role'] ?? authProvider.role ?? 'customer').toLowerCase(),
      userId: int.tryParse(uri.queryParameters['user_id'] ?? uri.queryParameters['userId'] ?? authProvider.userId?.toString() ?? '0') ?? 0,
      email: uri.queryParameters['email'] ?? authProvider.email,
      name: uri.queryParameters['name'],
    );

    await _completeLogin(
      authProvider: authProvider,
      result: result,
      navigatorKey: navigatorKey,
      returnRoute: uri.queryParameters['return_to'],
    );
  }

  static String _displayErrorMessage(String error) {
    final normalized = error.trim().toLowerCase();
    if (normalized.contains('expired') || normalized.contains('session')) {
      return 'Google sign-in session expired. Please try again.';
    }
    if (normalized.contains('cancel')) {
      return 'Google sign-in was cancelled.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  static Future<void> _showInvalidCallbackMessage(GlobalKey<NavigatorState> navigatorKey) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in did not return a valid response. Please try again.')),
    );
  }

  static Future<void> _showExchangeErrorMessage(GlobalKey<NavigatorState> navigatorKey, Object error) async {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    final message = error is Exception
        ? error.toString()
        : 'Google sign-in could not be completed. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<GoogleOAuthResult> _exchangeCode(String authCode) async {
    final payload = await ApiService.exchangeGoogleOAuthCode(authCode);
    return GoogleOAuthResult.fromJson(payload);
  }

  static Future<void> _completeLogin({
    required AuthProvider authProvider,
    required GoogleOAuthResult result,
    required GlobalKey<NavigatorState> navigatorKey,
    String? returnRoute,
  }) async {
    await authProvider.login(
      token: result.token,
      userId: result.userId,
      role: result.role,
      email: result.email,
      name: result.name,
    );

    await clearPendingNavigation();

    _restoreNavigation(
      authProvider: authProvider,
      navigatorKey: navigatorKey,
      returnRoute: returnRoute,
    );
  }

  static void _restoreNavigation({
    required AuthProvider authProvider,
    required GlobalKey<NavigatorState> navigatorKey,
    String? returnRoute,
  }) {
    final navigation = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigation == null || context == null || !context.mounted) {
      return;
    }

    Future<void>.microtask(() async {
      final pending = await readPendingNavigation();
      final fallbackRoute = _routeForRole(authProvider.role);
      final targetRoute = pending?.route ?? returnRoute ?? fallbackRoute;
      final normalizedRoute = _normalizeRouteName(targetRoute);
      final arguments = pending?.parameters.isEmpty == false ? pending!.parameters : null;

      if (kIsWeb) {
        await replaceBrowserUrl(normalizedRoute);
      }

      navigation.pushNamedAndRemoveUntil(normalizedRoute, (route) => false, arguments: arguments);
    });
  }

  static String _routeForRole(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return '/admin-dashboard';
      case 'restaurant':
        return '/restaurant-dashboard';
      case 'rider':
        return '/rider-dashboard';
      default:
        return '/home';
    }
  }

  static String _normalizeRouteName(String route) {
    if (route.isEmpty || route == '/') {
      return '/home';
    }

    final normalized = route.startsWith('/') ? route : '/$route';
    return switch (normalized) {
      '/login' => '/home',
      '/forgot-password' => '/home',
      '/reset-password' => '/home',
      '/checkout' => '/checkout',
      '/cart' => '/cart',
      '/home' => '/home',
      '/admin-dashboard' => '/admin-dashboard',
      '/restaurant-dashboard' => '/restaurant-dashboard',
      '/rider-dashboard' => '/rider-dashboard',
      _ => '/home',
    };
  }

  static Future<void> _persistPendingNavigation(PendingAuthNavigation navigation) async {
    await _storage.write(key: _pendingNavigationKey, value: jsonEncode(navigation.toJson()));
  }

  static Future<PendingAuthNavigation?> readPendingNavigation() async {
    final value = await _storage.read(key: _pendingNavigationKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return PendingAuthNavigation.fromJson(jsonDecode(value));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPendingNavigation() async {
    await _storage.delete(key: _pendingNavigationKey);
  }

  static Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
