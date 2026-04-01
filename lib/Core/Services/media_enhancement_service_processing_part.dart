part of 'media_enhancement_service.dart';

extension MediaEnhancementServiceProcessingPart on MediaEnhancementService {
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
    } catch (_) {
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

  Future<Uint8List?> applyAdjustments(
    File imageFile,
    MediaAdjustments adjustments,
  ) async {
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

      if (adjustments.brightness != 0.0) {
        processedImage =
            img.adjustColor(processedImage, brightness: adjustments.brightness);
        _processingProgress.value = 0.3;
      }

      if (adjustments.contrast != 0.0) {
        processedImage = img.adjustColor(
          processedImage,
          contrast: 1.0 + (adjustments.contrast / 100),
        );
        _processingProgress.value = 0.4;
      }

      if (adjustments.saturation != 0.0) {
        processedImage =
            img.adjustColor(processedImage, saturation: adjustments.saturation);
        _processingProgress.value = 0.5;
      }

      if (adjustments.exposure != 0.0) {
        processedImage = img.adjustColor(
          processedImage,
          brightness: adjustments.exposure * 0.5,
        );
        _processingProgress.value = 0.6;
      }

      if (adjustments.vibrance != 0.0) {
        processedImage = img.adjustColor(
          processedImage,
          saturation: adjustments.vibrance * 1.2,
        );
        _processingProgress.value = 0.7;
      }

      _processingProgress.value = 0.9;

      final processedBytes =
          Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));

      _processingProgress.value = 1.0;
      return processedBytes;
    } catch (_) {
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

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

      if (adjustments.hasAdjustments) {
        if (adjustments.brightness != 0.0) {
          processedImage = img.adjustColor(
            processedImage,
            brightness: adjustments.brightness,
          );
        }
        if (adjustments.contrast != 0.0) {
          processedImage = img.adjustColor(
            processedImage,
            contrast: 1.0 + (adjustments.contrast / 100),
          );
        }
        if (adjustments.saturation != 0.0) {
          processedImage = img.adjustColor(
            processedImage,
            saturation: adjustments.saturation,
          );
        }
        _processingProgress.value = 0.8;
      }

      final processedBytes =
          Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));

      _processingProgress.value = 1.0;
      return processedBytes;
    } catch (_) {
      return null;
    } finally {
      _isProcessing.value = false;
      _processingProgress.value = 0.0;
    }
  }

  bool _isImageFile(File file) {
    final extension = normalizeLowercase(file.path.split('.').last);
    return ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(extension);
  }

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
    return img.adjustColor(
      processed,
      brightness: 15,
      contrast: -10,
      saturation: -10,
    );
  }
}
