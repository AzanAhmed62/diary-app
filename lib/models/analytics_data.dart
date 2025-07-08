import 'package:hive/hive.dart';

part 'analytics_data.g.dart';

@HiveType(typeId: 2)
class AnalyticsData extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late int wordCount;

  @HiveField(2)
  late int characterCount;

  @HiveField(3)
  late int entriesCreated;

  @HiveField(4)
  late int entriesEdited;

  @HiveField(5)
  late Duration timeSpent; // Time spent writing

  @HiveField(6)
  late Map<String, int> moodCounts; // Mood frequency

  @HiveField(7)
  late Map<String, int> tagUsage; // Tag usage frequency

  @HiveField(8)
  late int streakDays; // Consecutive days of writing

  AnalyticsData({
    DateTime? date,
    this.wordCount = 0,
    this.characterCount = 0,
    this.entriesCreated = 0,
    this.entriesEdited = 0,
    Duration? timeSpent,
    Map<String, int>? moodCounts,
    Map<String, int>? tagUsage,
    this.streakDays = 0,
  }) {
    this.date = date ?? DateTime.now();
    this.timeSpent = timeSpent ?? Duration.zero;
    this.moodCounts = moodCounts ?? {};
    this.tagUsage = tagUsage ?? {};
  }

  // Create a copy with updated fields
  AnalyticsData copyWith({
    DateTime? date,
    int? wordCount,
    int? characterCount,
    int? entriesCreated,
    int? entriesEdited,
    Duration? timeSpent,
    Map<String, int>? moodCounts,
    Map<String, int>? tagUsage,
    int? streakDays,
  }) {
    return AnalyticsData(
      date: date ?? this.date,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      entriesCreated: entriesCreated ?? this.entriesCreated,
      entriesEdited: entriesEdited ?? this.entriesEdited,
      timeSpent: timeSpent ?? this.timeSpent,
      moodCounts: moodCounts ?? Map.from(this.moodCounts),
      tagUsage: tagUsage ?? Map.from(this.tagUsage),
      streakDays: streakDays ?? this.streakDays,
    );
  }

  // Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'wordCount': wordCount,
      'characterCount': characterCount,
      'entriesCreated': entriesCreated,
      'entriesEdited': entriesEdited,
      'timeSpent': timeSpent.inMilliseconds,
      'moodCounts': moodCounts,
      'tagUsage': tagUsage,
      'streakDays': streakDays,
    };
  }

  // Create from JSON for backup/import
  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      date: DateTime.parse(json['date']),
      wordCount: json['wordCount'] ?? 0,
      characterCount: json['characterCount'] ?? 0,
      entriesCreated: json['entriesCreated'] ?? 0,
      entriesEdited: json['entriesEdited'] ?? 0,
      timeSpent: Duration(milliseconds: json['timeSpent'] ?? 0),
      moodCounts: Map<String, int>.from(json['moodCounts'] ?? {}),
      tagUsage: Map<String, int>.from(json['tagUsage'] ?? {}),
      streakDays: json['streakDays'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'AnalyticsData{date: $date, wordCount: $wordCount, entriesCreated: $entriesCreated}';
  }
}

// Helper class for analytics calculations
class AnalyticsHelper {
  // Calculate words in a text
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // Calculate characters in a text (excluding spaces)
  static int countCharacters(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  // Calculate reading time estimate (average 200 words per minute)
  static Duration estimateReadingTime(int wordCount) {
    const wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return Duration(minutes: minutes);
  }

  // Get date key for analytics grouping
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get week key for analytics grouping
  static String getWeekKey(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return getDateKey(startOfWeek);
  }

  // Get month key for analytics grouping
  static String getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  // Calculate writing streak
  static int calculateWritingStreak(List<DateTime> entryDates) {
    if (entryDates.isEmpty) return 0;
    
    // Sort dates in descending order
    entryDates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    // Remove time component for date comparison
    currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
    
    for (final entryDate in entryDates) {
      final dateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
      final difference = currentDate.difference(dateOnly).inDays;
      
      if (difference == streak) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (difference > streak) {
        break;
      }
    }
    
    return streak;
  }
}
