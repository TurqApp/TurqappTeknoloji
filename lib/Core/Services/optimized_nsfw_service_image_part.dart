part of 'optimized_nsfw_service.dart';

Future<NSFWCheckResult> _performCheckImage(File imageFile) async {
  final stopwatch = Stopwatch()..start();

  try {
    await OptimizedNSFWService.initialize();

    final filePath = imageFile.path;
    final fileStats = await imageFile.stat();
    final policy = OptimizedNSFWService._activeNsfwPolicy;
    final cacheKey =
        '$filePath:${fileStats.size}:${fileStats.modified.millisecondsSinceEpoch}:${policy.name}';

    if (OptimizedNSFWService._imageCache.containsKey(cacheKey)) {
      stopwatch.stop();
      return OptimizedNSFWService._imageCache[cacheKey]!.toResult(
        stopwatch.elapsed,
      );
    }

    bool isNSFW = false;
    double confidence = 0.0;

    if (OptimizedNSFWService._useNudeNetOnDevice) {
      if (OptimizedNSFWService._onnxSession == null) {
        return NSFWCheckResult.error('NudeNet modeli yüklenemedi');
      }
      final detections = await _runNudeNetOnImage(imageFile);
      final verdict = _buildVerdict(
        detections,
        blockedClasses: OptimizedNSFWService._blockedNudeNetClasses,
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

    OptimizedNSFWService._imageCache[cacheKey] = _CachedModerationResult(
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

Future<List<_NudeNetDetection>> _runNudeNetOnImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Image decode failed');
  }

  final prepared = _prepareNudeNetInput(decoded);
  final input = await OrtValue.fromList(
    prepared.tensor,
    <int>[
      1,
      3,
      OptimizedNSFWService._nudeNetInputSize,
      OptimizedNSFWService._nudeNetInputSize,
    ],
  );

  try {
    final session = OptimizedNSFWService._onnxSession!;
    final outputs = await session.run(<String, OrtValue>{
      session.inputNames.first: input,
    });
    final output = outputs[session.outputNames.first];
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

_NudeNetPreparedInput _prepareNudeNetInput(img.Image source) {
  final normalized = img.bakeOrientation(source);
  final maxSize = math.max(normalized.width, normalized.height);
  final square = img.Image(width: maxSize, height: maxSize);
  img.fill(square, color: img.ColorRgb8(0, 0, 0));
  img.compositeImage(square, normalized, dstX: 0, dstY: 0);

  final resized = img.copyResize(
    square,
    width: OptimizedNSFWService._nudeNetInputSize,
    height: OptimizedNSFWService._nudeNetInputSize,
    interpolation: img.Interpolation.linear,
  );

  final planeSize = OptimizedNSFWService._nudeNetInputSize *
      OptimizedNSFWService._nudeNetInputSize;
  final tensor = Float32List(3 * planeSize);

  var pixelIndex = 0;
  for (var y = 0; y < OptimizedNSFWService._nudeNetInputSize; y++) {
    for (var x = 0; x < OptimizedNSFWService._nudeNetInputSize; x++) {
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

List<_NudeNetDetection> _postProcessNudeNet(
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
  final scale = paddedSize / OptimizedNSFWService._nudeNetInputSize;

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

    if (classId < 0 || maxScore < OptimizedNSFWService._nudeNetScoreThreshold) {
      continue;
    }

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
        label: OptimizedNSFWService._nudeNetLabels[classId],
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
      if (_iou(detection, existing) >
          OptimizedNSFWService._nudeNetNmsThreshold) {
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

double _iou(_NudeNetDetection a, _NudeNetDetection b) {
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

Future<bool> _performCheckInBackground(String imagePath) async {
  final result = await _performCheckImage(File(imagePath));
  return result.isNSFW;
}
