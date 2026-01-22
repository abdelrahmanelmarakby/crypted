// Search History Service - Persists recent chat search queries
// Phase 2 Enhancement: Search history for quick access to recent searches

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing chat search history
/// Stores recent search queries in SharedPreferences for persistence
class SearchHistoryService {
  static const String _storageKey = 'chat_search_history';
  static const int _maxHistoryItems = 10;

  /// Singleton instance
  static final SearchHistoryService _instance = SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  /// Cache for search history
  List<String> _historyCache = [];
  bool _isInitialized = false;

  /// Initialize the service and load history from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    _historyCache = await _loadFromStorage();
    _isInitialized = true;
  }

  /// Get the search history (most recent first)
  Future<List<String>> getHistory() async {
    await initialize();
    return List.unmodifiable(_historyCache);
  }

  /// Add a search query to history
  /// - Removes duplicates (moves existing query to top)
  /// - Limits history to [_maxHistoryItems] items
  Future<void> addToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    await initialize();

    // Remove existing entry if present (to move to top)
    _historyCache.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());

    // Add to beginning (most recent)
    _historyCache.insert(0, trimmed);

    // Enforce max limit
    if (_historyCache.length > _maxHistoryItems) {
      _historyCache = _historyCache.sublist(0, _maxHistoryItems);
    }

    await _saveToStorage();
  }

  /// Remove a specific query from history
  Future<void> removeFromHistory(String query) async {
    await initialize();
    _historyCache.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    await _saveToStorage();
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    _historyCache.clear();
    await _saveToStorage();
  }

  /// Check if history is empty
  Future<bool> isEmpty() async {
    await initialize();
    return _historyCache.isEmpty;
  }

  /// Load history from SharedPreferences
  Future<List<String>> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (e) {
      // If there's an error reading, return empty list
      return [];
    }
  }

  /// Save history to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_historyCache);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Silently fail - history is not critical
    }
  }
}
