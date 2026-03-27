import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const _Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final _repaintKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;

  static const _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.white,
  ];

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentPoints = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentPoints = [..._currentPoints, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _strokes.add(_Stroke(
          points: _currentPoints,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
        ));
        _currentPoints = [];
      });
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isNotEmpty) setState(() => _strokes.clear());
  }

  Future<String> _saveToFile() async {
    final boundary = _repaintKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getApplicationDocumentsDirectory();
    final attachDir = Directory(p.join(dir.path, 'attachments'));
    await attachDir.create(recursive: true);
    final fileName = '${const Uuid().v4()}.png';
    final filePath = p.join(attachDir.path, fileName);
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  Future<void> _save() async {
    final path = await _saveToFile();
    if (mounted) Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _strokes.isEmpty ? null : _clear,
            tooltip: 'Clear',
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: Colors.white,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      strokes: _strokes,
                      currentPoints: _currentPoints,
                      currentColor: _selectedColor,
                      currentWidth: _strokeWidth,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          // Toolbar
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Color picker
                ..._colors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: _selectedColor == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Stroke width
                const Icon(Icons.line_weight, size: 20),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  const _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  void _drawStroke(Canvas canvas, List<Offset> points, Color color,
      double strokeWidth) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _drawStroke(canvas, s.points, s.color, s.strokeWidth);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
