import 'package:flutter/material.dart';
import '../models/models.dart';

// ─── THEME PROVIDER ───────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

// ─── AUTH PROVIDER ────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  String? _token;
  int?    _userId;
  String? _role;
  String? _name;
  bool    _isLoggedIn = false;

  String? get token      => _token;
  int?    get userId     => _userId;
  String? get role       => _role;
  String? get name       => _name;
  bool    get isLoggedIn => _isLoggedIn;

  bool get isCustomer   => _role == 'customer';
  bool get isRestaurant => _role == 'restaurant';
  bool get isRider      => _role == 'rider';
  bool get isAdmin      => _role == 'admin';

  void login({required String token, required int userId,
      required String role, String? name}) {
    _token = token; _userId = userId;
    _role = role; _name = name; _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _token = null; _userId = null;
    _role = null; _name = null; _isLoggedIn = false;
    notifyListeners();
  }
}

// ─── CART PROVIDER ────────────────────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int?    _restaurantId;
  String? _restaurantName;

  List<CartItem> get items          => _items;
  int?           get restaurantId   => _restaurantId;
  String?        get restaurantName => _restaurantName;
  bool           get isEmpty        => _items.isEmpty;
  int            get itemCount      => _items.fold(0, (s, i) => s + i.quantity);
  int            get totalAmount    => _items.fold(0, (s, i) => s + i.subtotal);
  String         get displayTotal   =>
      'GH₵ ${(totalAmount / 100).toStringAsFixed(2)}';

  List<Map<String, int>> get orderPayload => _items
      .map((i) => {'menu_item_id': i.menuItem.id, 'quantity': i.quantity})
      .toList();

  void addItem(MenuItem menuItem, int restaurantId, String restaurantName) {
    if (_restaurantId != null && _restaurantId != restaurantId) _items.clear();
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
    final existing = _items.where((i) => i.menuItem.id == menuItem.id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void decreaseItem(int menuItemId) {
    final item = _items.where((i) => i.menuItem.id == menuItemId).firstOrNull;
    if (item == null) return;
    if (item.quantity > 1) { item.quantity--; } else { _items.remove(item); }
    if (_items.isEmpty) _restaurantId = null;
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    if (_items.isEmpty) _restaurantId = null;
    notifyListeners();
  }

  void clearCart() {
    _items.clear(); _restaurantId = null; _restaurantName = null;
    notifyListeners();
  }

  // backward compat
  void setLoggedIn(bool value, {String? token, int? userId, String? role}) {}
}