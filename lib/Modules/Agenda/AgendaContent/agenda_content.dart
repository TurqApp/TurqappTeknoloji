import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Services/post_story_share_service.dart';
import 'package:turqappv2/Core/Services/relative_time_tick_service.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Widgets/ring_upload_progress_indicator.dart';
import 'package:turqappv2/Core/Services/education_feed_cta_navigation_service.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/post_reshare_listing.dart';
import 'package:turqappv2/Modules/Agenda/SinglePost/single_post.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Services/post_interaction_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../../Core/texts.dart';
import '../../Profile/MyProfile/profile_view.dart';
import '../../SocialProfile/social_profile.dart';
import '../Common/post_content_base.dart';
import '../Common/post_content_controller.dart';
import '../Common/reshare_attribution.dart';
import '../Common/post_action_style.dart';
import 'agenda_content_controller.dart';

part 'agenda_content_quote_part.dart';
part 'agenda_content_media_part.dart';
part 'agenda_content_header_actions_part.dart';

class AgendaContent extends PostContentBase {
  final bool hideVideoPoster;
  const AgendaContent({
    super.key,
    required super.model,
    required super.isPreview,
    required super.shouldPlay,
    super.instanceTag,
    this.hideVideoPoster = false,
    bool isYenidenPaylasilanPost = false,
    super.reshareUserID,
    bool? showComments = false,
    bool? showArchivePost = false,
  }) : super(
          isReshared: isYenidenPaylasilanPost,
          showComments: showComments ?? false,
          showArchivePost: showArchivePost ?? false,
        );

  @override
  PostContentController createController() =>
      AgendaContentController(model: model);

  @override
  State<AgendaContent> createState() => _AgendaContentState();
}

