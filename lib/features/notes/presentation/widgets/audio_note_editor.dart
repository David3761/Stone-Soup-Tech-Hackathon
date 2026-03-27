import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../data/notes_repository.dart';
import '../../providers/notes_providers.dart';
import 'attachment_tile.dart';

class AudioNoteEditor extends ConsumerStatefulWidget {
  final int? noteId;

  const AudioNoteEditor({super.key, required this.noteId});

  @override
  ConsumerState<AudioNoteEditor> createState() => _AudioNoteEditorState();
}

class _AudioNoteEditorState extends ConsumerState<AudioNoteEditor> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  String? _recordingPath;

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

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordingPath =
        p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _recorder.start(const RecordConfig(), path: _recordingPath!);
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    await _addFile(path);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      if (file.path != null) await _addFile(file.path!);
    }
  }

  Future<void> _addFile(String sourcePath) async {
    final notifier =
        ref.read(noteEditorNotifierProvider(widget.noteId).notifier);
    final current = ref.read(noteEditorNotifierProvider(widget.noteId));
    final pos = current.valueOrNull?.attachments.length ?? 0;
    final staged = await NotesRepository.stageFile(
      sourcePath: sourcePath,
      noteId: widget.noteId ?? 0,
      position: pos,
    );
    notifier.addAttachment(staged);
  }

  void _showChooser() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Record now'),
              onTap: () {
                Navigator.pop(ctx);
                _startRecording();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Pick from files'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
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
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  _timerLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
          ),
        if (attachments.isEmpty && !_isRecording)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No recordings yet')),
          ),
        ...attachments.map(
          (a) => AttachmentTile(
            key: ValueKey(a.filePath),
            attachment: a,
            icon: Icons.audio_file,
            onDelete: () => ref
                .read(noteEditorNotifierProvider(widget.noteId).notifier)
                .removeAttachment(a),
          ),
        ),
        const SizedBox(height: 8),
        if (!_isRecording)
          ElevatedButton.icon(
            onPressed: _showChooser,
            icon: const Icon(Icons.add),
            label: const Text('Add Recording'),
          ),
      ],
    );
  }
}
