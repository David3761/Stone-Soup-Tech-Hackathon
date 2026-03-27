import 'package:flutter/material.dart';

import '../../domain/checklist_item.dart';

class ChecklistItemTile extends StatefulWidget {
  final ChecklistItemModel item;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onToggled;
  final VoidCallback onRemove;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onTextChanged,
    required this.onToggled,
    required this.onRemove,
  });

  @override
  State<ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<ChecklistItemTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(ChecklistItemTile old) {
    super.didUpdateWidget(old);
    // Only sync if item identity changed (reorder) not on every text change
    if (old.item.id != widget.item.id ||
        old.item.position != widget.item.position) {
      if (_controller.text != widget.item.text) {
        _controller.text = widget.item.text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checked = widget.item.isChecked;

    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: (v) => widget.onToggled(v ?? false),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Item…',
              isDense: true,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? theme.colorScheme.outline : null,
            ),
            onChanged: widget.onTextChanged,
          ),
        ),
        ReorderableDragStartListener(
          index: widget.item.position,
          child: const Icon(Icons.drag_handle_rounded, size: 20),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: widget.onRemove,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
