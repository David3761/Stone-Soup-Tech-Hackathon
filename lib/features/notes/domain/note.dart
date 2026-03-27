import 'note_type.dart';
import 'checklist_item.dart';
import 'note_attachment.dart';

class NoteWithItems {
  final int id;
  final String title;
  final String? textContent;
  final NoteType type;
  final List<ChecklistItemModel> checklistItems;
  final List<NoteAttachmentModel> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteWithItems({
    required this.id,
    required this.title,
    this.textContent,
    required this.type,
    this.checklistItems = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get previewText {
    switch (type) {
      case NoteType.text:
        return textContent ?? '';
      case NoteType.checklist:
        if (checklistItems.isEmpty) return 'Empty list';
        final checked = checklistItems.where((i) => i.isChecked).length;
        return '$checked / ${checklistItems.length} items checked';
      case NoteType.audio:
        final n = attachments.length;
        return n == 0 ? 'No recordings' : '$n recording${n == 1 ? '' : 's'}';
      case NoteType.video:
        final n = attachments.length;
        return n == 0 ? 'No videos' : '$n video${n == 1 ? '' : 's'}';
      case NoteType.photo:
        final n = attachments.length;
        return n == 0 ? 'No photos' : '$n photo${n == 1 ? '' : 's'}';
      case NoteType.drawing:
        final n = attachments.length;
        return n == 0 ? 'No drawings' : '$n drawing${n == 1 ? '' : 's'}';
    }
  }

  NoteWithItems copyWith({
    int? id,
    String? title,
    Object? textContent = _sentinel,
    NoteType? type,
    List<ChecklistItemModel>? checklistItems,
    List<NoteAttachmentModel>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteWithItems(
      id: id ?? this.id,
      title: title ?? this.title,
      textContent: textContent == _sentinel
          ? this.textContent
          : textContent as String?,
      type: type ?? this.type,
      checklistItems: checklistItems ?? this.checklistItems,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _sentinel = Object();
