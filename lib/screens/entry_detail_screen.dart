import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'add_edit_entry_screen.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final DiaryEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  late DiaryEntry _entry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _toggleFavorite() async {
    try {
      setState(() => _isLoading = true);
      
      final updatedEntry = _entry.copyWith(isFavorite: !_entry.isFavorite);
      await DatabaseService.updateEntry(updatedEntry);
      
      setState(() {
        _entry = updatedEntry;
      });
      
      _showSnackBar(
        _entry.isFavorite ? 'Added to favorites' : 'Removed from favorites',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('Failed to update favorite status', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareEntry() async {
    final dateFormat = DateFormat('MMMM dd, yyyy \'at\' HH:mm');
    final formattedDate = dateFormat.format(_entry.createdAt);
    
    final shareText = '''
${_entry.title}

${_entry.content}

${_entry.mood != null ? '\nMood: ${MoodConstants.moodEmojis[_entry.mood!] ?? ''} ${_entry.mood!.toUpperCase()}' : ''}
${_entry.tags.isNotEmpty ? '\nTags: ${_entry.tags.map((tag) => '#$tag').join(' ')}' : ''}

Written on $formattedDate
''';

    try {
      await Share.share(shareText, subject: _entry.title);
    } catch (e) {
      _showSnackBar('Failed to share entry', Colors.red);
    }
  }

  Future<void> _editEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEntryScreen(existingEntry: _entry),
      ),
    );
    
    if (result == true) {
      // Refresh the entry from database
      try {
        final updatedEntry = DatabaseService.getEntryById(_entry.id);
        if (updatedEntry != null) {
          setState(() {
            _entry = updatedEntry;
          });
        }
      } catch (e) {
        // Entry might have been deleted
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await DatabaseService.deleteEntry(_entry.id);
        
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        _showSnackBar('Failed to delete entry', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${_entry.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        actions: [
          // Favorite toggle
          IconButton(
            icon: Icon(
              _entry.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _isLoading ? null : _toggleFavorite,
            color: _entry.isFavorite ? Colors.red : null,
            tooltip: _entry.isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEntry,
            tooltip: 'Share entry',
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editEntry();
                  break;
                case 'delete':
                  _deleteEntry();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and favorite icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _entry.title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_entry.isFavorite)
                              Icon(
                                Icons.favorite,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Date and time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${dateFormat.format(_entry.createdAt)} at ${timeFormat.format(_entry.createdAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        
                        // Last modified (if different from created)
                        if (_entry.updatedAt.difference(_entry.createdAt).inMinutes > 1) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Last edited: ${dateFormat.format(_entry.updatedAt)} at ${timeFormat.format(_entry.updatedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Mood
                        if (_entry.mood != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  MoodConstants.moodEmojis[_entry.mood!] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Feeling ${_entry.mood!.toUpperCase()}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Content',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _entry.content.isNotEmpty ? _entry.content : 'No content available.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: _entry.content.isNotEmpty 
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tags
                  if (_entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tags',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _entry.tags.map((tag) => _buildTagChip(context, tag)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editEntry,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Entry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _shareEntry,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                        child: const Icon(Icons.share),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
