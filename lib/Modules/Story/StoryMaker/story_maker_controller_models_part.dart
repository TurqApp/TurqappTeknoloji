part of 'story_maker_controller.dart';

enum StoryElementType {
  video,
  image,
  text,
  sticker,
  gif,
  drawing,
}

class StoryElement {
  final String id;
  StoryElementType type;
  String content;
  double width;
  double height;
  Offset position;
  double rotation;
  int zIndex;
  bool isMuted;
  double fontSize;
  double aspectRatio;
  int textColor;
  int textBgColor;
  bool hasTextBg;
  String textAlign;
  String fontWeight;
  bool italic;
  bool underline;
  double shadowBlur;
  double shadowOpacity;
  String fontFamily;
  bool hasOutline;
  int outlineColor;
  String stickerType;
  String stickerData;
  String mediaLookPreset;
  Offset? initialFocalPoint;
  Offset? initialPosition;
  double? initialWidth;
  double? initialHeight;
  double? initialRotation;
  double? initialFontSize;

  StoryElement({
    String? id,
    required this.type,
    required this.content,
    required this.width,
    required this.height,
    required this.position,
    this.rotation = 0,
    this.zIndex = 0,
    this.isMuted = false,
    this.fontSize = 20,
    this.aspectRatio = 1.0,
    this.textColor = 0xFFFFFFFF,
    this.textBgColor = 0x66000000,
    this.hasTextBg = false,
    this.textAlign = 'center',
    this.fontWeight = 'regular',
    this.italic = false,
    this.underline = false,
    this.shadowBlur = 2.0,
    this.shadowOpacity = 0.6,
    this.fontFamily = 'MontserratMedium',
    this.hasOutline = false,
    this.outlineColor = 0xFF000000,
    this.stickerType = '',
    this.stickerData = '',
    this.mediaLookPreset = 'original',
    this.initialFocalPoint,
    this.initialPosition,
    this.initialWidth,
    this.initialHeight,
    this.initialRotation,
    this.initialFontSize,
  }) : id = id ?? _generateId();

  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart =
        List.generate(5, (_) => random.nextInt(36).toRadixString(36)).join();
    return 'element_$timestamp$randomPart';
  }
}
