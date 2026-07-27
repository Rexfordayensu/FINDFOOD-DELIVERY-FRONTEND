class Restaurant {
  final int id;
  final String name;
  final String cuisineType;
  final String address;
  final String email;
  final bool isActive;
  final bool isApproved;
  final int ownerId;
  final String? imageUrl;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisineType,
    required this.address,
    required this.email,
    required this.isActive,
    required this.isApproved,
    required this.ownerId,
    this.imageUrl, 
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
        imageUrl: json['image_url'],
      );
}

class MenuItem {
  final int id;
  final String name;
  final String? description;
  final int price; // pesewas
  final bool isAvailable;
  final int restaurantId;
  final String? imageUrl; // NEW: uploaded photo path, e.g. /static/menu_images/xyz.jpg

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isAvailable,
    required this.restaurantId,
    this.imageUrl,
  });

  /// Builds the full URL to display the uploaded image, or null if none set
  String? fullImageUrl(String baseUrl) =>
      imageUrl != null ? '$baseUrl$imageUrl' : null;

  String get displayPrice => 'GH₵ ${(price / 100).toStringAsFixed(2)}';

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: json['price'],
        isAvailable: json['is_available'] ?? true,
        restaurantId: json['restaurant_id'],
        imageUrl: json['image_url'],
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

  String? get restaurantName => null;

  Order copyWith({
    int? id,
    String? status,
    int? totalAmount,
    int? restaurantId,
    int? userId,

    // You can add other fields here if you need to copy them later
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      // ... pass your other existing class fields here like:
      // total: total,
    );
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  int get subtotal => menuItem.price * quantity;
  String get displaySubtotal => 'GH₵ ${(subtotal / 100).toStringAsFixed(2)}';
}

// ─── CHAT MESSAGE ─────────────────────────────────────────────────────────────
class ChatMessage {
  final int id;
  final int orderId;
  final int senderId;
  final String senderRole;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        orderId: json['order_id'],
        senderId: json['sender_id'],
        senderRole: json['sender_role'],
        content: json['content'],
        createdAt: DateTime.parse(json['created_at']),
        isMine: json['is_mine'] ?? false,
      );

  static Future<Object?> getMessages({required String token, required int orderId}) async {}
}

// ─── ANALYTICS ────────────────────────────────────────────────────────────────
class BestSeller {
  final String name;
  final int quantitySold;

  BestSeller({required this.name, required this.quantitySold});

  factory BestSeller.fromJson(Map<String, dynamic> json) => BestSeller(
        name: json['name'] ?? 'Unknown',
        quantitySold: json['quantity_sold'] ?? 0,
      );
}

class DailyRevenue {
  final String day;
  final int revenue;

  DailyRevenue({required this.day, required this.revenue});

  factory DailyRevenue.fromJson(Map<String, dynamic> json) => DailyRevenue(
        day: json['day'] ?? '',
        revenue: json['revenue'] ?? 0,
      );
}

class RestaurantAnalytics {
  final int totalOrders;
  final int deliveredOrders;
  final int totalRevenue;
  final int averageOrderValue;
  final List<BestSeller> bestSellers;
  final List<DailyRevenue> dailyRevenue;

  RestaurantAnalytics({
    required this.totalOrders,
    required this.deliveredOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.bestSellers,
    required this.dailyRevenue,
  });

  String get displayRevenue => 'GH₵ ${(totalRevenue / 100).toStringAsFixed(2)}';
  String get displayAvgOrder =>
      'GH₵ ${(averageOrderValue / 100).toStringAsFixed(2)}';

  factory RestaurantAnalytics.fromJson(Map<String, dynamic> json) =>
      RestaurantAnalytics(
        totalOrders: json['total_orders'] ?? 0,
        deliveredOrders: json['delivered_orders'] ?? 0,
        totalRevenue: json['total_revenue'] ?? 0,
        averageOrderValue: json['average_order_value'] ?? 0,
        bestSellers: ((json['best_sellers'] ?? []) as List)
            .map((b) => BestSeller.fromJson(b))
            .toList(),
        dailyRevenue: ((json['daily_revenue'] ?? []) as List)
            .map((d) => DailyRevenue.fromJson(d))
            .toList(),
      );
}

class RiderAnalytics {
  final int totalDeliveries;
  final int completedDeliveries;
  final int totalEarnings;
  final int averageEarningPerDelivery;

  RiderAnalytics({
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.totalEarnings,
    required this.averageEarningPerDelivery,
  });

  String get displayEarnings =>
      'GH₵ ${(totalEarnings / 100).toStringAsFixed(2)}';
  String get displayAvg =>
      'GH₵ ${(averageEarningPerDelivery / 100).toStringAsFixed(2)}';

  factory RiderAnalytics.fromJson(Map<String, dynamic> json) => RiderAnalytics(
        totalDeliveries: json['total_deliveries'] ?? 0,
        completedDeliveries: json['completed_deliveries'] ?? 0,
        totalEarnings: json['total_earnings'] ?? 0,
        averageEarningPerDelivery: json['average_earning_per_delivery'] ?? 0,
      );
}