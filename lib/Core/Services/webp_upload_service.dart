import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'webp_upload_service_convert_part.dart';
part 'webp_upload_service_upload_part.dart';

class WebpUploadService {
  static const int defaultMaxImageDimension = 600;

  static Future<Uint8List?> toWebpFromFile(
    File file, {
    int quality = 85,
  }) =>
      _performToWebpFromFile(
        file,
        quality: quality,
      );

  static Future<Uint8List?> toWebpFromBytes(
    Uint8List bytes, {
    int quality = 85,
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) =>
      _performToWebpFromBytes(
        bytes,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

  static Future<String> uploadFileAsWebp({
    FirebaseStorage? storage,
    required File file,
    required String storagePathWithoutExt,
    int quality = 85,
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) =>
      _performUploadFileAsWebp(
        storage: storage ?? AppFirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: storagePathWithoutExt,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

  static Future<String> uploadBytesAsWebp({
    FirebaseStorage? storage,
    required Uint8List bytes,
    required String storagePathWithoutExt,
    int quality = 85,
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) =>
      _performUploadBytesAsWebp(
        storage: storage ?? AppFirebaseStorage.instance,
        bytes: bytes,
        storagePathWithoutExt: storagePathWithoutExt,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

  static Future<String> uploadPreparedWebpBytes({
    required Uint8List bytes,
    required String storagePathWithoutExt,
  }) =>
      _performUploadPreparedWebpBytes(
        storage: AppFirebaseStorage.instance,
        bytes: bytes,
        storagePathWithoutExt: storagePathWithoutExt,
      );
}
