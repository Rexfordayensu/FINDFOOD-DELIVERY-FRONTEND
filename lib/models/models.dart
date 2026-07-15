class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'] ?? json['full_name'] ?? 'Unknown user',
        email: json['email'] ?? '',
        role: json['role'] ?? 'customer',
        isActive: json['is_active'] ?? true,
      );
}

class Restaurant {
  final int id;
  final String name;
  final String cuisineType;
  final String address;
  final String email;
  final bool isActive;
  final bool isApproved;
  final int ownerId;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisineType,
    required this.address,
    required this.email,
    required this.isActive,
    required this.isApproved,
    required this.ownerId,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'],
        name: json['name'],
        cuisineType: json['cuisine_type'],
        address: json['address'],
        email: json['email'],
        isActive: json['is_active'] ?? true,
        isApproved: json['is_approved'] ?? false,
        ownerId: json['owner_id'] ?? 0,
      );
}

class MenuItem {
  final int id;
  final String name;
  final String? description;
  final int price; // in pesewas (smallest unit)
  final bool isAvailable;
  final int restaurantId;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isAvailable,
    required this.restaurantId,
  });

  // Display price in GHS
  String get displayPrice => 'GH₵ ${(price / 100).toStringAsFixed(2)}';

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: json['price'],
        isAvailable: json['is_available'] ?? true,
        restaurantId: json['restaurant_id'],
      );
}

class Order {
  final int id;
  final int totalAmount;
  final String status;
  final int restaurantId;
  final int userId;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.restaurantId,
    required this.userId,
  });

  String get displayTotal => 'GH₵ ${(totalAmount / 100).toStringAsFixed(2)}';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        totalAmount: json['total_amount'],
        status: json['status'],
        restaurantId: json['restaurant_id'],
        userId: json['user_id'],
      );
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  int get subtotal => menuItem.price * quantity;
  String get displaySubtotal => 'GH₵ ${(subtotal / 100).toStringAsFixed(2)}';
}