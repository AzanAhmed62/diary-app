import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 1)
class UserPreferences extends HiveObject {
  @HiveField(0)
  late String theme; // 'light', 'dark', 'system'

  @HiveField(1)
  late double fontSize;

  @HiveField(2)
  late bool biometricEnabled;

  @HiveField(3)
  late String defaultView; // 'list', 'grid', 'timeline'

  @HiveField(4)
  late bool autoSave;

  @HiveField(5)
  late String sortBy; // 'date', 'title', 'modified'

  @HiveField(6)
  late bool sortAscending;

  @HiveField(7)
  late String primaryColor;

  @HiveField(8)
  late bool showPreview;

  @HiveField(9)
  late int backupFrequency; // days

  UserPreferences({
    this.theme = 'system',
    this.fontSize = 16.0,
    this.biometricEnabled = false,
    this.defaultView = 'list',
    this.autoSave = true,
    this.sortBy = 'date',
    this.sortAscending = false,
    this.primaryColor = 'blue',
    this.showPreview = true,
    this.backupFrequency = 7,
  });

  // Create a copy with updated fields
  UserPreferences copyWith({
    String? theme,
    double? fontSize,
    bool? biometricEnabled,
    String? defaultView,
    bool? autoSave,
    String? sortBy,
    bool? sortAscending,
    String? primaryColor,
    bool? showPreview,
    int? backupFrequency,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      defaultView: defaultView ?? this.defaultView,
      autoSave: autoSave ?? this.autoSave,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      primaryColor: primaryColor ?? this.primaryColor,
      showPreview: showPreview ?? this.showPreview,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  // Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'fontSize': fontSize,
      'biometricEnabled': biometricEnabled,
      'defaultView': defaultView,
      'autoSave': autoSave,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
      'primaryColor': primaryColor,
      'showPreview': showPreview,
      'backupFrequency': backupFrequency,
    };
  }

  // Create from JSON for backup/import
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] ?? 'system',
      fontSize: json['fontSize']?.toDouble() ?? 16.0,
      biometricEnabled: json['biometricEnabled'] ?? false,
      defaultView: json['defaultView'] ?? 'list',
      autoSave: json['autoSave'] ?? true,
      sortBy: json['sortBy'] ?? 'date',
      sortAscending: json['sortAscending'] ?? false,
      primaryColor: json['primaryColor'] ?? 'blue',
      showPreview: json['showPreview'] ?? true,
      backupFrequency: json['backupFrequency'] ?? 7,
    );
  }

  @override
  String toString() {
    return 'UserPreferences{theme: $theme, fontSize: $fontSize, defaultView: $defaultView}';
  }
}
