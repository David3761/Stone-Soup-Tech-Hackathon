import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notes_repository.dart';
import '../domain/checklist_item.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import '../domain/note_filter.dart';
import '../domain/note_type.dart';

part 'notes_providers.g.dart';

// ---------------------------------------------------------------------------
// Filter / sort state
// ---------------------------------------------------------------------------

@riverpod
class NoteFilterNotifier extends _$NoteFilterNotifier {
  @override
  NoteFilter build() => const NoteFilter();

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setTypeFilter(NoteType? type) =>
      state = state.copyWith(typeFilter: type);

  void setSortField(SortField field) =>
      state = state.copyWith(sortBy: field);

  void setSortDirection(SortDirection direction) =>
      state = state.copyWith(sortDirection: direction);

  void clearFilters() => state = const NoteFilter();
}

// ---------------------------------------------------------------------------
// Notes list stream
// ---------------------------------------------------------------------------

@riverpod
Stream<List<NoteWithItems>> notesList(NotesListRef ref) {
  final filter = ref.watch(noteFilterNotifierProvider);
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchNotes(filter);
}

// ---------------------------------------------------------------------------
// Editor state
// ---------------------------------------------------------------------------

class NoteEditorState {
  final int? noteId;
  final String title;
  final NoteType type;
  final String textContent;
  final List<ChecklistItemModel> checklistItems;
  /// All attachments currently associated with the note (saved + staged).
  /// Staged items have id == null.
  final List<NoteAttachmentModel> attachments;
  /// Attachments that were removed during this edit session (saved items only).
  final List<NoteAttachmentModel> removedAttachments;
  final bool isDirty;
  final bool isSaving;

  const NoteEditorState({
    this.noteId,
    required this.title,
    required this.type,
    required this.textContent,
    required this.checklistItems,
    this.attachments = const [],
    this.removedAttachments = const [],
    this.isDirty = false,
    this.isSaving = false,
  });

  factory NoteEditorState.empty({NoteType type = NoteType.text}) =>
      NoteEditorState(
        noteId: null,
        title: '',
        type: type,
        textContent: '',
        checklistItems: const [],
      );

  factory NoteEditorState.fromNote(NoteWithItems note) => NoteEditorState(
        noteId: note.id,
        title: note.title,
        type: note.type,
        textContent: note.textContent ?? '',
        checklistItems: note.checklistItems,
        attachments: note.attachments,
      );

