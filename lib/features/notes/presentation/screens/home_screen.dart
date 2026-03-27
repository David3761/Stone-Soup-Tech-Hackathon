import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notes_repository.dart';
import '../../domain/note_type.dart';
import '../../providers/notes_providers.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNote(BuildContext context, {int? noteId, NoteType? type}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(noteId: noteId, initialType: type),
      ),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'New note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('Text note'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Checklist'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.checklist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text('Audio recording'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.audio);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded),
              title: const Text('Video recording'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Photos'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.draw_rounded),
              title: const Text('Drawing'),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, type: NoteType.drawing);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FilterSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(noteFilterNotifierProvider);
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes…',
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(noteFilterNotifierProvider.notifier).setSearch(v),
              )
            : const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                ref
                    .read(noteFilterNotifierProvider.notifier)
                    .setSearch('');
              }
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showFilterSheet(context),
              ),
              if (filter.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    filter.hasActiveFilters
                        ? 'No notes match the current filters'
                        : 'No notes yet\nTap + to create one',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => _openNote(context, noteId: note.id),
                onDelete: () => _confirmDelete(context, note.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(notesRepositoryProvider).deleteNote(noteId);
    }
  }
}
