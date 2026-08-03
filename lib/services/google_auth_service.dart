import 'package:flutter/material.dart';

import '../screens/auth/google_oauth_flow.dart';
import 'providers.dart';

class GoogleAuthService {
  static Future<void> signIn({
    required BuildContext context,
    String? route,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    await GoogleOAuthFlowService.startGoogleAuth(
      context: context,
      route: route,
      action: action,
      parameters: parameters,
    );
  }

  static Future<void> signOut({required AuthProvider authProvider}) async {
    await authProvider.logout();
  }
}