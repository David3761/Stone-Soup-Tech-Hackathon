import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/note_filter.dart';
import '../../domain/note_type.dart';
import '../../providers/notes_providers.dart';

class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

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
            SegmentedButton<NoteType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(
                  value: NoteType.text,
                  label: Text('Text'),
                  icon: Icon(Icons.text_fields_rounded),
                ),
                ButtonSegment(
                  value: NoteType.checklist,
                  label: Text('Checklist'),
                  icon: Icon(Icons.checklist_rounded),
                ),
              ],
              selected: {filter.typeFilter},
              onSelectionChanged: (val) =>
                  notifier.setTypeFilter(val.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
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
