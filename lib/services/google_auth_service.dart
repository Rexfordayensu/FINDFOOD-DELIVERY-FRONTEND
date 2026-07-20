import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

// Adjust this path if api_service.dart is located in a different directory
import 'api_service.dart';

class GoogleAuthService {
  // ✅ Web Client ID from Google Cloud Console
  static const String _webClientId =
      '779814360612-t3r0i8l4pa2r8jqfb1bcd4nh8e429tot.googleusercontent.com';

  // Configured using constructor for newer SDK specifications
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  // Getter to access the instance across the application
  static GoogleSignIn get instance => _googleSignIn;

  /// Web-safe widget wrapper that renders a platform-aware Google Sign-In element.
  /// Place this inside your Login/Sign-In Screen layout.
  static Widget buildSignInButton({required VoidCallback onPressed}) {
    if (kIsWeb) {
      // Return a clean web button wrapper matching standard Design patterns
      return OutlinedButton.icon(
        icon: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
          height: 18,
        ),
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
      );
    }

    // Default Mobile/Native Native fallback UI button layout
    return ElevatedButton.icon(
      icon: const Icon(Icons.login_rounded),
      label: const Text('Sign in with Google'),
      onPressed: onPressed,
    );
  }

  /// Authentication execution method
  static Future<Map<String, dynamic>> signIn() async {
    try {
      // Force account picker to show every time by executing a clear cycle
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) throw 'Google sign-in cancelled.';

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw 'Failed to get Google ID token. Check your Web Client ID configurations.';
      }

      // Send to FastAPI backend endpoint for verification
      final url = Uri.parse('${ApiService.baseUrl}/auth/google?token=${Uri.encodeComponent(idToken)}');
      
      final response = await http.post(url);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['detail'] ?? 'Google sign-in failed on server';
      }
    } catch (e) {
      // Strip native prefix boilerplate to output clean downstream UX error strings
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      throw Exception(errorMessage);
    }
  }

  /// Global sign out logic
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}