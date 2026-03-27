import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/note_filter.dart';
import '../../domain/note_type.dart';
import '../../providers/notes_providers.dart';

class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

  IconData _typeIcon(NoteType type) => switch (type) {
        NoteType.text => Icons.text_fields_rounded,
        NoteType.checklist => Icons.checklist_rounded,
        NoteType.audio => Icons.mic_rounded,
        NoteType.video => Icons.videocam_rounded,
        NoteType.photo => Icons.photo_camera_rounded,
        NoteType.drawing => Icons.draw_rounded,
      };

  String _typeLabel(NoteType type) => switch (type) {
        NoteType.text => 'Text',
        NoteType.checklist => 'Checklist',
        NoteType.audio => 'Audio',
        NoteType.video => 'Video',
        NoteType.photo => 'Photo',
        NoteType.drawing => 'Drawing',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(noteFilterNotifierProvider);
    final notifier = ref.read(noteFilterNotifierProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filter & Sort', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (filter.hasActiveFilters)
                  TextButton(
                    onPressed: notifier.clearFilters,
                    child: const Text('Clear all'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            Text('Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter.typeFilter == null,
                  onSelected: (_) => notifier.setTypeFilter(null),
                  visualDensity: VisualDensity.compact,
                ),
                for (final type in NoteType.values)
                  FilterChip(
                    avatar: Icon(_typeIcon(type), size: 16),
                    label: Text(_typeLabel(type)),
                    selected: filter.typeFilter == type,
                    onSelected: (_) => notifier.setTypeFilter(
                      filter.typeFilter == type ? null : type,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sort by', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<SortField>(
              segments: const [
                ButtonSegment(
                    value: SortField.updatedAt, label: Text('Modified')),
                ButtonSegment(
                    value: SortField.createdAt, label: Text('Created')),
                ButtonSegment(
                    value: SortField.title, label: Text('Title')),
              ],
              selected: {filter.sortBy},
              onSelectionChanged: (val) => notifier.setSortField(val.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Order', style: theme.textTheme.labelLarge),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Newest first'),
                  selected:
                      filter.sortDirection == SortDirection.descending,
                  onSelected: (_) =>
                      notifier.setSortDirection(SortDirection.descending),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Oldest first'),
                  selected:
                      filter.sortDirection == SortDirection.ascending,
                  onSelected: (_) =>
                      notifier.setSortDirection(SortDirection.ascending),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
