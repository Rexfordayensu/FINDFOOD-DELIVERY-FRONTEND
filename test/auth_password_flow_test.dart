import 'package:flutter_test/flutter_test.dart';
import 'package:findfood_app/services/api_service.dart';

void main() {
  group('password reset helpers', () {
    test('extracts reset token from a deep link or browser URL', () {
      expect(
        extractResetTokenFromUri(Uri.parse('https://example.com/reset-password?token=abc123')),
        'abc123',
      );
      expect(
        extractResetTokenFromUri(Uri.parse('findfood://reset-password?token=xyz789')),
        'xyz789',
      );
      expect(
        extractResetTokenFromUri(Uri.parse('https://example.com/reset-password')),
        isNull,
      );
    });

    test('preserves backend messages for password reset failures', () {
      const error = PasswordResetException(
        'reset_failed',
        'The reset link is invalid or expired.',
      );

      expect(error.message, 'The reset link is invalid or expired.');
    });
  });
}
