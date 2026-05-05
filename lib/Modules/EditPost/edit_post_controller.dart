import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/post_caption_limits.dart';
import 'package:turqappv2/Core/Services/text_moderation_service.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Modules/EditPost/edit_post_model.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import '../../Core/LocationFinderView/location_finder_view.dart';
import '../../Core/Services/optimized_nsfw_service.dart';
import '../../Core/Services/profile_manifest_sync_service.dart';
import '../../Core/Services/video_compression_service.dart';
import '../../Core/Services/media_compression_service.dart';
import '../../Core/Services/webp_upload_service.dart';
import '../Agenda/agenda_controller.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Agenda/Common/post_content_controller.dart';

part 'edit_post_controller_base_part.dart';
part 'edit_post_controller_class_part.dart';
part 'edit_post_controller_facade_part.dart';
part 'edit_post_controller_media_part.dart';
part 'edit_post_controller_actions_part.dart';
part 'edit_post_controller_fields_part.dart';
part 'edit_post_controller_runtime_part.dart';

class _EditPostGeneratedThumbnailResult {
  const _EditPostGeneratedThumbnailResult({
    required this.path,
    required this.strategy,
    this.frameMs,
    required this.version,
  });

  final String path;
  final String strategy;
  final int? frameMs;
  final int version;
}

const List<int> _editPostThumbnailCandidateMs = <int>[0, 33, 67, 100];

Future<_EditPostGeneratedThumbnailResult> generateStandardEditPostThumbnail({
  required String videoPath,
  required String tempDirPath,
}) async {
  Uint8List? bestData;
  int? bestMs;
  double bestScore = double.negativeInfinity;

  for (final ms in _editPostThumbnailCandidateMs) {
    final data = await vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      timeMs: ms,
      maxWidth: 600,
      quality: 80,
    );
    if (data == null || data.isEmpty) continue;
    final score = await _editPostThumbnailQualityScore(data);
    if (score != null && score >= 18) {
      final path = p.join(
        tempDirPath,
        '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg',
      );
      await File(path).writeAsBytes(data, flush: true);
      return _EditPostGeneratedThumbnailResult(
        path: path,
        strategy: 'auto_early_frame',
        frameMs: ms,
        version: 2,
      );
    }
    if (score != null && score > bestScore) {
      bestScore = score;
      bestData = data;
      bestMs = ms;
    } else {
      bestData ??= data;
      bestMs ??= ms;
    }
  }

  final fallbackPath = p.join(
    tempDirPath,
    '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg',
  );
  if (bestData != null) {
    await File(fallbackPath).writeAsBytes(bestData, flush: true);
  }
  return _EditPostGeneratedThumbnailResult(
    path: fallbackPath,
    strategy: 'auto_early_frame',
    frameMs: bestMs,
    version: 2,
  );
}

Future<double?> _editPostThumbnailQualityScore(Uint8List data) async {
  try {
    final codec = await ui.instantiateImageCodec(
      data,
      targetWidth: 24,
      targetHeight: 24,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();
    if (bytes.isEmpty) return null;

    double sum = 0;
    double sumSquares = 0;
    int count = 0;
    for (int i = 0; i + 3 < bytes.length; i += 4) {
      final r = bytes[i].toDouble();
      final g = bytes[i + 1].toDouble();
      final b = bytes[i + 2].toDouble();
      final luma = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
      sum += luma;
      sumSquares += luma * luma;
      count++;
    }
    if (count == 0) return null;
    final mean = sum / count;
    final variance = (sumSquares / count) - (mean * mean);
    if (mean < 14) return mean - 1000;
    return variance + (mean * 0.15);
  } catch (_) {
    return null;
  }
}
