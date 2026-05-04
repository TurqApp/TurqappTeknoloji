part of 'agenda_content.dart';

extension AgendaContentBodyPart on _AgendaContentState {
  double get _feedCaptionFontSize => _agendaPostCaptionFontSize;

  Widget mainbody() {
    final hasHeaderSubline =
        widget.model.konum != "" || widget.model.metin.trim().isNotEmpty;
    final mediaTopSpacing = hasHeaderSubline ? 4.0 : 0.0;
    final actionTopSpacing = hasHeaderSubline ? 2.0 : 0.0;
    final mediaVisualLift = hasHeaderSubline ? 0.0 : -6.0;

    if (widget.model.quotedPost) {
      return _buildQuotedMainBody(actionTopSpacing: actionTopSpacing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        if (!widget.model.hasRenderableVideoCard &&
            widget.model.img.isEmpty &&
            widget.model.poll.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 45),
            child: buildPollCard(),
          ),

        // Konum varsa göster
        if (widget.model.konum != "")
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 40),
            child: Row(
              children: [
                Icon(CupertinoIcons.map_pin, color: Colors.red, size: 20),
                SizedBox(width: 3),
                Text(
                  widget.model.konum,
                  style: _agendaPostMetaStyle.copyWith(
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ),

        // Video varsa göster
        if (widget.model.hasRenderableVideoCard)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: Row(
                children: [
                  const SizedBox(width: 45),
                  Expanded(
                    child: Builder(builder: (_) {
                      final double displayAspect = _isIzBirakPost
                          ? 0.92
                          : (widget.model.floodCount > 1 ? 1.0 : 0.80);
                      return VisibilityDetector(
                        key: Key('agenda-media-$controllerTag'),
                        onVisibilityChanged: (info) {
                          reportMediaVisibility(info.visibleFraction);
                        },
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: displayAspect,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SizedBox.expand(
                                  child: GestureDetector(
                                    onDoubleTap: controller.like,
                                    onTap: () async {
                                      if (isReplayOverlayBlockingTap) {
                                        return;
                                      }
                                      if (_shouldBlurIzBirakPost) {
                                        videoController?.pause();
                                        return;
                                      }
                                      if (widget.model.floodCount > 1) {
                                        _suspendAgendaFeedForRoute();
                                        await Get.to(() => FloodListing(
                                              mainModel: widget.model,
                                              hostSurface:
                                                  widget.floodHostSurface,
                                            ));
                                        if (!mounted) return;
                                        _restoreAgendaFeedCenter();
                                        return;
                                      }
                                      if (widget.isPreview) {
                                        final currentPos =
                                            await _resolveCurrentVideoPosition();
                                        final listForFullscreen =
                                            await _buildFullscreenStartList();

                                        _prepareVideoFullscreenTransition();
                                        _pauseFeedBeforeFullscreen();
                                        setPauseBlocked(true);
                                        if (mounted) {
                                          _setFullscreenState(true);
                                        }
                                        final res =
                                            await Get.to(() => SingleShortView(
                                                  startModel: widget.model,
                                                  startList: listForFullscreen,
                                                  initialPosition: currentPos,
                                                  injectedController:
                                                      videoController,
                                                ));
                                        setPauseBlocked(false);
                                        if (mounted) {
                                          _setFullscreenState(false);
                                        }

                                        if (!mounted) return;

                                        final modelIndex = agendaController
                                            .agendaList
                                            .indexWhere((p) =>
                                                p.docID == widget.model.docID);
                                        if (modelIndex >= 0) {
                                          agendaController.centeredIndex.value =
                                              modelIndex;
                                          agendaController.lastCenteredIndex =
                                              modelIndex;
                                        }

                                        final vc = videoController;
                                        if (vc != null &&
                                            vc.value.isInitialized) {
                                          if (res is Map &&
                                              res['docID'] ==
                                                  widget.model.docID) {
                                            final int? ms =
                                                res['positionMs'] as int?;
                                            if (ms != null) {
                                              await vc.seekTo(
                                                  Duration(milliseconds: ms));
                                              if (widget.shouldPlay) {
                                                vc.play();
                                                vc.setVolume(agendaController
                                                        .isMuted.value
                                                    ? 0
                                                    : 1);
                                              }
                                              return;
                                            }
                                          }
                                          if (widget.shouldPlay) {
                                            tryAutoPlayWhenBuffered();
                                          }
                                        }
                                      } else {
                                        final currentPos =
                                            await _resolveCurrentVideoPosition();
                                        final listForFullscreen =
                                            await _buildFullscreenStartList();

                                        _prepareVideoFullscreenTransition();
                                        _pauseFeedBeforeFullscreen();
                                        setPauseBlocked(true);
                                        _setFullscreenState(true);
                                        final res =
                                            await Get.to(() => SingleShortView(
                                                  startModel: widget.model,
                                                  startList: listForFullscreen,
                                                  initialPosition: currentPos,
                                                  injectedController:
                                                      videoController,
                                                ));
                                        setPauseBlocked(false);
                                        _setFullscreenState(false);

                                        if (!mounted) return;

                                        final modelIndex = agendaController
                                            .agendaList
                                            .indexWhere((p) =>
                                                p.docID == widget.model.docID);
                                        if (modelIndex >= 0) {
                                          agendaController.centeredIndex.value =
                                              modelIndex;
                                          agendaController.lastCenteredIndex =
                                              modelIndex;
                                        }

                                        final vc = videoController;
                                        if (vc != null &&
                                            vc.value.isInitialized) {
                                          if (res is Map &&
                                              res['docID'] ==
                                                  widget.model.docID) {
                                            final int? ms =
                                                res['positionMs'] as int?;
                                            if (ms != null) {
                                              await vc.seekTo(
                                                  Duration(milliseconds: ms));
                                              if (widget.shouldPlay) {
                                                vc.play();
                                                vc.setVolume(agendaController
                                                        .isMuted.value
                                                    ? 0
                                                    : 1);
                                              }
                                              return;
                                            }
                                          }
                                          if (widget.shouldPlay) {
                                            tryAutoPlayWhenBuffered();
                                          }
                                        }
                                      }
                                    },
                                    child: Builder(builder: (_) {
                                      if (_shouldBlurIzBirakPost) {
                                        return _buildVideoThumbnail(
                                          aspectRatio: displayAspect,
                                        );
                                      }
                                      if (videoController == null) {
                                        return _buildVideoThumbnail(
                                          aspectRatio: displayAspect,
                                        );
                                      }
                                      final instanceTag =
                                          widget.instanceTag?.trim() ?? '';
                                      const preferWarmPoolPauseOnAndroid =
                                          false;
                                      final isProfileFamilySurface =
                                          (widget.instanceTag ?? '')
                                                  .startsWith('profile_') ||
                                              (widget.instanceTag ?? '')
                                                  .startsWith('archives_') ||
                                              (widget.instanceTag ?? '')
                                                  .startsWith('liked_post_') ||
                                              (widget.instanceTag ?? '')
                                                  .startsWith('social_');
                                      final isFeedStyleInlineSurface =
                                          isPrimaryFeedSurfaceInstance ||
                                              isProfileFamilySurface ||
                                              instanceTag.startsWith('flood_') ||
                                              instanceTag.startsWith(
                                                'explore_series_',
                                              );
                                      final showInlinePlayer =
                                          videoController != null;
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          !showInlinePlayer || _isFullscreen
                                              ? const SizedBox.shrink()
                                              : videoController!.buildPlayer(
                                                  key: ValueKey(
                                                      'agenda-$controllerTag'),
                                                  aspectRatio: displayAspect,
                                                  useAspectRatio: false,
                                                  overrideAutoPlay:
                                                      shouldAutoResumeInlinePlatformView,
                                                  isPrimaryFeedSurface:
                                                      isPrimaryFeedSurfaceInstance,
                                                  preferWarmPoolPauseOnAndroid:
                                                      preferWarmPoolPauseOnAndroid,
                                                  preferResumePoster:
                                                      (!isFeedStyleInlineSurface &&
                                                              shouldSuppressGenericResumeThumbnail) ||
                                                          isProfileFamilySurface,
                                                  startupRecoveryWatchdogEnabled:
                                                      shouldEnableStartupRecoveryWatchdog,
                                                  preferStableStartupBuffer:
                                                      PlaybackSurfacePolicy
                                                          .preferStableFeedStartupBuffer(
                                                        platform:
                                                            defaultTargetPlatform,
                                                        isFeedStyleSurface:
                                                            isFeedStyleInlineSurface,
                                                      ),
                                                ),
                                          ValueListenableBuilder<HLSVideoValue>(
                                            valueListenable: videoValueNotifier,
                                            builder: (_, v, child) {
                                              if (widget.hideVideoPoster ||
                                                  (isFeedStyleInlineSurface &&
                                                      defaultTargetPlatform !=
                                                          TargetPlatform.iOS)) {
                                                return const SizedBox.shrink();
                                              }
                                              final showStartupPlaceholder =
                                                  shouldShowStartupPlaybackPlaceholder(
                                                v,
                                              );
                                              if (isFeedStyleInlineSurface &&
                                                  !showStartupPlaceholder) {
                                                return const SizedBox.shrink();
                                              }
                                              final shouldHidePoster =
                                                  shouldHidePlaybackPoster(v);
                                              final posterFadeDuration =
                                                  showStartupPlaceholder
                                                      ? const Duration(
                                                          milliseconds: 90,
                                                        )
                                                      : AppDuration
                                                          .thumbnailFadeOut;
                                              return IgnorePointer(
                                                ignoring: true,
                                                child: AnimatedOpacity(
                                                  opacity:
                                                      shouldHidePoster ? 0 : 1,
                                                  duration: posterFadeDuration,
                                                  curve: Curves.easeOut,
                                                  child: child!,
                                                ),
                                              );
                                            },
                                            child: _buildVideoThumbnail(
                                              aspectRatio: displayAspect,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: buildUploadIndicator(),
                                          ),
                                          ValueListenableBuilder<HLSVideoValue>(
                                            valueListenable: videoValueNotifier,
                                            builder: (_, v, __) =>
                                                buildFeedReplayOverlay(v),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                if (videoController != null &&
                                    !_shouldBlurIzBirakPost)
                                  ValueListenableBuilder<HLSVideoValue>(
                                    valueListenable: videoValueNotifier,
                                    builder: (_, v, __) {
                                      if (!v.isInitialized ||
                                          v.duration <= Duration.zero) {
                                        return const SizedBox.shrink();
                                      }
                                      final remaining = v.duration - v.position;
                                      final safeRemaining = remaining.isNegative
                                          ? Duration.zero
                                          : remaining;
                                      final countdownColor =
                                          isStartupCacheOriginVideo
                                              ? const Color(0xFF61E37A)
                                              : Colors.white;
                                      return Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _formatDuration(safeRemaining),
                                            style: TextStyle(
                                              color: countdownColor,
                                              fontSize: 12,
                                              fontFamily: "Montserrat",
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if ((widget.isReshared &&
                                        widget.model.originalUserID.isEmpty) ||
                                    widget.model.originalUserID.isNotEmpty)
                                  Positioned(
                                    left: 8,
                                    bottom: (widget.model.flood == false &&
                                            widget.model.floodCount > 1)
                                        ? 26
                                        : 8,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.isReshared &&
                                            widget.model.originalUserID.isEmpty)
                                          _buildAgendaReshareOverlay(),
                                        if (widget
                                            .model.originalUserID.isNotEmpty)
                                          SharedPostLabel(
                                            originalUserID:
                                                widget.model.originalUserID,
                                            sourceUserID:
                                                widget.model.quotedPost
                                                    ? widget.model
                                                        .quotedSourceUserID
                                                    : '',
                                            labelSuffix: widget.model.quotedPost
                                                ? 'alıntılandı'
                                                : '',
                                            textColor: Colors.white,
                                            fontSize:
                                                _agendaPostAttributionFontSize,
                                          ),
                                      ],
                                    ),
                                  ),
                                _buildIzBirakBlurOverlay(),
                                _buildIzBirakBottomBar(),
                                if (!widget.suppressFloodBadge &&
                                    widget.model.flood == false &&
                                    widget.model.floodCount > 1)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        _suspendAgendaFeedForRoute();
                                        Get.to(() => FloodListing(
                                              mainModel: widget.model,
                                              hostSurface:
                                                  widget.floodHostSurface,
                                            ))?.then((_) {
                                          if (!mounted) return;
                                          _restoreAgendaFeedCenter();
                                        });
                                      },
                                      child: Texts.colorfulFloodLeftSide,
                                    ),
                                  ),
                                if (!_isIzBirakPost)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        ValueListenableBuilder<HLSVideoValue>(
                                          valueListenable: videoValueNotifier,
                                          builder: (context, value, _) {
                                            final isPlaying =
                                                value.isInitialized &&
                                                    value.isPlaying;
                                            return GestureDetector(
                                              onTap: () {
                                                final vc = videoController;
                                                if (vc == null) return;
                                                if (isPlaying) {
                                                  pauseVideoManually();
                                                } else {
                                                  resumeVideoManually();
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                padding:
                                                    const EdgeInsets.all(7),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isPlaying
                                                      ? CupertinoIcons
                                                          .pause_fill
                                                      : CupertinoIcons
                                                          .play_fill,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        GestureDetector(
                                          onTap:
                                              agendaController.isMuted.toggle,
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Obx(() {
                                              return Icon(
                                                agendaController.isMuted.value
                                                    ? CupertinoIcons.volume_off
                                                    : CupertinoIcons.volume_up,
                                                color: Colors.white,
                                                size: 14,
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

        // Resimler
        if (widget.model.img.isNotEmpty)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing, left: 45),
              child: buildImageGrid(widget.model.img),
            ),
          ),
        if ((widget.model.hasRenderableVideoCard ||
                widget.model.img.isNotEmpty) &&
            widget.model.poll.isNotEmpty)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing, left: 45),
              child: buildPollCard(),
            ),
          ),

        // Alt butonlar
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: Obx(() {
            final currentUser = controller.userService.currentUserRx.value;
            final me = currentUser?.userID.trim().isNotEmpty == true
                ? currentUser!.userID.trim()
                : controller.userService.effectiveUserId.trim();
            if (me.isEmpty) return const SizedBox.shrink();
            return Transform.translate(
              offset: const Offset(17, 0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionSlot(
                      commentButton(context),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      likeButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      reshareButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      statButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(
                      saveButton(),
                      pullTowardSend: true,
                    ),
                    _buildActionSlot(sendButton()),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeedCaption({
    required String text,
    required Color color,
  }) {
    final cleanedText =
        _AgendaContentState._ctaNavigationService.sanitizeCaptionText(
      text,
      meta: widget.model.reshareMap,
    );
    if (cleanedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClickableTextContent(
      text: cleanedText,
      startWith7line: true,
      toggleExpandOnTextTap: true,
      fontSize: _feedCaptionFontSize,
      fontColor: color,
      mentionColor: Colors.blue,
      hashtagColor: Colors.blue,
      urlColor: Colors.blue,
      interactiveColor: Colors.blue,
      expandButtonColor: AppColors.primaryColor,
      expandOverlayRightInset: 3,
      onUrlTap: _handleFeedUrlTap,
      onHashtagTap: (tag) {
        if (tag.trim().isEmpty) return;
        Get.to(() => TagPosts(tag: tag.trim()));
      },
      onMentionTap: (mention) async {
        final targetUid =
            await UsernameLookupRepository.ensure().findUidForHandle(mention) ??
                '';

        final currentUid = controller.userService.effectiveUserId;
        if (targetUid.isNotEmpty && targetUid != currentUid) {
          await const ProfileNavigationService().openSocialProfile(targetUid);
        }
      },
    );
  }
}
