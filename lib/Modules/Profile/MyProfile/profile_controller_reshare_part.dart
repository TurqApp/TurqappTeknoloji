part of 'profile_controller.dart';

extension ProfileControllerResharePart on ProfileController {
  void _performBindResharesRealtime() {
    final uid = _resolvedActiveUid;
    if (uid == null) return;
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(uid).listen((refs) {
      _latestReshareRefs = refs;
      _hydrateReshares(uid, refs);
    }, onError: (error) {
      print('ProfileController reshares listener error: $error');
    });
  }

  Future<void> _performHydrateReshares(
    String uid,
    List<UserPostReference> refs,
  ) async {
    try {
      final posts = await _linkService.fetchResharedPosts(uid, refs);
      if (posts.isNotEmpty || reshares.isEmpty) {
        reshares.assignAll(List<PostsModel>.from(posts));
      }
    } catch (e) {
      print('ProfileController hydrate reshares error: $e');
    }
  }

  int _performReshareSortTimestampFor(String postId, int fallback) {
    for (final ref in _latestReshareRefs) {
      if (ref.postId == postId) return ref.timeStamp.toInt();
    }
    return fallback;
  }

  Future<void> _performGetReshares() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;
    await _hydrateReshares(uid, _latestReshareRefs);
  }

  Future<void> _performGetResharesSingle() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    final post = await _profileRepository.fetchLatestResharePost(uid);
    if (post == null) {
      reshares.clear();
      return;
    }

    if (post.timeStamp > DateTime.now().millisecondsSinceEpoch ||
        post.deletedPost == true) {
      return;
    }

    final exists = reshares.any((p) => p.docID == post.docID);
    if (!exists) {
      reshares.insert(0, post);
    }
  }

  void _performRemoveReshare(String postId) {
    reshares.removeWhere((post) => post.docID == postId);
  }
}