class _AgendaContentState extends State<AgendaContent>
    with PostContentBaseState<AgendaContent> {
  static const PostActionStyle _actionStyle = PostActionStyle.modern();
  static const bool _showActionTapAreas = false;
  static const Color _actionColor = Color(0xFF6F7A85);
  static const Color _videoFallbackColor = Colors.transparent;
  static const List<String> _flagReasons = <String>[
    'Uyuşturucu',
    'Kumar',
    'Çıplaklık',
    'Dolandırıcılık',
    'Şiddet',
    'Spam',
    'Diğer',
  ];
  static final RxSet<String> _flaggedPostIds = <String>{}.obs;
  static const EducationFeedCtaNavigationService _ctaNavigationService =
      EducationFeedCtaNavigationService();
  final arsivController = Get.put(ArchiveController());
  bool _isFullscreen = false;
  bool _pauseQueuedAfterBuild = false;
  late final RelativeTimeTickService _relativeTimeTickService;
  Future<List<dynamic>>? _quotedSourceFuture;
  String _quotedSourceFutureUserId = '';
  String _quotedSourceFuturePostId = '';

  int get _feedCacheWidth {
    final media = MediaQuery.of(context);
    return (media.size.width * media.devicePixelRatio).round();
  }

  int _feedCacheHeightForAspectRatio(double aspectRatio) {
    return (_feedCacheWidth / aspectRatio).round();
  }

  bool get _isIzBirakPost => widget.model.scheduledAt.toInt() > 0;

  bool get _shouldBlurIzBirakPost =>
      _isIzBirakPost && _izBirakPublishDate.isAfter(DateTime.now());

  DateTime get _izBirakPublishDate => DateTime.fromMillisecondsSinceEpoch(
        widget.model.scheduledAt.toInt() > 0
            ? widget.model.scheduledAt.toInt()
            : widget.model.izBirakYayinTarihi.toInt(),
      );

  @override
  void initState() {
    super.initState();
    _relativeTimeTickService = RelativeTimeTickService.ensure();
    _refreshQuotedSourceFuture();
  }

  @override
  void didUpdateWidget(covariant AgendaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUserId = oldWidget.model.quotedSourceUserID.trim().isNotEmpty
        ? oldWidget.model.quotedSourceUserID.trim()
        : oldWidget.model.originalUserID.trim();
    final newUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    final oldPostId = oldWidget.model.originalPostID.trim();
    final newPostId = widget.model.originalPostID.trim();
    if (oldUserId != newUserId || oldPostId != newPostId) {
      _refreshQuotedSourceFuture();
    }
  }

  Future<void> _subscribeToIzBirak() async {
    AppSnackbar(
      'İz Bırak',
      'Yayın tarihinde bildirim alacaksınız.',
    );
    final ok =
        await IzBirakSubscriptionService.ensure().subscribe(widget.model.docID);
    if (!ok) {
      AppSnackbar(
        'İz Bırak',
        'Bildirim kaydı oluşturulamadı.',
        backgroundColor: Colors.red.shade700.withValues(alpha: 0.92),
      );
    }
  }

  Widget _buildIzBirakBlurOverlay() {
    if (!_shouldBlurIzBirakPost) return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }

  Widget _buildIzBirakBottomBar() {
    if (!_isIzBirakPost) return const SizedBox.shrink();
    final text = 'Yayın Tarihi : ${formatIzBirakLong(_izBirakPublishDate)}';
    final subscriptionService = IzBirakSubscriptionService.ensure();
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(
                () {
                  final subscribed =
                      subscriptionService.isSubscribed(widget.model.docID);
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      borderRadius: BorderRadius.circular(20),
                      onPressed: subscribed ? null : _subscribeToIzBirak,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: subscribed
                              ? const Color(0xFF1F8F46)
                              : Colors.green,
                        ),
                        child: Icon(
                          subscribed
                              ? CupertinoIcons.check_mark
                              : CupertinoIcons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isBlackBadgeUser {
    final raw = (controller.userService.currentUser?.rozet ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i');
    return raw == 'siyah' || raw == 'black';
  }

  @override
  Widget build(BuildContext context) {
    // Build sırasında doğrudan pause() çağırmak Obx'i yeniden kirletebilir.
    // Bu yüzden pause işlemini frame sonuna erteliyoruz.
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value ||
        _shouldBlurIzBirakPost) {
      if (!_pauseQueuedAfterBuild) {
        _pauseQueuedAfterBuild = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pauseQueuedAfterBuild = false;
          if (!mounted) return;
          try {
            videoController?.pause();
          } catch (_) {}
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Obx(() {
        // Sadece bir tane Column döndür, if ile child yer değiştir
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.gizlendi.value)
              gonderiGizlendi(context)
            else if (controller.arsiv.value)
              gonderiArsivlendi(context)
            else if (controller.silindi.value)
              AnimatedOpacity(
                opacity: controller.silindiOpacity.value,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: gonderiSilindi(context),
              )
            else
              mainbody()
          ],
        );
      }),
    );
  }

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
        if (!widget.model.hasPlayableVideo && widget.model.img.isEmpty)
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
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium"),
                )
              ],
            ),
          ),

        // Video varsa göster
        if (widget.model.hasPlayableVideo)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: Row(
                children: [
                  const SizedBox(width: 45),
                  Expanded(
                    child: Builder(builder: (_) {
                      final double displayAspect = _isIzBirakPost ? 0.92 : 0.80;
                      return VisibilityDetector(
                        key: Key('agenda-media-${widget.model.docID}'),
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
                                    onTap: () async {
                                      if (_shouldBlurIzBirakPost) {
                                        videoController?.pause();
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
                                          setState(() => _isFullscreen = true);
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
                                          setState(() => _isFullscreen = false);
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
                                        if (controller.model.floodCount > 1) {
                                          videoController?.pause();
                                          await Get.to(() => FloodListing(
                                              mainModel: widget.model));
                                          if (widget.shouldPlay) {
                                            videoController?.play();
                                          }
                                        } else {
                                          final currentPos =
                                              await _resolveCurrentVideoPosition();
                                          final listForFullscreen =
                                              await _buildFullscreenStartList();

                                          _prepareVideoFullscreenTransition();
                                          _pauseFeedBeforeFullscreen();
                                          setPauseBlocked(true);
                                          if (mounted) {
                                            setState(
                                                () => _isFullscreen = true);
                                          }
                                          final res = await Get.to(() =>
                                              SingleShortView(
                                                startModel: widget.model,
                                                startList: listForFullscreen,
                                                initialPosition: currentPos,
                                                injectedController:
                                                    videoController,
                                              ));
                                          setPauseBlocked(false);
                                          if (mounted) {
                                            setState(
                                                () => _isFullscreen = false);
                                          }

                                          if (!mounted) return;

                                          final modelIndex = agendaController
                                              .agendaList
                                              .indexWhere((p) =>
                                                  p.docID ==
                                                  widget.model.docID);
                                          if (modelIndex >= 0) {
                                            agendaController.centeredIndex
                                                .value = modelIndex;
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
                                      }
                                    },
                                    child: Builder(builder: (_) {
                                      final thumb = widget.model.thumbnail;
                                      if (_shouldBlurIzBirakPost) {
                                        return _buildVideoThumbnail();
                                      }
                                      if (videoController == null) {
                                        return _buildVideoThumbnail();
                                      }
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _isFullscreen
                                              ? const SizedBox.shrink()
                                              : videoController!.buildPlayer(
                                                  key: ValueKey(
                                                      'agenda-${widget.model.docID}-${videoController.hashCode}'),
                                                  aspectRatio: displayAspect,
                                                  useAspectRatio: false,
                                                ),
                                          ValueListenableBuilder<HLSVideoValue>(
                                            valueListenable: videoValueNotifier,
                                            builder: (_, v, child) {
                                              if (widget.hideVideoPoster) {
                                                return const SizedBox.shrink();
                                              }
                                              if (v.hasRenderedFirstFrame) {
                                                return const SizedBox.shrink();
                                              }
                                              return child!;
                                            },
                                            child: thumb.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: thumb,
                                                    fit: BoxFit.cover,
                                                    memCacheWidth:
                                                        _feedCacheWidth,
                                                    memCacheHeight:
                                                        _feedCacheHeightForAspectRatio(
                                                      displayAspect,
                                                    ),
                                                    placeholder: (_, __) =>
                                                        const ColoredBox(
                                                      color:
                                                          _videoFallbackColor,
                                                    ),
                                                    errorWidget: (_, __, ___) =>
                                                        const ColoredBox(
                                                      color:
                                                          _videoFallbackColor,
                                                    ),
                                                  )
                                                : const ColoredBox(
                                                    color: _videoFallbackColor,
                                                  ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: buildUploadIndicator(),
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
                                      if (!v.isInitialized) {
                                        return const SizedBox.shrink();
                                      }
                                      final remaining = v.duration - v.position;
                                      final safeRemaining = remaining.isNegative
                                          ? Duration.zero
                                          : remaining;
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontFamily: "Montserrat",
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (widget.model.flood == false &&
                                    widget.model.floodCount > 1)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        videoController?.pause();
                                        Get.to(() => FloodListing(
                                                mainModel: widget.model))
                                            ?.then(
                                                (_) => videoController?.play());
                                      },
                                      child: Texts.colorfulFloodLeftSide,
                                    ),
                                  ),
                                if ((widget.isReshared &&
                                        widget.model.originalUserID.isEmpty) ||
                                    widget.model.originalUserID.isNotEmpty)
                                  Positioned(
                                    left: 8,
                                    bottom: ((widget.model.flood == false &&
                                            widget.model.floodCount > 1)
                                        ? 26
                                        : 8),
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
                                            fontSize: 12,
                                          ),
                                      ],
                                    ),
                                  ),
                                _buildIzBirakBlurOverlay(),
                                _buildIzBirakBottomBar(),
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
                                                  vc.pause();
                                                } else {
                                                  vc.play();
                                                  videoStateManager
                                                      .playOnlyThis(
                                                          playbackHandleKey);
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                padding:
                                                    const EdgeInsets.all(8),
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
                                                  size: 16,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        GestureDetector(
                                          onTap:
                                              agendaController.isMuted.toggle,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
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
                                                size: 16,
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
        if (widget.model.hasPlayableVideo || widget.model.img.isNotEmpty)
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
            final me = FirebaseAuth.instance.currentUser;
            if (me == null) return const SizedBox.shrink();
            return Transform.translate(
              offset: const Offset(17, 0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: commentButton(context)),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: likeButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: reshareButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: statButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: saveButton()),
                        )),
                    SizedBox(width: 58, child: Center(child: sendButton())),
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
    final cleanedText = _ctaNavigationService.sanitizeCaptionText(
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
      fontSize: 13,
      fontColor: color,
      mentionColor: Colors.blue,
      hashtagColor: Colors.blue,
      urlColor: Colors.blue,
      interactiveColor: Colors.blue,
      onUrlTap: _handleFeedUrlTap,
      onHashtagTap: (tag) {
        if (tag.trim().isEmpty) return;
        Get.to(() => TagPosts(tag: tag.trim()));
      },
      onMentionTap: (mention) async {
        final targetUid =
            await UsernameLookupRepository.ensure().findUidForHandle(mention) ??
                '';

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (targetUid.isNotEmpty && targetUid != currentUid) {
          await Get.to(() => SocialProfile(userID: targetUid));
        }
      },
    );
  }

  Widget buildPollCard() {
    return Obx(() {
      final model = controller.currentModel.value ?? widget.model;
      final poll = model.poll;
      if (poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      final totalVotes =
          (poll['totalVotes'] is num) ? poll['totalVotes'] as num : 0;
      final uid = controller.userService.userId;
      final userVotes = poll['userVotes'] is Map
          ? Map<String, dynamic>.from(poll['userVotes'])
          : <String, dynamic>{};
      final userVoteRaw = userVotes[uid];
      final int? userVote = userVoteRaw is num
          ? userVoteRaw.toInt()
          : int.tryParse('${userVoteRaw ?? ''}');

      final createdAt = (poll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (poll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      final expired = DateTime.now().millisecondsSinceEpoch > expiresAt;
      final canVote = !expired && userVote == null;
      final showResults = userVote != null || expired;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(options.length, (i) {
              final text = (options[i]['text'] ?? '').toString();
              final votes = (options[i]['votes'] ?? 0) as num;
              final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
              final label = '${String.fromCharCode(65 + i)}) ';
              final isSelected = userVote == i;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canVote ? () => controller.votePoll(i) : null,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.withAlpha(18) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$label$text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (showResults)
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Toplam ${totalVotes.toInt()} oy',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const Spacer(),
                Text(
                  _pollRemainingLabel(
                    expired: expired,
                    expiresAtMs: expiresAt,
                  ),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            )
          ],
        ),
      );
    });
  }

  Widget buildUploadIndicator() {
    final uploadService = Get.isRegistered<UploadQueueService>()
        ? Get.find<UploadQueueService>()
        : Get.put(UploadQueueService());

    return Obx(() {
      QueuedUpload? item;
      for (final q in uploadService.queue) {
        if (q.id == widget.model.docID &&
            (q.status == UploadStatus.pending ||
                q.status == UploadStatus.uploading)) {
          item = q;
          break;
        }
      }

      double? progress;
      if (item != null) {
        progress = item.progress;
      } else {
        final hasVideo = widget.model.hasPlayableVideo ||
            widget.model.video.trim().isNotEmpty ||
            widget.model.hlsMasterUrl.trim().isNotEmpty ||
            widget.model.thumbnail.trim().isNotEmpty;
        final hlsNotReady = widget.model.hlsStatus != 'ready' ||
            widget.model.hlsMasterUrl.trim().isEmpty;
        if (hasVideo && hlsNotReady) {
          final startMs = widget.model.hlsUpdatedAt > 0
              ? widget.model.hlsUpdatedAt.toInt()
              : widget.model.timeStamp.toInt();
          final elapsedMin =
              ((DateTime.now().millisecondsSinceEpoch - startMs) / 60000)
                  .clamp(0, 30);
          progress = 0.9 + (elapsedMin / 30) * 0.09;
        }
      }

      if (progress == null) return const SizedBox.shrink();
      if (progress <= 0) {
        progress = 0.02;
      }
      return RingUploadProgressIndicator(
        isUploading: true,
        progress: progress,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload,
            size: 12,
            color: Colors.black54,
          ),
        ),
      );
    });
  }

  String _pollRemainingLabel(
      {required bool expired, required int expiresAtMs}) {
    if (expired) return 'Süre Doldu';
    final remainingMs = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'Süre Doldu';
    final totalMinutes = (remainingMs / 60000).floor();
    final totalHours = (totalMinutes / 60).floor();
    final days = (totalHours / 24).floor();
    if (days >= 1) return '$days g';
    final hours = totalHours;
    final minutes = totalMinutes % 60;
    return '$hours sa $minutes dk';
  }

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            12.ph,
            const Text(
              "Gönderi Gizlendi",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(
                color: Colors.grey,
              ),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
            GestureDetector(
              onTap: () {
                controller.gizlemeyiGeriAl();
                videoController?.play();
              },
              child: const Text(
                "Geri Al",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Gönderi Arşivlendi",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
            GestureDetector(
              onTap: () {
                controller.arsivdenCikart();
                videoController?.play();
              },
              child: const Text(
                "Geri Al",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Gönderi Sildiniz",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderi artık yayında değil.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }

  void _refreshFlaggedPostState() {
    if (!mounted) return;
    setState(() {});
  }

  StoryUserModel? _resolveStoryUser() {
    if (!Get.isRegistered<StoryRowController>()) return null;
    final users = Get.find<StoryRowController>().users;
    for (final user in users) {
      if (user.userID == widget.model.userID) {
        return user;
      }
    }
    return null;
  }
}
