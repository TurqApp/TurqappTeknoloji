import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class WebpUploadService {
  static Future<Uint8List?> toWebpFromFile(
    File file, {
    int quality = 85,
  }) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (e) {
      debugPrint('[WebP] file compress failed: $e');
      return null;
    }
  }

  static Future<Uint8List?> toWebpFromBytes(
    Uint8List bytes, {
    int quality = 85,
  }) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: quality,
      );
    } catch (e) {
      debugPrint('[WebP] bytes compress failed: $e');
      return null;
    }
  }

  static Future<String> uploadFileAsWebp({
    required FirebaseStorage storage,
    required File file,
    required String storagePathWithoutExt,
    int quality = 85,
  }) async {
    final data = await toWebpFromFile(file, quality: quality);
    if (data == null || data.isEmpty) {
      throw Exception('WebP conversion failed');
    }
    final ref = storage.ref().child('$storagePathWithoutExt.webp');
    await ref.putData(
      data,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
      ),
    );
    return ref.getDownloadURL();
  }

  static Future<String> uploadBytesAsWebp({
    required FirebaseStorage storage,
    required Uint8List bytes,
    required String storagePathWithoutExt,
    int quality = 85,
  }) async {
    final data = await toWebpFromBytes(bytes, quality: quality);
    if (data == null || data.isEmpty) {
      throw Exception('WebP conversion failed');
    }
    final ref = storage.ref().child('$storagePathWithoutExt.webp');
    if (kDebugMode) {
      debugPrint('[UploadPreflight][WebP] path=${ref.fullPath} bytes=${data.length}');
    }
    await ref.putData(
      data,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
      ),
    );
    return ref.getDownloadURL();
  }
}
