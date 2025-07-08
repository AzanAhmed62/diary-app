import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
import '../models/analytics_data.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class AnalyticsService {
  static const String _analyticsBoxName = 'analytics_data';
  static Box<AnalyticsData>? _analyticsBox;
  
  /// Initialize analytics service
  static Future<void> initialize() async {
    try {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AnalyticsDataAdapter());
      }
      
      // Open box
      _analyticsBox = await Hive.openBox<AnalyticsData>(_analyticsBoxName);
      print('Analytics service initialized successfully');
    } catch (e) {
      print('Error initializing analytics service: $e');
      rethrow;
    }
  }
  
  /// Get the analytics box
  static Box<AnalyticsData> get analyticsBox {
    if (_analyticsBox == null || !_analyticsBox!.isOpen) {
      throw Exception('Analytics box is not initialized. Call initialize() first.');
    }
    return _analyticsBox!;
  }
  
  /// Track entry creation
  static Future<void> trackEntryCreated(DiaryEntry entry) async {
    try {
      final today = DateTime.now();
      final dateKey = AnalyticsHelper.getDateKey(today);
      
      AnalyticsData? todayData = analyticsBox.get(dateKey);
      
      if (todayData == null) {
        todayData = AnalyticsData(date: today);
      }
      
      // Update statistics
      final wordCount = AnalyticsHelper.countWords(entry.content);
      final characterCount = AnalyticsHelper.countCharacters(entry.content);
      
      final updatedData = todayData.copyWith(
        entriesCreated: todayData.entriesCreated + 1,
        wordCount: todayData.wordCount + wordCount,
        characterCount: todayData.characterCount + characterCount,
      );
      
      // Update mood counts
      if (entry.mood != null) {
        final moodCounts = Map<String, int>.from(updatedData.moodCounts);
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
        updatedData.moodCounts.clear();
        updatedData.moodCounts.addAll(moodCounts);
      }
      
      // Update tag usage
      final tagUsage = Map<String, int>.from(updatedData.tagUsage);
      for (final tag in entry.tags) {
        tagUsage[tag] = (tagUsage[tag] ?? 0) + 1;
      }
      updatedData.tagUsage.clear();
      updatedData.tagUsage.addAll(tagUsage);
      
      await analyticsBox.put(dateKey, updatedData);
      
      // Update writing streak
      await _updateWritingStreak();
      
    } catch (e) {
      print('Error tracking entry creation: $e');
    }
  }
  
  /// Track entry edit
  static Future<void> trackEntryEdited(DiaryEntry entry) async {
    try {
      final today = DateTime.now();
      final dateKey = AnalyticsHelper.getDateKey(today);
      
      AnalyticsData? todayData = analyticsBox.get(dateKey);
      
      if (todayData == null) {
        todayData = AnalyticsData(date: today);
      }
      
      final updatedData = todayData.copyWith(
        entriesEdited: todayData.entriesEdited + 1,
      );
      
      await analyticsBox.put(dateKey, updatedData);
      
    } catch (e) {
      print('Error tracking entry edit: $e');
    }
  }
  
  /// Track writing time
  static Future<void> trackWritingTime(Duration timeSpent) async {
    try {
      final today = DateTime.now();
      final dateKey = AnalyticsHelper.getDateKey(today);
      
      AnalyticsData? todayData = analyticsBox.get(dateKey);
      
      if (todayData == null) {
        todayData = AnalyticsData(date: today);
      }
      
      final updatedData = todayData.copyWith(
        timeSpent: todayData.timeSpent + timeSpent,
      );
      
      await analyticsBox.put(dateKey, updatedData);
      
    } catch (e) {
      print('Error tracking writing time: $e');
    }
  }
  
  /// Update writing streak
  static Future<void> _updateWritingStreak() async {
    try {
      final allEntries = DatabaseService.getAllEntries();
      final entryDates = allEntries.map((e) => e.createdAt).toList();
      final streak = AnalyticsHelper.calculateWritingStreak(entryDates);
      
      // Update today's analytics with current streak
      final today = DateTime.now();
      final dateKey = AnalyticsHelper.getDateKey(today);
      
      AnalyticsData? todayData = analyticsBox.get(dateKey);
      if (todayData != null) {
        final updatedData = todayData.copyWith(streakDays: streak);
        await analyticsBox.put(dateKey, updatedData);
      }
      
    } catch (e) {
      print('Error updating writing streak: $e');
    }
  }
  
  /// Get writing statistics for a date range
  static Map<String, dynamic> getWritingStats({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;
      
      int totalEntries = 0;
      int totalWords = 0;
      int totalCharacters = 0;
      int totalEdits = 0;
      Duration totalTimeSpent = Duration.zero;
      final Map<String, int> moodCounts = {};
      final Map<String, int> tagUsage = {};
      
      // Iterate through date range
      DateTime currentDate = start;
      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        final dateKey = AnalyticsHelper.getDateKey(currentDate);
        final data = analyticsBox.get(dateKey);
        
        if (data != null) {
          totalEntries += data.entriesCreated;
          totalWords += data.wordCount;
          totalCharacters += data.characterCount;
          totalEdits += data.entriesEdited;
          totalTimeSpent += data.timeSpent;
          
          // Merge mood counts
          data.moodCounts.forEach((mood, count) {
            moodCounts[mood] = (moodCounts[mood] ?? 0) + count;
          });
          
          // Merge tag usage
          data.tagUsage.forEach((tag, count) {
            tagUsage[tag] = (tagUsage[tag] ?? 0) + count;
          });
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // Calculate averages
      final daySpan = end.difference(start).inDays + 1;
      final avgWordsPerDay = daySpan > 0 ? totalWords / daySpan : 0;
      final avgEntriesPerDay = daySpan > 0 ? totalEntries / daySpan : 0;
      final avgTimePerDay = daySpan > 0 ? totalTimeSpent ~/ daySpan : Duration.zero;
      
      // Get current streak
      final allEntries = DatabaseService.getAllEntries();
      final entryDates = allEntries.map((e) => e.createdAt).toList();
      final currentStreak = AnalyticsHelper.calculateWritingStreak(entryDates);
      
      // Calculate reading time
      final estimatedReadingTime = AnalyticsHelper.estimateReadingTime(totalWords);
      
      return {
        'period': {
          'startDate': start,
          'endDate': end,
          'daySpan': daySpan,
        },
        'totals': {
          'entries': totalEntries,
          'words': totalWords,
          'characters': totalCharacters,
          'edits': totalEdits,
          'timeSpent': totalTimeSpent,
          'estimatedReadingTime': estimatedReadingTime,
        },
        'averages': {
          'wordsPerDay': avgWordsPerDay.round(),
          'entriesPerDay': avgEntriesPerDay,
          'timePerDay': avgTimePerDay,
        },
        'streak': {
          'currentStreak': currentStreak,
          'longestStreak': _getLongestStreak(),
        },
        'moods': moodCounts,
        'tags': tagUsage,
      };
    } catch (e) {
      print('Error getting writing stats: $e');
      return {};
    }
  }
  
  /// Get mood trends data for charts
  static List<Map<String, dynamic>> getMoodTrends({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;
      
      final List<Map<String, dynamic>> trends = [];
      
      DateTime currentDate = start;
      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        final dateKey = AnalyticsHelper.getDateKey(currentDate);
        final data = analyticsBox.get(dateKey);
        
        if (data != null && data.moodCounts.isNotEmpty) {
          // Find most common mood for the day
          String? dominantMood;
          int maxCount = 0;
          
          data.moodCounts.forEach((mood, count) {
            if (count > maxCount) {
              maxCount = count;
              dominantMood = mood;
            }
          });
          
          if (dominantMood != null) {
            trends.add({
              'date': currentDate,
              'mood': dominantMood,
              'count': maxCount,
              'allMoods': data.moodCounts,
            });
          }
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return trends;
    } catch (e) {
      print('Error getting mood trends: $e');
      return [];
    }
  }
  
  /// Get writing activity data for charts
  static List<Map<String, dynamic>> getWritingActivity({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;
      
      final List<Map<String, dynamic>> activity = [];
      
      DateTime currentDate = start;
      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        final dateKey = AnalyticsHelper.getDateKey(currentDate);
        final data = analyticsBox.get(dateKey);
        
        activity.add({
          'date': currentDate,
          'entries': data?.entriesCreated ?? 0,
          'words': data?.wordCount ?? 0,
          'timeSpent': data?.timeSpent ?? Duration.zero,
        });
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return activity;
    } catch (e) {
      print('Error getting writing activity: $e');
      return [];
    }
  }
  
  /// Get top tags by usage
  static List<Map<String, dynamic>> getTopTags({int limit = 10}) {
    try {
      final Map<String, int> allTagUsage = {};
      
      // Aggregate all tag usage
      for (final data in analyticsBox.values) {
        data.tagUsage.forEach((tag, count) {
          allTagUsage[tag] = (allTagUsage[tag] ?? 0) + count;
        });
      }
      
      // Sort by usage count
      final sortedTags = allTagUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedTags
          .take(limit)
          .map((entry) => {
                'tag': entry.key,
                'count': entry.value,
              })
          .toList();
    } catch (e) {
      print('Error getting top tags: $e');
      return [];
    }
  }
  
  /// Get writing productivity insights
  static Map<String, dynamic> getProductivityInsights() {
    try {
      final last30Days = getWritingStats(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      final last7Days = getWritingStats(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      
      final yesterday = getWritingStats(
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      // Calculate trends
      final wordsLast30 = last30Days['totals']['words'] as int;
      final wordsLast7 = last7Days['totals']['words'] as int;
      final entriesLast30 = last30Days['totals']['entries'] as int;
      final entriesLast7 = last7Days['totals']['entries'] as int;
      
      // Weekly vs monthly average
      final weeklyWordTrend = wordsLast7 > (wordsLast30 / 4.0);
      final weeklyEntryTrend = entriesLast7 > (entriesLast30 / 4.0);
      
      // Best writing day of week
      final bestDayOfWeek = _getBestWritingDayOfWeek();
      
      // Most productive hour (if we track time data)
      final mostProductiveHour = _getMostProductiveHour();
      
      return {
        'trends': {
          'wordsTrendUp': weeklyWordTrend,
          'entriesTrendUp': weeklyEntryTrend,
        },
        'patterns': {
          'bestDayOfWeek': bestDayOfWeek,
          'mostProductiveHour': mostProductiveHour,
        },
        'streaks': {
          'current': last30Days['streak']['currentStreak'],
          'longest': last30Days['streak']['longestStreak'],
        },
        'averages': {
          'last7Days': last7Days['averages'],
          'last30Days': last30Days['averages'],
        },
      };
    } catch (e) {
      print('Error getting productivity insights: $e');
      return {};
    }
  }
  
  /// Get longest writing streak
  static int _getLongestStreak() {
    try {
      final allEntries = DatabaseService.getAllEntries();
      if (allEntries.isEmpty) return 0;
      
      // Group entries by date
      final Map<String, List<DiaryEntry>> entriesByDate = {};
      for (final entry in allEntries) {
        final dateKey = AnalyticsHelper.getDateKey(entry.createdAt);
        entriesByDate.putIfAbsent(dateKey, () => []).add(entry);
      }
      
      // Sort dates
      final sortedDates = entriesByDate.keys.toList()..sort();
      
      int longestStreak = 0;
      int currentStreak = 0;
      DateTime? lastDate;
      
      for (final dateStr in sortedDates) {
        final date = DateTime.parse('$dateStr 00:00:00');
        
        if (lastDate == null || date.difference(lastDate).inDays == 1) {
          currentStreak++;
        } else {
          longestStreak = max(longestStreak, currentStreak);
          currentStreak = 1;
        }
        
        lastDate = date;
      }
      
      return max(longestStreak, currentStreak);
    } catch (e) {
      print('Error calculating longest streak: $e');
      return 0;
    }
  }
  
  /// Get best writing day of week
  static String _getBestWritingDayOfWeek() {
    try {
      final Map<int, int> dayWordCounts = {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0
      };
      
      for (final data in analyticsBox.values) {
        final dayOfWeek = data.date.weekday;
        dayWordCounts[dayOfWeek] = dayWordCounts[dayOfWeek]! + data.wordCount;
      }
      
      int bestDay = 1;
      int maxWords = 0;
      
      dayWordCounts.forEach((day, words) {
        if (words > maxWords) {
          maxWords = words;
          bestDay = day;
        }
      });
      
      const dayNames = [
        '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ];
      
      return dayNames[bestDay];
    } catch (e) {
      print('Error getting best writing day: $e');
      return 'Monday';
    }
  }
  
  /// Get most productive hour (placeholder for future implementation)
  static int _getMostProductiveHour() {
    // This would require tracking entry creation times by hour
    // For now, return a reasonable default
    return 20; // 8 PM
  }
  
  /// Export analytics data to JSON
  static Map<String, dynamic> exportAnalyticsData() {
    try {
      final allData = analyticsBox.values.map((data) => data.toJson()).toList();
      
      return {
        'analytics': allData,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      print('Error exporting analytics data: $e');
      return {};
    }
  }
  
  /// Import analytics data from JSON
  static Future<bool> importAnalyticsData(Map<String, dynamic> data) async {
    try {
      final analyticsData = data['analytics'] as List?;
      if (analyticsData == null) return false;
      
      for (final item in analyticsData) {
        final analytics = AnalyticsData.fromJson(item);
        final dateKey = AnalyticsHelper.getDateKey(analytics.date);
        await analyticsBox.put(dateKey, analytics);
      }
      
      return true;
    } catch (e) {
      print('Error importing analytics data: $e');
      return false;
    }
  }
  
  /// Clear all analytics data
  static Future<void> clearAnalyticsData() async {
    try {
      await analyticsBox.clear();
      print('Analytics data cleared successfully');
    } catch (e) {
      print('Error clearing analytics data: $e');
      rethrow;
    }
  }
}
