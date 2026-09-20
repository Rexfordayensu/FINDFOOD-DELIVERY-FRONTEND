import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalCustomerStore {
  static const _storage = FlutterSecureStorage();
  
  static const String _favoritesKey = 'favorite_restaurant_ids';
  static const String _recentViewsKey = 'recently_viewed_ids';
  static const String _recentSearchesKey = 'recent_searches_list';

  // Read list and convert internal string elements back to integers natively
  static Future<List<int>> _getIntList(String key) async {
    final data = await _storage.read(key: key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch favorite restaurant IDs as integers
  static Future<List<int>> favoriteRestaurantIds() async {
    return await _getIntList(_favoritesKey);
  }

  // Fetch recently viewed restaurant IDs as integers
  static Future<List<int>> recentlyViewedIds() async {
    return await _getIntList(_recentViewsKey);
  }

  // Fetch historical keyword searches (Still strings because text words are letters)
  static Future<List<String>> recentSearches() async {
    final data = await _storage.read(key: _recentSearchesKey);
    if (data == null) return [];
    try {
      return List<String>.from(json.decode(data));
    } catch (_) {
      return [];
    }
  }

  // Toggle restaurant favorite status natively using an integer
  static Future<void> toggleFavorite(int restaurantId) async {
    final recents = await _getIntList(_favoritesKey);
    final List<String> stringList = recents.map((e) => e.toString()).toList();
    final idString = restaurantId.toString();

    if (stringList.contains(idString)) {
      stringList.remove(idString);
    } else {
      stringList.add(idString);
    }
    await _storage.write(key: _favoritesKey, value: json.encode(stringList));
  }

  // Append new item to recently viewed history list using an integer
  static Future<void> addRecentlyViewed(int restaurantId) async {
    final recents = await _getIntList(_recentViewsKey);
    final List<String> stringList = recents.map((e) => e.toString()).toList();
    final idString = restaurantId.toString();

    stringList.remove(idString); 
    stringList.insert(0, idString); 
    if (stringList.length > 10) stringList.removeLast(); 
    await _storage.write(key: _recentViewsKey, value: json.encode(stringList));
  }

  // Append a query search keyword tracking string
  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    final data = await _storage.read(key: _recentSearchesKey);
    List<String> searches = [];
    if (data != null) {
      try { searches = List<String>.from(json.decode(data)); } catch (_) {}
    }
    final cleanQuery = query.trim();
    searches.remove(cleanQuery);
    searches.insert(0, cleanQuery);
    if (searches.length > 15) searches.removeLast();
    await _storage.write(key: _recentSearchesKey, value: json.encode(searches));
  }
}
