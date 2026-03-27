import 'note_type.dart';
import 'checklist_item.dart';

class NoteWithItems {
  final int id;
  final String title;
  final String? textContent;
  final NoteType type;
  final List<ChecklistItemModel> checklistItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteWithItems({
    required this.id,
    required this.title,
    this.textContent,
    required this.type,
    this.checklistItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get previewText {
    if (type == NoteType.text) return textContent ?? '';
    if (checklistItems.isEmpty) return 'Empty list';
    final checked = checklistItems.where((i) => i.isChecked).length;
    return '$checked / ${checklistItems.length} items checked';
  }

  NoteWithItems copyWith({
    int? id,
    String? title,
    Object? textContent = _sentinel,
    NoteType? type,
    List<ChecklistItemModel>? checklistItems,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _sentinel = Object();
