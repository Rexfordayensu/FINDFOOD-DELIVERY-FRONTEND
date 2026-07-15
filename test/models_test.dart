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

    test('parses user records from backend payload', () {
      final user = AppUser.fromJson({
        'id': 3,
        'name': 'Kofi',
        'email': 'kofi@example.com',
        'role': 'restaurant',
        'is_active': true,
      });

      expect(user.email, 'kofi@example.com');
      expect(user.role, 'restaurant');
      expect(user.isActive, isTrue);
    });
  });
}
