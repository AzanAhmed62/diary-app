import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/tag_input_widget.dart';
import '../widgets/mood_selector_widget.dart';

class AddEditEntryScreen extends ConsumerStatefulWidget {
  final DiaryEntry? existingEntry;

  const AddEditEntryScreen({super.key, this.existingEntry});

  @override
  ConsumerState<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends ConsumerState<AddEditEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  List<String> _tags = [];
  String? _selectedMood;
  bool _isFavorite = false;
  bool _isLoading = false;
  String _error = '';
  bool _hasUnsavedChanges = false;

  final _formKey = GlobalKey<FormState>();
  final _contentFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.existingEntry?.title ?? '');
    _contentController = TextEditingController(text: widget.existingEntry?.content ?? '');
    _tagController = TextEditingController();
    _tags = List.from(widget.existingEntry?.tags ?? []);
    _selectedMood = widget.existingEntry?.mood;
    _isFavorite = widget.existingEntry?.isFavorite ?? false;
  }

  void _setupListeners() {
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final newEntry = DiaryEntry(
        id: widget.existingEntry?.id,
        title: title,
        content: content,
        tags: _tags,
        mood: _selectedMood,
        isFavorite: _isFavorite,
        createdAt: widget.existingEntry?.createdAt,
      );

      if (widget.existingEntry == null) {
        await DatabaseService.addEntry(newEntry);
        _showSnackBar('Entry created successfully!', Colors.green);
      } else {
        await DatabaseService.updateEntry(newEntry);
        _showSnackBar('Entry updated successfully!', Colors.green);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to save entry: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    _showSnackBar(message, Colors.red);
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      if (_tags.length < AppConstants.maxTagsPerEntry) {
        setState(() {
          _tags.add(trimmedTag);
          _hasUnsavedChanges = true;
        });
        _tagController.clear();
      } else {
        _showSnackBar('Maximum ${AppConstants.maxTagsPerEntry} tags allowed', Colors.orange);
      }
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasUnsavedChanges = true;
    });
  }

  void _selectMood(String? mood) {
    setState(() {
      _selectedMood = mood;
      _hasUnsavedChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
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
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingEntry != null;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
          actions: [
            // Favorite toggle
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                  _hasUnsavedChanges = true;
                });
              },
              color: _isFavorite ? Colors.red : null,
              tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
            // Save button
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _handleSave,
              tooltip: 'Save entry',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Saving entry...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_error.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Entry Title',
                          hintText: 'What\'s on your mind?',
                          prefixIcon: Icon(Icons.title),
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _contentFocusNode.requestFocus(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.trim().length > AppConstants.maxTitleLength) {
                            return 'Title is too long (max ${AppConstants.maxTitleLength} characters)';
                          }
                          return null;
                        },
                        maxLength: AppConstants.maxTitleLength,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Content field
                      Text(
                        'Content',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts here...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          validator: (value) {
                            if (value != null && value.length > AppConstants.maxContentLength) {
                              return 'Content is too long (max ${AppConstants.maxContentLength} characters)';
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mood selector
                      MoodSelectorWidget(
                        selectedMood: _selectedMood,
                        onMoodSelected: _selectMood,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tags section
                      TagInputWidget(
                        tags: _tags,
                        onTagAdded: _addTag,
                        onTagRemoved: _removeTag,
                        tagController: _tagController,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save button (bottom)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSave,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(isEditing ? 'Update Entry' : 'Save Entry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

