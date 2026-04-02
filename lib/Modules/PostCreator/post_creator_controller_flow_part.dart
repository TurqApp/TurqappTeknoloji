part of 'post_creator_controller.dart';

extension PostCreatorControllerFlowPart on PostCreatorController {
  String _firstNonEmptyValue(Iterable<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<
      ({
        String nickname,
        String username,
        String fullName,
        String displayName,
        String avatarUrl,
        String rozet
      })> _resolveAuthorSummary() async {
    final current = CurrentUserService.instance;
    final uid = current.userId;
    final userRaw = uid.isNotEmpty
        ? await UserRepository.ensure().getUserRaw(
              uid,
              preferCache: true,
              cacheOnly: false,
            ) ??
            const <String, dynamic>{}
        : const <String, dynamic>{};

    final nickname = _firstNonEmptyValue([
      normalizeHandleInput(userRaw['nickname']?.toString() ?? ''),
      normalizeHandleInput(current.nickname),
    ]);

    final username = _firstNonEmptyValue([
      normalizeHandleInput(userRaw['username']?.toString() ?? ''),
      normalizeHandleInput(userRaw['usernameLower']?.toString() ?? ''),
    ]);

    final displayName = _firstNonEmptyValue([
      (userRaw['displayName'] ?? '').toString().trim(),
      (userRaw['fullName'] ?? '').toString().trim(),
      [
        (userRaw['firstName'] ?? '').toString().trim(),
        (userRaw['lastName'] ?? '').toString().trim(),
      ].where((e) => e.isNotEmpty).join(' ').trim(),
      current.fullName.trim(),
      nickname,
    ]);

    final fullName = _firstNonEmptyValue([
      displayName,
      (userRaw['displayName'] ?? '').toString().trim(),
      (userRaw['fullName'] ?? '').toString().trim(),
      [
        (userRaw['firstName'] ?? '').toString().trim(),
        (userRaw['lastName'] ?? '').toString().trim(),
      ].where((e) => e.isNotEmpty).join(' ').trim(),
      current.fullName.trim(),
      nickname,
    ]);

    final avatarUrl = _firstNonEmptyValue([
      (userRaw['avatarUrl'] ?? '').toString().trim(),
      (userRaw['profileImage'] ?? '').toString().trim(),
      (userRaw['photoUrl'] ?? '').toString().trim(),
      (userRaw['imageUrl'] ?? '').toString().trim(),
      current.avatarUrl.trim(),
    ]);

    final rozet = _firstNonEmptyValue([
      (userRaw['rozet'] ?? '').toString().trim(),
      current.currentUser?.rozet.trim() ?? '',
    ]);

    return (
      nickname: nickname,
      username: username,
      fullName: fullName,
      displayName: displayName,
      avatarUrl: avatarUrl,
      rozet: rozet,
    );
  }

  void _initializeServices() {
    try {} catch (_) {}
  }

  Map<String, dynamic> _normalizePollForSave(
      Map<String, dynamic> poll, int createdAtMs) {
    final normalized = Map<String, dynamic>.from(poll);
    final options = (normalized['options'] is List)
        ? List<Map<String, dynamic>>.from(
            (normalized['options'] as List)
                .map((o) => Map<String, dynamic>.from(o)),
          )
        : <Map<String, dynamic>>[];
    int totalVotes = 0;
    for (final opt in options) {
      final v = opt['votes'];
      final int votes = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
      opt['votes'] = votes;
      totalVotes += votes;
    }
    normalized['options'] = options;
    normalized['totalVotes'] = totalVotes;
    normalized['durationHours'] =
        (normalized['durationHours'] is num) ? normalized['durationHours'] : 24;
    normalized['createdDate'] = createdAtMs;
    normalized['userVotes'] = normalized['userVotes'] is Map
        ? Map<String, dynamic>.from(normalized['userVotes'])
        : <String, dynamic>{};
    return normalized;
  }

  bool _validatePollRequirements() {
    for (final postModel in postList) {
      final controller = ensureComposerControllerFor(postModel.index);
      final poll = controller.pollData.value;
      if (poll == null || poll.isEmpty) continue;
      final hasCaption = controller.textEdit.text.trim().isNotEmpty;
      final hasMedia = controller.croppedImages.isNotEmpty ||
          controller.reusedImageUrls.isNotEmpty ||
          controller.selectedImages.isNotEmpty ||
          controller.selectedVideo.value != null;
      if (!hasCaption && !hasMedia) {
        AppSnackbar(
          'post_creator.poll_title'.tr,
          'post_creator.poll_requirement'.tr,
        );
        return false;
      }
    }
    return true;
  }

  void _showModerationSnackbarOnce(String title, String message) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastModerationSnackbarAtMs < 1500) {
      return;
    }
    _lastModerationSnackbarAtMs = nowMs;
    AppSnackbar(title, message);
  }

  Future<bool> _runModerationPreflightForComposer() async {
    for (final postModel in postList) {
      final controller = ensureComposerControllerFor(postModel.index);
      final text = controller.textEdit.text.trim();

      if (text.isNotEmpty) {
        final blockedMatch = await kufurEslesmesiniBul(text);
        if (blockedMatch != null) {
          final blockedWord = blockedMatch.displayValue.replaceAll('"', "'");
          _showModerationSnackbarOnce(
            '',
            'comments.community_violation_body_with_word'.trParams({
              'word': blockedWord,
            }),
          );
          return false;
        }
      }

      for (final image in controller.selectedImages) {
        final nsfwImage = await OptimizedNSFWService.checkImage(image);
        if (nsfwImage.errorMessage != null) {
          _showModerationSnackbarOnce(
            'post_creator.upload_failed_title'.tr,
            'post_creator.upload_failed_message'.tr,
          );
          return false;
        }
        if (nsfwImage.isNSFW) {
          _showModerationSnackbarOnce(
            'post_creator.upload_failed_title'.tr,
            'post_creator.image_rejected'.tr,
          );
          return false;
        }
      }

      final video = controller.selectedVideo.value;
      if (video != null) {
        final nsfwVideo = await OptimizedNSFWService.checkVideo(video);
        if (nsfwVideo.errorMessage != null) {
          _showModerationSnackbarOnce(
            'post_creator.upload_failed_title'.tr,
            'post_creator.upload_failed_message'.tr,
          );
          return false;
        }
        if (nsfwVideo.isNSFW) {
          _showModerationSnackbarOnce(
            'post_creator.upload_failed_title'.tr,
            'post_creator.video_rejected'.tr,
          );
          return false;
        }
      }
    }
    return true;
  }

  bool _validateCaptionLengths() {
    final maxCaptionLength = PostCaptionLimits.forCurrentUser();
    for (final postModel in postList) {
      final controller = ensureComposerControllerFor(postModel.index);
      final validation = UploadValidationService.validateTextLength(
        controller.textEdit.text,
        maxLength: maxCaptionLength,
      );
      if (!validation.isValid) {
        UploadValidationService.showValidationError(
          validation.errorMessage ?? 'upload_validation.error_title'.tr,
        );
        return false;
      }
    }
    return true;
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _draftService.autoSaveInterval),
      (_) => _saveCurrentDraft(),
    );
  }

  Future<void> _saveCurrentDraft() async {
    if (!_draftService.autoSaveEnabled) return;

    try {
      for (final postModel in postList) {
        final controller = ensureComposerControllerFor(postModel.index);
        final text = controller.textEdit.text.trim();

        if (text.isNotEmpty ||
            controller.selectedImages.isNotEmpty ||
            controller.reusedImageUrls.isNotEmpty ||
            controller.selectedVideo.value != null ||
            controller.gif.value.isNotEmpty) {
          await _draftService.saveDraft(
            text: text,
            images: controller.selectedImages,
            video: controller.selectedVideo.value,
            location: '',
            gif: controller.gif.value,
            commentEnabled: comment.value,
            sharePrivacy: paylasimSelection.value,
            scheduledDate: _normalizedIzBirakDateTime(),
          );
        }
      }
    } catch (e) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.storage,
        severity: ErrorSeverity.low,
        userMessage: 'post_creator.draft_save_failed'.tr,
        showToUser: false,
      );
    }
  }

  void uploadAllPostsInBackgroundWithErrorHandling() async {
    if (isPublishing.value) return;
    isPublishing.value = true;
    try {
      if (!_validateCaptionLengths()) {
        return;
      }

      if (!_networkRuntimeService.isConnected) {
        await _errorService.handleError(
          'No internet connection',
          category: ErrorCategory.network,
          severity: ErrorSeverity.high,
          userMessage: 'post_creator.no_internet'.tr,
          isRetryable: true,
          metadata: {'userInitiated': true},
        );
        return;
      }

      final progressController = ensureUploadProgressController();
      final allImages = <File>[];
      final allVideos = <File>[];

      for (final postModel in postList) {
        final c = ensureComposerControllerFor(postModel.index);

        allImages.addAll(c.selectedImages);
        if (c.selectedVideo.value != null) {
          allVideos.add(c.selectedVideo.value!);
        }

        final perPostValidation = await UploadValidationService.validatePost(
          images: c.selectedImages.toList(),
          videos: c.selectedVideo.value != null
              ? [c.selectedVideo.value!]
              : const <File>[],
          text: (c.reusedVideoUrl.value.trim().isNotEmpty ||
                  c.reusedImageUrls.isNotEmpty)
              ? 'media'
              : c.textEdit.text.trim(),
          maxTextLength: PostCaptionLimits.forCurrentUser(),
        );
        if (!perPostValidation.isValid) {
          await _errorService.handleError(
            perPostValidation.errorMessage ?? 'Validation failed',
            category: ErrorCategory.validation,
            severity: ErrorSeverity.medium,
            userMessage: perPostValidation.errorMessage ??
                'post_creator.validation_failed'.tr,
          );
          return;
        }
      }

      for (final image in allImages) {
        final fileSize = await image.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).round();

        if (!_networkRuntimeService.shouldAllowUpload(fileSizeMB: fileSizeMB)) {
          final recommendation = _networkRuntimeService.getUploadRecommendation(
            fileSizeMB: fileSizeMB,
          );
          await _errorService.handleError(
            'Upload not recommended',
            category: ErrorCategory.network,
            severity: ErrorSeverity.medium,
            userMessage: recommendation['reason'],
            metadata: {
              ...recommendation,
              'userInitiated': true,
            },
          );
          return;
        }
      }

      final totalSizeValidation = UploadValidationService.validateTotalPostSize(
        allImages,
        allVideos,
      );
      if (!totalSizeValidation.isValid) {
        await _errorService.handleError(
          totalSizeValidation.errorMessage ?? 'Validation failed',
          category: ErrorCategory.validation,
          severity: ErrorSeverity.medium,
          userMessage: totalSizeValidation.errorMessage ??
              'post_creator.validation_failed'.tr,
        );
        return;
      }

      if (!await _runModerationPreflightForComposer()) {
        return;
      }

      Get.back();

      final totalPosts = postList.length;
      progressController.startProgress(
        total: totalPosts,
        initialStatus: 'post_creator.uploading_media'.tr,
      );

      if (_networkRuntimeService.isOnCellular &&
          !_networkRuntimeService.settings.autoUploadOnWiFi) {
        await _addToUploadQueue(progressController);
      } else {
        await _uploadDirectly(progressController);
      }
    } catch (e, stackTrace) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'post_creator.upload_failed_generic'.tr,
        stackTrace: stackTrace,
        isRetryable: true,
        metadata: {
          'postCount': postList.length,
          'publishMode': publishMode.value,
        },
      );
    } finally {
      isPublishing.value = false;
    }
  }

  Future<void> _addToUploadQueue(
      UploadProgressController progressController) async {
    try {
      _startQueueRingMonitor();
      if (!_validatePollRequirements()) return;
      var addedCount = 0;
      final queueUuid = const Uuid().v4();
      final batchCreatedAt = DateTime.now();
      final normalizedScheduledAt =
          _normalizedIzBirakDateTime()?.millisecondsSinceEpoch ?? 0;
      final batchTimeStamp = normalizedScheduledAt != 0
          ? normalizedScheduledAt
          : batchCreatedAt.millisecondsSinceEpoch;
      for (int index = 0; index < postList.length; index++) {
        final postModel = postList[index];
        final controller = ensureComposerControllerFor(postModel.index);
        final hasText = controller.textEdit.text.trim().isNotEmpty;
        final hasImages = controller.croppedImages.isNotEmpty ||
            controller.selectedImages.isNotEmpty ||
            controller.reusedImageUrls.isNotEmpty;
        final hasVideo = controller.selectedVideo.value != null ||
            controller.reusedVideoUrl.value.trim().isNotEmpty;
        final hasGif = controller.gif.value.trim().isNotEmpty;
        final hasPoll = controller.pollData.value != null &&
            (controller.pollData.value?['options'] is List) &&
            (controller.pollData.value!['options'] as List).isNotEmpty;
        if (!(hasText || hasImages || hasVideo || hasGif || hasPoll)) {
          continue;
        }
        final docID = '${queueUuid}_$index';

        final authorSummary = await _resolveAuthorSummary();
        final postData = {
          'id': docID,
          'text': controller.textEdit.text.trim(),
          'location': '',
          'gif': controller.gif.value,
          'userID': CurrentUserService.instance.effectiveUserId,
          'authorNickname': authorSummary.nickname,
          'authorDisplayName': authorSummary.displayName,
          'authorAvatarUrl': authorSummary.avatarUrl,
          'nickname': authorSummary.nickname,
          'username': authorSummary.username,
          'fullName': authorSummary.fullName,
          'displayName': authorSummary.displayName,
          'avatarUrl': authorSummary.avatarUrl,
          'rozet': authorSummary.rozet,
          'sourceImagePaths':
              controller.selectedImages.map((f) => f.path).toList(),
          'sourceVideoPath': controller.selectedVideo.value?.path ?? '',
          'yorumMap': {
            'visibility': commentVisibility.value,
          },
          'reshareMap': {
            'visibility': paylasimSelection.value,
          },
          if (controller.pollData.value != null)
            'poll': controller.pollData.value,
          'sharedAsPost': _isSharedAsPost,
          'originalUserID': _sharedOriginalUserID,
          'originalPostID': _sharedOriginalPostID,
          'sourcePostID': _sharedSourcePostID,
          'quotedPost': _isSharedAsPost ? _isQuotedPost : false,
          'quotedOriginalText':
              (_isSharedAsPost && _isQuotedPost) ? _quotedOriginalText : '',
          'quotedSourceUserID':
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUserID : '',
          'quotedSourceDisplayName': (_isSharedAsPost && _isQuotedPost)
              ? _quotedSourceDisplayName
              : '',
          'quotedSourceUsername':
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceUsername : '',
          'quotedSourceAvatarUrl':
              (_isSharedAsPost && _isQuotedPost) ? _quotedSourceAvatarUrl : '',
          'scheduledAt': normalizedScheduledAt,
          'timeStamp': batchTimeStamp,
        };

        final imagePaths = <String>[];
        if (controller.croppedImages.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          for (int i = 0; i < controller.croppedImages.length; i++) {
            final data = controller.croppedImages[i];
            if (data == null) continue;
            final filePath = p.join(
              tempDir.path,
              'upload_${docID}_$i.webp',
            );
            final f = File(filePath);
            await f.writeAsBytes(data, flush: true);
            imagePaths.add(filePath);
          }
        } else {
          imagePaths.addAll(controller.selectedImages.map((f) => f.path));
        }

        final poll = controller.pollData.value ?? const {};
        final int scheduledAt = (postData['scheduledAt'] is num)
            ? postData['scheduledAt'] as int
            : 0;
        final pollPayload = (poll.isNotEmpty)
            ? _normalizePollForSave(
                poll,
                scheduledAt > 0 ? scheduledAt : batchTimeStamp,
              )
            : null;
        if (pollPayload != null) {
          postData['poll'] = pollPayload;
        }

        final queuedUpload = QueuedUpload(
          id: docID,
          postData: jsonEncode(postData),
          imagePaths: imagePaths,
          videoPath: controller.selectedVideo.value?.path,
          createdAt: batchCreatedAt,
        );

        final added = await _uploadQueueRuntimeService.addToQueue(
          queuedUpload,
          startProcessing: false,
        );
        if (added) {
          addedCount++;
        }
      }

      if (addedCount == 0) {
        progressController.complete('post_creator.queue_already_added'.tr);
        return;
      }

      _uploadQueueRuntimeService.processPendingQueue();

      progressController.complete('post_creator.queue_added_complete'.tr);
      AppSnackbar(
        '',
        'post_creator.queue_added_body'.tr,
        backgroundColor: Colors.green.withValues(alpha: 0.7),
      );
    } catch (e) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'post_creator.queue_add_failed'.tr,
        isRetryable: true,
      );
    }
  }

  void _startQueueRingMonitor() {
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;
    _queueRingTimer?.cancel();
    _queueRingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final stats = _uploadQueueRuntimeService.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      if (!processing && pending == 0) {
        nav?.uploadingPosts.value = false;
        timer.cancel();
      }
    });
  }
}
