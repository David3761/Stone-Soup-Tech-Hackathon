import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/checklist_item.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import '../domain/note_filter.dart';
import '../domain/note_type.dart';

part 'notes_repository.g.dart';

@riverpod
NotesRepository notesRepository(NotesRepositoryRef ref) {
  return NotesRepository(ref.watch(appDatabaseProvider));
}

class NotesRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  NotesRepository(this._db);

  // -------------------------------------------------------------------------
  // File helpers
  // -------------------------------------------------------------------------

  static Future<String> _persistFile(
    String sourcePath,
    String extension,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(dir.path, 'attachments'));
    await attachmentsDir.create(recursive: true);
    final fileName = '${_uuid.v4()}.$extension';
    final dest = p.join(attachmentsDir.path, fileName);
    await File(sourcePath).copy(dest);
    return dest;
  }

  static Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Watch / read
  // -------------------------------------------------------------------------

  Stream<List<NoteWithItems>> watchNotes(NoteFilter filter) =>
      _db.notesDao.watchNotesWithItems(filter);

  Future<NoteWithItems?> getNote(int id) async {
    final note = await _db.notesDao.getNoteById(id);
    if (note == null) return null;
    final items = await _db.notesDao.getItemsForNote(id);
    final rawAttachments = await _db.notesDao.getAttachmentsForNote(id);
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
      attachments: rawAttachments
          .map(
            (a) => NoteAttachmentModel(
              id: a.id,
              noteId: a.noteId,
              filePath: a.filePath,
              fileName: a.fileName,
              position: a.position,
              createdAt: a.createdAt,
            ),
          )
          .toList(),
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  // -------------------------------------------------------------------------
  // Create
  // -------------------------------------------------------------------------

  Future<int> createNote({
    required String title,
    required NoteType type,
    String? textContent,
    List<ChecklistItemModel> items = const [],
    List<NoteAttachmentModel> newAttachments = const [],
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
      for (var i = 0; i < newAttachments.length; i++) {
        await _db.notesDao.insertAttachment(
          NoteAttachmentsCompanion.insert(
            noteId: noteId,
            filePath: newAttachments[i].filePath,
            fileName: newAttachments[i].fileName,
            position: Value(i),
            createdAt: newAttachments[i].createdAt,
          ),
        );
      }
      return noteId;
    });
  }

  // -------------------------------------------------------------------------
  // Update
  // -------------------------------------------------------------------------

  Future<void> updateNote({
    required int id,
    required String title,
    required NoteType type,
    String? textContent,
    List<ChecklistItemModel> items = const [],
    List<NoteAttachmentModel> newAttachments = const [],
    List<NoteAttachmentModel> removedAttachments = const [],
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
      for (final a in removedAttachments) {
        if (a.id != null) await _db.notesDao.deleteAttachment(a.id!);
      }
      final existingCount = (await _db.notesDao.getAttachmentsForNote(
        id,
      )).length;
      for (var i = 0; i < newAttachments.length; i++) {
        await _db.notesDao.insertAttachment(
          NoteAttachmentsCompanion.insert(
            noteId: id,
            filePath: newAttachments[i].filePath,
            fileName: newAttachments[i].fileName,
            position: Value(existingCount + i),
            createdAt: newAttachments[i].createdAt,
          ),
        );
      }
    });
    for (final a in removedAttachments) {
      await _deleteFile(a.filePath);
    }
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  Future<void> deleteNote(int id) async {
    final rawAttachments = await _db.notesDao.getAttachmentsForNote(id);
    await _db.transaction(() async {
      await _db.notesDao.deleteItemsForNote(id);
      await _db.notesDao.deleteAttachmentsForNote(id);
      await _db.notesDao.deleteNote(id);
    });
    for (final a in rawAttachments) {
      await _deleteFile(a.filePath);
    }
  }

  // -------------------------------------------------------------------------
  // Public file helper — used by editor widgets to stage a file
  // -------------------------------------------------------------------------

  static Future<NoteAttachmentModel> stageFile({
    required String sourcePath,
    required int noteId,
    required int position,
  }) async {
    final ext = p.extension(sourcePath).replaceFirst('.', '');
    final permanentPath = await _persistFile(
      sourcePath,
      ext.isEmpty ? 'bin' : ext,
    );
    return NoteAttachmentModel(
      noteId: noteId,
      filePath: permanentPath,
      fileName: p.basename(permanentPath),
      position: position,
      createdAt: DateTime.now(),
    );
  }

  static Future<void> deleteFile(String filePath) => _deleteFile(filePath);
}
