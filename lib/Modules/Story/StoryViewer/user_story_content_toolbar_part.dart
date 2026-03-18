// ignore_for_file: invalid_use_of_protected_member

part of 'user_story_content.dart';

extension UserStoryContentToolbarPart on _UserStoryContentState {
  Widget myToolBar() {
    final currentStory = widget.user.stories[storyIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction counts for my story
          Obx(() {
            final counts = controller.reactionCounts;
            if (counts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: counts.entries
                    .where((e) => e.value > 0)
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 3),
                              Text(
                                e.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _pauseStoryAudio();
                    _timer?.cancel();
                    await controller.showPostCommentsBottomSheet(
                        currentStory.id,
                        widget.user.nickname,
                        widget.user.userID ==
                            FirebaseAuth.instance.currentUser!.uid,
                        onClosed: (v) {
                      _startProgress();
                      unawaited(_resumeStoryAudio());
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.bubble_left_bubble_right,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    unawaited(_pauseStoryAudio());
                    _timer?.cancel();
                    controller.showLikesBottomSheet(currentStory.id,
                        onClosed: (v) {
                      _startProgress();
                      unawaited(_resumeStoryAudio());
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_thumbsup,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              GestureDetector(
                onTap: () {
                  unawaited(_pauseStoryAudio());
                  _timer?.cancel();
                  controller.showSeensBottomSheet(currentStory.id,
                      onClosed: (v) {
                    _startProgress();
                    unawaited(_resumeStoryAudio());
                  });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(50), shape: BoxShape.circle),
                  child: Icon(
                    CupertinoIcons.eyeglasses,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // One Cikar (Highlight) button
              GestureDetector(
                onTap: () {
                  unawaited(_pauseStoryAudio());
                  _timer?.cancel();
                  Get.bottomSheet(
                    HighlightPickerSheet(storyId: currentStory.id),
                    isScrollControlled: true,
                    ignoreSafeArea: false,
                    isDismissible: true,
                    enableDrag: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    backgroundColor: Colors.white,
                  ).then((_) {
                    _startProgress();
                    unawaited(_resumeStoryAudio());
                  });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bookmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Download button
              GestureDetector(
                onTap: () async {
                  try {
                    _timer?.cancel();
                    final boundary = _repaintKey.currentContext
                        ?.findRenderObject() as RenderRepaintBoundary?;
                    if (boundary == null) return;
                    final image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData == null) return;
                    final pngBytes = byteData.buffer.asUint8List();
                    final result = await SaverGallery.saveImage(
                      pngBytes,
                      fileName:
                          'story_${DateTime.now().millisecondsSinceEpoch}.png',
                      androidRelativePath: 'Pictures/TurqApp',
                      skipIfExists: false,
                    );
                    if (result.isSuccess) {
                      AppSnackbar(
                        'Kaydedildi',
                        'Hikaye cihaz galerisine kaydedildi.',
                        duration: const Duration(seconds: 2),
                      );
                    }
                  } catch (_) {
                  } finally {
                    _startProgress();
                  }
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_down_to_line,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final deletedStoriesController =
                      Get.isRegistered<DeletedStoriesController>()
                          ? Get.find<DeletedStoriesController>()
                          : null;
                  final isDeletedStory = deletedStoriesController
                          ?.deletedAtById
                          .containsKey(currentStory.id) ==
                      true;
                  noYesAlert(
                      title: isDeletedStory ? "Kalıcı Sil" : "Sil",
                      message: isDeletedStory
                          ? "Bu hikaye kalıcı olarak silinsin mi?"
                          : "Bu hikaye silinsin mi?",
                      onYesPressed: () async {
                        final currentStory = widget.user.stories[storyIndex];
                        if (isDeletedStory) {
                          await StoryRepository.ensure()
                              .permanentlyDeleteStory(currentStory.id);
                          deletedStoriesController?.list
                              .removeWhere((e) => e.id == currentStory.id);
                          deletedStoriesController?.deletedAtById
                              .remove(currentStory.id);
                          deletedStoriesController?.deleteReasonById
                              .remove(currentStory.id);
                          unawaited(
                            deletedStoriesController?.fetch(
                                  initial: false,
                                  forceRemote: true,
                                ) ??
                                Future<void>.value(),
                          );
                        } else {
                          await deleteStory(
                              userId: widget.user.userID,
                              storyId: currentStory.id);
                        }

                        setState(() {
                          widget.user.stories.removeAt(storyIndex);

                          // --- Burayı daha güvenli hale getiriyoruz ---
                          if (widget.user.stories.isEmpty) {
                            // Hiç hikaye kalmadıysa
                            widget.onUserStoryFinished?.call();
                            return;
                          }

                          // Eğer index out of range olduysa, sonuncu hikayeye çek
                          if (storyIndex >= widget.user.stories.length) {
                            storyIndex = widget.user.stories.length - 1;
                          }
                        });

                        // Kaldığı yerden devam et (artık stories boş değilse)
                        if (widget.user.stories.isNotEmpty) {
                          _updateController(); // Controller'ı güncelle
                          _startOrWait();
                        }
                      });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget otherToolBar() {
    final currentStory = widget.user.stories[storyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction emoji row
          Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: UserStoryContentController.reactionEmojis.map((emoji) {
                final isSelected = controller.myReaction.value == emoji;
                return GestureDetector(
                  onTap: () => controller.react(currentStory.id, emoji),
                  child: AnimatedScale(
                    scale: isSelected ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
          // Comment + like row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _pauseStoryAudio();
                    _timer?.cancel();
                    await controller.showPostCommentsBottomSheet(
                      currentStory.id,
                      widget.user.nickname,
                      false,
                      onClosed: (v) {
                        if (!mounted) return;
                        _startProgress();
                        unawaited(_resumeStoryAudio());
                      },
                    );
                    if (!mounted) return;
                    _startProgress();
                    await _resumeStoryAudio();
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "Hikayeye yorum yaz..",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                return GestureDetector(
                  onTap: () {
                    controller.like(currentStory.id);
                  },
                  onLongPress: () {
                    unawaited(_pauseStoryAudio());
                    _timer?.cancel();
                    controller.showLikesBottomSheet(currentStory.id,
                        onClosed: (v) {
                      _startProgress();
                      unawaited(_resumeStoryAudio());
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.isLikedMe.value
                                ? CupertinoIcons.hand_thumbsup_fill
                                : CupertinoIcons.hand_thumbsup,
                            color: controller.isLikedMe.value
                                ? Colors.blueAccent
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            controller.likeCount.value.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: "MontserratMedium"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // Share button
              GestureDetector(
                onTap: () async {
                  await _pauseStoryAudio();
                  _timer?.cancel();
                  await ShareActionGuard.run(() async {
                    try {
                      final currentStory = widget.user.stories[storyIndex];
                      String previewImage = '';
                      if (currentStory.elements.isNotEmpty) {
                        previewImage = currentStory.elements
                            .firstWhere(
                              (e) => e.type == StoryElementType.image,
                              orElse: () => currentStory.elements.first,
                            )
                            .content;
                      }
                      final shortUrl =
                          await ShortLinkService().getStoryPublicUrl(
                        storyId: currentStory.id,
                        title: '${widget.user.nickname} hikayesi',
                        desc: 'TurqApp üzerinde hikayeyi görüntüle',
                        imageUrl: previewImage.isEmpty ? null : previewImage,
                      );
                      await ShareLinkService.shareUrl(
                        url: shortUrl,
                        title: '${widget.user.nickname} hikayesi',
                        subject: '${widget.user.nickname} hikayesi',
                      );
                    } catch (_) {}
                  });
                  if (!mounted) return;
                  _startProgress();
                  await _resumeStoryAudio();
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.share_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> deleteStory(
      {required String userId, required String storyId}) async {
    String musicId = '';
    try {
      musicId = await StoryRepository.ensure().softDeleteStory(
        storyId,
        reason: 'manual',
      );
      if (musicId.isNotEmpty) {
        unawaited(
          StoryMusicLibraryService.instance.removeStoryUsage(
            musicId: musicId,
            storyId: storyId,
          ),
        );
      }
    } catch (e) {
      debugPrint('deleteStory update error: $e');
    }

    // Story refresh
    try {
      await Get.find<StoryRowController>().loadStories();
    } catch (e) {
      debugPrint("Story delete refresh error: $e");
    }
  }
}
