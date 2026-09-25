import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OTP response parsing', () {
    test('uses the backend otp_required value', () {
      expect(otpRequiredFromResponse({'otp_required': false}), isFalse);
      expect(otpRequiredFromResponse({'otp_required': true}), isTrue);
      expect(otpRequiredFromResponse({'two_factor': true}), isFalse);
    });

    test('allows normal password login when OTP is not requested', () {
      expect(
          otpRequiredFromResponse({
            'access_token': 'JWT_TOKEN_HERE',
            'token_type': 'bearer',
            'user_id': 12,
            'role': 'customer',
          }),
          isFalse);
    });
  });

  group('password reset helpers', () {
    test('extracts reset token from a deep link or browser URL', () {
      expect(
        extractResetTokenFromUri(
            Uri.parse('https://example.com/reset-password?token=abc123')),
        'abc123',
      );
      expect(
        extractResetTokenFromUri(
            Uri.parse('findfood://reset-password?token=xyz789')),
        'xyz789',
      );
      expect(
        extractResetTokenFromUri(
            Uri.parse('https://example.com/reset-password')),
        isNull,
      );
    });

    test('preserves backend messages for password reset failures', () {
      final error = PasswordResetException(
        'reset_failed',
        'The reset link is invalid or expired.',
      );

      expect(error.message, 'The reset link is invalid or expired.');
    });
  });
}

bool otpRequiredFromResponse(Map<String, dynamic> data) {
  return data['otp_required'] == true;
}

String? extractResetTokenFromUri(Uri uri) {
  return uri.queryParameters['token'];
}

class PasswordResetException implements Exception {
  final String status;
  final String message;
  PasswordResetException(this.status, this.message);
  @override
  String toString() => message;
}
