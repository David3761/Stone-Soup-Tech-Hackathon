import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notes_table.dart';
import '../tables/checklist_items_table.dart';
import '../../../features/notes/domain/note_type.dart';
import '../../../features/notes/domain/note_filter.dart';
import '../../../features/notes/domain/note.dart';
import '../../../features/notes/domain/checklist_item.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes, ChecklistItems])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<NoteWithItems>> watchNotesWithItems(NoteFilter filter) {
    final query = select(notes).join([
      leftOuterJoin(
        checklistItems,
        checklistItems.noteId.equalsExp(notes.id),
      ),
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
    ]);

    return query.watch().map(_groupRows);
  }

  List<NoteWithItems> _groupRows(List<TypedResult> rows) {
    final Map<int, Note> notesMap = {};
    final Map<int, List<ChecklistItem>> itemsMap = {};
    final List<int> order = [];

    for (final row in rows) {
      final note = row.readTable(notes);
      final item = row.readTableOrNull(checklistItems);
      if (!notesMap.containsKey(note.id)) {
        notesMap[note.id] = note;
        itemsMap[note.id] = [];
        order.add(note.id);
      }
      if (item != null) {
        itemsMap[note.id]!.add(item);
      }
    }

    return order.map((id) {
      final note = notesMap[id]!;
      final items = itemsMap[id]!;
      return NoteWithItems(
        id: note.id,
        title: note.title,
        textContent: note.textContent,
        type: NoteType.fromDb(note.type),
        checklistItems: items
            .map((i) => ChecklistItemModel(
                  id: i.id,
                  noteId: i.noteId,
                  text: i.content,
                  isChecked: i.isChecked,
                  position: i.position,
                ))
            .toList(),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
    }).toList();
  }

  Future<Note?> getNoteById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ChecklistItem>> getItemsForNote(int noteId) =>
      (select(checklistItems)
            ..where((t) => t.noteId.equals(noteId))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

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

  Future<int> insertChecklistItem(ChecklistItemsCompanion item) =>
      into(checklistItems).insert(item);

  Future<int> deleteItemsForNote(int noteId) =>
      (delete(checklistItems)..where((t) => t.noteId.equals(noteId))).go();

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();
}
