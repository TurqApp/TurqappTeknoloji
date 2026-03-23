import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'network_awareness_service.dart';
import '../upload_constants.dart';

part 'video_compression_service_flow_part.dart';
part 'video_compression_service_support_part.dart';

class VideoCompressionService extends GetxController {
  /// Compresses the given [videoFile] based on network conditions and size limits.
  /// Returns the compressed file if successful; otherwise returns the original file.
  static Future<File> compressForNetwork(File videoFile,
          {double targetMbps = 5.0}) =>
      _performCompressForNetwork(
        videoFile,
        targetMbps: targetMbps,
      );
}
