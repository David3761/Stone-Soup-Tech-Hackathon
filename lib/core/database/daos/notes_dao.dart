import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notes_table.dart';
import '../tables/checklist_items_table.dart';
import '../tables/note_attachments_table.dart';
import '../../../features/notes/domain/note_type.dart';
import '../../../features/notes/domain/note_filter.dart';
import '../../../features/notes/domain/note.dart';
import '../../../features/notes/domain/checklist_item.dart';
import '../../../features/notes/domain/note_attachment.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes, ChecklistItems, NoteAttachments])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // -------------------------------------------------------------------------
  // Watch stream with triple LEFT JOIN
  // -------------------------------------------------------------------------

  Stream<List<NoteWithItems>> watchNotesWithItems(NoteFilter filter) {
    final query = select(notes).join([
      leftOuterJoin(checklistItems, checklistItems.noteId.equalsExp(notes.id)),
      leftOuterJoin(
          noteAttachments, noteAttachments.noteId.equalsExp(notes.id)),
    ]);

    if (filter.searchQuery.isNotEmpty) {
      final q = '%${filter.searchQuery}%';
      query.where(notes.title.like(q) | notes.textContent.like(q));
    }

    if (filter.typeFilter != null) {
      query.where(notes.type.equals(filter.typeFilter!.dbValue));
    }

    if (filter.createdAfter != null) {
      query.where(notes.createdAt.isBiggerOrEqualValue(filter.createdAfter!));
    }

    if (filter.createdBefore != null) {
      query.where(notes.createdAt.isSmallerOrEqualValue(filter.createdBefore!));
    }

    final orderMode = filter.sortDirection == SortDirection.ascending
        ? OrderingMode.asc
        : OrderingMode.desc;

    final sortExpr = switch (filter.sortBy) {
      SortField.updatedAt => notes.updatedAt as Expression,
      SortField.createdAt => notes.createdAt as Expression,
      SortField.title => notes.title as Expression,
    };

    query.orderBy([
      OrderingTerm(expression: sortExpr, mode: orderMode),
      OrderingTerm(expression: notes.id),
      OrderingTerm(expression: checklistItems.position),
      OrderingTerm(expression: noteAttachments.position),
    ]);

    return query.watch().map(_groupRows);
  }

  List<NoteWithItems> _groupRows(List<TypedResult> rows) {
    final Map<int, Note> notesMap = {};
    final Map<int, List<ChecklistItem>> itemsMap = {};
    final Map<int, List<NoteAttachment>> attachmentsMap = {};
    // Sets for dedup (triple JOIN creates a cross product)
    final Map<int, Set<int>> seenItemIds = {};
    final Map<int, Set<int>> seenAttachmentIds = {};
    final List<int> order = [];

    for (final row in rows) {
      final note = row.readTable(notes);
      final item = row.readTableOrNull(checklistItems);
      final attachment = row.readTableOrNull(noteAttachments);

      if (!notesMap.containsKey(note.id)) {
        notesMap[note.id] = note;
        itemsMap[note.id] = [];
        attachmentsMap[note.id] = [];
        seenItemIds[note.id] = {};
        seenAttachmentIds[note.id] = {};
        order.add(note.id);
      }

      if (item != null && seenItemIds[note.id]!.add(item.id)) {
        itemsMap[note.id]!.add(item);
      }
      if (attachment != null &&
          seenAttachmentIds[note.id]!.add(attachment.id)) {
        attachmentsMap[note.id]!.add(attachment);
      }
    }

    return order.map((id) {
      final note = notesMap[id]!;
      return NoteWithItems(
        id: note.id,
        title: note.title,
        textContent: note.textContent,
        type: NoteType.fromDb(note.type),
        checklistItems: itemsMap[id]!
            .map((i) => ChecklistItemModel(
                  id: i.id,
                  noteId: i.noteId,
                  text: i.content,
                  isChecked: i.isChecked,
                  position: i.position,
                ))
            .toList(),
        attachments: attachmentsMap[id]!
            .map((a) => NoteAttachmentModel(
                  id: a.id,
                  noteId: a.noteId,
                  filePath: a.filePath,
                  fileName: a.fileName,
                  position: a.position,
                  createdAt: a.createdAt,
                ))
            .toList(),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Note CRUD
  // -------------------------------------------------------------------------

  Future<Note?> getNoteById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);

  Future<void> updateNoteFields(
    int id, {
    required String title,
    required String type,
    required Value<String?> textContent,
    required DateTime updatedAt,
  }) =>
      (update(notes)..where((t) => t.id.equals(id))).write(NotesCompanion(
        title: Value(title),
        type: Value(type),
        textContent: textContent,
        updatedAt: Value(updatedAt),
      ));

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();

  // -------------------------------------------------------------------------
  // Checklist item CRUD
  // -------------------------------------------------------------------------

  Future<List<ChecklistItem>> getItemsForNote(int noteId) =>
      (select(checklistItems)
            ..where((t) => t.noteId.equals(noteId))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

  Future<int> insertChecklistItem(ChecklistItemsCompanion item) =>
      into(checklistItems).insert(item);

  Future<int> deleteItemsForNote(int noteId) =>
      (delete(checklistItems)..where((t) => t.noteId.equals(noteId))).go();

  // -------------------------------------------------------------------------
  // Attachment CRUD
  // -------------------------------------------------------------------------

  Future<List<NoteAttachment>> getAttachmentsForNote(int noteId) =>
      (select(noteAttachments)
            ..where((t) => t.noteId.equals(noteId))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

  Future<int> insertAttachment(NoteAttachmentsCompanion attachment) =>
      into(noteAttachments).insert(attachment);

  Future<int> deleteAttachment(int id) =>
      (delete(noteAttachments)..where((t) => t.id.equals(id))).go();

  Future<int> deleteAttachmentsForNote(int noteId) =>
      (delete(noteAttachments)..where((t) => t.noteId.equals(noteId))).go();
}
