class ChecklistItemModel {
  final int? id;
  final int noteId;
  final String text;
  final bool isChecked;
  final int position;

  const ChecklistItemModel({
    this.id,
    required this.noteId,
    required this.text,
    this.isChecked = false,
    this.position = 0,
  });

  ChecklistItemModel copyWith({
    int? id,
    int? noteId,
    String? text,
    bool? isChecked,
    int? position,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      position: position ?? this.position,
    );
  }
}
