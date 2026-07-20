import 'dart:convert';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── Safe decoder ──────────────────────────────────────────────────────────
  static Map<String, dynamic> _decode(http.Response response) {
    final ct = response.headers['content-type'] ?? '';
    if (ct.contains('application/json')) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {
      'detail': response.body.isNotEmpty
          ? response.body
          : 'Server error (${response.statusCode})'
    };
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
      body:{
        'username': email, 
        'password': password
        },
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '779814360612-t3r0i8l4pa2r8jqfb1bcd4nh8e429tot.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve security token from Google.');
      }

      // Send it to your FastAPI backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      final data = _decode(response);
      if (response.statusCode == 200) {
        return data; 
      }
      throw Exception(data['detail'] ?? 'Google backend registration failed.');
    } catch (e) {
      debugPrint('Google Auth Client Error Trace: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  required String role,
  required String cuisineType, // Strictly required parameter
  required String address,     // Strictly required parameter
}) async {
  // 1. Build the baseline request body
  final Map<String, dynamic> requestBody = {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
  };

  // 2. Only expose/send these fields to the backend if registering a restaurant
  if (role == 'restaurant' || role == 'vendor') {
    requestBody['cuisine_type'] = cuisineType;
    requestBody['address'] = address;
  }

  // 3. Make the API call
  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  final data = _decode(response);
  if (response.statusCode == 201) return data;
  throw Exception(data['detail'] ?? 'Registration failed');
}

  // ── FORGOT / RESET PASSWORD ───────────────────────────────────────────────

  /// Called from the bottom sheet in login_screen.dart
  static Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/auth/forgot-password?email=${Uri.encodeComponent(email)}'),
    );
    if (response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to send reset code');
    }
  }

  /// Called from forgot_password_screen.dart Step 1
  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/auth/forgot-password?email=${Uri.encodeComponent(email)}'),
    );
    if (response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to send reset code');
    }
  }

  /// Called from forgot_password_screen.dart Step 2
  static Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'
          '?token=${Uri.encodeComponent(token)}'
          '&new_password=${Uri.encodeComponent(newPassword)}'),
    );
    if (response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to reset password');
    }
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
    required dynamic price,
  }) async {
    // FIX: Passing fields directly into the URI query string parameters 
    // to satisfy the backend validation requiring 'menu_input' in the query location.
    final response = await http.post(
      Uri.parse('$baseUrl/restaurants/$restaurantId/menu'
          '?name=${Uri.encodeComponent(name)}'
          '&description=${Uri.encodeComponent(description ?? "")}'
          '&price=${double.tryParse(price.toString()) ?? 0.0}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201) {
      final data = _decode(response);
      return MenuItem.fromJson(data);
    } else {
      throw Exception('Failed to add item (${response.statusCode}): ${response.body}');
    }
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

  static Future<Order> updateOrderStatus(
    String token,
    int orderId,
    String newStatus)
   async {
    final url = Uri.parse('$baseUrl/orders/$orderId/status').replace(
      queryParameters: {
        'new_status': newStatus,
      },
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Failed to update order status');
    }
    return Order.fromJson(data);
  }

  // ── DELIVERIES (Rider) ────────────────────────────────────────────────────

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

  // ── ADMIN ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPendingRestaurants(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurants?restaurant_status=pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load pending restaurants');
  }

  static Future<void> approveRestaurant(
      String token, int restaurantId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/restaurants/$restaurantId/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to approve');
    }
  }

  static Future<void> rejectRestaurant(
      String token, int restaurantId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/restaurants/$restaurantId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to reject');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load users');
  }

  static Future<Map<String, dynamic>> getPlatformStats(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return _decode(response);
    throw Exception('Failed to load stats');
  }

  static Future<Map<String, dynamic>> submitCheckout({
    required String token,
    required int restaurantId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'items': items,
        }),
      );

      final data = _decode(response);
      if (response.statusCode == 200) {
        return data;
      }
      throw Exception(data['detail'] ?? 'Checkout failed');
    } catch (e) {
      debugPrint('Checkout Error: $e');
      rethrow;
    }
  }

