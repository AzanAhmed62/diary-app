import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MoodSelectorWidget extends StatelessWidget {
  final String? selectedMood;
  final Function(String?) onMoodSelected;

  const MoodSelectorWidget({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // First row of moods
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: MoodConstants.allMoods.map((mood) {
                  final isSelected = selectedMood == mood;
                  final emoji = MoodConstants.moodEmojis[mood] ?? '';
                  
                  return GestureDetector(
                    onTap: () {
                      // Toggle selection - if already selected, deselect
                      if (isSelected) {
                        onMoodSelected(null);
                      } else {
                        onMoodSelected(mood);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _capitalizeMood(mood),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Clear selection button
              if (selectedMood != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => onMoodSelected(null),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear selection'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Selected mood display
        if (selectedMood != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MoodConstants.moodEmojis[selectedMood!] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Feeling ${_capitalizeMood(selectedMood!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  String _capitalizeMood(String mood) {
    if (mood.isEmpty) return mood;
    return mood[0].toUpperCase() + mood.substring(1);
  }
}
