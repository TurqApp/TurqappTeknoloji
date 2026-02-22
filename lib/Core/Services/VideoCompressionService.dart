import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'NetworkAwarenessService.dart';
import '../UploadConstants.dart';

class VideoCompressionService extends GetxController {
  /// Compresses the given [videoFile] based on network conditions and size limits.
  /// Returns the compressed file if successful; otherwise returns the original file.
  static Future<File> compressForNetwork(File videoFile, {double targetMbps = 5.0}) async {
    try {
      // Guard legacy low values persisted in old settings.
      if (targetMbps < 4.0) targetMbps = 5.0;

      final network = Get.isRegistered<NetworkAwarenessService>()
          ? Get.find<NetworkAwarenessService>()
          : null;

      // Choose initial quality based on network
      var quality = VideoQuality.DefaultQuality;
      if (network != null && network.isOnCellular) {
        quality = VideoQuality.DefaultQuality; // keep details on modern devices
      } else if (network != null && network.isOnWiFi) {
        quality = VideoQuality.DefaultQuality; // keep good quality on wifi
      }

      // Effective ceiling should match post-size policy, not the broad raw video cap.
      final maxBytes = UploadConstants.maxTotalPostSizeBytes;

      // First try with chosen quality
      if (kDebugMode) {
        final size = await videoFile.length();
        debugPrint('[VideoCompression] Start: file=${videoFile.path.split('/').last} '
            'size=${(size / (1024*1024)).toStringAsFixed(2)} MB '
            'targetMbps=$targetMbps');
      }

      MediaInfo? info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        includeAudio: true,
        deleteOrigin: false,
      );

      File output = File(info?.path ?? videoFile.path);

      // Evaluate by size and approximate bitrate (if duration known)
      int durationMs = info?.duration?.toInt() ?? 0;
      int fileBytes = await output.length();
      double mbps = 0;
      if (durationMs > 0) {
        mbps = (fileBytes * 8) / (durationMs / 1000) / 1e6; // Mbps
      }
      if (kDebugMode) {
        debugPrint('[VideoCompression] First pass: quality=$quality '
            'size=${(fileBytes/1e6).toStringAsFixed(2)} MB '
            'duration=${(durationMs/1000).toStringAsFixed(2)} s '
            'bitrate=${mbps.toStringAsFixed(2)} Mbps');
      }

      // Prepare fallback ladder (from higher to lower) for cellular
      final lowerBound = targetMbps * 0.5;
      final upperBound = targetMbps * 2.0;

      if (network != null && network.isOnCellular) {
        final ladder = <VideoQuality>[
          VideoQuality.Res1280x720Quality,
          VideoQuality.MediumQuality,
        ];
        for (final q in ladder) {
          if (fileBytes <= maxBytes) break;
          info = await VideoCompress.compressVideo(
            videoFile.path,
            quality: q,
            includeAudio: true,
            deleteOrigin: false,
          );
          output = File(info?.path ?? videoFile.path);
          fileBytes = await output.length();
          durationMs = info?.duration?.toInt() ?? durationMs;
          if (durationMs > 0) {
            mbps = (fileBytes * 8) / (durationMs / 1000) / 1e6;
          }
          if (kDebugMode) {
            debugPrint('[VideoCompression] Step (cellular): quality=$q '
                'size=${(fileBytes/1e6).toStringAsFixed(2)} MB '
                'bitrate=${mbps.toStringAsFixed(2)} Mbps');
          }
        }
      } else {
        // On Wi‑Fi, ensure below max size; if not, step down once or twice
        if (fileBytes > maxBytes) {
          final ladder = <VideoQuality>[
            VideoQuality.Res1280x720Quality,
            VideoQuality.MediumQuality,
          ];
          for (final q in ladder) {
            if (fileBytes <= maxBytes) break;
            info = await VideoCompress.compressVideo(
              videoFile.path,
              quality: q,
              includeAudio: true,
              deleteOrigin: false,
            );
            output = File(info?.path ?? videoFile.path);
            fileBytes = await output.length();
            if (kDebugMode) {
              double mbpsWifi = 0;
              if (durationMs > 0) {
                mbpsWifi = (fileBytes * 8) / (durationMs / 1000) / 1e6;
              }
              debugPrint('[VideoCompression] Step (wifi): quality=$q '
                  'size=${(fileBytes/1e6).toStringAsFixed(2)} MB '
                  'bitrate=${mbpsWifi.toStringAsFixed(2)} Mbps');
            }
          }
        }
      }

      if (kDebugMode) {
        final finalBytes = await output.length();
        double finalMbps = 0;
        if (durationMs > 0) {
          finalMbps = (finalBytes * 8) / (durationMs / 1000) / 1e6;
        }
        debugPrint('[VideoCompression] Final: '
            'size=${(finalBytes/1e6).toStringAsFixed(2)} MB '
            'bitrate=${finalMbps.toStringAsFixed(2)} Mbps '
            'targetRange=${lowerBound.toStringAsFixed(2)}-${upperBound.toStringAsFixed(2)} '
            'path=${output.path.split('/').last}');
      }

      return output;

    } catch (_) {
      return videoFile;
    }
  }
}
