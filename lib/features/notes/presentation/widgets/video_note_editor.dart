import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/notes_repository.dart';
import '../../providers/notes_providers.dart';
import 'attachment_tile.dart';

class VideoNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const VideoNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<VideoNoteEditor> createState() => _VideoNoteEditorState();
}

class _VideoNoteEditorState extends ConsumerState<VideoNoteEditor> {
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

  Future<void> _record() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;
    if (!mounted) return;
    await _addFile(video.path);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    if (!mounted) return;
    await _addFile(video.path);
  }

  void _showChooser() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record with camera'),
              onTap: () {
                Navigator.pop(ctx);
                _record();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
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

    return Column(
      children: [
        if (attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No videos yet')),
          ),
        ...attachments.map(
          (a) => AttachmentTile(
            key: ValueKey(a.filePath),
            attachment: a,
            icon: Icons.video_file,
            onDelete: () => ref
                .read(noteEditorNotifierProvider(widget.noteId).notifier)
                .removeAttachment(a),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _showChooser,
          icon: const Icon(Icons.add),
          label: const Text('Add Video'),
        ),
      ],
    );
  }
}
