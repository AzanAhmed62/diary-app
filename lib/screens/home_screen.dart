import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/entry_card.dart';
import 'add_edit_entry_screen.dart';
import 'entry_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final entries = DatabaseService.getSortedEntries('date', false);
      
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load entries: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleEntry() async {
    try {
      final sampleEntry = DiaryEntry(
        title: 'Welcome to Your Diary!',
        content: '''Welcome to your personal diary app! 

This is your first entry. Here you can:
• Record your daily thoughts and experiences
• Add photos and memories
• Organize entries with tags
• Search through your entries
• Export your diary for backup

Start writing your story today! ✨

Tap the + button to create a new entry, or tap this entry to edit it.''',
        tags: ['welcome', 'first-entry'],
        mood: 'excited',
      );

      await DatabaseService.addEntry(sampleEntry);
      await _loadEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome entry created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Diary Awaits',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start your journaling journey by creating your first entry. Capture your thoughts, memories, and experiences.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createSampleEntry,
              icon: const Icon(Icons.add),
              label: const Text('Create First Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEntries,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: EntryCard(
              entry: entry,
              onTap: () => _navigateToEntryDetail(entry),
              onEdit: () => _navigateToEditEntry(entry),
              onDelete: () async {
                // Show confirmation dialog
                final confirmed = await _showDeleteConfirmation(entry);
                if (confirmed == true) {
                  await _deleteEntry(entry);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(DiaryEntry entry) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    try {
      await DatabaseService.deleteEntry(entry.id);
      await _loadEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditEntryScreen(),
      ),
    );
    
    if (result == true) {
      await _loadEntries();
    }
  }

  Future<void> _navigateToEditEntry(DiaryEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEntryScreen(existingEntry: entry),
      ),
    );
    
    if (result == true) {
      await _loadEntries();
    }
  }

  Future<void> _navigateToEntryDetail(DiaryEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(entry: entry),
      ),
    );
    
    // If entry was deleted or modified, refresh the list
    if (result == true) {
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search screen
              print('Search tapped');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
              print('Settings tapped');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorState()
              : _entries.isEmpty
                  ? _buildEmptyState()
                  : _buildEntriesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        tooltip: 'Add new entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}
