import 'package:drift/drift.dart';
import 'notes_table.dart';

class NoteAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().references(Notes, #id)();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
