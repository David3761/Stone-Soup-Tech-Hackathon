import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notes_providers.dart';

class TextNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const TextNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<TextNoteEditor> createState() => _TextNoteEditorState();
}

class _TextNoteEditorState extends ConsumerState<TextNoteEditor> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState =
        ref.watch(noteEditorNotifierProvider(widget.noteId)).valueOrNull;

    // Sync controller once when state first loads
    if (!_initialized && editorState != null) {
      _initialized = true;
      final text = editorState.textContent;
      _controller.text = text;
      _controller.selection =
          TextSelection.collapsed(offset: text.length);
    }

    return TextField(
      controller: _controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        hintText: 'Start writing…',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      onChanged: (v) => ref
          .read(noteEditorNotifierProvider(widget.noteId).notifier)
          .setTextContent(v),
    );
  }
}
