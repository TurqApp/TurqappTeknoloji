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
                  unawaited(_pauseCurrentStoryPlayback());
                },
                onLongPressEnd: (_) {
                  setState(() {
                    _isHoldPaused = false;
                  });
                  unawaited(_resumeCurrentStoryPlayback());
                },
                child: _waitingForMusic
                    ? const SizedBox.expand()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          final normalizeSingleMedia = mediaLayer.length == 1;

                          return Stack(
                            // Key ekleyerek Stack'in yeniden render olmasını sağla
                            key: ValueKey(
                                'story_stack_${currentStory.id}_$storyIndex'),
                            children: [
                              ...mediaLayer.map((element) {
                                final displayElement =
                                    _normalizedMediaDisplayElement(
                                  element,
                                  currentStory.id,
                                  viewportSize,
                                  enabled: normalizeSingleMedia,
                                );
                                switch (displayElement.type) {
                                  case StoryElementType.image:
                                    return StoryImageWidget(
                                      key: ValueKey(
                                          'img_${displayElement.content}_${currentStory.id}'),
                                      element: displayElement,
                                    );
                                  case StoryElementType.video:
                                    return StoryVideoWidget(
                                      key: ValueKey(
                                          'vid_${displayElement.content}_${currentStory.id}'),
                                      storyId: currentStory.id,
                                      element: displayElement,
                                      maxDuration: _UserStoryContentState
                                          ._storyVideoPlaybackHardCap,
                                      paused: _isHoldPaused,
                                      onStarted: (Duration actualDuration) {
                                        _clearStoryTransitionCover(
                                          currentStory.id,
                                          reason: 'video_started',
                                        );
                                        final effective = actualDuration >
                                                _UserStoryContentState
                                                    ._storyVideoPlaybackHardCap
                                            ? _UserStoryContentState
                                                ._storyVideoPlaybackHardCap
                                            : actualDuration;
                                        if (_waitingForVideo) {
                                          _timer?.cancel();
                                          setState(() {
                                            progress = 0.0;
                                            progressMaxDuration = effective;
                                            _waitingForVideo = false;
                                          });
                                        }
                                      },
                                      onProgress: (double value) {
                                        if (!mounted || _waitingForVideo) {
                                          return;
                                        }
                                        final next =
                                            value.clamp(0.0, 1.0).toDouble();
                                        if ((next - progress).abs() < 0.003 &&
                                            next < 1.0) {
                                          return;
                                        }
                                        setState(() {
                                          progress = next;
                                        });
                                      },
                                      onEnded: () {
                                        _nextStory(auto: true);
                                      },
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              }),
                              if (_storyTransitionCoverStoryId ==
                                  currentStory.id)
                                ...mediaLayer.take(1).map((element) {
                                  final displayElement =
                                      _normalizedMediaDisplayElement(
                                    element,
                                    currentStory.id,
                                    viewportSize,
                                    enabled: normalizeSingleMedia,
                                  );
                                  return _buildStoryTransitionCover(
                                    displayElement,
                                    currentStory.id,
                                  );
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
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
        if (currentStory.userId == _currentUid) myToolBar() else otherToolBar()
      ],
    );
  }

  Widget _buildStoryTransitionCover(StoryElement element, String storyId) {
    final String imageUrl;
    if (element.type == StoryElementType.video) {
      imageUrl = element.posterUrl.trim();
    } else if (element.type == StoryElementType.image ||
        element.type == StoryElementType.gif) {
      imageUrl = element.content.trim();
    } else {
      return const SizedBox.shrink();
    }
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: element.rotation,
          child: CachedNetworkImage(
            cacheManager: TurqImageCacheManager.instance,
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            placeholder: (context, url) => const SizedBox.expand(),
            errorWidget: (context, url, error) => const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  StoryElement _normalizedMediaDisplayElement(
    StoryElement element,
    String storyId,
    Size viewportSize, {
    required bool enabled,
  }) {
    if (!enabled || viewportSize.width <= 0 || viewportSize.height <= 0) {
      return element;
    }

    final mediaAspect = _safeStoryMediaAspectRatio(element);
    final viewportAspect = viewportSize.width / viewportSize.height;
    final double width;
    final double height;
    if (mediaAspect > viewportAspect) {
      width = viewportSize.width;
      height = width / mediaAspect;
    } else {
      height = viewportSize.height;
      width = height * mediaAspect;
    }
    final position = Offset(
      (viewportSize.width - width) / 2,
      (viewportSize.height - height) / 2,
    );

    final logKey = '$storyId:${element.id}:${viewportSize.width.round()}x'
        '${viewportSize.height.round()}';
    if (_loggedSharedPostLayoutKeys.add(logKey)) {
      final platformLabel = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'other';
      debugPrint(
        '[StoryMediaLayout] platform=$platformLabel story=$storyId '
        'type=${element.type.name} viewport=${viewportSize.width.toStringAsFixed(1)}x'
        '${viewportSize.height.toStringAsFixed(1)} '
        'saved=${element.position.dx.toStringAsFixed(1)},'
        '${element.position.dy.toStringAsFixed(1)} '
        '${element.width.toStringAsFixed(1)}x${element.height.toStringAsFixed(1)} '
        'display=${position.dx.toStringAsFixed(1)},'
        '${position.dy.toStringAsFixed(1)} '
        '${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)} '
        'aspect=${mediaAspect.toStringAsFixed(4)}',
      );
    }

    return StoryElement(
      id: element.id,
      type: element.type,
      content: element.content,
      width: width,
      height: height,
      position: position,
      rotation: element.rotation,
      zIndex: element.zIndex,
      isMuted: element.isMuted,
      fontSize: element.fontSize,
      aspectRatio: mediaAspect,
      textColor: element.textColor,
      textBgColor: element.textBgColor,
      hasTextBg: element.hasTextBg,
      textAlign: element.textAlign,
      fontWeight: element.fontWeight,
      italic: element.italic,
      underline: element.underline,
      shadowBlur: element.shadowBlur,
      shadowOpacity: element.shadowOpacity,
      fontFamily: element.fontFamily,
      hasOutline: element.hasOutline,
      outlineColor: element.outlineColor,
      stickerType: element.stickerType,
      stickerData: element.stickerData,
      mediaLookPreset: element.mediaLookPreset,
      posterUrl: element.posterUrl,
    );
  }

  double _safeStoryMediaAspectRatio(StoryElement element) {
    if (element.aspectRatio.isFinite && element.aspectRatio > 0) {
      return element.aspectRatio;
    }
    if (element.width > 0 && element.height > 0) {
      return element.width / element.height;
    }
    return 9 / 16;
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
            onTap: currentUser.userID == _currentUid
                ? null
                : () async {
                    await _pauseCurrentStoryPlayback();
                    const ProfileNavigationService()
                        .openSocialProfile(currentUser.userID)
                        .then((_) {
                      if (mounted) {
                        unawaited(_resumeCurrentStoryPlayback());
                      }
                    });
                  },
            child: CachedUserAvatar(
              userId: currentUser.userID,
              imageUrl: currentUser.avatarUrl,
              radius: 16.5,
              placeholder: const SizedBox.square(
                dimension: 33,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              errorWidget: const DefaultAvatar(radius: 16.5),
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
                        onTap: currentUser.userID == _currentUid
                            ? null
                            : () async {
                                await _pauseCurrentStoryPlayback();
                                const ProfileNavigationService()
                                    .openSocialProfile(currentUser.userID)
                                    .then((_) {
                                  if (mounted) {
                                    unawaited(_resumeCurrentStoryPlayback());
                                  }
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
                              await _pauseCurrentStoryPlayback();
                              await Get.to(
                                () => StoryMusicProfileView(
                                  musicId: currentStory.musicId,
                                ),
                              );
                              if (mounted) {
                                await _resumeCurrentStoryPlayback();
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
