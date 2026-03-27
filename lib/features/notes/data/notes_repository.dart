import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/checklist_item.dart';
import '../domain/note.dart';
import '../domain/note_filter.dart';
import '../domain/note_type.dart';

part 'notes_repository.g.dart';

@riverpod
NotesRepository notesRepository(NotesRepositoryRef ref) {
  return NotesRepository(ref.watch(appDatabaseProvider));
}
//eqv to
// final notesRepositoryProvider = Provider.autoDispose<NotesRepository>((ref) {
//   return NotesRepository(ref.watch(appDatabaseProvider));
// });

class NotesRepository {
  final AppDatabase _db;
  NotesRepository(this._db);

  Stream<List<NoteWithItems>> watchNotes(NoteFilter filter) =>
      _db.notesDao.watchNotesWithItems(filter);

  Future<NoteWithItems?> getNote(int id) async {
    final note = await _db.notesDao.getNoteById(id);
    if (note == null) return null;
    final items = await _db.notesDao.getItemsForNote(id);
    return NoteWithItems(
      id: note.id,
      title: note.title,
      textContent: note.textContent,
      type: NoteType.fromDb(note.type),
      checklistItems: items
          .map(
            (i) => ChecklistItemModel(
              id: i.id,
              noteId: i.noteId,
              text: i.content,
              isChecked: i.isChecked,
              position: i.position,
            ),
          )
          .toList(),
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  Future<int> createNote({
    required String title,
    required NoteType type,
    String? textContent,
    List<ChecklistItemModel> items = const [],
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      final noteId = await _db.notesDao.insertNote(
        NotesCompanion.insert(
          title: Value(title),
          type: type.dbValue,
          textContent: Value(textContent),
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (var i = 0; i < items.length; i++) {
        await _db.notesDao.insertChecklistItem(
          ChecklistItemsCompanion.insert(
            noteId: noteId,
            content: Value(items[i].text),
            isChecked: Value(items[i].isChecked),
            position: Value(i),
          ),
        );
      }
      return noteId;
    });
  }

  Future<void> updateNote({
    required int id,
    required String title,
    required NoteType type,
    String? textContent,
    List<ChecklistItemModel> items = const [],
  }) async {
    await _db.transaction(() async {
      await _db.notesDao.updateNoteFields(
        id,
        title: title,
        type: type.dbValue,
        textContent: Value(textContent),
        updatedAt: DateTime.now(),
      );
      await _db.notesDao.deleteItemsForNote(id);
      for (var i = 0; i < items.length; i++) {
        await _db.notesDao.insertChecklistItem(
          ChecklistItemsCompanion.insert(
            noteId: id,
            content: Value(items[i].text),
            isChecked: Value(items[i].isChecked),
            position: Value(i),
          ),
        );
      }
    });
  }

  Future<void> deleteNote(int id) async {
    await _db.transaction(() async {
      await _db.notesDao.deleteItemsForNote(id);
      await _db.notesDao.deleteNote(id);
    });
  }
}
