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
    if (!await ensurePhotoPermission()) {
      return <File>[];
    }
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: maxAssets,
    );
    if (picked.isEmpty) return <File>[];
    return picked.map((x) => File(x.path)).toList();
  }

  static Future<File?> pickSingleImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
  }) async {
    if (source == ImageSource.camera) {
      if (!await ensureCameraPermission()) return null;
    } else if (!await ensurePhotoPermission()) {
      return null;
    }
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<List<File>> pickVideos(
    BuildContext context, {
    required int maxAssets,
  }) async {
    if (!await _ensureVideoPermission()) {
      return <File>[];
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
    if (!await _ensureVideoPermission()) {
      return null;
    }
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<File?> pickSingleVideoFromSource(
    BuildContext context, {
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    if (source == ImageSource.camera) {
      if (!await ensureCameraVideoPermission()) return null;
    } else if (!await _ensureVideoPermission()) {
      return null;
    }
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  static Future<bool> ensureCameraVideoPermission() async {
    if (!await ensureCameraPermission()) return false;
    return ensureMicrophonePermission();
  }

  static Future<bool> ensureCameraPermission() =>
      _ensurePermission(Permission.camera, permissionId: 'camera');

  static Future<bool> ensureMicrophonePermission() =>
      _ensurePermission(Permission.microphone, permissionId: 'microphone');

  static Future<bool> ensurePhotoPermission() async {
    if (Platform.isAndroid) {
      final photoStatus =
          await _requestPermission(Permission.photos, permissionId: 'photos');
      if (_isAllowed(photoStatus)) return true;

      final storageStatus =
          await _requestPermission(Permission.storage, permissionId: 'storage');
      return _isAllowed(storageStatus);
    }

    if (Platform.isIOS) {
      return _ensurePermission(Permission.photos, permissionId: 'photos');
    }

    return true;
  }

  static Future<bool> _ensureVideoPermission() async {
    if (Platform.isIOS) {
      return _ensurePermission(Permission.photos, permissionId: 'photos');
    }
    if (!Platform.isAndroid) return true;

    final videoStatus =
        await _requestPermission(Permission.videos, permissionId: 'videos');
    if (_isAllowed(videoStatus)) {
      return true;
    }

    final photoStatus =
        await _requestPermission(Permission.photos, permissionId: 'photos');
    if (_isAllowed(photoStatus)) return true;

    final storageStatus =
        await _requestPermission(Permission.storage, permissionId: 'storage');
    return _isAllowed(storageStatus);
  }

  static Future<bool> _ensurePermission(
    Permission permission, {
    required String permissionId,
  }) async {
    final status = await permission.status;
    if (_isAllowed(status)) return true;
    final requested = await _requestPermission(
      permission,
      permissionId: permissionId,
    );
    return _isAllowed(requested);
  }

  static Future<PermissionStatus> _requestPermission(
    Permission permission, {
    required String permissionId,
  }) {
    return permission.request();
  }

  static bool _isAllowed(PermissionStatus status) =>
      status.isGranted || status.isLimited;
}
