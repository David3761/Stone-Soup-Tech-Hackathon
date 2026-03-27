import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/notes_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/note_attachments_table.dart';
import 'daos/notes_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Notes, ChecklistItems, NoteAttachments],
  daos: [NotesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(noteAttachments);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notes.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
