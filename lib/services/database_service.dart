import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/user_preferences.dart';

class DatabaseService {
  static const String _entriesBoxName = 'diary_entries';
  static const String _preferencesBoxName = 'user_preferences';
  
  static Box<DiaryEntry>? _entriesBox;
  static Box<UserPreferences>? _preferencesBox;

  /// Initialize the database
  static Future<void> initialize() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DiaryEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      
      // Open boxes
      _entriesBox = await Hive.openBox<DiaryEntry>(_entriesBoxName);
      _preferencesBox = await Hive.openBox<UserPreferences>(_preferencesBoxName);
      
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  /// Close all boxes
  static Future<void> close() async {
    await _entriesBox?.close();
    await _preferencesBox?.close();
  }

  /// Get the entries box
  static Box<DiaryEntry> get entriesBox {
    if (_entriesBox == null || !_entriesBox!.isOpen) {
      throw Exception('Entries box is not initialized. Call initialize() first.');
    }
    return _entriesBox!;
  }

  /// Get the preferences box
  static Box<UserPreferences> get preferencesBox {
    if (_preferencesBox == null || !_preferencesBox!.isOpen) {
      throw Exception('Preferences box is not initialized. Call initialize() first.');
    }
    return _preferencesBox!;
  }

  // DIARY ENTRIES METHODS

  /// Get all diary entries
  static List<DiaryEntry> getAllEntries() {
    return entriesBox.values.toList();
  }

  /// Get diary entry by ID
  static DiaryEntry? getEntryById(String id) {
    return entriesBox.values.firstWhere(
      (entry) => entry.id == id,
      orElse: () => throw Exception('Entry not found'),
    );
  }

  /// Add a new diary entry
  static Future<void> addEntry(DiaryEntry entry) async {
    try {
      await entriesBox.add(entry);
      print('Entry added successfully: ${entry.id}');
    } catch (e) {
      print('Error adding entry: $e');
      rethrow;
    }
  }

  /// Update an existing diary entry
  static Future<void> updateEntry(DiaryEntry entry) async {
    try {
      // Find the entry in the box
      final entryKey = entriesBox.keys.firstWhere(
        (key) => entriesBox.get(key)?.id == entry.id,
        orElse: () => throw Exception('Entry not found'),
      );
      
      // Update the updatedAt timestamp
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      
      await entriesBox.put(entryKey, updatedEntry);
      print('Entry updated successfully: ${entry.id}');
    } catch (e) {
      print('Error updating entry: $e');
      rethrow;
    }
  }

  /// Delete a diary entry
  static Future<void> deleteEntry(String id) async {
    try {
      // Find the entry in the box
      final entryKey = entriesBox.keys.firstWhere(
        (key) => entriesBox.get(key)?.id == id,
        orElse: () => throw Exception('Entry not found'),
      );
      
      await entriesBox.delete(entryKey);
      print('Entry deleted successfully: $id');
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  /// Search entries by title or content
  static List<DiaryEntry> searchEntries(String query) {
    final lowercaseQuery = query.toLowerCase();
    return entriesBox.values.where((entry) {
      return entry.title.toLowerCase().contains(lowercaseQuery) ||
             entry.content.toLowerCase().contains(lowercaseQuery) ||
             entry.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Get entries by date range
  static List<DiaryEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return entriesBox.values.where((entry) {
      return entry.createdAt.isAfter(start) && entry.createdAt.isBefore(end);
    }).toList();
  }

  /// Get entries by tags
  static List<DiaryEntry> getEntriesByTags(List<String> tags) {
    return entriesBox.values.where((entry) {
      return tags.any((tag) => entry.tags.contains(tag));
    }).toList();
  }

  /// Get favorite entries
  static List<DiaryEntry> getFavoriteEntries() {
    return entriesBox.values.where((entry) => entry.isFavorite).toList();
  }

  /// Get entries sorted by specified criteria
  static List<DiaryEntry> getSortedEntries(String sortBy, bool ascending) {
    final entries = getAllEntries();
    
    switch (sortBy) {
      case 'date':
        entries.sort((a, b) => ascending 
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
        break;
      case 'title':
        entries.sort((a, b) => ascending 
          ? a.title.compareTo(b.title)
          : b.title.compareTo(a.title));
        break;
      case 'modified':
        entries.sort((a, b) => ascending 
          ? a.updatedAt.compareTo(b.updatedAt)
          : b.updatedAt.compareTo(a.updatedAt));
        break;
      default:
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return entries;
  }

  // USER PREFERENCES METHODS

  /// Get user preferences
  static UserPreferences getUserPreferences() {
    return preferencesBox.get('preferences') ?? UserPreferences();
  }

  /// Save user preferences
  static Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      await preferencesBox.put('preferences', preferences);
      print('User preferences saved successfully');
    } catch (e) {
      print('Error saving user preferences: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  /// Get database statistics
  static Map<String, dynamic> getDatabaseStats() {
    return {
      'totalEntries': entriesBox.length,
      'favoriteEntries': getFavoriteEntries().length,
      'uniqueTags': _getUniqueTags().length,
      'databaseSize': _calculateDatabaseSize(),
    };
  }

  /// Get all unique tags
  static List<String> _getUniqueTags() {
    final Set<String> uniqueTags = {};
    for (final entry in entriesBox.values) {
      uniqueTags.addAll(entry.tags);
    }
    return uniqueTags.toList()..sort();
  }

  /// Calculate approximate database size
  static int _calculateDatabaseSize() {
    // This is a rough estimate
    return entriesBox.length * 1000; // Assuming average 1KB per entry
  }

  /// Clear all data (use with caution)
  static Future<void> clearAllData() async {
    try {
      await entriesBox.clear();
      await preferencesBox.clear();
      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  /// Compact database (optimize storage)
  static Future<void> compactDatabase() async {
    try {
      await entriesBox.compact();
      await preferencesBox.compact();
      print('Database compacted successfully');
    } catch (e) {
      print('Error compacting database: $e');
      rethrow;
    }
  }
}
