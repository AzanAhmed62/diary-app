import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/user_preferences.dart';
import '../models/analytics_data.dart';
import 'database_service.dart';

class CloudSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final Connectivity _connectivity = Connectivity();
  
  // Encryption
  static final _key = Key.fromSecureRandom(32);
  static final _iv = IV.fromSecureRandom(16);
  static final _encrypter = Encrypter(AES(_key));
  
  // Collection names
  static const String _entriesCollection = 'diary_entries';
  static const String _preferencesCollection = 'user_preferences';
  static const String _analyticsCollection = 'analytics_data';
  static const String _syncMetaCollection = 'sync_metadata';
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;
  
  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check network connectivity
  static Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// Sign in anonymously (for demo purposes)
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Encrypt sensitive data
  static String _encryptData(String data) {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }
  
  /// Decrypt sensitive data
  static String _decryptData(String encryptedData) {
    final encrypted = Encrypted.fromBase64(encryptedData);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
  
  /// Sync all data to cloud
  static Future<bool> syncToCloud({bool forceSync = false}) async {
    if (!isAuthenticated) {
      print('User not authenticated');
      return false;
    }
    
    if (!await hasInternetConnection()) {
      print('No internet connection');
      return false;
    }
    
    try {
      final userId = currentUserId!;
      
      // Check if sync is needed
      if (!forceSync && !await _isSyncNeeded()) {
        print('Sync not needed');
        return true;
      }
      
      // Sync entries
      await _syncEntriesToCloud(userId);
      
      // Sync preferences
      await _syncPreferencesToCloud(userId);
      
      // Sync analytics
      await _syncAnalyticsToCloud(userId);
      
      // Update sync metadata
      await _updateSyncMetadata(userId);
      
      print('✅ Cloud sync completed successfully');
      return true;
    } catch (e) {
      print('❌ Error syncing to cloud: $e');
      return false;
    }
  }
  
  /// Sync data from cloud
  static Future<bool> syncFromCloud() async {
    if (!isAuthenticated) {
      print('User not authenticated');
      return false;
    }
    
    if (!await hasInternetConnection()) {
      print('No internet connection');
      return false;
    }
    
    try {
      final userId = currentUserId!;
      
      // Sync entries from cloud
      await _syncEntriesFromCloud(userId);
      
      // Sync preferences from cloud
      await _syncPreferencesFromCloud(userId);
      
      // Sync analytics from cloud
      await _syncAnalyticsFromCloud(userId);
      
      print('✅ Cloud sync from cloud completed successfully');
      return true;
    } catch (e) {
      print('❌ Error syncing from cloud: $e');
      return false;
    }
  }
  
  /// Check if sync is needed
  static Future<bool> _isSyncNeeded() async {
    try {
      final userId = currentUserId!;
      final metaDoc = await _firestore
          .collection(_syncMetaCollection)
          .doc(userId)
          .get();
      
      if (!metaDoc.exists) return true;
      
      final lastSync = (metaDoc.data()?['lastSync'] as Timestamp?)?.toDate();
      if (lastSync == null) return true;
      
      // Check if local data has been modified since last sync
      final localEntries = DatabaseService.getAllEntries();
      for (final entry in localEntries) {
        if (entry.updatedAt.isAfter(lastSync)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking sync status: $e');
      return true; // Assume sync is needed if we can't check
    }
  }
  
  /// Sync entries to cloud
  static Future<void> _syncEntriesToCloud(String userId) async {
    final entries = DatabaseService.getAllEntries();
    final batch = _firestore.batch();
    
    for (final entry in entries) {
      final docRef = _firestore
          .collection(_entriesCollection)
          .doc(userId)
          .collection('entries')
          .doc(entry.id);
      
      // Encrypt sensitive content
      final encryptedContent = _encryptData(entry.content);
      final data = entry.toJson();
      data['content'] = encryptedContent;
      
      batch.set(docRef, data, SetOptions(merge: true));
    }
    
    await batch.commit();
  }
  
  /// Sync entries from cloud
  static Future<void> _syncEntriesFromCloud(String userId) async {
    final snapshot = await _firestore
        .collection(_entriesCollection)
        .doc(userId)
        .collection('entries')
        .get();
    
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        
        // Decrypt content
        if (data['content'] != null) {
          data['content'] = _decryptData(data['content']);
        }
        
        final entry = DiaryEntry.fromJson(data);
        
        // Check if entry exists locally
        try {
          final existingEntry = DatabaseService.getEntryById(entry.id);
          if (existingEntry != null && existingEntry.updatedAt.isBefore(entry.updatedAt)) {
            await DatabaseService.updateEntry(entry);
          }
        } catch (e) {
          // Entry doesn't exist locally, add it
          await DatabaseService.addEntry(entry);
        }
      } catch (e) {
        print('Error syncing entry ${doc.id}: $e');
      }
    }
  }
  
  /// Sync preferences to cloud
  static Future<void> _syncPreferencesToCloud(String userId) async {
    final preferences = DatabaseService.getUserPreferences();
    
    await _firestore
        .collection(_preferencesCollection)
        .doc(userId)
        .set(preferences.toJson(), SetOptions(merge: true));
  }
  
  /// Sync preferences from cloud
  static Future<void> _syncPreferencesFromCloud(String userId) async {
    final doc = await _firestore
        .collection(_preferencesCollection)
        .doc(userId)
        .get();
    
    if (doc.exists) {
      final preferences = UserPreferences.fromJson(doc.data()!);
      await DatabaseService.saveUserPreferences(preferences);
    }
  }
  
  /// Sync analytics to cloud
  static Future<void> _syncAnalyticsToCloud(String userId) async {
    // Note: Analytics will be implemented with a separate service
    // This is a placeholder for future implementation
  }
  
  /// Sync analytics from cloud
  static Future<void> _syncAnalyticsFromCloud(String userId) async {
    // Note: Analytics will be implemented with a separate service
    // This is a placeholder for future implementation
  }
  
  /// Update sync metadata
  static Future<void> _updateSyncMetadata(String userId) async {
    await _firestore
        .collection(_syncMetaCollection)
        .doc(userId)
        .set({
      'lastSync': FieldValue.serverTimestamp(),
      'deviceId': await _getDeviceId(),
      'version': '1.0.0',
    }, SetOptions(merge: true));
  }
  
  /// Get device identifier
  static Future<String> _getDeviceId() async {
    // Simple device identifier for demo purposes
    return Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'other';
  }
  
  /// Upload file to Firebase Storage
  static Future<String?> uploadFile(File file, String path) async {
    if (!isAuthenticated) return null;
    
    try {
      final userId = currentUserId!;
      final ref = _storage.ref().child('users/$userId/$path');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Download file from Firebase Storage
  static Future<File?> downloadFile(String url, String localPath) async {
    try {
      final ref = _storage.refFromURL(url);
      final file = File(localPath);
      
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
  
  /// Create full backup
  static Future<String?> createFullBackup() async {
    if (!isAuthenticated) return null;
    
    try {
      final userId = currentUserId!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Gather all data
      final entries = DatabaseService.getAllEntries();
      final preferences = DatabaseService.getUserPreferences();
      
      final backupData = {
        'timestamp': timestamp,
        'version': '1.0.0',
        'entries': entries.map((e) => e.toJson()).toList(),
        'preferences': preferences.toJson(),
        'metadata': {
          'totalEntries': entries.length,
          'createdAt': DateTime.now().toIso8601String(),
        },
      };
      
      // Convert to JSON and compress
      final jsonString = jsonEncode(backupData);
      final compressed = gzip.encode(utf8.encode(jsonString));
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/diary_backup_$timestamp.gz');
      await backupFile.writeAsBytes(compressed);
      
      // Upload to cloud storage
      final downloadUrl = await uploadFile(
        backupFile,
        'backups/full_backup_$timestamp.gz',
      );
      
      // Clean up temporary file
      await backupFile.delete();
      
      return downloadUrl;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }
  
  /// Restore from backup
  static Future<bool> restoreFromBackup(String backupUrl) async {
    try {
      // Download backup file
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/restore_backup.gz');
      
      final downloadedFile = await downloadFile(backupUrl, backupFile.path);
      if (downloadedFile == null) return false;
      
      // Decompress and parse
      final compressed = await backupFile.readAsBytes();
      final decompressed = gzip.decode(compressed);
      final jsonString = utf8.decode(decompressed);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup format
      if (backupData['version'] == null || backupData['entries'] == null) {
        throw Exception('Invalid backup format');
      }
      
      // Clear existing data (with user confirmation in UI)
      await DatabaseService.clearAllData();
      
      // Restore entries
      final entriesData = backupData['entries'] as List;
      for (final entryData in entriesData) {
        final entry = DiaryEntry.fromJson(entryData);
        await DatabaseService.addEntry(entry);
      }
      
      // Restore preferences
      if (backupData['preferences'] != null) {
        final preferences = UserPreferences.fromJson(backupData['preferences']);
        await DatabaseService.saveUserPreferences(preferences);
      }
      
      // Clean up
      await backupFile.delete();
      
      print('✅ Backup restored successfully');
      return true;
    } catch (e) {
      print('❌ Error restoring backup: $e');
      return false;
    }
  }
  
  /// Get sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return {
          'isAuthenticated': false,
          'hasConnection': await hasInternetConnection(),
          'lastSync': null,
          'pendingChanges': 0,
        };
      }
      
      final metaDoc = await _firestore
          .collection(_syncMetaCollection)
          .doc(userId)
          .get();
      
      final lastSync = metaDoc.exists
          ? (metaDoc.data()?['lastSync'] as Timestamp?)?.toDate()
          : null;
      
      // Count pending changes
      int pendingChanges = 0;
      if (lastSync != null) {
        final entries = DatabaseService.getAllEntries();
        pendingChanges = entries.where((e) => e.updatedAt.isAfter(lastSync)).length;
      }
      
      return {
        'isAuthenticated': true,
        'hasConnection': await hasInternetConnection(),
        'lastSync': lastSync,
        'pendingChanges': pendingChanges,
      };
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'isAuthenticated': isAuthenticated,
        'hasConnection': false,
        'lastSync': null,
        'pendingChanges': 0,
        'error': e.toString(),
      };
    }
  }
}
