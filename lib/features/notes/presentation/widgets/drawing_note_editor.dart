import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/note_attachment.dart';
import '../../providers/notes_providers.dart';
import '../screens/drawing_screen.dart';

class DrawingNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const DrawingNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<DrawingNoteEditor> createState() => _DrawingNoteEditorState();
}

class _DrawingNoteEditorState extends ConsumerState<DrawingNoteEditor> {
  @override
  void initState() {
    super.initState();
    if (widget.noteId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final animation = ModalRoute.of(context)?.animation;
        if (animation == null || animation.isCompleted) {
          _openDrawingScreen();
        } else {
          late AnimationStatusListener listener;
          listener = (status) {
            if (status == AnimationStatus.completed) {
              animation.removeStatusListener(listener);
              if (mounted) _openDrawingScreen();
            }
          };
          animation.addStatusListener(listener);
        }
      });
    }
  }

  Future<void> _openDrawingScreen() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DrawingScreen()),
    );
    if (path == null) return;
    if (!mounted) return;
    final notifier = ref.read(noteEditorNotifierProvider(widget.noteId).notifier);
    final current = ref.read(noteEditorNotifierProvider(widget.noteId));
    final pos = current.valueOrNull?.attachments.length ?? 0;
    final attachment = NoteAttachmentModel(
      noteId: widget.noteId ?? 0,
      filePath: path,
      fileName: p.basename(path),
      position: pos,
      createdAt: DateTime.now(),
    );
    notifier.addAttachment(attachment);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(noteEditorNotifierProvider(widget.noteId));
    final attachments = stateAsync.valueOrNull?.attachments ?? [];

    return Column(
      children: [
        if (attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No drawings yet')),
          ),
        if (attachments.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final a = attachments[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(a.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(noteEditorNotifierProvider(widget.noteId).notifier)
                          .removeAttachment(a),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _openDrawingScreen,
          icon: const Icon(Icons.draw),
          label: const Text('New Drawing'),
        ),
      ],
    );
  }
}
