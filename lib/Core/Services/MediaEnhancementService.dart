import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

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

  /// Add a new media file for editing
  String addMediaForEditing(File mediaFile) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final isImage = _isImageFile(mediaFile);

    final edit = MediaEdit(
      id: id,
      originalFile: mediaFile,
      adjustments: MediaAdjustments(),
      isImage: isImage,
      timestamp: DateTime.now(),
    );

    _currentEdits.add(edit);
    return id;
  }

  /// Apply filter to image
  Future<Uint8List?> applyFilter(File imageFile, FilterType filter) async {
    if (filter == FilterType.none) {
      return await imageFile.readAsBytes();
    }

    _isProcessing.value = true;
    _processingProgress.value = 0.0;

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      _processingProgress.value = 0.3;

      img.Image processedImage;

      switch (filter) {
        case FilterType.vintage:
          processedImage = _applyVintageFilter(image);
          break;
        case FilterType.blackWhite:
          processedImage = img.grayscale(image);
          break;
        case FilterType.sepia:
          processedImage = img.sepia(image);
          break;
        case FilterType.vivid:
          processedImage = _applyVividFilter(image);
          break;
        case FilterType.cool:
          processedImage = _applyCoolFilter(image);
          break;
        case FilterType.warm:
          processedImage = _applyWarmFilter(image);
          break;
        case FilterType.dramatic:
          processedImage = _applyDramaticFilter(image);
          break;
        case FilterType.soft:
          processedImage = _applySoftFilter(image);
          break;
        default:
          processedImage = image;
      }

      _processingProgress.value = 0.8;

      final processedBytes =
          Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));

      _processingProgress.value = 1.0;
      return processedBytes;
    } catch (e) {
      print('Error applying filter: $e');
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

  /// Apply adjustments to image
  Future<Uint8List?> applyAdjustments(
      File imageFile, MediaAdjustments adjustments) async {
    if (!adjustments.hasAdjustments) {
      return await imageFile.readAsBytes();
    }

    _isProcessing.value = true;
    _processingProgress.value = 0.0;

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      _processingProgress.value = 0.2;

      img.Image processedImage = image;

      // Apply brightness
      if (adjustments.brightness != 0.0) {
        processedImage =
            img.adjustColor(processedImage, brightness: adjustments.brightness);
        _processingProgress.value = 0.3;
      }

      // Apply contrast
      if (adjustments.contrast != 0.0) {
        processedImage = img.adjustColor(processedImage,
            contrast: 1.0 + (adjustments.contrast / 100));
        _processingProgress.value = 0.4;
      }

      // Apply saturation
      if (adjustments.saturation != 0.0) {
        processedImage =
            img.adjustColor(processedImage, saturation: adjustments.saturation);
        _processingProgress.value = 0.5;
      }

      // Apply exposure (simulated with brightness)
      if (adjustments.exposure != 0.0) {
        processedImage = img.adjustColor(processedImage,
            brightness: adjustments.exposure * 0.5);
        _processingProgress.value = 0.6;
      }

      // Apply vibrance (enhanced saturation)
      if (adjustments.vibrance != 0.0) {
        processedImage = img.adjustColor(processedImage,
            saturation: adjustments.vibrance * 1.2);
        _processingProgress.value = 0.7;
      }

      _processingProgress.value = 0.9;

      final processedBytes =
          Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));

      _processingProgress.value = 1.0;
      return processedBytes;
    } catch (e) {
      print('Error applying adjustments: $e');
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

  /// Apply both filter and adjustments
  Future<Uint8List?> applyFullProcessing(
    File imageFile,
    FilterType filter,
    MediaAdjustments adjustments,
  ) async {
    _isProcessing.value = true;
    _processingProgress.value = 0.0;

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      _processingProgress.value = 0.1;

      img.Image processedImage = image;

      // Apply filter first
      if (filter != FilterType.none) {
        switch (filter) {
          case FilterType.vintage:
            processedImage = _applyVintageFilter(processedImage);
            break;
          case FilterType.blackWhite:
            processedImage = img.grayscale(processedImage);
            break;
          case FilterType.sepia:
            processedImage = img.sepia(processedImage);
            break;
          case FilterType.vivid:
            processedImage = _applyVividFilter(processedImage);
            break;
          case FilterType.cool:
            processedImage = _applyCoolFilter(processedImage);
            break;
          case FilterType.warm:
            processedImage = _applyWarmFilter(processedImage);
            break;
          case FilterType.dramatic:
            processedImage = _applyDramaticFilter(processedImage);
            break;
          case FilterType.soft:
            processedImage = _applySoftFilter(processedImage);
            break;
          default:
            break;
        }
        _processingProgress.value = 0.5;
      }

      // Apply adjustments
      if (adjustments.hasAdjustments) {
        if (adjustments.brightness != 0.0) {
          processedImage = img.adjustColor(processedImage,
              brightness: adjustments.brightness);
        }
        if (adjustments.contrast != 0.0) {
          processedImage = img.adjustColor(processedImage,
              contrast: 1.0 + (adjustments.contrast / 100));
        }
        if (adjustments.saturation != 0.0) {
          processedImage = img.adjustColor(processedImage,
              saturation: adjustments.saturation);
        }
        _processingProgress.value = 0.8;
      }

      final processedBytes =
          Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));

      _processingProgress.value = 1.0;
      return processedBytes;
    } catch (e) {
      print('Error in full processing: $e');
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

  /// Update current filter
  void setFilter(FilterType filter) {
    _selectedFilter.value = filter;
  }

  /// Update adjustment value
  void updateAdjustment(AdjustmentType type, double value) {
    switch (type) {
      case AdjustmentType.brightness:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(brightness: value);
        break;
      case AdjustmentType.contrast:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(contrast: value);
        break;
      case AdjustmentType.saturation:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(saturation: value);
        break;
      case AdjustmentType.exposure:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(exposure: value);
        break;
      case AdjustmentType.highlights:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(highlights: value);
        break;
      case AdjustmentType.shadows:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(shadows: value);
        break;
      case AdjustmentType.vibrance:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(vibrance: value);
        break;
      case AdjustmentType.clarity:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(clarity: value);
        break;
      case AdjustmentType.warmth:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(warmth: value);
        break;
      case AdjustmentType.tint:
        _currentAdjustments.value =
            _currentAdjustments.value.copyWith(tint: value);
        break;
    }
  }

  /// Reset all adjustments
  void resetAdjustments() {
    _currentAdjustments.value = MediaAdjustments();
  }

  /// Reset specific adjustment
  void resetAdjustment(AdjustmentType type) {
    updateAdjustment(type, 0.0);
  }

  /// Get adjustment value
  double getAdjustmentValue(AdjustmentType type) {
    final adjustments = _currentAdjustments.value;
    switch (type) {
      case AdjustmentType.brightness:
        return adjustments.brightness;
      case AdjustmentType.contrast:
        return adjustments.contrast;
      case AdjustmentType.saturation:
        return adjustments.saturation;
      case AdjustmentType.exposure:
        return adjustments.exposure;
      case AdjustmentType.highlights:
        return adjustments.highlights;
      case AdjustmentType.shadows:
        return adjustments.shadows;
      case AdjustmentType.vibrance:
        return adjustments.vibrance;
      case AdjustmentType.clarity:
        return adjustments.clarity;
      case AdjustmentType.warmth:
        return adjustments.warmth;
      case AdjustmentType.tint:
        return adjustments.tint;
    }
  }

  /// Get available filters
  List<FilterType> getAvailableFilters() {
    return FilterType.values;
  }

  /// Get available adjustments
  List<Map<String, dynamic>> getAvailableAdjustments() {
    return [
      {
        'type': AdjustmentType.brightness,
        'label': 'Brightness',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.brightness_6,
      },
      {
        'type': AdjustmentType.contrast,
        'label': 'Contrast',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.contrast,
      },
      {
        'type': AdjustmentType.saturation,
        'label': 'Saturation',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.color_lens,
      },
      {
        'type': AdjustmentType.exposure,
        'label': 'Exposure',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.exposure,
      },
      {
        'type': AdjustmentType.vibrance,
        'label': 'Vibrance',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.vibration,
      },
      {
        'type': AdjustmentType.warmth,
        'label': 'Warmth',
        'min': -100.0,
        'max': 100.0,
        'icon': Icons.wb_sunny,
      },
    ];
  }

  /// Check if file is an image
  bool _isImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(extension);
  }

  // Filter implementations
  img.Image _applyVintageFilter(img.Image image) {
    img.Image processed =
        img.adjustColor(image, brightness: -10, contrast: 15, saturation: -20);
    processed = img.sepia(processed, amount: 0.3);
    return processed;
  }

  img.Image _applyVividFilter(img.Image image) {
    return img.adjustColor(image, contrast: 20, saturation: 30, brightness: 5);
  }

  img.Image _applyCoolFilter(img.Image image) {
    return img.adjustColor(image, contrast: 10, saturation: 10);
  }

  img.Image _applyWarmFilter(img.Image image) {
    return img.adjustColor(image, brightness: 10, contrast: 5, saturation: 15);
  }

  img.Image _applyDramaticFilter(img.Image image) {
    return img.adjustColor(image, contrast: 40, saturation: 20, brightness: -5);
  }

  img.Image _applySoftFilter(img.Image image) {
    img.Image processed = img.gaussianBlur(image, radius: 1);
    return img.adjustColor(processed,
        brightness: 15, contrast: -10, saturation: -10);
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats() {
    final totalEdits = _currentEdits.length;
    final imageEdits = _currentEdits.where((edit) => edit.isImage).length;
    final videoEdits = _currentEdits.where((edit) => !edit.isImage).length;

    return {
      'totalEdits': totalEdits,
      'imageEdits': imageEdits,
      'videoEdits': videoEdits,
      'isProcessing': _isProcessing.value,
      'processingProgress': _processingProgress.value,
      'hasAdjustments': _currentAdjustments.value.hasAdjustments,
      'selectedFilter': _selectedFilter.value.label,
    };
  }
}
