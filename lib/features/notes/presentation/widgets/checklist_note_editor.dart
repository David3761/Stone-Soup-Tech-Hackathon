import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notes_providers.dart';
import 'checklist_item_tile.dart';

class ChecklistNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const ChecklistNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<ChecklistNoteEditor> createState() =>
      _ChecklistNoteEditorState();
}

class _ChecklistNoteEditorState extends ConsumerState<ChecklistNoteEditor> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(noteEditorNotifierProvider(widget.noteId).notifier)
        .addChecklistItem(text);
    _addController.clear();
    _addFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref
            .watch(noteEditorNotifierProvider(widget.noteId))
            .valueOrNull
            ?.checklistItems ??
        [];
    final notifier = ref.read(
      noteEditorNotifierProvider(widget.noteId).notifier,
    );

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 4),
            itemCount: items.length,
            onReorder: notifier.reorderChecklistItems,
            itemBuilder: (context, index) {
              final item = items[index];
              return ChecklistItemTile(
                key: ValueKey(item.id ?? 'new_$index'),
                item: item,
                onTextChanged: (text) =>
                    notifier.updateChecklistItem(index, text),
                onToggled: (_) => notifier.toggleChecklistItem(index),
                onRemove: () => notifier.removeChecklistItem(index),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.add_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _addController,
                  focusNode: _addFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add item…',
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: _addItem,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
