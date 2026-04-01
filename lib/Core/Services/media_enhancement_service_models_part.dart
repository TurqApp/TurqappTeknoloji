part of 'media_enhancement_service.dart';

enum FilterType {
  none('Original'),
  vintage('Vintage'),
  blackWhite('B&W'),
  sepia('Sepia'),
  vivid('Vivid'),
  cool('Cool'),
  warm('Warm'),
  dramatic('Dramatic'),
  soft('Soft');

  const FilterType(this.label);
  final String label;
}

enum AdjustmentType {
  brightness,
  contrast,
  saturation,
  exposure,
  highlights,
  shadows,
  vibrance,
  clarity,
  warmth,
  tint,
}

class MediaAdjustments {
  final double brightness;
  final double contrast;
  final double saturation;
  final double exposure;
  final double highlights;
  final double shadows;
  final double vibrance;
  final double clarity;
  final double warmth;
  final double tint;

  MediaAdjustments({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.exposure = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.vibrance = 0.0,
    this.clarity = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
  });

  MediaAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? highlights,
    double? shadows,
    double? vibrance,
    double? clarity,
    double? warmth,
    double? tint,
  }) =>
      MediaAdjustments(
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        exposure: exposure ?? this.exposure,
        highlights: highlights ?? this.highlights,
        shadows: shadows ?? this.shadows,
        vibrance: vibrance ?? this.vibrance,
        clarity: clarity ?? this.clarity,
        warmth: warmth ?? this.warmth,
        tint: tint ?? this.tint,
      );

  Map<String, dynamic> toJson() => {
        'brightness': brightness,
        'contrast': contrast,
        'saturation': saturation,
        'exposure': exposure,
        'highlights': highlights,
        'shadows': shadows,
        'vibrance': vibrance,
        'clarity': clarity,
        'warmth': warmth,
        'tint': tint,
      };

  factory MediaAdjustments.fromJson(Map<String, dynamic> json) =>
      MediaAdjustments(
        brightness: json['brightness']?.toDouble() ?? 0.0,
        contrast: json['contrast']?.toDouble() ?? 0.0,
        saturation: json['saturation']?.toDouble() ?? 0.0,
        exposure: json['exposure']?.toDouble() ?? 0.0,
        highlights: json['highlights']?.toDouble() ?? 0.0,
        shadows: json['shadows']?.toDouble() ?? 0.0,
        vibrance: json['vibrance']?.toDouble() ?? 0.0,
        clarity: json['clarity']?.toDouble() ?? 0.0,
        warmth: json['warmth']?.toDouble() ?? 0.0,
        tint: json['tint']?.toDouble() ?? 0.0,
      );

  bool get hasAdjustments =>
      brightness != 0.0 ||
      contrast != 0.0 ||
      saturation != 0.0 ||
      exposure != 0.0 ||
      highlights != 0.0 ||
      shadows != 0.0 ||
      vibrance != 0.0 ||
      clarity != 0.0 ||
      warmth != 0.0 ||
      tint != 0.0;
}

class MediaEdit {
  final String id;
  final File originalFile;
  final FilterType filter;
  final MediaAdjustments adjustments;
  final bool isImage;
  final DateTime timestamp;

  MediaEdit({
    required this.id,
    required this.originalFile,
    this.filter = FilterType.none,
    required this.adjustments,
    required this.isImage,
    required this.timestamp,
  });
}
