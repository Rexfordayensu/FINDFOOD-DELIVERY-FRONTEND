import 'package:flutter_test/flutter_test.dart';
import 'package:findfood_app/screens/auth/google_oauth_flow.dart';

void main() {
  group('Google OAuth callback parsing', () {
    test('parses the backend JSON payload returned from the callback', () {
      const payload = '{"access_token":"jwt-token","token_type":"bearer","message":"Google login successful!","user_id":1,"role":"customer","name":"Ada","email":"ada@example.com"}';

      final result = GoogleOAuthResult.fromResponse(payload);

      expect(result, isNotNull);
      expect(result.token, 'jwt-token');
      expect(result.role, 'customer');
      expect(result.userId, 1);
      expect(result.email, 'ada@example.com');
      expect(result.name, 'Ada');
    });

    test('supports frontend redirect fallback values when the callback is a URL', () {
      const payload = 'http://localhost:63988/google-success?token=frontend-token&role=restaurant&user_id=42&email=chef@example.com&name=Chef';

      final result = GoogleOAuthResult.fromResponse(payload);

      expect(result, isNotNull);
      expect(result.token, 'frontend-token');
      expect(result.role, 'restaurant');
      expect(result.userId, 42);
      expect(result.email, 'chef@example.com');
      expect(result.name, 'Chef');
    });

    test('recognizes the backend callback URL used by the redirect flow', () {
      expect(GoogleOAuthConfig.isBackendCallbackUrl('http://localhost:8000/auth/google/callback?code=abc&state=xyz'), isTrue);
      expect(GoogleOAuthConfig.isBackendCallbackUrl('http://localhost:63988/google-success?token=abc'), isFalse);
    });

    test('builds a backend login URL with a runtime redirect URI while keeping OAuth state out of Flutter', () {
      final loginUrl = GoogleOAuthConfig.buildLoginUrl(
        backendBaseUrl: 'http://localhost:8000',
        redirectUri: 'http://localhost:63988/auth/callback',
      );

      expect(loginUrl, equals('http://localhost:8000/auth/google/login?redirect_uri=http%3A%2F%2Flocalhost%3A63988%2Fauth%2Fcallback'));
      expect(loginUrl, isNot(contains('state=')));
      expect(loginUrl, isNot(contains('nonce=')));
    });

    test('ignores normal startup routes but recognizes real OAuth callbacks', () {
      final normalRoute = Uri.parse('http://localhost:63988/home');
      final startupHashRoute = Uri.parse('http://localhost:63988/#/home');
      final callbackRoute = Uri.parse('http://localhost:63988/auth/callback?code=abc&status=success');

      expect(GoogleOAuthConfig.looksLikeOAuthCallback(normalRoute), isFalse);
      expect(GoogleOAuthConfig.looksLikeOAuthCallback(startupHashRoute), isFalse);
      expect(GoogleOAuthConfig.looksLikeOAuthCallback(callbackRoute), isTrue);
    });

    test('serializes and restores pending navigation state', () {
      const pending = PendingAuthNavigation(
        route: '/checkout',
        action: 'complete_payment',
        parameters: {'product_id': '123'},
      );

      final encoded = pending.toJson();
      final restored = PendingAuthNavigation.fromJson(encoded);

      expect(restored.route, '/checkout');
      expect(restored.action, 'complete_payment');
      expect(restored.parameters['product_id'], '123');
    });
  });
}
