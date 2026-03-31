part of 'education_feed_post_share_service.dart';

extension EducationFeedPostShareServicePublishPart
    on EducationFeedPostShareService {
  ({
    String nickname,
    String displayName,
    String avatarUrl,
    String rozet,
  }) _resolveAuthorSummary() {
    final current = CurrentUserService.instance;
    final nickname = current.nickname.trim();
    final effectiveDisplayName = current.effectiveDisplayName.trim();
    final fullName = current.fullName.trim();
    final displayName = effectiveDisplayName.isNotEmpty
        ? effectiveDisplayName
        : (fullName.isNotEmpty ? fullName : nickname);
    return (
      nickname: nickname,
      displayName: displayName,
      avatarUrl: current.avatarUrl.trim(),
      rozet: current.rozet.trim(),
    );
  }

  Future<void> _shareDirectly({
    required String text,
    required String imageUrl,
    required double aspectRatio,
    required String ctaLabel,
    required String ctaUrl,
    required String ctaType,
    required String ctaDocId,
  }) async {
    final ensured = await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
      timeout: const Duration(seconds: 8),
    );
    final currentUid =
        (ensured ?? CurrentUserService.instance.authUserId).trim();
    if (currentUid.isEmpty) {
      AppSnackbar(
        'login.sign_in'.tr,
        'education_feed.share_sign_in_required'.tr,
      );
      return;
    }
    if (imageUrl.trim().isEmpty) {
      AppSnackbar('common.error'.tr, 'education_feed.share_image_missing'.tr);
      return;
    }

    await ShareActionGuard.run(() async {
      final loader = GlobalLoaderController.ensure();
      loader.isOn.value = true;

      try {
        final postId = const Uuid().v4();
        final now = DateTime.now().millisecondsSinceEpoch;
        final authorSummary = _resolveAuthorSummary();
        final normalizedAspectRatio = double.parse(
          aspectRatio.toStringAsFixed(4),
        );
        final imageUrls = [imageUrl.trim()];
        final imgMap = imageUrls
            .map(
              (url) => {
                'url': url,
                'aspectRatio': normalizedAspectRatio,
              },
            )
            .toList();

        await FirebaseFirestore.instance.collection('Posts').doc(postId).set({
          'arsiv': false,
          'debugMode': false,
          'deletedPost': false,
          'deletedPostTime': 0,
          'flood': false,
          'floodCount': 1,
          'gizlendi': false,
          'img': imageUrls,
          'imgMap': imgMap,
          'isAd': false,
          'ad': false,
          'izBirakYayinTarihi': now,
          'stats': {
            'commentCount': 0,
            'likeCount': 0,
            'reportedCount': 0,
            'retryCount': 0,
            'savedCount': 0,
            'statsCount': 0,
          },
          'konum': '',
          'mainFlood': '',
          'metin': text,
          'reshareMap': {
            'visibility': 0,
            'ctaLabel': ctaLabel,
            'ctaUrl': ctaUrl,
            'ctaType': ctaType,
            'ctaDocId': ctaDocId,
          },
          'scheduledAt': 0,
          'sikayetEdildi': false,
          'stabilized': false,
          'tags': [],
          'thumbnail': imageUrl.trim(),
          'timeStamp': now,
          'userID': currentUid,
          'authorNickname': authorSummary.nickname,
          'authorDisplayName': authorSummary.displayName,
          'authorAvatarUrl': authorSummary.avatarUrl,
          'nickname': authorSummary.nickname,
          'fullName': authorSummary.displayName,
          'displayName': authorSummary.displayName,
          'avatarUrl': authorSummary.avatarUrl,
          'rozet': authorSummary.rozet,
          'video': '',
          'hlsStatus': 'none',
          'hlsMasterUrl': '',
          'hlsUpdatedAt': 0,
          'yorum': true,
          'yorumMap': {
            'visibility': 0,
          },
          'originalUserID': '',
          'originalPostID': '',
          'sharedAsPost': false,
        });
        unawaited(
          TypesensePostService.instance.syncPostById(postId).catchError((_) {}),
        );

        final newPost = PostsModel(
          ad: false,
          arsiv: false,
          aspectRatio: normalizedAspectRatio,
          debugMode: false,
          deletedPost: false,
          deletedPostTime: 0,
          docID: postId,
          flood: false,
          floodCount: 1,
          gizlendi: false,
          img: imageUrls,
          isAd: false,
          izBirakYayinTarihi: now,
          konum: '',
          mainFlood: '',
          metin: text,
          originalPostID: '',
          originalUserID: '',
          paylasGizliligi: 0,
          reshareMap: {
            'visibility': 0,
            'ctaLabel': ctaLabel,
            'ctaUrl': ctaUrl,
            'ctaType': ctaType,
            'ctaDocId': ctaDocId,
          },
          scheduledAt: 0,
          sikayetEdildi: false,
          stabilized: false,
          stats: PostStats(),
          tags: const [],
          thumbnail: imageUrl.trim(),
          timeStamp: now,
          userID: currentUid,
          authorNickname: authorSummary.nickname,
          authorDisplayName: authorSummary.displayName,
          authorAvatarUrl: authorSummary.avatarUrl,
          rozet: authorSummary.rozet,
          video: '',
          hlsStatus: 'none',
          hlsMasterUrl: '',
          hlsUpdatedAt: 0,
          yorum: true,
          yorumMap: const {'visibility': 0},
        );

        final agendaController = maybeFindAgendaController();
        if (agendaController != null) {
          agendaController.addUploadedPostsAtTop([newPost]);
          if (agendaController.scrollController.hasClients) {
            await agendaController.scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
            );
          }
        }

        await _persistToHomeFeedSnapshot(currentUid, newPost);
        ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();

        AppSnackbar(
          'common.success'.tr,
          'education_feed.shared_home'.tr,
        );
      } catch (_) {
        AppSnackbar('common.error'.tr, 'education_feed.share_failed'.tr);
      } finally {
        loader.isOn.value = false;
      }
    });
  }

  String _lines(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  String _shorten(String text, {int maxLength = 220}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1).trim()}…';
  }

  String _buildInternalUrl({
    required String type,
    required String docId,
  }) {
    return 'turqapp://education/$type/${docId.trim()}';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  Future<void> _persistToHomeFeedSnapshot(
      String userId, PostsModel post) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || post.docID.trim().isEmpty) return;

    final repository = ensureFeedSnapshotRepository();
    final snapshot = await repository.bootstrapHome(
      userId: normalizedUserId,
      limit: 40,
    );
    final merged = <String, PostsModel>{post.docID: post};
    for (final existing in snapshot.data ?? const <PostsModel>[]) {
      merged.putIfAbsent(existing.docID, () => existing);
    }

    final ordered = merged.values.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await repository.persistHomeSnapshot(
      userId: normalizedUserId,
      posts: ordered,
      limit: 40,
      source: CachedResourceSource.memory,
    );
  }
}
