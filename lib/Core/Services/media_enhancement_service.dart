import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'media_enhancement_service_processing_part.dart';
part 'media_enhancement_service_controls_part.dart';

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

class MediaEnhancementService extends GetxController {
  static MediaEnhancementService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MediaEnhancementService());
  }

  static MediaEnhancementService? maybeFind() {
    final isRegistered = Get.isRegistered<MediaEnhancementService>();
    if (!isRegistered) return null;
    return Get.find<MediaEnhancementService>();
  }

  final RxList<MediaEdit> _currentEdits = <MediaEdit>[].obs;
  final Rx<FilterType> _selectedFilter = FilterType.none.obs;
  final Rx<MediaAdjustments> _currentAdjustments = MediaAdjustments().obs;
  final RxBool _isProcessing = false.obs;
  final RxDouble _processingProgress = 0.0.obs;

  // Getters
  List<MediaEdit> get currentEdits => _currentEdits;
  FilterType get selectedFilter => _selectedFilter.value;
  MediaAdjustments get currentAdjustments => _currentAdjustments.value;
  bool get isProcessing => _isProcessing.value;
  double get processingProgress => _processingProgress.value;
}
