import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/google_oauth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/customer_pages.dart';
import 'screens/customer/food_feed_screen.dart';
import 'screens/customer/order_tracking_screen.dart';
import 'screens/customer/menu_detail_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/customer/order_chat_screen.dart';
import 'screens/rider/rider_dashboard.dart';
import 'screens/restaurant/restaurant_pending_approval_screen.dart';
import 'screens/restaurants/restaurant_dashboard.dart';
import 'services/providers.dart';

GoRouter createAppRouter(
  AuthProvider auth, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  String? pendingLocation;

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Uri(
      path: Uri.base.path.isEmpty ? '/' : Uri.base.path,
      queryParameters:
          Uri.base.queryParameters.isEmpty ? null : Uri.base.queryParameters,
    ).toString(),
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const FoodFeedScreen()),
      GoRoute(path: '/home', redirect: (_, __) => '/'),
      GoRoute(path: '/admin-dashboard', redirect: (_, __) => '/admin'),
      GoRoute(
          path: '/restaurant-dashboard',
          redirect: (_, __) => '/restaurant/orders'),
      GoRoute(path: '/rider-dashboard', redirect: (_, __) => '/rider'),
      GoRoute(path: '/loading', builder: (_, __) => const _LoadingScreen()),
      GoRoute(
          path: '/auth/callback', builder: (_, __) => const _LoadingScreen()),
      GoRoute(
        path: '/email-verification',
        builder: (_, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final role = state.uri.queryParameters['role'] ?? '';
          final mode = state.uri.queryParameters['mode'] == 'login'
              ? VerificationMode.login
              : VerificationMode.registration;
          return EmailVerificationScreen(
            email: email,
            role: role,
            mode: mode,
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          returnRoute: state.uri.queryParameters['returnTo'] ?? '/home',
        ),
      ),
      GoRoute(
        path: '/google-oauth',
        builder: (_, state) => GoogleOAuthScreen(
          returnRoute: state.uri.queryParameters['returnTo'] ?? '/home',
        ),
      ),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const CustomerOrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const CustomerProfileScreen(),
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (_, state) {
          final order = state.extra;
          if (order is Order) return OrderTrackingScreen(order: order);
          return const _MissingRouteDataScreen();
        },
      ),
      GoRoute(
        path: '/restaurants/:restaurantId',
        builder: (_, state) {
          final restaurant = state.extra;
          if (restaurant is Restaurant) {
            return MenuDetailScreen(restaurant: restaurant);
          }
          return const _MissingRouteDataScreen();
        },
      ),
      GoRoute(
        path: '/chat/:orderId',
        builder: (_, state) {
          final data = state.extra;
          if (data is Map<String, dynamic>) {
            return ChatScreen(
              orderId: int.parse(state.pathParameters['orderId']!),
              otherPartyName: data['name']?.toString() ?? 'Customer',
              otherPartyRole: data['role']?.toString() ?? 'customer',
            );
          }
          return const _MissingRouteDataScreen();
        },
      ),
      GoRoute(
        path: '/order-chat/:orderId',
        builder: (_, state) {
          final order = state.extra;
          if (order is Order) {
            return OrderChatScreen(
              orderId: order.id,
              order: order,
              otherPartyLabel: order.restaurantName ?? 'Restaurant',
            );
          }
          return const _MissingRouteDataScreen();
        },
      ),
      GoRoute(
        path: '/restaurant/orders',
        builder: (context, __) => RestaurantDashboard(
          token: context.read<AuthProvider>().token ?? '',
          initialIndex: 0,
        ),
      ),
      GoRoute(
        path: '/restaurant/menu',
        builder: (context, __) => RestaurantDashboard(
          token: context.read<AuthProvider>().token ?? '',
          initialIndex: 1,
        ),
      ),
      GoRoute(
        path: '/restaurant/earnings',
        builder: (context, __) => RestaurantDashboard(
          token: context.read<AuthProvider>().token ?? '',
          initialIndex: 2,
        ),
      ),
      GoRoute(
        path: '/restaurant/settings',
        builder: (context, __) => RestaurantDashboard(
          token: context.read<AuthProvider>().token ?? '',
          initialIndex: 3,
        ),
      ),
      GoRoute(
        path: '/rider',
        builder: (_, __) => const RiderDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/restaurant/pending',
        builder: (_, __) => const RestaurantPendingApprovalScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.uri.path;
      if (!auth.isInitialized) {
        if (location != '/loading' && location != '/auth/callback') {
          pendingLocation ??= state.uri.toString();
        }
        return location == '/loading' || location == '/auth/callback'
            ? null
            : '/loading';
      }

      if (location == '/loading') {
        final requestedLocation = pendingLocation;
        pendingLocation = null;
        if (requestedLocation == null ||
            requestedLocation == '/' ||
            requestedLocation == '/home') {
          return _homeForRole(auth);
        }
        return requestedLocation;
      }
      if (location == '/auth/callback') return null;

      final isPublic = location == '/' ||
          location == '/home' ||
          location == '/login' ||
          location == '/email-verification' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      if (location == '/login' && auth.isLoggedIn) {
        final returnTo = state.uri.queryParameters['returnTo'];
        if (auth.isCustomer && returnTo != null && _isCustomerRoute(returnTo)) {
          return returnTo;
        }
        return _homeForRole(auth);
      }
      if (isPublic) return null;
      if (!auth.isLoggedIn) {
        final loginUri = Uri(
          path: '/login',
          queryParameters: {
            'returnTo': Uri(
              path: state.uri.path,
              queryParameters: state.uri.queryParameters,
            ).toString(),
          },
        );
        return loginUri.toString();
      }

      final restaurantRoute = location.startsWith('/restaurant/');
      final roleRoute = location == '/rider' || location == '/admin';
      final conversationRoute =
          location.startsWith('/chat/') || location.startsWith('/order-chat/');
      if (restaurantRoute && !auth.isRestaurant) return _homeForRole(auth);
      if (location == '/rider' && !auth.isRider) return _homeForRole(auth);
      if (location == '/admin' && !auth.isAdmin) return _homeForRole(auth);
      if (!restaurantRoute &&
          !roleRoute &&
          !conversationRoute &&
          !auth.isCustomer) {
        return _homeForRole(auth);
      }
      return null;
    },
  );
}

String _homeForRole(AuthProvider auth) {
  switch (auth.role) {
    case 'restaurant':
      return auth.isRestaurantApproved
          ? '/restaurant/orders'
          : '/restaurant/pending';
    case 'rider':
      return '/rider';
    case 'admin':
      return '/admin';
    default:
      return '/';
  }
}

bool _isCustomerRoute(String route) {
  return route == '/' ||
      route == '/home' ||
      route == '/orders' ||
      route == '/profile' ||
      route == '/cart' ||
      route == '/checkout' ||
      route.startsWith('/restaurants/');
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MissingRouteDataScreen extends StatelessWidget {
  const _MissingRouteDataScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order unavailable')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/orders'),
          child: const Text('Back to orders'),
        ),
      ),
    );
  }
}
