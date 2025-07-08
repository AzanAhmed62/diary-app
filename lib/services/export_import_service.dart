import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../models/user_preferences.dart';
import '../models/analytics_data.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'analytics_service.dart';

class ExportImportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('EEEE, MMMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  
  /// Request storage permissions
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't require explicit storage permission for app documents
  }
  
  /// Export entries to PDF
  static Future<File?> exportToPDF({
    List<DiaryEntry>? entries,
    String? title,
    bool includeAnalytics = false,
  }) async {
    try {
      // Request permission
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }
      
      final allEntries = entries ?? DatabaseService.getAllEntries();
      if (allEntries.isEmpty) {
        throw Exception('No entries to export');
      }
      
      // Sort entries by date
      allEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Add title page
      await _addTitlePage(pdf, title ?? 'My Diary', allEntries.length);
      
      // Add entries
      await _addEntriesToPDF(pdf, allEntries);
      
      // Add analytics if requested
      if (includeAnalytics) {
        await _addAnalyticsToPDF(pdf, allEntries);
      }
      
      // Save PDF to file
      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/diary_export_$timestamp.pdf');
      
      await file.writeAsBytes(await pdf.save());
      
      print('✅ PDF export completed: ${file.path}');
      return file;
      
    } catch (e) {
      print('❌ Error exporting to PDF: $e');
      return null;
    }
  }
  
  /// Add title page to PDF
  static Future<void> _addTitlePage(pw.Document pdf, String title, int entryCount) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Personal Diary Collection',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '$entryCount ${entryCount == 1 ? 'Entry' : 'Entries'}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Exported on ${_displayDateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Add entries to PDF
  static Future<void> _addEntriesToPDF(pw.Document pdf, List<DiaryEntry> entries) async {
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      entry.title,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${i + 1} of ${entries.length}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Date and metadata
                pw.Row(
                  children: [
                    pw.Text(
                      _displayDateFormat.format(entry.createdAt),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      _timeFormat.format(entry.createdAt),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                
                // Mood
                if (entry.mood != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Mood: ${entry.mood}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
                
                // Tags
                if (entry.tags.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Tags: ${entry.tags.join(', ')}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
                
                pw.SizedBox(height: 20),
                
                // Content
                pw.Expanded(
                  child: pw.Text(
                    entry.content,
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
                
                // Footer
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Created: ${_dateFormat.format(entry.createdAt)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (entry.updatedAt != entry.createdAt)
                      pw.Text(
                        'Updated: ${_dateFormat.format(entry.updatedAt)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
  }
  
  /// Add analytics to PDF
  static Future<void> _addAnalyticsToPDF(pw.Document pdf, List<DiaryEntry> entries) async {
    final stats = AnalyticsService.getWritingStats();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Writing Analytics',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary statistics
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              _buildStatRow('Total Entries:', '${stats['totals']?['entries'] ?? 0}'),
              _buildStatRow('Total Words:', '${stats['totals']?['words'] ?? 0}'),
              _buildStatRow('Total Characters:', '${stats['totals']?['characters'] ?? 0}'),
              _buildStatRow('Average Words per Day:', '${stats['averages']?['wordsPerDay'] ?? 0}'),
              _buildStatRow('Current Writing Streak:', '${stats['streak']?['currentStreak'] ?? 0} days'),
              _buildStatRow('Longest Writing Streak:', '${stats['streak']?['longestStreak'] ?? 0} days'),
              
              pw.SizedBox(height: 20),
              
              // Mood distribution
              if (stats['moods'] != null && (stats['moods'] as Map).isNotEmpty) ...[
                pw.Text(
                  'Mood Distribution',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                ...(stats['moods'] as Map<String, dynamic>).entries.map(
                  (entry) => _buildStatRow('${entry.key}:', '${entry.value} entries'),
                ),
                
                pw.SizedBox(height: 20),
              ],
              
              // Top tags
              if (stats['tags'] != null && (stats['tags'] as Map).isNotEmpty) ...[
                pw.Text(
                  'Top Tags',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                ...(stats['tags'] as Map<String, dynamic>).entries.take(10).map(
                  (entry) => _buildStatRow('${entry.key}:', '${entry.value} uses'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
  
  /// Build a statistics row for PDF
  static pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
  
  /// Share PDF file
  static Future<void> sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'My Diary Export',
        subject: 'Diary Export - ${_dateFormat.format(DateTime.now())}',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }
  
  /// Print PDF
  static Future<void> printPDF(Uint8List pdfData) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }
  
  /// Export data to JSON
  static Future<File?> exportToJSON({
    bool includeEntries = true,
    bool includePreferences = true,
    bool includeAnalytics = true,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }
      
      final Map<String, dynamic> exportData = {
        'metadata': {
          'exportedAt': DateTime.now().toIso8601String(),
          'version': AppConstants.appVersion,
          'appName': AppConstants.appName,
        },
      };
      
      // Export entries
      if (includeEntries) {
        final entries = DatabaseService.getAllEntries();
        exportData['entries'] = entries.map((e) => e.toJson()).toList();
      }
      
      // Export preferences
      if (includePreferences) {
        final preferences = DatabaseService.getUserPreferences();
        exportData['preferences'] = preferences.toJson();
      }
      
      // Export analytics
      if (includeAnalytics) {
        try {
          exportData['analytics'] = AnalyticsService.exportAnalyticsData();
        } catch (e) {
          print('Warning: Could not export analytics data: $e');
        }
      }
      
      // Save to file
      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/diary_backup_$timestamp.json');
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await file.writeAsString(jsonString);
      
      print('✅ JSON export completed: ${file.path}');
      return file;
      
    } catch (e) {
      print('❌ Error exporting to JSON: $e');
      return null;
    }
  }
  
  /// Import data from JSON file
  static Future<bool> importFromJSON() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return false;
      }
      
      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup format
      if (data['metadata'] == null) {
        throw Exception('Invalid backup format: missing metadata');
      }
      
      // Import entries
      if (data['entries'] != null) {
        final entriesData = data['entries'] as List;
        for (final entryData in entriesData) {
          try {
            final entry = DiaryEntry.fromJson(entryData);
            
            // Check if entry already exists
            try {
              final existingEntry = DatabaseService.getEntryById(entry.id);
              if (existingEntry == null || existingEntry.updatedAt.isBefore(entry.updatedAt)) {
                await DatabaseService.updateEntry(entry);
              }
            } catch (e) {
              // Entry doesn't exist, add it
              await DatabaseService.addEntry(entry);
            }
          } catch (e) {
            print('Error importing entry: $e');
          }
        }
      }
      
      // Import preferences
      if (data['preferences'] != null) {
        try {
          final preferences = UserPreferences.fromJson(data['preferences']);
          await DatabaseService.saveUserPreferences(preferences);
        } catch (e) {
          print('Error importing preferences: $e');
        }
      }
      
      // Import analytics
      if (data['analytics'] != null) {
        try {
          await AnalyticsService.importAnalyticsData(data['analytics']);
        } catch (e) {
          print('Error importing analytics: $e');
        }
      }
      
      print('✅ JSON import completed successfully');
      return true;
      
    } catch (e) {
      print('❌ Error importing from JSON: $e');
      return false;
    }
  }
  
  /// Export entries to plain text
  static Future<File?> exportToText({
    List<DiaryEntry>? entries,
    String? title,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }
      
      final allEntries = entries ?? DatabaseService.getAllEntries();
      if (allEntries.isEmpty) {
        throw Exception('No entries to export');
      }
      
      // Sort entries by date
      allEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      final buffer = StringBuffer();
      
      // Add header
      buffer.writeln('${title ?? 'My Diary'}');
      buffer.writeln('=' * 50);
      buffer.writeln('Exported on ${_displayDateFormat.format(DateTime.now())}');
      buffer.writeln('Total entries: ${allEntries.length}');
      buffer.writeln();
      
      // Add entries
      for (int i = 0; i < allEntries.length; i++) {
        final entry = allEntries[i];
        
        buffer.writeln('Entry ${i + 1}: ${entry.title}');
        buffer.writeln('-' * 40);
        buffer.writeln('Date: ${_displayDateFormat.format(entry.createdAt)}');
        buffer.writeln('Time: ${_timeFormat.format(entry.createdAt)}');
        
        if (entry.mood != null) {
          buffer.writeln('Mood: ${entry.mood}');
        }
        
        if (entry.tags.isNotEmpty) {
          buffer.writeln('Tags: ${entry.tags.join(', ')}');
        }
        
        buffer.writeln();
        buffer.writeln(entry.content);
        buffer.writeln();
        
        if (entry.updatedAt != entry.createdAt) {
          buffer.writeln('Last updated: ${_displayDateFormat.format(entry.updatedAt)}');
        }
        
        buffer.writeln();
        buffer.writeln('=' * 50);
        buffer.writeln();
      }
      
      // Save to file
      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/diary_export_$timestamp.txt');
      
      await file.writeAsString(buffer.toString());
      
      print('✅ Text export completed: ${file.path}');
      return file;
      
    } catch (e) {
      print('❌ Error exporting to text: $e');
      return null;
    }
  }
  
  /// Get export options
  static Map<String, String> getExportFormats() {
    return {
      'pdf': 'PDF Document',
      'json': 'JSON Backup',
      'text': 'Plain Text',
    };
  }
  
  /// Get file size in human readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Clean up old export files
  static Future<void> cleanupOldExports({int maxFiles = 10}) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final files = output.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('diary_export_') || file.path.contains('diary_backup_'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Delete old files
      if (files.length > maxFiles) {
        final filesToDelete = files.skip(maxFiles);
        for (final file in filesToDelete) {
          try {
            await file.delete();
            print('Deleted old export file: ${file.path}');
          } catch (e) {
            print('Error deleting file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old exports: $e');
    }
  }
}
