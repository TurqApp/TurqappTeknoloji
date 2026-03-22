part of 'post_creator_controller.dart';

extension _PostCreatorControllerRouteX on PostCreatorController {
  Future<void> _prepareForRoute({
    required String routeId,
    required bool sharedAsPost,
    required bool editMode,
  }) async {
    if (_preparedRouteId == routeId) return;
    _preparedRouteId = routeId;
    await _resetComposerState();
    if (sharedAsPost || editMode) return;
  }

  Future<void> _resetComposerState() async {
    for (final post in postList) {
      final tag = post.index.toString();
      final controller = CreatorContentController.maybeFind(tag: tag);
      if (controller != null) {
        await controller.resetComposerState();
        Get.delete<CreatorContentController>(tag: tag, force: true);
      }
    }
    postList.assignAll([PostCreatorModel(index: 0, text: "")]);
    postList.refresh();
    resetComposerItemIndexSeed(1);
    selectedIndex.value = 0;
    comment.value = true;
    commentVisibility.value = 0;
    paylasimSelection.value = 0;
    publishMode.value = 0;
    izBirakDateTime.value = null;
    _sharedSourceApplied = false;
    _sharedSourceFingerprint = "";
    _isSharedAsPost = false;
    _sharedOriginalUserID = "";
    _sharedOriginalPostID = "";
    _sharedSourcePostID = "";
    _isQuotedPost = false;
    _quotedOriginalText = "";
    _quotedSourceUserID = "";
    _quotedSourceDisplayName = "";
    _quotedSourceUsername = "";
    _quotedSourceAvatarUrl = "";
    _editSourceApplied = false;
    isEditMode.value = false;
    editingPostID.value = '';
    isSavingEdit.value = false;
  }

  void _handleDidChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final bottomInset = view.viewInsets.bottom;
    isKeyboardOpen.value = bottomInset > 10;
  }

  DateTime? _normalizedIzBirakDateTime() {
    final picked = izBirakDateTime.value;
    if (publishMode.value != 1 || picked == null) return null;
    final now = DateTime.now();
    if (picked.isBefore(now)) return now;
    final max = maxIzBirakDate;
    if (picked.isAfter(max)) return max;
    return picked;
  }

  Future<void> _hydrateQuotedSourceIfNeeded() async {
    if (!_isSharedAsPost || !_isQuotedPost) return;

    final sourcePostId = _sharedSourcePostID.trim().isNotEmpty
        ? _sharedSourcePostID.trim()
        : _sharedOriginalPostID.trim();

    Map<String, dynamic> sourcePost = const <String, dynamic>{};
    if (sourcePostId.isNotEmpty) {
      sourcePost = await _postRepository.fetchPostRawById(
            sourcePostId,
            preferCache: true,
          ) ??
          const <String, dynamic>{};
    }

    final resolvedText = _quotedOriginalText.trim().isNotEmpty
        ? _quotedOriginalText.trim()
        : (sourcePost['metin'] ?? '').toString().trim();
    if (resolvedText.isNotEmpty) {
      _quotedOriginalText = resolvedText;
    }

    final sourceUserId = _quotedSourceUserID.trim().isNotEmpty
        ? _quotedSourceUserID.trim()
        : (sourcePost['userID'] ?? sourcePost['userId'] ?? '')
            .toString()
            .trim();
    if (sourceUserId.isNotEmpty) {
      _quotedSourceUserID = sourceUserId;
    }

    if (sourceUserId.isEmpty) return;

    final userRaw = await UserRepository.ensure().getUserRaw(
          sourceUserId,
          preferCache: true,
          cacheOnly: false,
        ) ??
        const <String, dynamic>{};

    final resolvedDisplayName = _quotedSourceDisplayName.trim().isNotEmpty
        ? _quotedSourceDisplayName.trim()
        : [
            (userRaw['displayName'] ?? '').toString().trim(),
            [
              (userRaw['firstName'] ?? '').toString().trim(),
              (userRaw['lastName'] ?? '').toString().trim(),
            ].where((e) => e.isNotEmpty).join(' ').trim(),
            (userRaw['nickname'] ?? '').toString().trim(),
            (userRaw['username'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedDisplayName.isNotEmpty) {
      _quotedSourceDisplayName = resolvedDisplayName;
    }

    final resolvedUsername = _quotedSourceUsername.trim().isNotEmpty
        ? _quotedSourceUsername.trim()
        : [
            (userRaw['username'] ?? '').toString().trim(),
            (userRaw['nickname'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedUsername.isNotEmpty) {
      _quotedSourceUsername = resolvedUsername;
    }

    final resolvedAvatar = _quotedSourceAvatarUrl.trim().isNotEmpty
        ? _quotedSourceAvatarUrl.trim()
        : [
            (userRaw['avatarUrl'] ?? '').toString().trim(),
            (userRaw['profileImage'] ?? '').toString().trim(),
            (userRaw['photoUrl'] ?? '').toString().trim(),
            (userRaw['imageUrl'] ?? '').toString().trim(),
          ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (resolvedAvatar.isNotEmpty) {
      _quotedSourceAvatarUrl = resolvedAvatar;
    }
  }
}
