import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class WebpUploadService {
  static const int defaultMaxImageDimension = 600;

  static Future<String?> _ensureUploadAuthReady() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance.authStateChanges().firstWhere(
          (candidate) => candidate != null,
        );
      } catch (_) {
        user = FirebaseAuth.instance.currentUser;
      }
    }
    if (user == null) return null;
    try {
      await user.getIdToken(true);
    } catch (_) {
      // Best effort token refresh.
    }
    return user.uid;
  }

  static bool _isAuthRetryable(FirebaseException e) {
    final code = e.code.toLowerCase();
    return code == 'unauthenticated' || code == 'unauthorized';
  }

  static Future<void> _refreshAuthTokenIfPossible() async {
    try {
      await _ensureUploadAuthReady();
    } catch (_) {
      // Best effort refresh; if it fails, original upload error will surface.
    }
  }

  static Future<void> _putDataWithSingleAuthRetry(
    Reference ref,
    Uint8List data,
    SettableMetadata metadata,
  ) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];

    FirebaseException? lastError;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        await ref.putData(data, metadata);
        return;
      } on FirebaseException catch (e) {
        if (!_isAuthRetryable(e)) rethrow;
        lastError = e;
        if (attempt == retryDelays.length) break;
        await _refreshAuthTokenIfPossible();
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
    throw lastError!;
  }

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
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) async {
    try {
      Uint8List sourceBytes = bytes;
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        if (decoded.width > maxWidth || decoded.height > maxHeight) {
          final scale = math.min(
            maxWidth / decoded.width,
            maxHeight / decoded.height,
          );
          final resized = img.copyResize(
            decoded,
            width: math.max(1, (decoded.width * scale).round()),
            height: math.max(1, (decoded.height * scale).round()),
            interpolation: img.Interpolation.cubic,
          );
          sourceBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 92));
        }
      }
      return await FlutterImageCompress.compressWithList(
        sourceBytes,
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
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) async {
    final fileBytes = await file.readAsBytes();
    final data = await toWebpFromBytes(
      fileBytes,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (data == null || data.isEmpty) {
      throw Exception('WebP conversion failed');
    }
    final uid = await _ensureUploadAuthReady();
    final ref = storage.ref().child('$storagePathWithoutExt.webp');
    if (kDebugMode) {
      debugPrint(
        '[UploadPreflight][WebP] path=${ref.fullPath} uid=$uid bytes=${data.length}',
      );
    }
    await _putDataWithSingleAuthRetry(
      ref,
      data,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
        customMetadata: {
          if ((uid ?? '').isNotEmpty) 'uploaderUid': uid!,
        },
      ),
    );
    return ref.getDownloadURL();
  }

  static Future<String> uploadBytesAsWebp({
    required FirebaseStorage storage,
    required Uint8List bytes,
    required String storagePathWithoutExt,
    int quality = 85,
    int maxWidth = defaultMaxImageDimension,
    int maxHeight = defaultMaxImageDimension,
  }) async {
    final data = await toWebpFromBytes(
      bytes,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (data == null || data.isEmpty) {
      throw Exception('WebP conversion failed');
    }
    final uid = await _ensureUploadAuthReady();
    final ref = storage.ref().child('$storagePathWithoutExt.webp');
    if (kDebugMode) {
      debugPrint(
        '[UploadPreflight][WebP] path=${ref.fullPath} uid=$uid bytes=${data.length}',
      );
    }
    await _putDataWithSingleAuthRetry(
      ref,
      data,
      SettableMetadata(
        contentType: 'image/webp',
        cacheControl: 'public, max-age=31536000, immutable',
        customMetadata: {
          if ((uid ?? '').isNotEmpty) 'uploaderUid': uid!,
        },
      ),
    );
    return ref.getDownloadURL();
  }
}
