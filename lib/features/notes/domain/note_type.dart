enum NoteType {
  text,
  checklist,
  audio,
  video,
  photo,
  drawing;

  String get dbValue => name;

  static NoteType fromDb(String value) =>
      NoteType.values.firstWhere((e) => e.name == value);

  bool get isMedia =>
      this == audio || this == video || this == photo || this == drawing;
}
