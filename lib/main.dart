import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'services/analytics_service.dart';
import 'services/cloud_sync_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (optional for cloud sync)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed (cloud sync disabled): $e');
  }
  
  // Initialize the database
  try {
    await DatabaseService.initialize();
    print('✅ Database initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize database: $e');
  }
  
  // Initialize analytics service
  try {
    await AnalyticsService.initialize();
    print('✅ Analytics service initialized successfully');
  } catch (e) {
    print('⚠️ Analytics service initialization failed: $e');
  }
  
  runApp(const ProviderScope(child: DiaryApp()));
}

class DiaryApp extends ConsumerWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follow system theme
      
      // Home screen
      home: const HomeScreen(),
      
      // Error handling
      builder: (context, child) {
        // Handle any global errors or setup here
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
