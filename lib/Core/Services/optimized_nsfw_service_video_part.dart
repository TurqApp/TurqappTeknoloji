part of 'optimized_nsfw_service.dart';

Future<NSFWCheckResult> _performCheckVideo(File videoFile) async {
  final stopwatch = Stopwatch()..start();

  try {
    await OptimizedNSFWService.initialize();
    if (OptimizedNSFWService._useNudeNetOnDevice &&
        OptimizedNSFWService._onnxSession == null) {
      return NSFWCheckResult.error('NudeNet modeli yüklenemedi');
    }
    if (!OptimizedNSFWService._useNudeNetOnDevice) {
      return NSFWCheckResult.error(
        'NudeNet upload gate bu platformda aktif degil',
      );
    }

    final filePath = videoFile.path;
    final fileStats = await videoFile.stat();
    final policy = OptimizedNSFWService._activeNsfwPolicy;
    final cacheKey =
        '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}:${policy.name}';

    if (OptimizedNSFWService._videoCache.containsKey(cacheKey)) {
      stopwatch.stop();
      return OptimizedNSFWService._videoCache[cacheKey]!.toResult(
        stopwatch.elapsed,
      );
    }

    final result = await _checkVideoFrames(videoFile);
    if (kDebugMode) {
      debugPrint('[NSFW][Video] '
          'blocked=${result.isNSFW} '
          'frames=${result.framesChecked} '
          'confidence=${result.confidence.toStringAsFixed(3)} '
          'error=${result.errorMessage}');
    }
    OptimizedNSFWService._videoCache[cacheKey] = _CachedModerationResult(
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

Future<NSFWCheckResult> _checkVideoFrames(File videoFile) async {
  final editor = VideoEditorBuilder(videoPath: videoFile.path);
  final metadata = await editor.getVideoMetadata();
  final durationMs = metadata.duration;
  final policy = OptimizedNSFWService._activeNsfwPolicy;

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

List<int> _calculateOptimalVideoSamplePoints(int durationMs) {
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

Future<List<NSFWCheckResult>> _performCheckImagesParallel(
  List<File> imageFiles, {
  Function(int current, int total)? onProgress,
}) async {
  final results = <NSFWCheckResult>[];

  for (var i = 0; i < imageFiles.length; i++) {
    onProgress?.call(i + 1, imageFiles.length);
    final result = await _performCheckImage(imageFiles[i]);
    results.add(result);
    if (result.isNSFW) {
      break;
    }
  }

  return results;
}

Future<dynamic> _runLegacyVideoDetector(File file) async {
  final detector = OptimizedNSFWService._legacyVideoDetector;
  if (detector == null) return null;
  try {
    return await detector.detectNSFWFromFile(file);
  } catch (_) {
    return null;
  }
}
