part of 'video_compression_service.dart';

class _VideoCompressionPass {
  const _VideoCompressionPass({
    required this.output,
    required this.durationMs,
    required this.fileBytes,
    required this.mbps,
  });

  final File output;
  final int durationMs;
  final int fileBytes;
  final double mbps;
}

Future<_VideoCompressionPass> _runCompressionPass(
  File videoFile,
  VideoQuality quality,
) async {
  final info = await VideoCompress.compressVideo(
    videoFile.path,
    quality: quality,
    includeAudio: true,
    deleteOrigin: false,
  );

  final output = File(info?.path ?? videoFile.path);
  final durationMs = info?.duration?.toInt() ?? 0;
  final fileBytes = await output.length();
  final mbps = _computeMbps(
    fileBytes: fileBytes,
    durationMs: durationMs,
  );
  return _VideoCompressionPass(
    output: output,
    durationMs: durationMs,
    fileBytes: fileBytes,
    mbps: mbps,
  );
}

double _computeMbps({
  required int fileBytes,
  required int durationMs,
}) {
  if (durationMs <= 0) return 0;
  return (fileBytes * 8) / (durationMs / 1000) / 1e6;
}

void _logPassthrough(int originalBytes) {
  if (!kDebugMode) return;
  debugPrint(
    '[VideoCompression] Passthrough: '
    'size=${(originalBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
  );
}

void _logStart(
  File videoFile, {
  required int originalBytes,
  required double targetMbps,
}) {
  if (!kDebugMode) return;
  debugPrint(
    '[VideoCompression] Start: file=${videoFile.path.split('/').last} '
    'size=${(originalBytes / (1024 * 1024)).toStringAsFixed(2)} MB '
    'targetMbps=$targetMbps',
  );
}

void _logStep(
  String label,
  VideoQuality quality,
  _VideoCompressionPass pass,
) {
  if (!kDebugMode) return;
  debugPrint(
    '[VideoCompression] $label: quality=$quality '
    'size=${(pass.fileBytes / 1e6).toStringAsFixed(2)} MB '
    'duration=${(pass.durationMs / 1000).toStringAsFixed(2)} s '
    'bitrate=${pass.mbps.toStringAsFixed(2)} Mbps',
  );
}

void _logFinal({
  required File output,
  required int fileBytes,
  required int durationMs,
  required double lowerBound,
  required double upperBound,
}) {
  if (!kDebugMode) return;
  final finalMbps = _computeMbps(
    fileBytes: fileBytes,
    durationMs: durationMs,
  );
  debugPrint(
    '[VideoCompression] Final: '
    'size=${(fileBytes / 1e6).toStringAsFixed(2)} MB '
    'bitrate=${finalMbps.toStringAsFixed(2)} Mbps '
    'targetRange=${lowerBound.toStringAsFixed(2)}-${upperBound.toStringAsFixed(2)} '
    'path=${output.path.split('/').last}',
  );
}

void _logRevertedToOriginal() {
  if (!kDebugMode) return;
  debugPrint(
    '[VideoCompression] Reverted to original: compressed did not reduce size',
  );
}
