import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/providers.dart';
import 'services/otp_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/customer/food_feed_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/rider/rider_dashboard.dart';
import 'screens/restaurants/restaurant_dashboard.dart';
import 'screens/auth/google_oauth_flow.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
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

    final destination = switch (role) {
      'admin' => const AdminDashboard(),
      'restaurant' => RestaurantDashboard(token: auth.token ?? token),
      'rider' => const RiderDashboard(),
      _ => const FoodFeedScreen(),
    };

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'FindFood',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          home: const SplashScreen(destination: FoodFeedScreen()),
          routes: {
            '/home': (context) => const FoodFeedScreen(),
            '/login': (context) => const LoginScreen(),
            '/cart': (context) => const CartScreen(),
            '/checkout': (context) => const CartScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/admin-dashboard': (context) => const AdminDashboard(),
            '/restaurant-dashboard': (context) => RestaurantDashboard(token: Provider.of<AuthProvider>(context, listen: false).token ?? ''),
            '/rider-dashboard': (context) => const RiderDashboard(),
          },
          onGenerateRoute: (settings) {
            final name = settings.name;
            if (name == null || name.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const SplashScreen(destination: FoodFeedScreen()),
              );
            }

            final uri = Uri.tryParse(name);
            if (uri != null && uri.path == '/reset-password') {
              final token = extractResetTokenFromUri(uri);
              return MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(token: token),
              );
            }

            if (uri != null && uri.path == '/forgot-password') {
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen(),
              );
            }

            return MaterialPageRoute(
              builder: (_) => const SplashScreen(destination: FoodFeedScreen()),
            );
          },
        );
      },
    );
  }
}