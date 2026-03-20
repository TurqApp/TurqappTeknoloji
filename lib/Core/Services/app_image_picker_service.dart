import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

class AppImagePickerService {
  static final ImagePicker _picker = ImagePicker();
  static const Set<String> _videoExtensions = <String>{
    '.mp4',
    '.mov',
    '.m4v',
    '.avi',
    '.mkv',
    '.webm',
    '.3gp',
    '.mpeg',
    '.mpg',
  };

  static Future<List<File>> pickImages(
    BuildContext context, {
    required int maxAssets,
  }) async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: maxAssets,
    );
    if (picked.isEmpty) return <File>[];
    return picked.map((x) => File(x.path)).toList();
  }

  static Future<File?> pickSingleImage(BuildContext context) async {
    if (Platform.isAndroid) {
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
        return null;
      }
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<List<File>> pickVideos(
    BuildContext context, {
    required int maxAssets,
  }) async {
    if (Platform.isAndroid) {
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
        return <File>[];
      }
    }
    final picked = await _picker.pickMultipleMedia(limit: maxAssets);
    if (picked.isEmpty) return <File>[];
    final videos = picked.where((x) {
      final lowerPath = normalizeLowercase(x.path);
      return _videoExtensions.any(lowerPath.endsWith);
    }).toList();
    return videos.map((x) => File(x.path)).toList();
  }

  static Future<File?> pickSingleVideo(BuildContext context) async {
    if (Platform.isAndroid) {
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
        return null;
      }
    }
    final files = await pickVideos(context, maxAssets: 1);
    if (files.isEmpty) return null;
    return files.first;
  }
}
