import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'media_enhancement_service_processing_part.dart';
part 'media_enhancement_service_controls_part.dart';
part 'media_enhancement_service_models_part.dart';

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
