part of 'video_compression_service.dart';

Future<File> _performCompressForNetwork(
  File videoFile, {
  required double targetMbps,
}) async {
  try {
    if (targetMbps < 4.0) targetMbps = 5.0;

    final originalBytes = await videoFile.length();
    if (originalBytes <= UploadConstants.maxPassthroughVideoBytes) {
      _logPassthrough(originalBytes);
      return videoFile;
    }

    final network = NetworkAwarenessService.maybeFind();
    var quality = VideoQuality.DefaultQuality;
    if (network != null && network.isOnCellular) {
      quality = VideoQuality.DefaultQuality;
    } else if (network != null && network.isOnWiFi) {
      quality = VideoQuality.DefaultQuality;
    }

    final maxBytes = UploadConstants.maxPassthroughVideoBytes;
    _logStart(
      videoFile,
      originalBytes: originalBytes,
      targetMbps: targetMbps,
    );

    var pass = await _runCompressionPass(videoFile, quality);
    _logStep('First pass', quality, pass);

    final lowerBound = targetMbps * 0.5;
    final upperBound = targetMbps * 2.0;
    final ladder = <VideoQuality>[
      VideoQuality.Res1280x720Quality,
      VideoQuality.MediumQuality,
    ];

    if (network != null && network.isOnCellular) {
      for (final q in ladder) {
        if (pass.fileBytes <= maxBytes) break;
        pass = await _runCompressionPass(videoFile, q);
        _logStep('Step (cellular)', q, pass);
      }
    } else if (pass.fileBytes > maxBytes) {
      for (final q in ladder) {
        if (pass.fileBytes <= maxBytes) break;
        pass = await _runCompressionPass(videoFile, q);
        _logStep('Step (wifi)', q, pass);
      }
    }

    _logFinal(
      output: pass.output,
      fileBytes: pass.fileBytes,
      durationMs: pass.durationMs,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );

    if (pass.fileBytes >= originalBytes) {
      _logRevertedToOriginal();
      return videoFile;
    }

    return pass.output;
  } catch (_) {
    return videoFile;
  }
}
