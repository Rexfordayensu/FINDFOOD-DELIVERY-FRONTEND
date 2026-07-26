import 'package:flutter_test/flutter_test.dart';
import 'package:findfood_app/models/models.dart';

void main() {
  group('model parsing', () {
    test('parses restaurant approval state from backend payload', () {
      final restaurant = Restaurant.fromJson({
        'id': 7,
        'name': 'Mama’s Kitchen',
        'cuisine_type': 'Ghanaian',
        'address': 'Accra',
        'email': 'mama@example.com',
        'is_active': true,
        'is_approved': false,
        'owner_id': 12,
      });

      expect(restaurant.isApproved, isFalse);
      expect(restaurant.ownerId, 12);
    });

    test('serializes payment initialization payload without email or phone number', () {
      final request = PaymentInitializationRequest(orderId: 123, provider: 'paystack');
      final payload = request.toJson();

      expect(payload, {
        'order_id': 123,
        'provider': 'paystack',
      });
      expect(payload.containsKey('email'), isFalse);
      expect(payload.containsKey('phone_number'), isFalse);
    });
  });
}
