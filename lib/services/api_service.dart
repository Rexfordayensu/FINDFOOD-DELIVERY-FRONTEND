import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── Safe JSON decoder — handles plain text errors from server ─────────────
  static Map<String, dynamic> _decode(http.Response response) {
    final ct = response.headers['content-type'] ?? '';
    if (ct.contains('application/json')) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    // Server sent plain text (e.g. "Internal Server Error") — wrap it
    return {'detail': response.body.isNotEmpty
        ? response.body
        : 'Server error (${response.statusCode})'};
  }

  static List<dynamic> _decodeList(http.Response response) {
    final ct = response.headers['content-type'] ?? '';
    if (ct.contains('application/json')) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
    }
    return [];
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return data;
    throw Exception(data['detail'] ?? 'Registration failed (${response.statusCode})');
  }

  // ── RESTAURANTS ───────────────────────────────────────────────────────────

  static Future<List<Restaurant>> getRestaurants() async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants'));
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((r) => Restaurant.fromJson(r))
          .toList();
    }
    throw Exception('Failed to load restaurants (${response.statusCode})');
  }

  static Future<Restaurant> createRestaurant({
    required String token,
    required String name,
    required String cuisineType,
    required String address,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/restaurants'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'cuisine_type': cuisineType,
        'address': address,
        'email': email,
        'password': password,
      }),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return Restaurant.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to create restaurant');
  }

  // ── MENU ──────────────────────────────────────────────────────────────────

  static Future<List<MenuItem>> getMenu(int restaurantId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/menu'));
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((m) => MenuItem.fromJson(m))
          .toList();
    }
    throw Exception('Failed to load menu (${response.statusCode})');
  }

  static Future<MenuItem> addMenuItem({
    required String token,
    required int restaurantId,
    required String name,
    required String? description,
    required int price,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/restaurants/$restaurantId/menu'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'price': price,
      }),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return MenuItem.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to add item');
  }

  // ── ORDERS ────────────────────────────────────────────────────────────────

  static Future<Order> placeOrder({
    required String token,
    required int restaurantId,
    required List<Map<String, int>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'restaurant_id': restaurantId, 'items': items}),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return Order.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to place order');
  }

  static Future<List<Order>> getMyOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((o) => Order.fromJson(o))
          .toList();
    }
    throw Exception('Failed to load orders (${response.statusCode})');
  }

  static Future<Order> updateOrderStatus({
    required String token,
    required int orderId,
    required String newStatus,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status?new_status=$newStatus'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return Order.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to update status');
  }

  // ── DELIVERIES ────────────────────────────────────────────────────────────

  static Future<List<Order>> getAvailableDeliveries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/deliveries/available'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return _decodeList(response)
          .map((o) => Order.fromJson(o))
          .toList();
    }
    throw Exception('Failed to load deliveries (${response.statusCode})');
  }

  // ── PAYMENTS ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> initiatePayment({
    required String token,
    required int orderId,
    required String provider,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_id': orderId,
        'provider': provider,
        'phone_number': phoneNumber,
      }),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return data;
    throw Exception(data['detail'] ?? 'Payment failed');
  }
}