import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notes_repository.dart';
import '../../domain/note_type.dart';
import '../../providers/notes_providers.dart';
import '../widgets/checklist_note_editor.dart';
import '../widgets/text_note_editor.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  final NoteType? initialType;

  const NoteEditorScreen({super.key, this.noteId, this.initialType});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  bool _titleInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    // For new notes, set initial type after first frame
    if (widget.noteId == null && widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(noteEditorNotifierProvider(null).notifier)
            .setType(widget.initialType!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _handlePop() async {
    final editorState = ref
        .read(noteEditorNotifierProvider(widget.noteId))
        .valueOrNull;
    if (editorState == null || !editorState.isDirty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Do you want to save your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save' && mounted) {
      await ref
          .read(noteEditorNotifierProvider(widget.noteId).notifier)
          .save();
    }
    return result != 'cancel' && result != null;
  }

  Future<void> _save() async {
    await ref
        .read(noteEditorNotifierProvider(widget.noteId).notifier)
        .save();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
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
    if (confirmed == true && mounted) {
      await ref
          .read(notesRepositoryProvider)
          .deleteNote(widget.noteId!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorAsync =
        ref.watch(noteEditorNotifierProvider(widget.noteId));

    // Sync title controller once when data first loads
    editorAsync.whenData((s) {
      if (!_titleInitialized) {
        _titleInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _titleController.text = s.title;
            _titleController.selection =
                TextSelection.collapsed(offset: s.title.length);
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _handlePop();
        if (shouldPop && mounted) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: editorAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const Text('Error'),
            data: (s) => SegmentedButton<NoteType>(
              segments: const [
                ButtonSegment(
                  value: NoteType.text,
                  icon: Icon(Icons.text_fields_rounded),
                  label: Text('Text'),
                ),
                ButtonSegment(
                  value: NoteType.checklist,
                  icon: Icon(Icons.checklist_rounded),
                  label: Text('List'),
                ),
              ],
              selected: {s.type},
              onSelectionChanged: (val) => ref
                  .read(noteEditorNotifierProvider(widget.noteId).notifier)
                  .setType(val.first),
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact),
            ),
          ),
          actions: [
            if (widget.noteId != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                onPressed: _delete,
                tooltip: 'Delete',
              ),
            editorAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (s) => IconButton(
                icon: s.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                onPressed: s.isSaving ? null : _save,
                tooltip: 'Save',
              ),
            ),
          ],
        ),
        body: editorAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (s) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                  onChanged: (v) => ref
                      .read(noteEditorNotifierProvider(widget.noteId)
                          .notifier)
                      .setTitle(v),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: s.type == NoteType.text
                    ? TextNoteEditor(noteId: widget.noteId)
                    : ChecklistNoteEditor(noteId: widget.noteId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
