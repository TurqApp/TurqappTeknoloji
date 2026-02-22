import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class NSFWCheckResult {
  final bool isNSFW;
  final double confidence;
  final int framesChecked;
  final Duration processingTime;
  final String? errorMessage;

  NSFWCheckResult({
    required this.isNSFW,
    required this.confidence,
    required this.framesChecked,
    required this.processingTime,
    this.errorMessage,
  });

  factory NSFWCheckResult.error(String message) {
    return NSFWCheckResult(
      isNSFW: false,
      confidence: 0.0,
      framesChecked: 0,
      processingTime: Duration.zero,
      errorMessage: message,
    );
  }
}

class OptimizedNSFWService {
  static final Map<String, bool> _cache = {};
  static NsfwDetector? _detector;
  static bool _isInitialized = false;

  static Future<void> initialize({double threshold = 0.3}) async {
    if (_isInitialized) return;

    try {
      _detector = await NsfwDetector.load(threshold: threshold);
      _isInitialized = true;
    } catch (e) {
      print('NSFW Detector initialization failed: $e');
    }
  }

  static Future<NSFWCheckResult> checkImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      await initialize();
      if (_detector == null) {
        return NSFWCheckResult.error('NSFW Detector not initialized');
      }

      final filePath = imageFile.path;
      final fileStats = await imageFile.stat();
      final cacheKey =
          '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}';

      if (_cache.containsKey(cacheKey)) {
        stopwatch.stop();
        return NSFWCheckResult(
          isNSFW: _cache[cacheKey]!,
          confidence: 1.0,
          framesChecked: 1,
          processingTime: stopwatch.elapsed,
        );
      }

      // Perform NSFW check
      final result = await _detector!.detectNSFWFromFile(imageFile);
      final isNSFW = result?.isNsfw == true;

      // Cache the result
      _cache[cacheKey] = isNSFW;

      stopwatch.stop();
      return NSFWCheckResult(
        isNSFW: isNSFW,
        confidence: result?.score ?? 0.0,
        framesChecked: 1,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return NSFWCheckResult.error('Image NSFW check failed: $e');
    }
  }

  /// Optimized video NSFW check with smart sampling
  static Future<NSFWCheckResult> checkVideo(File videoFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      await initialize();
      if (_detector == null) {
        return NSFWCheckResult.error('NSFW Detector not initialized');
      }

      // Check cache first
      final filePath = videoFile.path;
      final fileStats = await videoFile.stat();
      final cacheKey =
          '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}';

      if (_cache.containsKey(cacheKey)) {
        stopwatch.stop();
        return NSFWCheckResult(
          isNSFW: _cache[cacheKey]!,
          confidence: 1.0,
          framesChecked: 0,
          processingTime: stopwatch.elapsed,
        );
      }

      final result = await _checkVideoFrames(videoFile);

      // Cache the result
      _cache[cacheKey] = result.isNSFW;

      stopwatch.stop();
      return NSFWCheckResult(
        isNSFW: result.isNSFW,
        confidence: result.confidence,
        framesChecked: result.framesChecked,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return NSFWCheckResult.error('Video NSFW check failed: $e');
    }
  }

  /// Smart video frame sampling - only check key moments
  static Future<NSFWCheckResult> _checkVideoFrames(File videoFile) async {
    final editor = VideoEditorBuilder(videoPath: videoFile.path);
    final metadata = await editor.getVideoMetadata();
    final durationMs = metadata.duration;

    if (durationMs <= 0) {
      return NSFWCheckResult.error('Invalid video duration');
    }

    final tempDir = await getTemporaryDirectory();
    final List<int> samplePoints = _calculateOptimalSamplePoints(durationMs);

    int framesChecked = 0;
    double maxConfidence = 0.0;
    bool foundNSFW = false;

    try {
      for (final positionMs in samplePoints) {
        final thumbPath = p.join(tempDir.path, 'nsfw_check_$positionMs.jpg');

        await editor.generateThumbnail(
          positionMs: positionMs,
          quality: 70, // Lower quality for faster processing
          outputPath: thumbPath,
        );

        final thumbFile = File(thumbPath);
        if (await thumbFile.exists()) {
          final result = await _detector!.detectNSFWFromFile(thumbFile);
          framesChecked++;

          if (result?.isNsfw == true) {
            foundNSFW = true;
            maxConfidence = math.max(maxConfidence, result?.score ?? 0.0);

            // Early exit on first NSFW detection
            await thumbFile.delete();
            break;
          }

          maxConfidence = math.max(maxConfidence, result?.score ?? 0.0);
          await thumbFile.delete();
        }
      }

      return NSFWCheckResult(
        isNSFW: foundNSFW,
        confidence: maxConfidence,
        framesChecked: framesChecked,
        processingTime: Duration.zero, // Will be set by caller
      );
    } catch (e) {
      return NSFWCheckResult.error('Frame analysis failed: $e');
    }
  }

  /// Calculate optimal sample points for video analysis
  static List<int> _calculateOptimalSamplePoints(int durationMs) {
    final points = <int>[];

    if (durationMs <= 3000) {
      // Very short videos: check start and middle
      points.addAll([0, durationMs ~/ 2]);
    } else if (durationMs <= 10000) {
      // Short videos: check 3 points
      points.addAll([
        0,
        durationMs ~/ 2,
        durationMs - 1000,
      ]);
    } else if (durationMs <= 30000) {
      // Medium videos: check 5 points
      final interval = durationMs ~/ 5;
      for (int i = 0; i < 5; i++) {
        points.add(i * interval);
      }
    } else {
      // Long videos: check 7 strategic points
      points.addAll([
        0, // Start
        2000, // 2 seconds in
        durationMs ~/ 4, // 25%
        durationMs ~/ 2, // 50%
        (durationMs * 3) ~/ 4, // 75%
        durationMs - 3000, // 3 seconds from end
        durationMs - 1000, // 1 second from end
      ]);
    }

    // Ensure all points are within bounds
    return points.where((p) => p >= 0 && p < durationMs).toList();
  }

  /// Check multiple images in parallel with progress callback
  static Future<List<NSFWCheckResult>> checkImagesParallel(
    List<File> imageFiles, {
    Function(int current, int total)? onProgress,
  }) async {
    final results = <NSFWCheckResult>[];

    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);

      final result = await checkImage(imageFiles[i]);
      results.add(result);

      // Early exit if NSFW found
      if (result.isNSFW) {
        break;
      }
    }

    return results;
  }

  /// Clean up cache (call periodically to prevent memory issues)
  static void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'isInitialized': _isInitialized,
      'memoryUsage': _cache.length * 64, // Rough estimate in bytes
    };
  }

  /// Background isolate for heavy NSFW checking (future enhancement)
  static Future<bool> checkInBackground(String imagePath) async {
    // This would run NSFW detection in a separate isolate
    // to prevent blocking the main UI thread
    return await compute(_isolateNSFWCheck, imagePath);
  }

  static Future<bool> _isolateNSFWCheck(String imagePath) async {
    try {
      final detector = await NsfwDetector.load(threshold: 0.5);
      final result = await detector.detectNSFWFromFile(File(imagePath));
      return result?.isNsfw == true;
    } catch (e) {
      return false;
    }
  }
}
