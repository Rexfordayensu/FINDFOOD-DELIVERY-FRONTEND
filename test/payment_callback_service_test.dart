import 'package:flutter_test/flutter_test.dart';
import 'package:findfood_app/services/payment_callback_service.dart';

void main() {
  group('extractPaymentReference', () {
    test('extracts reference from callback query parameters', () {
      final uri = Uri.parse('findfood://payment-callback?reference=PSK-ABC123');
      expect(extractPaymentReference(uri), 'PSK-ABC123');
    });

    test('falls back to trxref when reference is absent', () {
      final uri = Uri.parse('findfood://payment-callback?trxref=PSK-XYZ789');
      expect(extractPaymentReference(uri), 'PSK-XYZ789');
    });
  });
}
