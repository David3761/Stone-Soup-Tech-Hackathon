import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/notes_repository.dart';
import '../../providers/notes_providers.dart';

class PhotoNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const PhotoNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<PhotoNoteEditor> createState() => _PhotoNoteEditorState();
}

class _PhotoNoteEditorState extends ConsumerState<PhotoNoteEditor> {
  @override
  void initState() {
    super.initState();
    if (widget.noteId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final animation = ModalRoute.of(context)?.animation;
        if (animation == null || animation.isCompleted) {
          _showChooser();
        } else {
          late AnimationStatusListener listener;
          listener = (status) {
            if (status == AnimationStatus.completed) {
              animation.removeStatusListener(listener);
              if (mounted) _showChooser();
            }
          };
          animation.addStatusListener(listener);
        }
      });
    }
  }

  Future<void> _addFile(String sourcePath) async {
    final notifier = ref.read(noteEditorNotifierProvider(widget.noteId).notifier);
    final current = ref.read(noteEditorNotifierProvider(widget.noteId));
    final pos = current.valueOrNull?.attachments.length ?? 0;
    final staged = await NotesRepository.stageFile(
      sourcePath: sourcePath,
      noteId: widget.noteId ?? 0,
      position: pos,
    );
    notifier.addAttachment(staged);
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    await _addFile(image.path);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    for (final image in images) {
      await _addFile(image.path);
    }
  }

  void _showChooser() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _capture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(noteEditorNotifierProvider(widget.noteId));
    final attachments = stateAsync.valueOrNull?.attachments ?? [];

    if (attachments.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No photos yet')),
          ),
          ElevatedButton.icon(
            onPressed: _showChooser,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Photo'),
          ),
        ],
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: attachments.length + 1,
          itemBuilder: (context, index) {
            if (index == attachments.length) {
              return InkWell(
                onTap: _showChooser,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo),
                ),
              );
            }
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
      ],
    );
  }
}
