enum NoteType {
  text,
  checklist;

  String get dbValue => name;

  static NoteType fromDb(String value) =>
      NoteType.values.firstWhere((e) => e.name == value);
}
