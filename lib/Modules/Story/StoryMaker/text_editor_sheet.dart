import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TextEditorResult {
  final String text;
  final int textColor;
  final int textBgColor;
  final bool hasTextBg;
  final String textAlign; // 'left' | 'center' | 'right'
  final String fontWeight; // 'regular' | 'bold'
  final bool italic;
  final bool underline;
  final double shadowBlur;
  final double shadowOpacity;
  final String fontFamily;
  final bool hasOutline;
  final int outlineColor;

  TextEditorResult({
    required this.text,
    required this.textColor,
    required this.textBgColor,
    required this.hasTextBg,
    required this.textAlign,
    required this.fontWeight,
    required this.italic,
    required this.underline,
    required this.shadowBlur,
    required this.shadowOpacity,
    this.fontFamily = 'MontserratMedium',
    this.hasOutline = false,
    this.outlineColor = 0xFF000000,
  });
}

class TextEditorSheet extends StatefulWidget {
  const TextEditorSheet({super.key});

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _hasBg = true; // Varsayılan: arka plan açık (okunurluk için)
  String _align = 'center';
  String _weight = 'regular';
  int _textColor = 0xFFFFFFFF; // Varsayılan: beyaz
  final int _bgColor = 0xAA000000;
  bool _italic = false;
  bool _underline = false;
  double _shadowBlur = 2.0;
  double _shadowOpacity = 0.6;
  int _fontIndex = 0;
  bool _hasOutline = false;
  final int _outlineColor = 0xFF000000;

  static const List<String> _fontFamilies = [
    'MontserratMedium',
    'MontserratBold',
    'serif',
    'monospace',
  ];

  static const List<String> _fontLabels = [
    'Aa',
    'Aa',
    'Aa',
    'Aa',
  ];

  final List<int> _colors = const [
    0xFFFFFFFF,
    0xFF000000,
    0xFFFF3B30,
    0xFFFF9500,
    0xFFFFCC00,
    0xFF34C759,
    0xFF007AFF,
    0xFF5856D6,
    0xFFFF2D55,
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Container(
        width: size.width,
        height: size.height * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Stack(
          children: [
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('story.text_title'.tr,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'MontserratMedium')),
                  TextButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(
                        context,
                        TextEditorResult(
                          text: text,
                          textColor: _textColor,
                          textBgColor: _bgColor,
                          hasTextBg: _hasBg,
                          textAlign: _align,
                          fontWeight: _weight,
                          italic: _italic,
                          underline: _underline,
                          shadowBlur: _shadowBlur,
                          shadowOpacity: _shadowOpacity,
                          fontFamily: _fontFamilies[_fontIndex],
                          hasOutline: _hasOutline,
                          outlineColor: _outlineColor,
                        ),
                      );
                    },
                    child: Text('common.done'.tr,
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),

            // Center text editor
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _hasBg ? Color(_bgColor) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: null,
                    textAlign: _align == 'left'
                        ? TextAlign.left
                        : _align == 'right'
                            ? TextAlign.right
                            : TextAlign.center,
                    style: TextStyle(
                      color: Color(_textColor),
                      fontSize: 22,
                      fontWeight:
                          _weight == 'bold' ? FontWeight.bold : FontWeight.w500,
                      fontFamily: _fontFamilies[_fontIndex],
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'story.write_text'.tr,
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),

            // Left toolbar (toggles)
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Font family selector
                  GestureDetector(
                    onTap: () => setState(() {
                      _fontIndex = (_fontIndex + 1) % _fontFamilies.length;
                    }),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _fontLabels[_fontIndex],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: _fontFamilies[_fontIndex],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Outline toggle
                  IconButton(
                    onPressed: () => setState(() => _hasOutline = !_hasOutline),
                    icon: Icon(CupertinoIcons.textformat_abc,
                        color: _hasOutline ? Colors.greenAccent : Colors.white),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _hasBg = !_hasBg),
                    icon: Icon(CupertinoIcons.rectangle_on_rectangle,
                        color: _hasBg ? Colors.greenAccent : Colors.white),
                  ),
                  IconButton(
                    onPressed: () => setState(
                        () => _weight = _weight == 'bold' ? 'regular' : 'bold'),
                    icon: Icon(CupertinoIcons.bold,
                        color: _weight == 'bold'
                            ? Colors.blueAccent
                            : Colors.white),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _italic = !_italic),
                    icon: Icon(CupertinoIcons.italic,
                        color: _italic ? Colors.blueAccent : Colors.white),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _underline = !_underline),
                    icon: Icon(CupertinoIcons.underline,
                        color: _underline ? Colors.blueAccent : Colors.white),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (_align == 'left') {
                        _align = 'center';
                      } else if (_align == 'center') {
                        _align = 'right';
                      } else {
                        _align = 'left';
                      }
                    }),
                    icon: Icon(
                      _align == 'left'
                          ? CupertinoIcons.text_alignleft
                          : _align == 'right'
                              ? CupertinoIcons.text_alignright
                              : CupertinoIcons.text_aligncenter,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Right toolbar (color dots)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 44,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Shadow opacity slider (vertical)
                      RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _shadowOpacity,
                          min: 0,
                          max: 1,
                          onChanged: (v) => setState(() => _shadowOpacity = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Shadow blur slider
                      RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _shadowBlur,
                          min: 0,
                          max: 8,
                          onChanged: (v) => setState(() => _shadowBlur = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Color dots
                      ..._colors.map((c) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => _textColor = c),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(c),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
