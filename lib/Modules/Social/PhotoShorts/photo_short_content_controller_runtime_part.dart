part of 'photo_short_content_controller.dart';

extension PhotoShortContentControllerRuntimePart
    on PhotoShortsContentController {
  ({String title, String body}) _buildPostPushCopy() {
    final senderName = fullName.value.trim().isNotEmpty
        ? fullName.value.trim()
        : nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'app.name'.tr;
    final hasVideo = model.video.trim().isNotEmpty;
    final hasImage = model.img.isNotEmpty;
    final text = model.metin.trim();

    final preview =
        text.length > 90 ? '${text.substring(0, 90).trim()}...' : text;
    final title = '$safeSender yeni bir gönderi paylaştı';
    final body = preview.isNotEmpty
        ? preview
        : hasVideo
            ? 'Yeni video gönderisi'
            : hasImage
                ? 'Yeni fotoğraf gönderisi'
                : 'Yeni gönderi paylaştı';
    return (title: title, body: body);
  }

  String? _pushPreviewImageUrl() {
    if (model.img.isNotEmpty) {
      final firstImage = model.img.first.trim();
      if (firstImage.isNotEmpty) return firstImage;
    }
    final thumbnail = model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    return null;
  }

  void _initializeRuntime() {
    _interactionService = PostInteractionService.ensure();
    _postRepository = PostRepository.ensure();
    _adminPushRepository = AdminPushRepository.ensure();

    Future.microtask(() {
      countManager.initializeCounts(
        model.docID,
        likeCount: model.stats.likeCount.toInt(),
        commentCount: model.stats.commentCount.toInt(),
        savedCount: model.stats.savedCount.toInt(),
        retryCount: model.stats.retryCount.toInt(),
        statsCount: model.stats.statsCount.toInt(),
      );
      _initializeStats();
      _loadUserInteractionStatus();
    });

    getGizleArsivSikayetEdildi();
    avatarUrl.value = model.authorAvatarUrl.trim();
    nickname.value = model.authorNickname.trim();
    fullName.value = model.authorDisplayName.trim();
    fetchUserData(model.userID);
    getReSharedUsers(model.docID);
    getYenidenPaylasBilgisi();
    getSeens();
    saveSeeing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindMembershipListeners();
      _bindReshareListener();
      _bindPostDocCounts();
    });
  }

  void _disposeRuntime() {
    _interactionWorker?.dispose();
    _postRepository.releasePost(model.docID);
    _likeDocSub?.cancel();
    _savedDocSub?.cancel();
    _reshareDocSub?.cancel();
    _postDocSub?.cancel();
  }

  void _bindMembershipListeners() {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    _interactionWorker?.dispose();
    if (_postState != null) {
      _interactionWorker = everAll([
        _postState!.liked,
        _postState!.saved,
        _postState!.reshared,
      ], (_) {
        _syncSharedInteractionState();
      });
    }
  }

  void _bindReshareListener() {
    _syncSharedInteractionState();
  }

  void _bindPostDocCounts() {
    _postState ??= _postRepository.attachPost(model);
  }

  void _syncSharedInteractionState() {
    final uid = _currentUserId;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    final savedState = _postState!.saved.value;
    final reshared = _postState!.reshared.value;
    if (uid.isNotEmpty) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
      if (savedState) {
        if (!saved.contains(uid)) saved.add(uid);
      } else {
        saved.remove(uid);
      }
    }
    isLiked.value = liked;
    isSaved.value = savedState;
    isReshared.value = reshared;
    yenidenPaylasildiMi.value = reshared;
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
  }

  Future<void> _loadUserInteractionStatus() async {
    _postState ??= _postRepository.attachPost(model);
    _syncSharedInteractionState();
    isReported.value = _postState?.reported.value ?? false;
  }
}
