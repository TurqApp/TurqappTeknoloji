part of 'post_creator_controller.dart';

extension PostCreatorControllerSourcePart on PostCreatorController {
  Future<String> resolveQuoteCounterTargetPostId() async {
    final sourcePostId = _sharedSourcePostID.trim();
    final originalPostId = _sharedOriginalPostID.trim();
    final candidate = sourcePostId.isNotEmpty ? sourcePostId : originalPostId;
    if (candidate.isEmpty) return '';

    final raw = await _postRepository.fetchPostRawById(
          candidate,
          preferCache: true,
        ) ??
        const <String, dynamic>{};
    if (raw.isEmpty) {
      return candidate;
    }

    final floodCount = raw['floodCount'];
    final isSeries = floodCount is num
        ? floodCount.toInt() > 1
        : int.tryParse('$floodCount') != null && int.parse('$floodCount') > 1;
    if (!isSeries) {
      return candidate;
    }

    final mainFlood = (raw['mainFlood'] ?? '').toString().trim();
    final isFlood = raw['flood'] == true;
    if (isFlood && mainFlood.isNotEmpty) {
      return mainFlood;
    }
    return candidate;
  }

  Future<void> applySharedSourceIfNeeded({
    required String videoUrl,
    required List<String> imageUrls,
    required double aspectRatio,
    required String thumbnail,
    required bool sharedAsPost,
    String? originalUserID,
    String? originalPostID,
    String? sourcePostID,
    bool quotedPost = false,
    String? quotedOriginalText,
    String? quotedSourceUserID,
    String? quotedSourceDisplayName,
    String? quotedSourceUsername,
    String? quotedSourceAvatarUrl,
  }) async {
    final cleanUrl = videoUrl.trim();
    final cleanImages =
        imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final fingerprint = [
      sharedAsPost,
      cleanUrl,
      cleanImages.join('|'),
      aspectRatio.toStringAsFixed(6),
      thumbnail.trim(),
      (originalUserID ?? '').trim(),
      (originalPostID ?? '').trim(),
      (sourcePostID ?? '').trim(),
      quotedPost,
      (quotedOriginalText ?? '').trim(),
      (quotedSourceUserID ?? '').trim(),
      (quotedSourceDisplayName ?? '').trim(),
      (quotedSourceUsername ?? '').trim(),
      (quotedSourceAvatarUrl ?? '').trim(),
    ].join('::');
    if (!sharedAsPost) {
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
      return;
    }
    if (_sharedSourceApplied && _sharedSourceFingerprint == fingerprint) return;
    _sharedSourceApplied = true;
    _sharedSourceFingerprint = fingerprint;

    _isSharedAsPost = true;
    _sharedOriginalUserID = (originalUserID ?? '').trim();
    _sharedOriginalPostID = (originalPostID ?? '').trim();
    _sharedSourcePostID = (sourcePostID ?? '').trim();
    _isQuotedPost = quotedPost;
    _quotedOriginalText = (quotedOriginalText ?? '').trim();
    _quotedSourceUserID = (quotedSourceUserID ?? '').trim();
    _quotedSourceDisplayName = (quotedSourceDisplayName ?? '').trim();
    _quotedSourceUsername = (quotedSourceUsername ?? '').trim();
    _quotedSourceAvatarUrl = (quotedSourceAvatarUrl ?? '').trim();
    await _hydrateQuotedSourceIfNeeded();

    const tag = '0';
    final c = CreatorContentController.ensure(tag: tag);
    if (cleanUrl.isNotEmpty) {
      await c.setReusedVideoSource(
        videoUrl: cleanUrl,
        aspectRatio: aspectRatio,
        thumbnail: thumbnail,
      );
    } else if (cleanImages.isNotEmpty) {
      await c.setReusedImageSources(
        cleanImages,
        aspectRatio: aspectRatio,
      );
    }
  }

  Future<void> applyEditSourceIfNeeded({
    required bool editMode,
    required PostsModel? editPost,
  }) async {
    if (!editMode || editPost == null) return;
    if (_editSourceApplied && editingPostID.value == editPost.docID) return;
    _editSourceApplied = true;

    isEditMode.value = true;
    editingPostID.value = editPost.docID;
    postList.value = [PostCreatorModel(index: 0, text: editPost.metin)];
    resetComposerItemIndexSeed(1);
    selectedIndex.value = 0;
    commentVisibility.value = editPost.yorumVisibility;
    comment.value = commentVisibility.value != 3;
    paylasimSelection.value = editPost.paylasimVisibility;

    const tag = '0';
    final c = CreatorContentController.ensure(tag: tag);
    c.textEdit.text = editPost.metin;
    c.textEdit.selection = TextSelection.fromPosition(
      TextPosition(offset: c.textEdit.text.length),
    );
  }

  Future<bool> savePostEdit() async {
    if (isSavingEdit.value) return false;
    final docID = editingPostID.value.trim();
    if (docID.isEmpty) {
      AppSnackbar(
        'common.error'.tr,
        'post_creator.edit_target_missing'.tr,
      );
      return false;
    }

    const tag = '0';
    final c = CreatorContentController.maybeFind(tag: tag);
    if (c == null) {
      AppSnackbar(
        'common.error'.tr,
        'post_creator.edit_content_missing'.tr,
      );
      return false;
    }
    final text = c.textEdit.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final yorumVisible = commentVisibility.value.clamp(0, 3);
    final reshVisible = paylasimSelection.value.clamp(0, 2);
    final update = <String, dynamic>{
      'metin': text,
      'editTime': now,
      'yorum': yorumVisible != 3,
      'yorumMap': {'visibility': yorumVisible},
      'paylasGizliligi': reshVisible,
      'reshareMap': {'visibility': reshVisible},
    };

    try {
      isSavingEdit.value = true;
      String targetDocID = docID;

      try {
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(targetDocID)
            .update(update);
      } on FirebaseException catch (e) {
        if (e.code != 'not-found') rethrow;
        final resolvedId = await _postRepository.resolveDocumentIdByLegacyId(
          docID,
          preferCache: true,
        );
        if (resolvedId == null) {
          rethrow;
        }
        targetDocID = resolvedId;
        await FirebaseFirestore.instance
            .collection('Posts')
            .doc(targetDocID)
            .update(update);
      }

      final agenda = AgendaController.maybeFind();
      if (agenda != null) {
        final idx = agenda.agendaList
            .indexWhere((e) => e.docID == docID || e.docID == targetDocID);
        if (idx != -1) {
          final old = agenda.agendaList[idx];
          agenda.agendaList[idx] = old.copyWith(
            metin: text,
            editTime: now,
            yorum: yorumVisible != 3,
            yorumMap: {'visibility': yorumVisible},
            paylasGizliligi: reshVisible,
            reshareMap: {'visibility': reshVisible},
          );
          agenda.agendaList.refresh();
        }
      }

      try {
        ProfileController.maybeFind()?.fetchPosts(isInitial: true);
      } catch (_) {}

      AppSnackbar(
        'common.success'.tr,
        'post_creator.edit_updated'.tr,
      );
      return true;
    } catch (e) {
      String msg = 'post_creator.edit_update_failed'.tr;
      if (e is FirebaseException &&
          e.message != null &&
          e.message!.trim().isNotEmpty) {
        msg = e.message!.trim();
      }
      AppSnackbar('common.error'.tr, msg);
      return false;
    } finally {
      isSavingEdit.value = false;
    }
  }
}
