import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:get/get.dart';

class DrawingScreen extends StatefulWidget {
  final Function(String) onSave;

  const DrawingScreen({super.key, required this.onSave});

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

// Her nokta, genişliği ve rengi saklayan model
class _StrokePoint {
  final Offset? offset;
  final double strokeWidth;
  final Color color;
  _StrokePoint(this.offset, this.strokeWidth, this.color);
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<_StrokePoint> _points = [];
  Color _selectedColor = Colors.white;
  double _strokeWidth = 4.0;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'story.drawing_title'.tr,
          style: TextStyle(
            color: Colors.white,
            fontFamily: "MontserratBold",
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _saveDrawing,
            child: Text(
              'common.save'.tr,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "MontserratMedium",
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Çizim Alanı
          Positioned.fill(
            child: RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                // Başlangıç noktasını yakala
                onPanStart: (DragStartDetails details) {
                  setState(() {
                    _points.add(
                      _StrokePoint(
                        details.localPosition,
                        _strokeWidth,
                        _selectedColor,
                      ),
                    );
                  });
                },
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    _points.add(
                      _StrokePoint(
                        details.localPosition,
                        _strokeWidth,
                        _selectedColor,
                      ),
                    );
                  });
                },
                onPanEnd: (DragEndDetails _) => setState(() {
                  _points.add(
                    _StrokePoint(null, _strokeWidth, _selectedColor),
                  );
                }),
                child: CustomPaint(
                  painter: _DrawingPainter(points: _points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Alt sağda slider ve renk seçici butonu
          Positioned(
            bottom: 16,
            right: 16,
            left: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Slider
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 20,
                    value: _strokeWidth,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                    activeColor: _selectedColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Renk seçici butonu
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.black,
                        title: Text(
                          'story.brush_color'.tr,
                          style: TextStyle(color: Colors.white),
                        ),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            color: _selectedColor,
                            onColorChanged: (color) =>
                                setState(() => _selectedColor = color),
                            pickersEnabled: const <ColorPickerType, bool>{
                              ColorPickerType.wheel: true,
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'common.close'.tr,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    CupertinoIcons.color_filter,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = await File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png',
    ).writeAsBytes(pngBytes);
    widget.onSave(file.path);
    Navigator.pop(context);
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_StrokePoint> points;
  _DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1.offset != null && p2.offset != null) {
        final paint = Paint()
          ..color = p1.color
          ..strokeWidth = p1.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1.offset!, p2.offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
