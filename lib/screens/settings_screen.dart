import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/cloud_sync_service.dart';
import '../services/export_import_service.dart';
import '../services/database_service.dart';
import '../models/user_preferences.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserPreferences? _preferences;
  Map<String, dynamic>? _syncStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPreferences();
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPreferences() {
    setState(() {
      _preferences = DatabaseService.getUserPreferences();
    });
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await CloudSyncService.getSyncStatus();
      setState(() {
        _syncStatus = status;
      });
    } catch (e) {
      print('Error loading sync status: $e');
    }
  }

  Future<void> _updatePreferences(UserPreferences newPreferences) async {
    try {
      await DatabaseService.saveUserPreferences(newPreferences);
      setState(() {
        _preferences = newPreferences;
      });
      _showSnackBar('Settings saved successfully');
    } catch (e) {
      _showSnackBar('Error saving settings: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.settings)),
            Tab(text: 'Cloud Sync', icon: Icon(Icons.cloud)),
            Tab(text: 'Export/Import', icon: Icon(Icons.import_export)),
            Tab(text: 'About', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildCloudSyncTab(),
          _buildExportImportTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    if (_preferences == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Appearance'),
          const SizedBox(height: 16),
          _buildThemeSelector(),
          const SizedBox(height: 16),
          _buildFontSizeSlider(),
          const SizedBox(height: 16),
          _buildPrimaryColorSelector(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Content'),
          const SizedBox(height: 16),
          _buildDefaultViewSelector(),
          const SizedBox(height: 16),
          _buildSortingPreferences(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Writing'),
          const SizedBox(height: 16),
          _buildAutoSaveToggle(),
          const SizedBox(height: 16),
          _buildShowPreviewToggle(),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle('Backup'),
          const SizedBox(height: 16),
          _buildBackupFrequencySelector(),
        ],
      ),
    );
  }

  Widget _buildCloudSyncTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cloud Sync Status'),
          const SizedBox(height: 16),
          _buildSyncStatusCard(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Sync Actions'),
          const SizedBox(height: 16),
          _buildSyncActions(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Account'),
          const SizedBox(height: 16),
          _buildAccountActions(),
        ],
      ),
    );
  }

  Widget _buildExportImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Export Options'),
          const SizedBox(height: 16),
          _buildExportActions(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Import'),
          const SizedBox(height: 16),
          _buildImportActions(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Data Management'),
          const SizedBox(height: 16),
          _buildDataManagementActions(),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('App Information'),
          const SizedBox(height: 16),
          _buildAppInfo(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Statistics'),
          const SizedBox(height: 16),
          _buildDatabaseStats(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Legal'),
          const SizedBox(height: 16),
          _buildLegalInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.palette),
        title: const Text('Theme'),
        subtitle: Text(_preferences!.theme.toUpperCase()),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _updatePreferences(_preferences!.copyWith(theme: value));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'system', child: Text('System')),
            const PopupMenuItem(value: 'light', child: Text('Light')),
            const PopupMenuItem(value: 'dark', child: Text('Dark')),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields),
                const SizedBox(width: 16),
                Text(
                  'Font Size: ${_preferences!.fontSize.toInt()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _preferences!.fontSize,
              min: AppConstants.minFontSize,
              max: AppConstants.maxFontSize,
              divisions: ((AppConstants.maxFontSize - AppConstants.minFontSize) / 2).round(),
              onChanged: (value) {
                _updatePreferences(_preferences!.copyWith(fontSize: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryColorSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.color_lens),
                const SizedBox(width: 16),
                Text(
                  'Primary Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ColorConstants.primaryColors.entries.map((entry) {
                final isSelected = _preferences!.primaryColor == entry.key;
                return GestureDetector(
                  onTap: () {
                    _updatePreferences(_preferences!.copyWith(primaryColor: entry.key));
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(entry.value),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultViewSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.view_list),
        title: const Text('Default View'),
        subtitle: Text(_preferences!.defaultView.toUpperCase()),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _updatePreferences(_preferences!.copyWith(defaultView: value));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'list', child: Text('List')),
            const PopupMenuItem(value: 'grid', child: Text('Grid')),
            const PopupMenuItem(value: 'timeline', child: Text('Timeline')),
          ],
        ),
      ),
    );
  }

  Widget _buildSortingPreferences() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.sort),
            title: const Text('Sort By'),
            subtitle: Text(_preferences!.sortBy.toUpperCase()),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                _updatePreferences(_preferences!.copyWith(sortBy: value));
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'date', child: Text('Date')),
                const PopupMenuItem(value: 'title', child: Text('Title')),
                const PopupMenuItem(value: 'modified', child: Text('Modified')),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.arrow_upward),
            title: const Text('Ascending Order'),
            value: _preferences!.sortAscending,
            onChanged: (value) {
              _updatePreferences(_preferences!.copyWith(sortAscending: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveToggle() {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.save),
        title: const Text('Auto Save'),
        subtitle: const Text('Automatically save entries while writing'),
        value: _preferences!.autoSave,
        onChanged: (value) {
          _updatePreferences(_preferences!.copyWith(autoSave: value));
        },
      ),
    );
  }

  Widget _buildShowPreviewToggle() {
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.preview),
        title: const Text('Show Preview'),
        subtitle: const Text('Show content preview in entry list'),
        value: _preferences!.showPreview,
        onChanged: (value) {
          _updatePreferences(_preferences!.copyWith(showPreview: value));
        },
      ),
    );
  }

  Widget _buildBackupFrequencySelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.backup),
        title: const Text('Backup Frequency'),
        subtitle: Text('Every ${_preferences!.backupFrequency} days'),
        trailing: PopupMenuButton<int>(
          onSelected: (value) {
            _updatePreferences(_preferences!.copyWith(backupFrequency: value));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 1, child: Text('Daily')),
            const PopupMenuItem(value: 7, child: Text('Weekly')),
            const PopupMenuItem(value: 30, child: Text('Monthly')),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    if (_syncStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading sync status...'),
            ],
          ),
        ),
      );
    }

    final isAuthenticated = _syncStatus!['isAuthenticated'] as bool;
    final hasConnection = _syncStatus!['hasConnection'] as bool;
    final lastSync = _syncStatus!['lastSync'] as DateTime?;
    final pendingChanges = _syncStatus!['pendingChanges'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                  color: isAuthenticated ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  isAuthenticated ? 'Connected' : 'Not Connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isAuthenticated ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _buildStatusRow('Network', hasConnection ? 'Connected' : 'Offline'),
            if (lastSync != null)
              _buildStatusRow('Last Sync', DateFormat('MMM d, h:mm a').format(lastSync)),
            _buildStatusRow('Pending Changes', '$pendingChanges'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActions() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Now'),
            subtitle: const Text('Sync your data to the cloud'),
            trailing: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: _isLoading ? null : _performSync,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Download from Cloud'),
            subtitle: const Text('Download data from cloud storage'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _downloadFromCloud,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Backup'),
            subtitle: const Text('Create a full backup to cloud storage'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _createBackup,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    final isAuthenticated = _syncStatus?['isAuthenticated'] as bool? ?? false;
    
    return Column(
      children: [
        if (!isAuthenticated) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In'),
              subtitle: const Text('Sign in to enable cloud sync'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _signIn,
            ),
          ),
        ] else ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              subtitle: const Text('Disable cloud sync'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _signOut,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExportActions() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export to PDF'),
            subtitle: const Text('Create a PDF document of your entries'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _exportToPDF,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Export to JSON'),
            subtitle: const Text('Create a backup file with all data'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _exportToJSON,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Export to Text'),
            subtitle: const Text('Create a plain text file'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _exportToText,
          ),
        ),
      ],
    );
  }

  Widget _buildImportActions() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import from JSON'),
            subtitle: const Text('Import data from a backup file'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _importFromJSON,
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementActions() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clean Old Exports'),
            subtitle: const Text('Remove old export files to free space'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _cleanOldExports,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.compress),
            title: const Text('Compact Database'),
            subtitle: const Text('Optimize database storage'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _compactDatabase,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('App Name', AppConstants.appName),
            _buildInfoRow('Version', AppConstants.appVersion),
            _buildInfoRow('Description', AppConstants.appDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseStats() {
    final stats = DatabaseService.getDatabaseStats();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Total Entries', '${stats['totalEntries']}'),
            _buildInfoRow('Favorite Entries', '${stats['favoriteEntries']}'),
            _buildInfoRow('Unique Tags', '${stats['uniqueTags']}'),
            _buildInfoRow('Database Size', '~${stats['databaseSize']} bytes'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalInfo() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Open privacy policy
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Open terms of service
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _performSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await CloudSyncService.syncToCloud();
      if (success) {
        _showSnackBar('Sync completed successfully');
      } else {
        _showSnackBar('Sync failed - check your connection');
      }
    } catch (e) {
      _showSnackBar('Sync error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      await _loadSyncStatus();
    }
  }

  Future<void> _downloadFromCloud() async {
    try {
      final success = await CloudSyncService.syncFromCloud();
      if (success) {
        _showSnackBar('Download completed successfully');
      } else {
        _showSnackBar('Download failed - check your connection');
      }
    } catch (e) {
      _showSnackBar('Download error: $e');
    }
  }

  Future<void> _createBackup() async {
    try {
      final backupUrl = await CloudSyncService.createFullBackup();
      if (backupUrl != null) {
        _showSnackBar('Backup created successfully');
      } else {
        _showSnackBar('Backup failed');
      }
    } catch (e) {
      _showSnackBar('Backup error: $e');
    }
  }

  Future<void> _signIn() async {
    try {
      final user = await CloudSyncService.signInAnonymously();
      if (user != null) {
        _showSnackBar('Signed in successfully');
        await _loadSyncStatus();
      } else {
        _showSnackBar('Sign in failed');
      }
    } catch (e) {
      _showSnackBar('Sign in error: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await CloudSyncService.signOut();
      _showSnackBar('Signed out successfully');
      await _loadSyncStatus();
    } catch (e) {
      _showSnackBar('Sign out error: $e');
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final file = await ExportImportService.exportToPDF(includeAnalytics: true);
      if (file != null) {
        _showSnackBar('PDF exported successfully');
        // Optionally share the file
        await ExportImportService.sharePDF(file);
      } else {
        _showSnackBar('PDF export failed');
      }
    } catch (e) {
      _showSnackBar('Export error: $e');
    }
  }

  Future<void> _exportToJSON() async {
    try {
      final file = await ExportImportService.exportToJSON();
      if (file != null) {
        _showSnackBar('JSON backup created successfully');
      } else {
        _showSnackBar('JSON export failed');
      }
    } catch (e) {
      _showSnackBar('Export error: $e');
    }
  }

  Future<void> _exportToText() async {
    try {
      final file = await ExportImportService.exportToText();
      if (file != null) {
        _showSnackBar('Text file exported successfully');
      } else {
        _showSnackBar('Text export failed');
      }
    } catch (e) {
      _showSnackBar('Export error: $e');
    }
  }

  Future<void> _importFromJSON() async {
    try {
      final success = await ExportImportService.importFromJSON();
      if (success) {
        _showSnackBar('Import completed successfully');
      } else {
        _showSnackBar('Import cancelled or failed');
      }
    } catch (e) {
      _showSnackBar('Import error: $e');
    }
  }

  Future<void> _cleanOldExports() async {
    try {
      await ExportImportService.cleanupOldExports();
      _showSnackBar('Old export files cleaned successfully');
    } catch (e) {
      _showSnackBar('Cleanup error: $e');
    }
  }

  Future<void> _compactDatabase() async {
    try {
      await DatabaseService.compactDatabase();
      _showSnackBar('Database compacted successfully');
    } catch (e) {
      _showSnackBar('Compact error: $e');
    }
  }
}
