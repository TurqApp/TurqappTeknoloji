part of 'post_creator_controller.dart';

extension PostCreatorControllerFlowPart on PostCreatorController {
  String _normalizeHandleValue(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return '';
    if (value.contains(RegExp(r'\s'))) return '';
    return value.replaceFirst(RegExp(r'^@+'), '');
  }

  String _firstNonEmptyValue(Iterable<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<({String nickname, String username, String fullName, String displayName, String avatarUrl, String rozet})>
      _resolveAuthorSummary() async {
    final current = CurrentUserService.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? current.userId;
    final userRaw = uid.isNotEmpty
        ? await UserRepository.ensure().getUserRaw(
              uid,
              preferCache: true,
              cacheOnly: false,
            ) ??
            const <String, dynamic>{}
        : const <String, dynamic>{};

    final nickname = _firstNonEmptyValue([
      _normalizeHandleValue(userRaw['nickname']),
      _normalizeHandleValue(current.nickname),
    ]);

    final username = _firstNonEmptyValue([
      _normalizeHandleValue(userRaw['username']),
      _normalizeHandleValue(userRaw['usernameLower']),
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
    try {
      _errorService = Get.put(ErrorHandlingService());
      _networkService = Get.put(NetworkAwarenessService());
      _uploadQueueService = Get.put(UploadQueueService());
      _draftService = Get.put(DraftService());
    } catch (_) {}
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
          'Anket',
          'Anket için açıklama veya görsel/video gerekli.',
        );
        return false;
      }
    }
    return true;
  }

  void _showModerationSnackbarOnce(String title, String message) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - PostCreatorController._lastModerationSnackbarAtMs < 1500) {
      return;
    }
    PostCreatorController._lastModerationSnackbarAtMs = nowMs;
    AppSnackbar(title, message);
  }

  Future<bool> _runModerationPreflightForComposer() async {
    for (final postModel in postList) {
      final controller = ensureComposerControllerFor(postModel.index);

      for (final image in controller.selectedImages) {
        final nsfwImage = await OptimizedNSFWService.checkImage(image);
        if (nsfwImage.errorMessage != null) {
          _showModerationSnackbarOnce(
            'Yükleme Başarısız',
            'İçerik güvenlik kontrolü tamamlanamadı.',
          );
          return false;
        }
        if (nsfwImage.isNSFW) {
          _showModerationSnackbarOnce(
            'Yükleme Başarısız',
            'Bu görsel yüklenemiyor.',
          );
          return false;
        }
      }

      final video = controller.selectedVideo.value;
      if (video != null) {
        final nsfwVideo = await OptimizedNSFWService.checkVideo(video);
        if (nsfwVideo.errorMessage != null) {
          _showModerationSnackbarOnce(
            'Yükleme Başarısız',
            'İçerik güvenlik kontrolü tamamlanamadı.',
          );
          return false;
        }
        if (nsfwVideo.isNSFW) {
          _showModerationSnackbarOnce(
            'Yükleme Başarısız',
            'Bu video yüklenemiyor.',
          );
          return false;
        }
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
        userMessage: 'Taslak kaydetme başarısız',
        showToUser: false,
      );
    }
  }

  void uploadAllPostsInBackgroundWithErrorHandling() async {
    if (isPublishing.value) return;
    isPublishing.value = true;
    try {
      if (!_networkService.isConnected) {
        await _errorService.handleError(
          'No internet connection',
          category: ErrorCategory.network,
          severity: ErrorSeverity.high,
          userMessage: 'İnternet bağlantısı bulunamadı',
          isRetryable: true,
          metadata: {'userInitiated': true},
        );
        return;
      }

      final progressController = Get.find<UploadProgressController>();
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
        );
        if (!perPostValidation.isValid) {
          await _errorService.handleError(
            perPostValidation.errorMessage ?? 'Validation failed',
            category: ErrorCategory.validation,
            severity: ErrorSeverity.medium,
            userMessage: perPostValidation.errorMessage ??
                'Gönderi doğrulaması başarısız',
          );
          return;
        }
      }

      for (final image in allImages) {
        final fileSize = await image.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).round();

        if (!_networkService.shouldAllowUpload(fileSizeMB: fileSizeMB)) {
          final recommendation =
              _networkService.getUploadRecommendation(fileSizeMB: fileSizeMB);
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
              'Gönderi doğrulaması başarısız',
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
        initialStatus: 'Gönderiler hazırlanıyor...',
      );

      if (_networkService.isOnCellular &&
          !_networkService.settings.autoUploadOnWiFi) {
        await _addToUploadQueue(progressController);
      } else {
        await _uploadDirectly(progressController);
      }
    } catch (e, stackTrace) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'Gönderi yükleme başarısız',
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
      for (int index = 0; index < postList.length; index++) {
        final postModel = postList[index];
        final controller = ensureComposerControllerFor(postModel.index);
        final docID = '${queueUuid}_$index';

        final authorSummary = await _resolveAuthorSummary();
        final postData = {
          'id': docID,
          'text': controller.textEdit.text.trim(),
          'location': '',
          'gif': controller.gif.value,
          'userID': FirebaseAuth.instance.currentUser!.uid,
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
          'scheduledAt':
              _normalizedIzBirakDateTime()?.millisecondsSinceEpoch ?? 0,
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
                scheduledAt > 0
                    ? scheduledAt
                    : DateTime.now().millisecondsSinceEpoch,
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
          createdAt: DateTime.now(),
        );

        final added = await _uploadQueueService.addToQueue(
          queuedUpload,
          startProcessing: false,
        );
        if (added) {
          addedCount++;
        }
      }

      if (addedCount == 0) {
        progressController.complete('Bu medya zaten yükleme kuyruğunda.');
        return;
      }

      _uploadQueueService.processPendingQueue();

      progressController
          .complete('Gönderiler kuyruğa eklendi! Arka planda yüklenecek.');
      AppSnackbar(
        'Yükleme Kuyruğu',
        'Gönderiler arka plan kuyruğuna eklendi',
        backgroundColor: Colors.green.withValues(alpha: 0.7),
      );
    } catch (e) {
      await _errorService.handleError(
        e,
        category: ErrorCategory.upload,
        severity: ErrorSeverity.high,
        userMessage: 'Kuyruk ekleme başarısız',
        isRetryable: true,
      );
    }
  }

  void _startQueueRingMonitor() {
    final nav = _maybeNavBarController();
    nav?.uploadingPosts.value = true;
    _queueRingTimer?.cancel();
    _queueRingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final stats = _uploadQueueService.getQueueStats();
      final pending = (stats['pending'] as int?) ?? 0;
      final processing = (stats['processing'] as bool?) ?? false;
      if (!processing && pending == 0) {
        nav?.uploadingPosts.value = false;
        timer.cancel();
      }
    });
  }
}
