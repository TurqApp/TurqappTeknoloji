part of 'story_music_admin_view.dart';

extension StoryMusicAdminViewActionsPart on _StoryMusicAdminViewState {
  void _resetForm() {
    _updateViewState(() {
      _editingDocId = '';
      _isActive = true;
      _titleController.clear();
      _artistController.clear();
      _audioUrlController.clear();
      _coverUrlController.clear();
      _categoryController.clear();
      _orderController.clear();
    });
  }

  void _loadTrack(MusicModel track) {
    _updateViewState(() {
      _editingDocId = track.docID;
      _isActive = track.isActive;
      _titleController.text = track.title;
      _artistController.text = track.artist;
      _audioUrlController.text = track.audioUrl;
      _coverUrlController.text = track.coverUrl;
      _categoryController.text = track.category;
      _orderController.text = track.order > 0 ? track.order.toString() : '';
    });
  }

  Future<int> _resolveNextOrder() async {
    return _libraryService.fetchNextOrder();
  }

  Future<void> _loadTracks({bool forceRemote = false}) async {
    if (!mounted) return;
    _updateViewState(() => _isLoadingTracks = true);
    try {
      final tracks = await _libraryService.fetchAdminTracks(
        preferCache: !forceRemote,
        forceRemote: forceRemote,
      );
      if (!mounted) return;
      _updateViewState(() {
        _tracks
          ..clear()
          ..addAll(tracks);
      });
    } finally {
      if (mounted) {
        _updateViewState(() => _isLoadingTracks = false);
      }
    }
  }

  Future<void> _pickCover() async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    _updateViewState(() => _isBusy = true);
    try {
      final itemId = _editingDocId.isNotEmpty
          ? _editingDocId
          : DateTime.now().millisecondsSinceEpoch.toString();
      final coverUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: 'storyMusic/$itemId/cover',
      );
      _coverUrlController.text = coverUrl;
      AppSnackbar(
        'post_creator.success_title'.tr,
        'admin.story_music.cover_uploaded'.tr,
      );
      _updateViewState(() {});
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.story_music.cover_upload_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        _updateViewState(() => _isBusy = false);
      }
    }
  }

  Future<void> _saveTrack() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleController.text.trim();
    final audioUrl = _audioUrlController.text.trim();
    final artist = _artistController.text.trim();
    final coverUrl = _coverUrlController.text.trim();
    final category = _categoryController.text.trim();

    if (title.isEmpty || audioUrl.isEmpty) {
      AppSnackbar(
        'support.error_title'.tr,
        'admin.story_music.title_url_required'.tr,
      );
      return;
    }

    _updateViewState(() => _isBusy = true);
    try {
      final docId = _editingDocId.isNotEmpty
          ? _editingDocId
          : DateTime.now().millisecondsSinceEpoch.toString();
      final order = int.tryParse(_orderController.text.trim()) ??
          (_editingDocId.isNotEmpty ? 0 : await _resolveNextOrder());
      final now = DateTime.now().millisecondsSinceEpoch;

      final current = _editingDocId.isNotEmpty
          ? await _libraryService.fetchTrackById(docId, preferCache: true)
          : null;
      final existingUseCount = current?.useCount ?? 0;
      final existingShareCount = current?.shareCount ?? 0;
      final existingStoryCount = current?.storyCount ?? 0;
      final existingLastUsedAt = current?.lastUsedAt ?? 0;
      final existingCreatedAt = current?.createdAt ?? now;

      await _collection.doc(docId).set({
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'durationMs': current?.durationMs ?? 0,
        'useCount': existingUseCount,
        'shareCount': existingShareCount,
        'storyCount': existingStoryCount,
        'order': order,
        'isActive': _isActive,
        'category': category,
        'lastUsedAt': existingLastUsedAt,
        'createdAt': existingCreatedAt,
        'updatedAt': now,
      }, SetOptions(merge: true));

      AppSnackbar(
        'post_creator.success_title'.tr,
        _editingDocId.isEmpty
            ? 'admin.story_music.track_added'.tr
            : 'admin.story_music.track_updated'.tr,
      );
      _resetForm();
      await _loadTracks(forceRemote: true);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.story_music.save_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        _updateViewState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteTrack(MusicModel track) async {
    _updateViewState(() => _isBusy = true);
    try {
      await _collection.doc(track.docID).delete();
      if (_editingDocId == track.docID) {
        _resetForm();
      }
      await _loadTracks(forceRemote: true);
      AppSnackbar(
        'post_creator.success_title'.tr,
        'admin.story_music.track_deleted'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.story_music.delete_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        _updateViewState(() => _isBusy = false);
      }
    }
  }

  Future<void> _togglePreview(MusicModel track) async {
    final url = track.audioUrl.trim();
    if (url.isEmpty) return;
    if (_currentPreviewUrl == url) {
      await _audioPlayer.stop();
      _updateViewState(() => _currentPreviewUrl = '');
      return;
    }
    try {
      await _audioPlayer.stop();
      await AudioFocusCoordinator.instance.requestAudioPlayerPlay(
        _audioPlayer,
      );
      await _audioPlayer.play(UrlSource(url));
      _updateViewState(() => _currentPreviewUrl = url);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.story_music.preview_failed'.tr}: $e',
      );
    }
  }
}
