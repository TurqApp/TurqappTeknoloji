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
      final userService = CurrentUserService.maybeFind();
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

  static Future<NSFWCheckResult> checkImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      await initialize();

      final filePath = imageFile.path;
      final fileStats = await imageFile.stat();
      final policy = _activeNsfwPolicy;
      final cacheKey =
          '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}:${policy.name}';

      if (_imageCache.containsKey(cacheKey)) {
        stopwatch.stop();
        return _imageCache[cacheKey]!.toResult(stopwatch.elapsed);
      }

      bool isNSFW = false;
      double confidence = 0.0;

      if (_useNudeNetOnDevice) {
        if (_onnxSession == null) {
          return NSFWCheckResult.error('NudeNet modeli yüklenemedi');
        }
        final detections = await _runNudeNetOnImage(imageFile);
        final verdict = _buildVerdict(
          detections,
          blockedClasses: _blockedNudeNetClasses,
          minConfidence: switch (policy) {
            _NsfwPolicy.strict => 0.0,
            _NsfwPolicy.soft => 0.22,
            _NsfwPolicy.extraSoft => 0.42,
          },
        );
        isNSFW = verdict.isNSFW;
        confidence = verdict.confidence;
      } else {
        return NSFWCheckResult.error(
          'NudeNet upload gate bu platformda aktif degil',
        );
      }

      _imageCache[cacheKey] = _CachedModerationResult(
        isNSFW: isNSFW,
        confidence: confidence,
        framesChecked: 1,
      );

      stopwatch.stop();
      return NSFWCheckResult(
        isNSFW: isNSFW,
        confidence: confidence,
        framesChecked: 1,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return NSFWCheckResult.error('Image NSFW check failed: $e');
    }
  }

  static Future<NSFWCheckResult> checkVideo(File videoFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      await initialize();
      if (_useNudeNetOnDevice && _onnxSession == null) {
        return NSFWCheckResult.error('NudeNet modeli yüklenemedi');
      }
      if (!_useNudeNetOnDevice) {
        return NSFWCheckResult.error(
          'NudeNet upload gate bu platformda aktif degil',
        );
      }

      final filePath = videoFile.path;
      final fileStats = await videoFile.stat();
      final policy = _activeNsfwPolicy;
      final cacheKey =
          '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}:${policy.name}';

      if (_videoCache.containsKey(cacheKey)) {
        stopwatch.stop();
        return _videoCache[cacheKey]!.toResult(stopwatch.elapsed);
      }

      final result = await _checkVideoFrames(videoFile);
      if (kDebugMode) {
        debugPrint('[NSFW][Video] '
            'blocked=${result.isNSFW} '
            'frames=${result.framesChecked} '
            'confidence=${result.confidence.toStringAsFixed(3)} '
            'error=${result.errorMessage}');
      }
      _videoCache[cacheKey] = _CachedModerationResult(
        isNSFW: result.isNSFW,
        confidence: result.confidence,
        framesChecked: result.framesChecked,
        debugSamples: result.debugSamples,
      );

      stopwatch.stop();
      return NSFWCheckResult(
        isNSFW: result.isNSFW,
        confidence: result.confidence,
        framesChecked: result.framesChecked,
        processingTime: stopwatch.elapsed,
        debugSamples: result.debugSamples,
      );
    } catch (e) {
      stopwatch.stop();
      return NSFWCheckResult.error('Video NSFW check failed: $e');
    }
  }

  static Future<List<_NudeNetDetection>> _runNudeNetOnImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Image decode failed');
    }

    final prepared = _prepareNudeNetInput(decoded);
    final input = await OrtValue.fromList(
      prepared.tensor,
      <int>[1, 3, _nudeNetInputSize, _nudeNetInputSize],
    );

    try {
      final outputs = await _onnxSession!.run(<String, OrtValue>{
        _onnxSession!.inputNames.first: input,
      });
      final output = outputs[_onnxSession!.outputNames.first];
      if (output == null) {
        throw Exception('Model output missing');
      }

      final flattened = await output.asFlattenedList();
      return _postProcessNudeNet(
        flattened.cast<num>(),
        originalWidth: decoded.width,
        originalHeight: decoded.height,
        paddedSize: prepared.paddedSize,
      );
    } finally {
      await input.dispose();
    }
  }

  static _NudeNetPreparedInput _prepareNudeNetInput(img.Image source) {
    final normalized = img.bakeOrientation(source);
    final maxSize = math.max(normalized.width, normalized.height);
    final square = img.Image(width: maxSize, height: maxSize);
    img.fill(square, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(square, normalized, dstX: 0, dstY: 0);

    final resized = img.copyResize(
      square,
      width: _nudeNetInputSize,
      height: _nudeNetInputSize,
      interpolation: img.Interpolation.linear,
    );

    final planeSize = _nudeNetInputSize * _nudeNetInputSize;
    final tensor = Float32List(3 * planeSize);

    var pixelIndex = 0;
    for (var y = 0; y < _nudeNetInputSize; y++) {
      for (var x = 0; x < _nudeNetInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        tensor[pixelIndex] = pixel.r / 255.0;
        tensor[planeSize + pixelIndex] = pixel.g / 255.0;
        tensor[(2 * planeSize) + pixelIndex] = pixel.b / 255.0;
        pixelIndex++;
      }
    }

    return _NudeNetPreparedInput(
      tensor: tensor,
      paddedSize: maxSize,
    );
  }

  static List<_NudeNetDetection> _postProcessNudeNet(
    List<num> rawOutput, {
    required int originalWidth,
    required int originalHeight,
    required int paddedSize,
  }) {
    if (rawOutput.isEmpty) return const <_NudeNetDetection>[];

    const channels = 22;
    final candidates = rawOutput.length ~/ channels;
    if (candidates <= 0) return const <_NudeNetDetection>[];

    final detections = <_NudeNetDetection>[];
    final scale = paddedSize / _nudeNetInputSize;

    for (var i = 0; i < candidates; i++) {
      double maxScore = 0.0;
      var classId = -1;
      for (var c = 4; c < channels; c++) {
        final score = rawOutput[(c * candidates) + i].toDouble();
        if (score > maxScore) {
          maxScore = score;
          classId = c - 4;
        }
      }

      if (classId < 0 || maxScore < _nudeNetScoreThreshold) continue;

      final cx = rawOutput[i].toDouble();
      final cy = rawOutput[candidates + i].toDouble();
      final w = rawOutput[(2 * candidates) + i].toDouble();
      final h = rawOutput[(3 * candidates) + i].toDouble();

      var x = (cx - (w / 2)) * scale;
      var y = (cy - (h / 2)) * scale;
      var width = w * scale;
      var height = h * scale;

      x = x.clamp(0.0, originalWidth.toDouble());
      y = y.clamp(0.0, originalHeight.toDouble());
      width = math.min(width, originalWidth - x);
      height = math.min(height, originalHeight - y);

      detections.add(
        _NudeNetDetection(
          label: _nudeNetLabels[classId],
          score: maxScore,
          x: x,
          y: y,
          width: width,
          height: height,
        ),
      );
    }

    if (detections.isEmpty) return const <_NudeNetDetection>[];
    detections.sort((a, b) => b.score.compareTo(a.score));

    final selected = <_NudeNetDetection>[];
    for (final detection in detections) {
      var keep = true;
      for (final existing in selected) {
        if (_iou(detection, existing) > _nudeNetNmsThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(detection);
      }
    }
    return selected;
  }

  static double _iou(_NudeNetDetection a, _NudeNetDetection b) {
    final left = math.max(a.x, b.x);
    final top = math.max(a.y, b.y);
    final right = math.min(a.x + a.width, b.x + b.width);
    final bottom = math.min(a.y + a.height, b.y + b.height);

    final intersectionWidth = math.max(0.0, right - left);
    final intersectionHeight = math.max(0.0, bottom - top);
    final intersection = intersectionWidth * intersectionHeight;
    if (intersection <= 0) return 0.0;

    final union = a.area + b.area - intersection;
    if (union <= 0) return 0.0;
    return intersection / union;
  }

  static Future<NSFWCheckResult> _checkVideoFrames(File videoFile) async {
    final editor = VideoEditorBuilder(videoPath: videoFile.path);
    final metadata = await editor.getVideoMetadata();
    final durationMs = metadata.duration;
    final policy = _activeNsfwPolicy;

    if (durationMs <= 0) {
      return NSFWCheckResult.error('Invalid video duration');
    }

    final tempDir = await getTemporaryDirectory();
    final samplePoints = _calculateOptimalVideoSamplePoints(durationMs);

    var framesChecked = 0;
    var maxConfidence = 0.0;
    var foundNSFW = false;
    var blockedFrames = 0;
    final debugSamples = <String>[];

    try {
      for (final positionMs in samplePoints) {
        final thumbPath = p.join(tempDir.path, 'nsfw_check_$positionMs.jpg');
        await editor.generateThumbnail(
          positionMs: positionMs,
          quality: 95,
          outputPath: thumbPath,
        );

        final thumbFile = File(thumbPath);
        if (!await thumbFile.exists()) continue;

        final detections = await _runNudeNetOnImage(thumbFile);
        final result = _buildVerdict(
          detections,
          blockedClasses: _blockedNudeNetVideoClasses,
          framesChecked: 1,
          minConfidence: switch (policy) {
            _NsfwPolicy.strict => 0.0,
            _NsfwPolicy.soft => 0.26,
            _NsfwPolicy.extraSoft => 0.46,
          },
        );
        final legacyResult = await _runLegacyVideoDetector(thumbFile);
        final legacyBlocked = legacyResult?.isNsfw == true;
        final legacyScore = (legacyResult?.score ?? 0.0).toDouble();
        framesChecked++;
        maxConfidence = math.max(
          maxConfidence,
          math.max(result.confidence, legacyScore),
        );
        if (kDebugMode) {
          debugSamples.add(
            'ms=$positionMs nudeNet=${result.isNSFW}:${result.confidence.toStringAsFixed(3)} legacy=$legacyBlocked:${legacyScore.toStringAsFixed(3)} err=${result.errorMessage ?? "-"}',
          );
        }

        try {
          await thumbFile.delete();
        } catch (_) {}

        final legacyBlockThreshold = switch (policy) {
          _NsfwPolicy.strict => 0.24,
          _NsfwPolicy.soft => 0.32,
          _NsfwPolicy.extraSoft => 0.52,
        };
        if (legacyBlocked && legacyScore >= legacyBlockThreshold) {
          foundNSFW = true;
          break;
        }

        final frameBlockThreshold = switch (policy) {
          _NsfwPolicy.strict => 0.20,
          _NsfwPolicy.soft => 0.28,
          _NsfwPolicy.extraSoft => 0.46,
        };
        final hardBlockThreshold = switch (policy) {
          _NsfwPolicy.strict => 0.31,
          _NsfwPolicy.soft => 0.40,
          _NsfwPolicy.extraSoft => 0.60,
        };
        final blockedFrameQuota = switch (policy) {
          _NsfwPolicy.strict => 2,
          _NsfwPolicy.soft => 3,
          _NsfwPolicy.extraSoft => 4,
        };

        if (result.isNSFW && result.confidence >= frameBlockThreshold) {
          blockedFrames++;
          if (result.confidence >= hardBlockThreshold ||
              blockedFrames >= blockedFrameQuota) {
            foundNSFW = true;
            break;
          }
        }
      }

      return NSFWCheckResult(
        isNSFW: foundNSFW,
        confidence: maxConfidence,
        framesChecked: framesChecked,
        processingTime: Duration.zero,
        debugSamples: debugSamples,
      );
    } catch (e) {
      return NSFWCheckResult.error('Frame analysis failed: $e');
    }
  }

  static List<int> _calculateOptimalVideoSamplePoints(int durationMs) {
    final points = <int>{};

    if (durationMs <= 3000) {
      points.addAll(<int>[0, durationMs ~/ 2]);
    } else if (durationMs <= 10000) {
      points.addAll(<int>[0, durationMs ~/ 2, math.max(0, durationMs - 1000)]);
    } else if (durationMs <= 30000) {
      final interval = durationMs ~/ 5;
      for (var i = 0; i < 5; i++) {
        points.add(i * interval);
      }
      points.add(math.max(0, durationMs - 1000));
    } else {
      final interval = durationMs ~/ 8;
      for (var i = 0; i < 8; i++) {
        points.add(i * interval);
      }
      points.add(math.max(0, durationMs - 1000));
    }

    final sorted = points
        .where((p) => p >= 0 && p < durationMs)
        .toList(growable: false)
      ..sort();
    return sorted;
  }

  static Future<List<NSFWCheckResult>> checkImagesParallel(
    List<File> imageFiles, {
    Function(int current, int total)? onProgress,
  }) async {
    final results = <NSFWCheckResult>[];

    for (var i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);
      final result = await checkImage(imageFiles[i]);
      results.add(result);
      if (result.isNSFW) {
        break;
      }
    }

    return results;
  }

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

  static Future<bool> checkInBackground(String imagePath) async {
    final result = await checkImage(File(imagePath));
    return result.isNSFW;
  }

  static Future<dynamic> _runLegacyVideoDetector(File file) async {
    final detector = _legacyVideoDetector;
    if (detector == null) return null;
    try {
      return await detector.detectNSFWFromFile(file);
    } catch (_) {
      return null;
    }
  }
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
      .where((d) =>
          blockedClasses.contains(d.label) && d.score >= minConfidence)
      .toList(growable: false);
  final confidence = blocked.isEmpty
      ? 0.0
      : blocked.map((d) => d.score).reduce(math.max);
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
