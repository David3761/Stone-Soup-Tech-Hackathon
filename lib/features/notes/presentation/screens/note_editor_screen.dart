import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notes_repository.dart';
import '../../domain/note_type.dart';
import '../../providers/notes_providers.dart';
import '../widgets/audio_note_editor.dart';
import '../widgets/checklist_note_editor.dart';
import '../widgets/drawing_note_editor.dart';
import '../widgets/photo_note_editor.dart';
import '../widgets/text_note_editor.dart';
import '../widgets/video_note_editor.dart';

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
  ProviderSubscription<AsyncValue<NoteEditorState>>? _initialTypeSub;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    if (widget.noteId == null &&
        widget.initialType != null &&
        widget.initialType != NoteType.text) {
      // listenManual fires as soon as the provider has data (even if it loads
      // before the first frame), avoiding the whenData no-op on AsyncLoading.
      _initialTypeSub = ref.listenManual(
        noteEditorNotifierProvider(null),
        (prev, next) {
          if (next.hasValue && prev?.hasValue != true) {
            _initialTypeSub?.close();
            _initialTypeSub = null;
            ref
                .read(noteEditorNotifierProvider(null).notifier)
                .setType(widget.initialType!);
          }
        },
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    _initialTypeSub?.close();
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

    if (result == 'discard') {
      if (!mounted) return false;
      await ref
          .read(noteEditorNotifierProvider(widget.noteId).notifier)
          .discardStagedFiles();
    } else if (result == 'save' && mounted) {
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

  /// For text/checklist notes, shows a SegmentedButton type toggle.
  /// For media notes, shows a read-only type label chip.
  Widget _buildAppBarTitle(NoteEditorState s) {
    if (!s.type.isMedia) {
      return SegmentedButton<NoteType>(
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
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      );
    }

    final (icon, label) = switch (s.type) {
      NoteType.audio => (Icons.mic_rounded, 'Audio'),
      NoteType.video => (Icons.videocam_rounded, 'Video'),
      NoteType.photo => (Icons.photo_camera_rounded, 'Photo'),
      NoteType.drawing => (Icons.draw_rounded, 'Drawing'),
      _ => (Icons.note, ''),
    };
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEditor(NoteEditorState s) {
    return switch (s.type) {
      NoteType.text => TextNoteEditor(noteId: widget.noteId),
      NoteType.checklist => ChecklistNoteEditor(noteId: widget.noteId),
      NoteType.audio => AudioNoteEditor(noteId: widget.noteId),
      NoteType.video => VideoNoteEditor(noteId: widget.noteId),
      NoteType.photo => PhotoNoteEditor(noteId: widget.noteId),
      NoteType.drawing => DrawingNoteEditor(noteId: widget.noteId),
    };
  }

  @override
  Widget build(BuildContext context) {
    final editorAsync =
        ref.watch(noteEditorNotifierProvider(widget.noteId));

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
            data: _buildAppBarTitle,
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
              // Description field for media note types
              if (s.type.isMedia) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      controller: TextEditingController(text: s.textContent)
                        ..selection = TextSelection.collapsed(
                            offset: s.textContent.length),
                      onChanged: (v) => ref
                          .read(noteEditorNotifierProvider(widget.noteId)
                              .notifier)
                          .setTextContent(v),
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              Expanded(
                child: s.type.isMedia
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildEditor(s),
                      )
                    : _buildEditor(s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
