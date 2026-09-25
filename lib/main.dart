import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'web_url_strategy_stub.dart'
    if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart'
    as web_plugins;
import 'theme.dart';
import 'services/providers.dart';
import 'services/otp_provider.dart';
import 'screens/auth/google_oauth_flow.dart';
import 'router.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    web_plugins.setUrlStrategy(web_plugins.PathUrlStrategy());
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OtpProvider()),
        ChangeNotifierProvider(create: (_) => OrderPollingProvider()), // NEW
      ],
      child: const FindFoodApp(),
    ),
  );
}

class FindFoodApp extends StatefulWidget {
  const FindFoodApp({super.key});

  @override
  State<FindFoodApp> createState() => _FindFoodAppState();
}

class _FindFoodAppState extends State<FindFoodApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _router = createAppRouter(auth, navigatorKey: _navigatorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await auth.initializeFromSecureStorage();
      await GoogleOAuthFlowService.initializeDeepLinkHandling(
        authProvider: auth,
        navigatorKey: _navigatorKey,
      );
      await _handleDeepLink();
    });
  }

  Future<void> _handleDeepLink() async {
    final uri = Uri.base;
    final token = uri.queryParameters['token'] ?? uri.queryParameters['access_token'];
    if (token == null || token.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final role = (uri.queryParameters['role'] ?? auth.role ?? 'customer').toLowerCase();
    final userIdText = uri.queryParameters['user_id'] ?? uri.queryParameters['userId'];
    final userId = userIdText == null ? null : int.tryParse(userIdText);
    final email = uri.queryParameters['email'];

    await auth.login(
      token: token,
      userId: userId ?? auth.userId ?? 0,
      role: role,
      email: email ?? auth.email,
    );

    final route = switch (role) {
      'admin' => '/admin',
      'restaurant' => '/restaurant/orders',
      'rider' => '/rider',
      _ => '/',
    };
    _router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'FindFood',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          routerConfig: _router,
        );
      },
    );
  }
}