// ── MENU CRUD (edit/delete/toggle) ────────────────────────────────────────
  static Future<Restaurant> getMyRestaurant(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurants/mine'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return Restaurant.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to load your restaurant');
  }

  static Future<MenuItem> updateMenuItem({
    required String token,
    required int itemId,
    required String name,
    required String? description,
    required int price, required int restaurantId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
          {'name': name, 'description': description, 'price': price}),
    );
    final data = _decode(response);
    if (response.statusCode == 200) return MenuItem.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to update item');
  }

  static Future<bool> toggleMenuItem(String token, int itemId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/menu/$itemId/toggle'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data['is_available'] == true;
    throw Exception(data['detail'] ?? 'Failed to toggle item');
  }

  static Future<void> deleteMenuItem(String token, int itemId)  async {
    final url = Uri.parse('http://127.0.0.1:8000/menu/$itemId');
   
    final response = await http.delete(
     url,
      headers: {
        
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
        },
    );
    if (response.statusCode != 200) {
       _decode(response);
     throw Exception("Backend error: ${response.body}");
  }
}


  // ── ANALYTICS ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRestaurantAnalytics(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurants/mine/analytics'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to load analytics');
  }

  static Future<Map<String, dynamic>> getRiderAnalytics(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riders/me/analytics'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to load analytics');
  }

  // ── SCHEDULED ORDERS ──────────────────────────────────────────────────────
  static Future<Order> placeScheduledOrder({
    required String token,
    required int restaurantId,
    required List<Map<String, int>> items,
    required DateTime scheduledFor,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'restaurant_id': restaurantId,
        'items': items,
        'scheduled_for': scheduledFor.toIso8601String(),
      }),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return Order.fromJson(data);
    throw Exception(data['detail'] ?? 'Failed to schedule order');
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getChatMessages({
    required String token,
    required int orderId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load messages');
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String token,
    required int orderId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    final data = _decode(response);
    if (response.statusCode == 201) return data;
    throw Exception(data['detail'] ?? 'Failed to send message');
  }

  // ── RATINGS ───────────────────────────────────────────────────────────────
  static Future<void> submitRating({
    required String token,
    required int orderId,
    required int restaurantRating,
    required int riderRating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/rate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'restaurant_rating': restaurantRating,
        'rider_rating': riderRating,
        'comment': comment,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to submit rating');
    }
  }

  // ── MOMO PAYMENT (real gateway wiring) ────────────────────────────────────
  static Future<Map<String, dynamic>> initiateMomoPaymentReal({
    required String token,
    required int orderId,
    required String provider,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/momo/initiate'),
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
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw Exception(data['detail'] ?? 'MoMo payment failed');
  }

  static Future<Map<String, dynamic>> checkMomoPaymentStatus({
    required String token,
    required String referenceId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/momo/status/$referenceId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to check payment status');
  }

  static Future<void> updateNotificationPrefs
  ({required String token, required bool emailNotifications, required bool pushNotifications, required bool orderAlerts}) async {}

  static Future<Map<String, dynamic>> getNotificationPrefs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to load notification preferences');
  }

  
static Future<void> changeMyPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/change-password'
          '?current_password=${Uri.encodeComponent(currentPassword)}'
          '&new_password=${Uri.encodeComponent(newPassword)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final data = _decode(response);
      throw Exception(data['detail'] ?? 'Failed to change password');
    }
  }

  
  static Future<Map<String, dynamic>> updateMyProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'
          '?name=${Uri.encodeComponent(name)}'
          '&email=${Uri.encodeComponent(email)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to update profile');
  }
  
  static Future<Map<String, dynamic>> getMyProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to load profile');
  }

  static Future<Object?> toggleMenuItemAvailability({required String token, required int restaurantId, required int itemId}) async {
    return null;
  }

  static Future<void> removeMenuItemImage({required String token, required int restaurantId, required int itemId}) async {}

  static Future<MenuItem> uploadMenuItemImage({
    required String token, 
    required int restaurantId, 
    required int itemId,
     required Uint8List imageBytes, 
     required String filename}) async {

     final url = Uri.parse('$baseUrl/restaurants/$restaurantId/menu/$itemId/upload-image'); 
     final request = http.MultipartRequest('POST', url)
     ..headers['Authorization'] = 'Bearer \$token'
     // ignore: avoid_single_cascade_in_expression_statements
     ..files.add(
      http.MultipartFile.fromBytes(
        'file', // Must match the name parameter expected by your FastAPI backend (e.g., File(...))
        imageBytes,
        filename: filename,
        contentType: MediaType('image', filename.split('.').last == 'png' ? 'png' : 'jpeg'),
      ),
    );

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200 || response.statusCode == 201) {
    final Map<String, dynamic> data = json.decode(response.body);
    return MenuItem.fromJson(data); // This fulfills the promise to return a MenuItem
  } else {
    throw Exception('Failed to upload image: \${response.body}');
  }
}

static Future<Map<String, dynamic>> getRevenueDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/revenue'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode == 200) return data;
    throw Exception(data['detail'] ?? 'Failed to load revenue details');
  }

static Future<List<Map<String, dynamic>>> getAllOrdersAdmin(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load orders');
  }

  static Future<Object?> sendMessage({
  required String token, 
  required int orderId, 
  required String content,
}) async {
  final url = Uri.parse("http://127.0.0.1:8000/orders/$orderId/messages");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "message": content,
      }),
    );

    // 1. Log the status and body so we can see exactly what's happening
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    // 2. Accept both 200 (OK) and 201 (Created)
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body); 
    } else {
      print("Backend rejected with status: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Network Connection Error in sendMessage: $e");
    return null;
  }
}

  static Future<Object?> getMessages({
  required String token, 
  required int orderId,
}) async {
  // Replace with your local IP address (e.g. 192.168.x.x) if testing on a physical device!
  final url = Uri.parse("http://127.0.0.1:8000/orders/$orderId/messages");

  try {
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Returns the list of historical chat messages
    } else {
      print("Backend Error: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Network Connection Error in getMessages: $e");
    return null;
  }
}
     }
     


