part of 'story_maker_controller.dart';

extension StoryMakerControllerSavePart on StoryMakerController {
  void onScheduleStoryPressed() async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishStory)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar("common.error".tr, "story.no_user".tr);
      return;
    }
    if (elements.isEmpty) {
      AppSnackbar("common.error".tr, "story.empty_elements".tr);
      return;
    }

    final now = DateTime.now();
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (scheduledAt.isBefore(now)) {
      AppSnackbar("common.error".tr, "story.past_time_invalid".tr);
      return;
    }

    final elementsSnapshot = List<StoryElement>.from(elements);
    final musicSnapshot = music.value;
    final selectedMusicSnapshot = selectedMusic.value;
    final colorSnapshot = color.value;

    StoryMakerController.isUploadingStory.value = true;
    Get.back();

    _saveStoryBackground(
      user,
      elementsSnapshot,
      colorSnapshot,
      musicSnapshot,
      selectedMusicSnapshot: selectedMusicSnapshot,
      scheduledAt: scheduledAt,
    );
  }

  void onSaveStoryPressed() {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.publishStory)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar("common.error".tr, "story.no_user".tr);
      return;
    }

    if (elements.isEmpty) {
      AppSnackbar("common.error".tr, "story.empty_elements".tr);
      return;
    }
    final elementsSnapshot = List<StoryElement>.from(elements);
    final musicSnapshot = music.value;
    final selectedMusicSnapshot = selectedMusic.value;
    final colorSnapshot = color.value;

    StoryMakerController.isUploadingStory.value = true;
    Get.back();

    _saveStoryBackground(
      user,
      elementsSnapshot,
      colorSnapshot,
      musicSnapshot,
      selectedMusicSnapshot: selectedMusicSnapshot,
    );
  }

  Future<void> _saveStoryBackground(
    User user,
    List<StoryElement> elementsSnapshot,
    Color colorSnapshot,
    String musicSnapshot, {
    MusicModel? selectedMusicSnapshot,
    DateTime? scheduledAt,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('stories').doc();
      final storyId = docRef.id;

      final elementsCopy = List<StoryElement>.from(elementsSnapshot);

      if (elementsCopy.isEmpty) {
        AppSnackbar("common.error".tr, "story.empty_elements".tr);
        return;
      }

      final List<Map<String, dynamic>> serialized = [];
      for (final e in elementsCopy) {
        String url = e.content;
        final uri = Uri.tryParse(e.content.trim());
        final isRemoteSource = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.hasAuthority;
        if (isRemoteSource) {
          url = CdnUrlBuilder.toCdnUrl(e.content.trim());
        } else if (e.type == StoryElementType.image ||
            e.type == StoryElementType.video ||
            e.type == StoryElementType.drawing) {
          final file = File(e.content);
          if (!file.existsSync()) {
            debugPrint("Story media source missing");
            continue;
          }
          final ts = DateTime.now().millisecondsSinceEpoch;
          final uid = user.uid;
          if (e.type == StoryElementType.video) {
            final ext = path.extension(file.path);
            final ref =
                FirebaseStorage.instance.ref('stories/$uid/$storyId/$ts$ext');
            final task = await ref.putFile(
              file,
              SettableMetadata(
                contentType: 'video/mp4',
                cacheControl: 'public, max-age=31536000, immutable',
              ),
            );
            url = CdnUrlBuilder.toCdnUrl(await task.ref.getDownloadURL());
          } else {
            final downloadUrl = await WebpUploadService.uploadFileAsWebp(
              storage: FirebaseStorage.instance,
              file: file,
              storagePathWithoutExt: 'stories/$uid/$storyId/$ts',
            );
            url = CdnUrlBuilder.toCdnUrl(downloadUrl);
          }
        }
        serialized.add({
          'type': e.type.toString().split('.').last,
          'content': url,
          'width': e.width,
          'height': e.height,
          'position': {'x': e.position.dx, 'y': e.position.dy},
          'rotation': e.rotation,
          'zIndex': e.zIndex,
          'isMuted': e.isMuted,
          'fontSize': e.fontSize,
          'aspectRatio': e.aspectRatio,
          'textColor': e.textColor,
          'textBgColor': e.textBgColor,
          'hasTextBg': e.hasTextBg,
          'textAlign': e.textAlign,
          'fontWeight': e.fontWeight,
          'italic': e.italic,
          'underline': e.underline,
          'shadowBlur': e.shadowBlur,
          'shadowOpacity': e.shadowOpacity,
          'fontFamily': e.fontFamily,
          'hasOutline': e.hasOutline,
          'outlineColor': e.outlineColor,
          'stickerType': e.stickerType,
          'stickerData': e.stickerData,
          'mediaLookPreset': e.mediaLookPreset,
        });
      }

      if (serialized.isEmpty) {
        AppSnackbar("common.error".tr, "story.no_elements_saved".tr);
        return;
      }

      final storyData = <String, dynamic>{
        'userId': user.uid,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'backgroundColor': colorSnapshot.toARGB32(),
        'musicId': selectedMusicSnapshot?.docID ?? '',
        'musicUrl': musicSnapshot,
        'musicTitle': selectedMusicSnapshot?.title ?? '',
        'musicArtist': selectedMusicSnapshot?.artist ?? '',
        'musicCoverUrl': selectedMusicSnapshot?.coverUrl ?? '',
        'elements': serialized,
        'deleted': scheduledAt != null,
        'deletedAt': 0,
      };
      if (scheduledAt != null) {
        storyData['scheduledAt'] = scheduledAt.millisecondsSinceEpoch;
        storyData['deleteReason'] = 'scheduled';
      }
      await docRef.set(storyData);
      if (selectedMusicSnapshot != null && scheduledAt == null) {
        unawaited(
          StoryMusicLibraryService.instance.recordStoryUsage(
            track: selectedMusicSnapshot,
            storyId: storyId,
            userId: user.uid,
            createdAt: storyData['createdDate'] as int? ??
                DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      try {
        if (_audioPlayer.state != PlayerState.disposed) {
          await _audioPlayer.stop();
        }
      } catch (e) {
        debugPrint("AudioPlayer stop error (ignored): $e");
      }

      try {
        await StoryRowController.maybeFind()?.loadStories();
      } catch (e) {
        debugPrint("Story UI refresh error: $e");
      }
    } catch (err) {
      AppSnackbar(
        "common.error".tr,
        "story.save_failed".trParams({"error": err.toString()}),
      );
      debugPrint("saveStory error: $err");
    } finally {
      StoryMakerController.isUploadingStory.value = false;
    }
  }
}
