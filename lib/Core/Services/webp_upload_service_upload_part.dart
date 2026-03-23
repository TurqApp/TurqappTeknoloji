part of 'webp_upload_service.dart';

Future<String?> _performEnsureUploadAuthReady() {
  return CurrentUserService.instance.ensureAuthReady(
    waitForAuthState: true,
    forceTokenRefresh: true,
  );
}

bool _performIsAuthRetryable(FirebaseException e) {
  final code = normalizeLowercase(e.code);
  return code == 'unauthenticated' || code == 'unauthorized';
}

Future<void> _performRefreshAuthTokenIfPossible() async {
  try {
    await CurrentUserService.instance.refreshAuthTokenIfNeeded();
  } catch (_) {
    // Best effort refresh; if it fails, original upload error will surface.
  }
}

Future<void> _performPutDataWithSingleAuthRetry(
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
      if (!_performIsAuthRetryable(e)) rethrow;
      lastError = e;
      if (attempt == retryDelays.length) break;
      await _performRefreshAuthTokenIfPossible();
      await Future<void>.delayed(retryDelays[attempt]);
    }
  }
  throw lastError!;
}

Future<String> _performUploadFileAsWebp({
  required FirebaseStorage storage,
  required File file,
  required String storagePathWithoutExt,
  required int quality,
  required int maxWidth,
  required int maxHeight,
}) async {
  final fileBytes = await file.readAsBytes();
  final data = await _performToWebpFromBytes(
    fileBytes,
    quality: quality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
  if (data == null || data.isEmpty) {
    throw Exception('WebP conversion failed');
  }
  final uid = await _performEnsureUploadAuthReady();
  final ref = storage.ref().child('$storagePathWithoutExt.webp');
  if (kDebugMode) {
    debugPrint('[UploadPreflight][WebP] bytes=${data.length}');
  }
  await _performPutDataWithSingleAuthRetry(
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

Future<String> _performUploadBytesAsWebp({
  required FirebaseStorage storage,
  required Uint8List bytes,
  required String storagePathWithoutExt,
  required int quality,
  required int maxWidth,
  required int maxHeight,
}) async {
  final data = await _performToWebpFromBytes(
    bytes,
    quality: quality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
  if (data == null || data.isEmpty) {
    throw Exception('WebP conversion failed');
  }
  final uid = await _performEnsureUploadAuthReady();
  final ref = storage.ref().child('$storagePathWithoutExt.webp');
  if (kDebugMode) {
    debugPrint('[UploadPreflight][WebP] bytes=${data.length}');
  }
  await _performPutDataWithSingleAuthRetry(
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
