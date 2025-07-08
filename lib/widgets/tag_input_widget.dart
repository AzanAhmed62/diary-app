import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TagInputWidget extends StatelessWidget {
  final List<String> tags;
  final Function(String) onTagAdded;
  final Function(String) onTagRemoved;
  final TextEditingController tagController;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagAdded,
    required this.onTagRemoved,
    required this.tagController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        // Tag input field
        TextFormField(
          controller: tagController,
          decoration: InputDecoration(
            labelText: 'Add tags',
            hintText: 'Type a tag and press Enter',
            prefixIcon: const Icon(Icons.label_outline),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (tagController.text.trim().isNotEmpty) {
                  onTagAdded(tagController.text.trim());
                }
              },
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onTagAdded(value.trim());
            }
          },
          validator: (value) {
            if (value != null && value.trim().length > AppConstants.maxTagLength) {
              return 'Tag is too long (max ${AppConstants.maxTagLength} characters)';
            }
            return null;
          },
          maxLength: AppConstants.maxTagLength,
        ),
        
        // Tags display
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tags.length} tag${tags.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTagChip(context, tag)).toList(),
                ),
              ],
            ),
          ),
        ],
        
        // Tag limit info
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Maximum ${AppConstants.maxTagsPerEntry} tags allowed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    final theme = Theme.of(context);
    
    return Container(
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
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Text(
              '#$tag',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () => onTagRemoved(tag),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
