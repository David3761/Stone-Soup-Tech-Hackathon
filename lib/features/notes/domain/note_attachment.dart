class NoteAttachmentModel {
  final int? id; // null = not yet saved to DB
  final int noteId;
  final String filePath;
  final String fileName;
  final int position;
  final DateTime createdAt;

  const NoteAttachmentModel({
    this.id,
    required this.noteId,
    required this.filePath,
    required this.fileName,
    required this.position,
    required this.createdAt,
  });

  NoteAttachmentModel copyWith({
    int? id,
    int? noteId,
    String? filePath,
    String? fileName,
    int? position,
    DateTime? createdAt,
  }) {
    return NoteAttachmentModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
