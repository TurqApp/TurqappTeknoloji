part of 'post_creator_controller.dart';

extension _PostCreatorControllerUploadSupportX on PostCreatorController {
  String _resolvePostLocationCity() {
    return CurrentUserService.instance.preferredLocationCityOrEmpty;
  }

  bool _isAuthRetryableStorageError(FirebaseException e) {
    final code = normalizeLowercase(e.code);
    return code == 'unauthenticated' || code == 'unauthorized';
  }

  Future<String?> _ensureStorageUploadAuthReady() async {
    return CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
    );
  }

  Future<void> _refreshAuthTokenIfNeeded() async {
    try {
      await CurrentUserService.instance.refreshAuthTokenIfNeeded();
    } catch (_) {
      // Best effort refresh only.
    }
  }

  Future<Map<String, String>> _awaitGeneratedPostShortLink(String docID) async {
    final ref = FirebaseFirestore.instance.collection("Posts").doc(docID);
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1400),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        final snap = await ref.get(const GetOptions(source: Source.server));
        final data = snap.data() ?? const <String, dynamic>{};
        final shortId = (data["shortId"] ?? "").toString().trim();
        final shortUrl = (data["shortUrl"] ?? "").toString().trim();
        if (shortUrl.isNotEmpty) {
          return {
            "shortId": shortId,
            "shortUrl": shortUrl,
          };
        }
      } catch (_) {}

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    return const <String, String>{};
  }

  Future<void> _hydrateUploadedPostShortLinks(
    List<PostsModel> posts, {
    AgendaController? agendaController,
  }) async {
    if (posts.isEmpty) return;

    var changed = false;
    for (final post in posts) {
      if (post.docID.trim().isEmpty || post.shortUrl.trim().isNotEmpty) {
        continue;
      }
      final resolved = await _awaitGeneratedPostShortLink(post.docID);
      final shortUrl = (resolved["shortUrl"] ?? "").trim();
      if (shortUrl.isEmpty) continue;
      post.shortId = (resolved["shortId"] ?? "").trim();
      post.shortUrl = shortUrl;
      changed = true;
    }

    if (!changed) return;
    agendaController?.agendaList.refresh();
    await persistUploadedPostsToHomeFeed(posts);
  }

  Future<void> _preparePostShellForStorageUpload({
    required String docID,
    required String uid,
    required int timeStamp,
  }) async {
    final ref = FirebaseFirestore.instance.collection("Posts").doc(docID);
    await ref.set({
      "userID": uid,
      "timeStamp": timeStamp,
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

  NavBarController? _maybeNavBarController() => maybeFindNavBarController();
}
