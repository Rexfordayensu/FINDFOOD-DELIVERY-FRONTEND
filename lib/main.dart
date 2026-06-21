import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/providers.dart';
import 'screens/customer/food_feed_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const FindFoodApp(),
    ),
  );
}

class FindFoodApp extends StatelessWidget {
  const FindFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Use Consumer instead of Provider.of so the context
    // is always a child of MultiProvider, never the same level
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'FindFood',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          home: const FoodFeedScreen(),
        );
      },
    );
  }
}