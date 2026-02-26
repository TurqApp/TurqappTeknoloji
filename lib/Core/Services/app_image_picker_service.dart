import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AppImagePickerService {
  static final ImagePicker _picker = ImagePicker();

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
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return <File>[];
    return <File>[File(picked.path)];
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
