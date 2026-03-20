part of 'post_creator_controller.dart';

extension _PostCreatorControllerUploadSupportX on PostCreatorController {
  String _resolvePostLocationCity() {
    final user = CurrentUserService.instance.currentUserRx.value;
    final candidates = [
      user?.locationSehir,
      user?.city,
      user?.ikametSehir,
      user?.il,
      user?.ulke,
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _isAuthRetryableStorageError(FirebaseException e) {
    final code = normalizeLowercase(e.code);
    return code == 'unauthenticated' || code == 'unauthorized';
  }

  Future<String?> _ensureStorageUploadAuthReady() async {
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
      // Best effort refresh only.
    }
    return user.uid;
  }

  Future<void> _refreshAuthTokenIfNeeded() async {
    try {
      await _ensureStorageUploadAuthReady();
    } catch (_) {
      // Best effort refresh only.
    }
  }

  Future<void> _preparePostShellForStorageUpload({
    required String docID,
    required String uid,
    required int nowMs,
  }) async {
    final ref = FirebaseFirestore.instance.collection("Posts").doc(docID);
    await ref.set({
      "userID": uid,
      "timeStamp": nowMs,
      "isUploading": true,
      "hlsStatus": "none",
    }, SetOptions(merge: true));
    await FirebaseFirestore.instance.waitForPendingWrites();

    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        final snap = await ref.get(const GetOptions(source: Source.server));
        final shellUserId = (snap.data()?["userID"] ?? '').toString();
        if (snap.exists && shellUserId == uid) {
          return;
        }
      } catch (_) {
        // Best-effort server visibility check only.
      }

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  Future<TaskSnapshot> _putFileWithAuthRetry({
    required Reference ref,
    required File file,
    required SettableMetadata metadata,
  }) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];

    FirebaseException? lastError;
    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        return await ref.putFile(file, metadata);
      } on FirebaseException catch (e) {
        if (!_isAuthRetryableStorageError(e)) rethrow;
        lastError = e;
        if (attempt == retryDelays.length) break;
        await _refreshAuthTokenIfNeeded();
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
    throw lastError!;
  }

  NavBarController? _maybeNavBarController() {
    if (!Get.isRegistered<NavBarController>()) return null;
    return Get.find<NavBarController>();
  }
}
