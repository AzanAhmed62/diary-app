// App Information
class AppConstants {
  static const String appName = 'My Diary';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A personal digital diary app';
  
  // Database
  static const String databaseName = 'diary_database';
  static const int databaseVersion = 1;
  
  // Shared Preferences Keys
  static const String prefTheme = 'theme';
  static const String prefFontSize = 'font_size';
  static const String prefBiometric = 'biometric_enabled';
  static const String prefDefaultView = 'default_view';
  static const String prefAutoSave = 'auto_save';
  static const String prefSortBy = 'sort_by';
  static const String prefSortAscending = 'sort_ascending';
  
  // Theme Values
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSystem = 'system';
  
  // View Types
  static const String viewList = 'list';
  static const String viewGrid = 'grid';
  static const String viewTimeline = 'timeline';
  
  // Sort Options
  static const String sortByDate = 'date';
  static const String sortByTitle = 'title';
  static const String sortByModified = 'modified';
  
  // Default Values
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Text Limits
  static const int maxTitleLength = 100;
  static const int maxContentLength = 10000;
  static const int maxTagLength = 50;
  static const int maxTagsPerEntry = 10;
  
  // File Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Auto-save
  static const Duration autoSaveInterval = Duration(seconds: 30);
  
  // Backup
  static const int defaultBackupFrequency = 7; // days
  
  // Search
  static const int minSearchLength = 2;
  static const Duration searchDebounce = Duration(milliseconds: 500);
}

// Mood Constants
class MoodConstants {
  static const String happy = 'happy';
  static const String sad = 'sad';
  static const String excited = 'excited';
  static const String calm = 'calm';
  static const String angry = 'angry';
  static const String anxious = 'anxious';
  static const String grateful = 'grateful';
  static const String tired = 'tired';
  static const String confused = 'confused';
  static const String peaceful = 'peaceful';
  
  static const List<String> allMoods = [
    happy,
    sad,
    excited,
    calm,
    angry,
    anxious,
    grateful,
    tired,
    confused,
    peaceful,
  ];
  
  static const Map<String, String> moodEmojis = {
    happy: '😊',
    sad: '😢',
    excited: '🤩',
    calm: '😌',
    angry: '😠',
    anxious: '😰',
    grateful: '🙏',
    tired: '😴',
    confused: '😕',
    peaceful: '☮️',
  };
}

// Color Constants
class ColorConstants {
  static const Map<String, int> primaryColors = {
    'blue': 0xFF2196F3,
    'purple': 0xFF9C27B0,
    'teal': 0xFF009688,
    'green': 0xFF4CAF50,
    'orange': 0xFFFF9800,
    'red': 0xFFF44336,
    'pink': 0xFFE91E63,
    'indigo': 0xFF3F51B5,
  };
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String databaseError = 'Database error occurred. Please try again.';
  static const String fileError = 'File operation failed. Please try again.';
  static const String permissionError = 'Permission denied. Please grant necessary permissions.';
  static const String validationError = 'Please check your input and try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  
  // Entry specific
  static const String entryNotFound = 'Diary entry not found.';
  static const String entryTitleEmpty = 'Entry title cannot be empty.';
  static const String entryTitleTooLong = 'Entry title is too long (max ${AppConstants.maxTitleLength} characters).';
  static const String entryContentTooLong = 'Entry content is too long (max ${AppConstants.maxContentLength} characters).';
  
  // Search specific
  static const String searchQueryTooShort = 'Search query must be at least ${AppConstants.minSearchLength} characters.';
  static const String noSearchResults = 'No entries found matching your search.';
  
  // File specific
  static const String imageFileTooLarge = 'Image file is too large (max 5MB).';
  static const String unsupportedImageFormat = 'Unsupported image format. Supported formats: jpg, jpeg, png, gif.';
}

// Success Messages
class SuccessMessages {
  static const String entrySaved = 'Entry saved successfully!';
  static const String entryDeleted = 'Entry deleted successfully!';
  static const String entryUpdated = 'Entry updated successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  static const String dataExported = 'Data exported successfully!';
  static const String dataImported = 'Data imported successfully!';
  static const String backupCreated = 'Backup created successfully!';
}

// Routes
class Routes {
  static const String home = '/';
  static const String entryList = '/entries';
  static const String entryDetail = '/entry';
  static const String addEntry = '/add-entry';
  static const String editEntry = '/edit-entry';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String about = '/about';
}
