import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/providers.dart';
import 'services/otp_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/customer/food_feed_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  @override
  void initState() {
    super.initState();
    // Handle deep links
    _handleDeepLink();
  }

  void _handleDeepLink() {
    // TODO: Implement deep link handling for verify-email?email=user@example.com
    // This can be done using the app_links package or flutter_web_plugins
    // For now, this is a placeholder for future implementation
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'FindFood',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          home: const SplashScreen(destination: FoodFeedScreen()),
        );
      },
    );
  }
}