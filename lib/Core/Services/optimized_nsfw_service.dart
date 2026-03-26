import 'dart:io';
import 'dart:math' as math;

import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'optimized_nsfw_service_image_part.dart';
part 'optimized_nsfw_service_video_part.dart';

class NSFWCheckResult {
  final bool isNSFW;
  final double confidence;
  final int framesChecked;
  final Duration processingTime;
  final String? errorMessage;
  final List<String> debugSamples;

  NSFWCheckResult({
    required this.isNSFW,
    required this.confidence,
    required this.framesChecked,
    required this.processingTime,
    this.errorMessage,
    this.debugSamples = const <String>[],
  });

  factory NSFWCheckResult.error(String message) {
    return NSFWCheckResult(
      isNSFW: true,
      confidence: 0.0,
      framesChecked: 0,
      processingTime: Duration.zero,
      errorMessage: message,
      debugSamples: const <String>[],
    );
  }
}

enum _NsfwPolicy { strict, soft, extraSoft }

class OptimizedNSFWService {
  static const String _nudeNetAssetPath = 'assets/models/nudenet/320n.onnx';
  static const int _nudeNetInputSize = 320;
  static const double _nudeNetScoreThreshold = 0.12;
  static const double _nudeNetNmsThreshold = 0.45;

  static const List<String> _nudeNetLabels = <String>[
    'FEMALE_GENITALIA_COVERED',
    'FACE_FEMALE',
    'BUTTOCKS_EXPOSED',
    'FEMALE_BREAST_EXPOSED',
    'FEMALE_GENITALIA_EXPOSED',
    'MALE_BREAST_EXPOSED',
    'ANUS_EXPOSED',
    'FEET_EXPOSED',
    'BELLY_COVERED',
    'FEET_COVERED',
    'ARMPITS_COVERED',
    'ARMPITS_EXPOSED',
    'FACE_MALE',
    'BELLY_EXPOSED',
    'MALE_GENITALIA_EXPOSED',
    'ANUS_COVERED',
    'FEMALE_BREAST_COVERED',
    'BUTTOCKS_COVERED',
  ];

  static const Set<String> _blockedNudeNetClasses = <String>{
    'FEMALE_GENITALIA_COVERED',
    'BUTTOCKS_EXPOSED',
    'FEMALE_BREAST_EXPOSED',
    'FEMALE_GENITALIA_EXPOSED',
    'MALE_BREAST_EXPOSED',
    'ANUS_EXPOSED',
    'BELLY_COVERED',
    'BELLY_EXPOSED',
    'MALE_GENITALIA_EXPOSED',
    'ANUS_COVERED',
    'FEMALE_BREAST_COVERED',
    'BUTTOCKS_COVERED',
  };

  static final Map<String, _CachedModerationResult> _imageCache =
      <String, _CachedModerationResult>{};
  static final Map<String, _CachedModerationResult> _videoCache =
      <String, _CachedModerationResult>{};
  static final OnnxRuntime _onnxRuntime = OnnxRuntime();

  static OrtSession? _onnxSession;
  static NsfwDetector? _legacyVideoDetector;
  static bool _isInitialized = false;

  static bool get _useNudeNetOnDevice =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static _NsfwPolicy get _activeNsfwPolicy {
    try {
      final userService = maybeFindCurrentUserService();
      if (userService == null) return _NsfwPolicy.strict;
      final normalizedRozet = normalizeRozetValue(userService.rozet);
      switch (normalizedRozet) {
        case 'gri':
        case 'turkuaz':
        case 'sari':
          return _NsfwPolicy.extraSoft;
        case 'mavi':
        case 'siyah':
        case 'kirmizi':
          return _NsfwPolicy.soft;
        default:
          return userService.isVerified ? _NsfwPolicy.soft : _NsfwPolicy.strict;
      }
    } catch (_) {
      return _NsfwPolicy.strict;
    }
  }

  static Future<void> initialize({double threshold = 0.3}) async {
    if (_isInitialized) return;

    try {
      if (_useNudeNetOnDevice) {
        _onnxSession ??= await _onnxRuntime.createSessionFromAsset(
          _nudeNetAssetPath,
        );
        _legacyVideoDetector ??= await NsfwDetector.load(threshold: 0.24);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('NSFW detector initialization failed: $e');
    }
  }

  static Future<NSFWCheckResult> checkImage(File imageFile) =>
      _performCheckImage(imageFile);

  static Future<NSFWCheckResult> checkVideo(File videoFile) =>
      _performCheckVideo(videoFile);

  static Future<List<NSFWCheckResult>> checkImagesParallel(
    List<File> imageFiles, {
    Function(int current, int total)? onProgress,
  }) =>
      _performCheckImagesParallel(
        imageFiles,
        onProgress: onProgress,
      );

  static void clearCache() {
    _imageCache.clear();
    _videoCache.clear();
  }

  static Map<String, dynamic> getCacheStats() {
    return <String, dynamic>{
      'cacheSize': _imageCache.length + _videoCache.length,
      'imageCacheSize': _imageCache.length,
      'videoCacheSize': _videoCache.length,
      'isInitialized': _isInitialized,
      'usingNudeNet': _useNudeNetOnDevice,
      'memoryUsage': (_imageCache.length + _videoCache.length) * 64,
    };
  }

  static Future<bool> checkInBackground(String imagePath) =>
      _performCheckInBackground(imagePath);
}

const Set<String> _blockedNudeNetVideoClasses = <String>{
  'BUTTOCKS_EXPOSED',
  'FEMALE_BREAST_EXPOSED',
  'FEMALE_GENITALIA_EXPOSED',
  'ANUS_EXPOSED',
  'MALE_GENITALIA_EXPOSED',
};

NSFWCheckResult _buildVerdict(
  List<_NudeNetDetection> detections, {
  required Set<String> blockedClasses,
  int framesChecked = 1,
  double minConfidence = 0.0,
}) {
  final blocked = detections
      .where(
          (d) => blockedClasses.contains(d.label) && d.score >= minConfidence)
      .toList(growable: false);
  final confidence =
      blocked.isEmpty ? 0.0 : blocked.map((d) => d.score).reduce(math.max);
  return NSFWCheckResult(
    isNSFW: blocked.isNotEmpty,
    confidence: confidence,
    framesChecked: framesChecked,
    processingTime: Duration.zero,
  );
}

class _CachedModerationResult {
  final bool isNSFW;
  final double confidence;
  final int framesChecked;
  final List<String> debugSamples;

  const _CachedModerationResult({
    required this.isNSFW,
    required this.confidence,
    required this.framesChecked,
    this.debugSamples = const <String>[],
  });

  NSFWCheckResult toResult(Duration processingTime) {
    return NSFWCheckResult(
      isNSFW: isNSFW,
      confidence: confidence,
      framesChecked: framesChecked,
      processingTime: processingTime,
      debugSamples: debugSamples,
    );
  }
}

class _NudeNetPreparedInput {
  final Float32List tensor;
  final int paddedSize;

  const _NudeNetPreparedInput({
    required this.tensor,
    required this.paddedSize,
  });
}

class _NudeNetDetection {
  final String label;
  final double score;
  final double x;
  final double y;
  final double width;
  final double height;

  const _NudeNetDetection({
    required this.label,
    required this.score,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get area => width * height;
}
