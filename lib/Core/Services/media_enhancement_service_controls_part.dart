part of 'media_enhancement_service.dart';

extension MediaEnhancementServiceControlsPart on MediaEnhancementService {
  void setFilter(FilterType filter) {
    _selectedFilter.value = filter;
  }

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

  void resetAdjustments() {
    _currentAdjustments.value = MediaAdjustments();
  }

  void resetAdjustment(AdjustmentType type) {
    updateAdjustment(type, 0.0);
  }

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

  List<FilterType> getAvailableFilters() {
    return FilterType.values;
  }

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