  NoteEditorState copyWith({
    int? noteId,
    String? title,
    NoteType? type,
    String? textContent,
    List<ChecklistItemModel>? checklistItems,
    List<NoteAttachmentModel>? attachments,
    List<NoteAttachmentModel>? removedAttachments,
    bool? isDirty,
    bool? isSaving,
  }) {
    return NoteEditorState(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      checklistItems: checklistItems ?? this.checklistItems,
      attachments: attachments ?? this.attachments,
      removedAttachments: removedAttachments ?? this.removedAttachments,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ---------------------------------------------------------------------------
// Note editor notifier (family: noteId, null = new note)
// ---------------------------------------------------------------------------

@riverpod
class NoteEditorNotifier extends _$NoteEditorNotifier {
  @override
  Future<NoteEditorState> build(int? noteId) async {
    if (noteId == null) return NoteEditorState.empty();
    final repo = ref.read(notesRepositoryProvider);
    final note = await repo.getNote(noteId);
    return note != null ? NoteEditorState.fromNote(note) : NoteEditorState.empty();
  }

  void _update(NoteEditorState Function(NoteEditorState s) updater) {
    state = state.whenData(updater);
  }

  void setTitle(String title) =>
      _update((s) => s.copyWith(title: title, isDirty: true));

  void setType(NoteType type) {
    _update((s) {
      if (s.type == type) return s;
      if (type == NoteType.checklist && s.textContent.isNotEmpty) {
        final lines = s.textContent
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        final items = [
          for (var i = 0; i < lines.length; i++)
            ChecklistItemModel(
              noteId: s.noteId ?? 0,
              text: lines[i].trim(),
              position: i,
            ),
        ];
        return s.copyWith(
            type: type, checklistItems: items, textContent: '', isDirty: true);
      }
      if (type == NoteType.text && s.checklistItems.isNotEmpty) {
        final text = s.checklistItems.map((i) => i.text).join('\n');
        return s.copyWith(
            type: type, textContent: text, checklistItems: [], isDirty: true);
      }
      return s.copyWith(type: type, isDirty: true);
    });
  }

  void setTextContent(String content) =>
      _update((s) => s.copyWith(textContent: content, isDirty: true));

  void addChecklistItem(String text) {
    _update((s) {
      final item = ChecklistItemModel(
        noteId: s.noteId ?? 0,
        text: text,
        position: s.checklistItems.length,
      );
      return s.copyWith(
          checklistItems: [...s.checklistItems, item], isDirty: true);
    });
  }

  void updateChecklistItem(int index, String text) {
    _update((s) {
      final items = [...s.checklistItems];
      items[index] = items[index].copyWith(text: text);
      return s.copyWith(checklistItems: items, isDirty: true);
    });
  }

  void toggleChecklistItem(int index) {
    _update((s) {
      final items = [...s.checklistItems];
      items[index] = items[index].copyWith(isChecked: !items[index].isChecked);
      return s.copyWith(checklistItems: items, isDirty: true);
    });
  }

  void removeChecklistItem(int index) {
    _update((s) {
      final items = [...s.checklistItems]..removeAt(index);
      final reindexed = [
        for (var i = 0; i < items.length; i++) items[i].copyWith(position: i),
      ];
      return s.copyWith(checklistItems: reindexed, isDirty: true);
    });
  }

  void reorderChecklistItems(int oldIndex, int newIndex) {
    _update((s) {
      final items = [...s.checklistItems];
      if (newIndex > oldIndex) newIndex--;
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      final reindexed = [
        for (var i = 0; i < items.length; i++) items[i].copyWith(position: i),
      ];
      return s.copyWith(checklistItems: reindexed, isDirty: true);
    });
  }

  void addAttachment(NoteAttachmentModel attachment) {
    _update((s) => s.copyWith(
          attachments: [...s.attachments, attachment],
          isDirty: true,
        ));
  }

  void removeAttachment(NoteAttachmentModel attachment) {
    _update((s) {
      final updated = [...s.attachments]..remove(attachment);
      final removed = attachment.id != null
          ? [...s.removedAttachments, attachment]
          : s.removedAttachments;
      return s.copyWith(
        attachments: updated,
        removedAttachments: removed,
        isDirty: true,
      );
    });
  }

  /// Deletes staged (unsaved) attachment files from disk. Call on discard.
  Future<void> discardStagedFiles() async {
    final current = state.valueOrNull;
    if (current == null) return;
    for (final a in current.attachments) {
      if (a.id == null) await NotesRepository.deleteFile(a.filePath);
    }
  }

  Future<int?> save() async {
    final current = state.valueOrNull;
    if (current == null) return null;

    _update((s) => s.copyWith(isSaving: true));
    try {
      final repo = ref.read(notesRepositoryProvider);
      final newAttachments =
          current.attachments.where((a) => a.id == null).toList();

      if (current.noteId == null) {
        final newId = await repo.createNote(
          title: current.title,
          type: current.type,
          textContent:
              current.textContent.isEmpty ? null : current.textContent,
          items: current.checklistItems,
          newAttachments: newAttachments,
        );
        _update((s) => s.copyWith(
              noteId: newId,
              isDirty: false,
              isSaving: false,
              removedAttachments: [],
            ));
        return newId;
      } else {
        await repo.updateNote(
          id: current.noteId!,
          title: current.title,
          type: current.type,
          textContent:
              current.textContent.isEmpty ? null : current.textContent,
          items: current.checklistItems,
          newAttachments: newAttachments,
          removedAttachments: current.removedAttachments,
        );
        _update((s) => s.copyWith(
              isDirty: false,
              isSaving: false,
              removedAttachments: [],
            ));
        return current.noteId;
      }
    } catch (_) {
      _update((s) => s.copyWith(isSaving: false));
      rethrow;
    }
  }
}
