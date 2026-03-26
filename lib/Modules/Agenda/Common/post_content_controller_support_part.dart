part of 'post_content_controller.dart';

final Map<String, _UserProfileCacheEntry> _userProfileCache =
    <String, _UserProfileCacheEntry>{};
const Duration _userProfileCacheTtl = Duration(minutes: 20);
final Map<String, _ReshareUsersCacheEntry> _reshareUsersCache =
    <String, _ReshareUsersCacheEntry>{};
const Duration _reshareUsersCacheTtl = Duration(minutes: 2);

final userService = CurrentUserService.instance;
final countManager = PostCountManager.instance;
final PostRepository _postRepository = PostRepository.ensure();
final AdminPushRepository _adminPushRepository = AdminPushRepository.ensure();

PostContentController _ensurePostContentController({
  required String tag,
  required PostContentController Function() create,
}) {
  final existing = _maybeFindPostContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(create(), tag: tag);
}

PostContentController? _maybeFindPostContentController({
  required String tag,
}) {
  final isRegistered = Get.isRegistered<PostContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostContentController>(tag: tag);
}

void _invalidatePostContentControllerUserProfileCache(String userId) {
  _invalidatePostContentUserProfileCache(userId);
}

void _clearPostContentControllerUserProfileCache() {
  _clearPostContentUserProfileCache();
}

void _clearPostContentControllerReshareUsersCache() {
  _clearPostContentReshareUsersCache();
}

PostContentController ensurePostContentController({
  required String tag,
  required PostContentController Function() create,
}) =>
    _ensurePostContentController(tag: tag, create: create);

PostContentController? maybeFindPostContentController({required String tag}) =>
    _maybeFindPostContentController(tag: tag);

void invalidatePostContentUserProfileCache(String userId) {
  _invalidatePostContentControllerUserProfileCache(userId);
}

void clearPostContentUserProfileCache() {
  _clearPostContentControllerUserProfileCache();
}

void clearPostContentReshareUsersCache() {
  _clearPostContentControllerReshareUsersCache();
}

void _invalidatePostContentUserProfileCache(String userId) {
  final trimmed = userId.trim();
  if (trimmed.isEmpty) return;
  _userProfileCache.remove(trimmed);
}

void _clearPostContentUserProfileCache() => _userProfileCache.clear();

void _clearPostContentReshareUsersCache() => _reshareUsersCache.clear();

class _PostContentControllerSupportPart {
  final PostContentController _controller;

  const _PostContentControllerSupportPart(this._controller);

  bool get canSendAdminPush {
    return _controller._canSendAdminPush ||
        AdminAccessService.isKnownAdminSync();
  }

  ({String title, String body}) buildPostPushCopy() {
    final senderName = _controller.fullName.value.trim().isNotEmpty
        ? _controller.fullName.value.trim()
        : _controller.nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'app.name'.tr;
    final hasVideo = _controller.model.video.trim().isNotEmpty;
    final hasImage = _controller.model.img.isNotEmpty;
    final text = _controller.model.metin.trim();

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

  String? pushPreviewImageUrl() {
    if (_controller.model.img.isNotEmpty) {
      final firstImage = _controller.model.img.first.trim();
      if (firstImage.isNotEmpty) return firstImage;
    }
    final thumbnail = _controller.model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    return null;
  }

  String get reshareTargetPostId {
    final originalPostId = _controller.model.originalPostID.trim();
    if (originalPostId.isNotEmpty && _controller.model.quotedPost != true) {
      return originalPostId;
    }
    return _controller.model.docID;
  }
}

extension PostContentControllerSupportApi on PostContentController {
  CurrentUserService get userService => CurrentUserService.instance;

  ShortController get shortsController => ensureShortController();

  PostInteractionService get _interactionService =>
      ensurePostInteractionService();

  RxInt get likeCount => countManager.getLikeCount(model.docID);

  RxInt get commentCount => countManager.getCommentCount(model.docID);

  RxInt get savedCount => countManager.getSavedCount(model.docID);

  RxInt get retryCount => countManager.getRetryCount(model.docID);

  RxInt get statsCount => countManager.getStatsCount(model.docID);

  String get _currentUid => userService.effectiveUserId;

  AgendaController _resolveAgendaController() =>
      _performResolveAgendaController();

  bool get canSendAdminPush =>
      _PostContentControllerSupportPart(this).canSendAdminPush;

  ({String title, String body}) _buildPostPushCopy() =>
      _PostContentControllerSupportPart(this).buildPostPushCopy();

  String? _pushPreviewImageUrl() =>
      _PostContentControllerSupportPart(this).pushPreviewImageUrl();

  String get reshareTargetPostId =>
      _PostContentControllerSupportPart(this).reshareTargetPostId;
}
