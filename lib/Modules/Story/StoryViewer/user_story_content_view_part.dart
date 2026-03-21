// ignore_for_file: invalid_use_of_protected_member

part of 'user_story_content.dart';

extension UserStoryContentViewPart on _UserStoryContentState {
  Widget buildContent(BuildContext context) {
    // Eğer story tamamen silinmişse veya index bozuksa:
    if (widget.user.stories.isEmpty ||
        storyIndex < 0 ||
        storyIndex >= widget.user.stories.length) {
      // Ana sayfaya dön veya bir üst seviyeye çık, ya da sadece boş widget dön
      Future.microtask(() {
        widget.onUserStoryFinished?.call();
      });
      return const SizedBox.shrink(); // veya bir loading gösterebilirsin
    }

    final totalStories = widget.user.stories.length;
    final currentStory = widget.user.stories[storyIndex];
    final sourceBadge = _sourceProfileBadgeForStory(widget.user);
    final sortedElements = [...currentStory.elements]
      ..removeWhere((element) => element.stickerType == 'source_profile')
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final mediaLayer = sortedElements
        .where((element) =>
            element.type == StoryElementType.image ||
            element.type == StoryElementType.video)
        .toList(growable: false);
    final overlayLayer = sortedElements
        .where((element) =>
            element.type != StoryElementType.image &&
            element.type != StoryElementType.video)
        .toList(growable: false);

    return Column(
      key: ValueKey('story_column_${currentStory.id}'),
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
          child: Row(
            children: List.generate(totalStories, (i) {
              if (i < storyIndex) {
                // Tamamlanmış hikayeler
                return _buildProgressBar(1.0);
              } else if (i == storyIndex) {
                // Mevcut hikaye
                return _buildProgressBar(progress);
              } else {
                // Henüz başlamamış hikayeler
                return _buildProgressBar(0.0);
              }
            }),
          ),
        ),
        userInfo(widget.user, sourceBadge: sourceBadge),
        Expanded(
          child: RepaintBoundary(
            key: _repaintKey,
            child: Container(
              key: ValueKey('story_container_${currentStory.id}'),
              color: (currentStory.backgroundColor.a * 255.0)
                          .round()
                          .clamp(0, 255) ==
                      0
                  ? Colors.transparent
                  : currentStory.backgroundColor,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Yatay swipe: PageView (StoryViewer) tarafından yönetilsin
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (_tapLocked) return;

                  // Tap lock mekanizması
                  _tapLocked = true;
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) _tapLocked = false;
                  });

                  // Ekran genisliginin ortasına göre karar ver
                  if (details.localPosition.dx > screenWidth / 2) {
                    _nextStory();
                  } else {
                    _prevStory();
                  }
                },
                onLongPressStart: (_) {
                  setState(() {
                    _isHoldPaused = true;
                  });
                  _timer?.cancel();
                  unawaited(_pauseStoryAudio());
                },
                onLongPressEnd: (_) {
                  setState(() {
                    _isHoldPaused = false;
                  });
                  _startProgress();
                  unawaited(_resumeStoryAudio());
                },
                child: _waitingForMusic
                    ? const Center(child: CupertinoActivityIndicator())
                    : Stack(
                        // Key ekleyerek Stack'in yeniden render olmasını sağla
                        key: ValueKey(
                            'story_stack_${currentStory.id}_$storyIndex'),
                        children: [
                          ...mediaLayer.map((element) {
                            switch (element.type) {
                              case StoryElementType.image:
                                return StoryImageWidget(
                                  key: ValueKey(
                                      'img_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.video:
                                return StoryVideoWidget(
                                  key: ValueKey(
                                      'vid_${element.content}_${currentStory.id}'),
                                  element: element,
                                  maxDuration: const Duration(seconds: 60),
                                  paused: _isHoldPaused,
                                  onStarted: (Duration actualDuration) {
                                    final effective = actualDuration >
                                            const Duration(seconds: 60)
                                        ? const Duration(seconds: 60)
                                        : actualDuration;
                                    if (_waitingForVideo) {
                                      setState(() {
                                        progress = 0.0;
                                        progressMaxDuration = effective;
                                        _waitingForVideo = false;
                                      });
                                      _startProgress();
                                    }
                                  },
                                  onEnded: () {
                                    _nextStory(auto: true);
                                  },
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          }),
                          ...overlayLayer.map((element) {
                            switch (element.type) {
                              case StoryElementType.gif:
                                return StoryGifWidget(
                                  key: ValueKey(
                                      'gif_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.text:
                                return StoryTextWidget(
                                  key: ValueKey(
                                      'txt_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.sticker:
                                return StoryTextWidget(
                                  key: ValueKey(
                                      'sticker_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          }),
                          // Instagram-style: pause sadece progress bar'ı durdurur, görsel overlay yok
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (currentStory.userId == _currentUid)
          myToolBar()
        else
          otherToolBar()
      ],
    );
  }

  Widget _buildProgressBar(double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 2.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(1.5),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget userInfo(
    StoryUserModel currentUser, {
    StoryElement? sourceBadge,
  }) {
    final currentStory = currentUser.stories[storyIndex];
    const nicknameFontSize = 12.0;
    final hasMusic = currentStory.musicUrl.isNotEmpty;
    final musicTitle = currentStory.musicTitle.trim();
    final rawMusicArtist = currentStory.musicArtist.trim();
    final musicArtist = (() {
      final normalized = normalizeSearchText(rawMusicArtist);
      if (normalized == 'turqapp müzik' || normalized == 'turqapp muzik') {
        return '';
      }
      return rawMusicArtist;
    })();
    final musicLabel = musicTitle.isNotEmpty
        ? (musicArtist.isNotEmpty ? '$musicTitle • $musicArtist' : musicTitle)
        : getMusicNameFromURL(currentStory.musicUrl);

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              unawaited(_pauseStoryAudio());
              Get.to(() => SocialProfile(userID: currentUser.userID))
                  ?.then((_) {
                unawaited(_resumeStoryAudio());
              });
            },
            child: CachedUserAvatar(
              userId: currentUser.userID,
              imageUrl: currentUser.avatarUrl,
              radius: 16.5,
              placeholder: const DefaultAvatar(
                radius: 16.5,
                backgroundColor: Colors.white24,
                iconColor: Colors.white70,
                padding: EdgeInsets.all(5),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nickname + rozet + zaman yatay scrollable!
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          unawaited(_pauseStoryAudio());
                          Get.to(() =>
                                  SocialProfile(userID: currentUser.userID))
                              ?.then((_) {
                            unawaited(_resumeStoryAudio());
                          });
                        },
                        child: Text(
                          currentUser.nickname,
                          // Sadece burada maxLines yok!
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: nicknameFontSize,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RozetContent(size: 13, userID: currentUser.userID),
                      const SizedBox(width: 4),
                      Text(
                        timeAgoMetin(
                            currentStory.createdAt.millisecondsSinceEpoch),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      if (sourceBadge != null) ...[
                        const SizedBox(width: 6),
                        SharedPostLabel(
                          originalUserID: sourceBadge.stickerData,
                          sourceUserID: sourceBadge.stickerData,
                          textColor: Colors.white,
                          fontSize: nicknameFontSize,
                        ),
                      ],
                    ],
                  ),
                ),
                // Eğer müzik varsa yatay scrollable music
                if (hasMusic)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: currentStory.musicId.trim().isEmpty
                          ? null
                          : () async {
                              await _pauseStoryAudio();
                              await Get.to(
                                () => StoryMusicProfileView(
                                  musicId: currentStory.musicId,
                                ),
                              );
                              if (mounted) {
                                await _resumeStoryAudio();
                              }
                            },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.music_note_2,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              musicLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              CupertinoIcons.clear,
              size: 25,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
