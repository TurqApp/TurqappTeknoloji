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

  void _refreshQuotedSourceFuture() {
    final sourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    final sourcePostId = widget.model.originalPostID.trim();

    _quotedSourceFutureUserId = sourceUserId;
    _quotedSourceFuturePostId = sourcePostId;

    if (sourceUserId.isEmpty) {
      _quotedSourceFuture = null;
      return;
    }

    final profileCache = Get.isRegistered<UserProfileCacheService>()
        ? Get.find<UserProfileCacheService>()
        : Get.put(UserProfileCacheService(), permanent: true);
    final postRepository = PostRepository.ensure();

    _quotedSourceFuture = Future.wait<dynamic>([
      profileCache.getProfile(
        sourceUserId,
        preferCache: true,
        cacheOnly: false,
      ),
      if (sourcePostId.isNotEmpty)
        postRepository.fetchPostsByIds([sourcePostId])
      else
        Future.value(null),
    ]);
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

  Widget _buildVideoThumbnail({double? aspectRatio}) {
    final thumb = widget.model.thumbnail.trim();
    final fallback = const ColoredBox(color: _videoFallbackColor);
    final cacheHeight = aspectRatio != null
        ? _feedCacheHeightForAspectRatio(aspectRatio)
        : (_feedCacheWidth * 1.4).round();
    final image = thumb.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: thumb,
            fit: BoxFit.cover,
            memCacheWidth: _feedCacheWidth,
            memCacheHeight: cacheHeight,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          )
        : fallback;
    if (aspectRatio == null) return image;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: image,
    );
  }

  bool get _isBlackBadgeUser {
    final raw = (controller.userService.currentUser?.rozet ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i');
    return raw == 'siyah' || raw == 'black';
  }

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      videoStateManager.pauseAllVideos();
    } catch (_) {}
  }

  void _prepareVideoFullscreenTransition() {
    // Geçişte aynı controller'ı fullscreen'e enjekte edeceğiz.
    // Pause çağırmayıp yalnızca feed tarafındaki bir kerelik auto-pause'u atlat.
    markSkipNextPause();
  }

  Future<Duration> _resolveCurrentVideoPosition() async {
    final vc = videoController;
    if (vc != null) {
      try {
        final pos = vc.value.position;
        if (pos > Duration.zero) return pos;
      } catch (_) {}

      try {
        final seconds = await vc.hlsController.getCurrentTime();
        if (seconds > 0) {
          return Duration(milliseconds: (seconds * 1000).round());
        }
      } catch (_) {}
    }

    final savedState = videoStateManager.getVideoState(widget.model.docID);
    return savedState?.position ?? Duration.zero;
  }

  Future<List<PostsModel>> _buildFullscreenStartList() async {
    final candidates = agendaController.agendaList
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    if (candidates.isEmpty) {
      return [widget.model];
    }

    final ids = candidates.map((p) => p.docID).toSet().toList();
    final freshById = await PostRepository.ensure().fetchPostsByIds(
      ids,
      preferCache: true,
    );

    final refreshed = candidates
        .map((p) => freshById[p.docID] ?? p)
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    final tapped = freshById[widget.model.docID] ?? widget.model;
    final rest = refreshed.where((p) => p.docID != tapped.docID).toList()
      ..shuffle();

    return [tapped, ...rest];
  }

  bool _hasEducationFeedCta() {
    final resolved = _ctaNavigationService.resolveMeta(widget.model.reshareMap);
    return resolved.type.isNotEmpty && resolved.docId.isNotEmpty;
  }

  Future<void> _openImageMediaOrFeedCta() async {
    if (_hasEducationFeedCta()) {
      await _ctaNavigationService.openFromPostMeta(widget.model.reshareMap);
      return;
    }

    _pauseFeedBeforeFullscreen();
    final visibleList = agendaController.agendaList
        .where((val) =>
            val.deletedPost == false &&
            val.arsiv == false &&
            val.gizlendi == false &&
            val.img.isNotEmpty)
        .toList();

    if (widget.isPreview) {
      Get.to(() => PhotoShorts(
            fetchedList: visibleList,
            startModel: widget.model,
          ));
    } else {
      if (widget.model.floodCount > 1) {
        Get.to(FloodListing(mainModel: widget.model));
      } else {
        Get.to(() => PhotoShorts(
              fetchedList: visibleList,
              startModel: widget.model,
            ));
      }
    }
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

  Widget _buildQuotedMainBody({required double actionTopSpacing}) {
    final hasOwnCaption = widget.model.metin.trim().isNotEmpty;
    final quoteCardTopSpacing = hasOwnCaption ? 8.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        if (widget.model.konum != "")
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 40),
            child: Row(
              children: [
                Icon(CupertinoIcons.map_pin, color: Colors.red, size: 20),
                const SizedBox(width: 3),
                Text(
                  widget.model.konum,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding:
              EdgeInsets.only(top: quoteCardTopSpacing, left: 45, right: 8),
          child: _buildAgendaQuoteCard(),
        ),
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

  Widget _buildAgendaQuoteCard() {
    final quotedText = widget.model.quotedOriginalText.trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openQuotedOriginalPost,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9DEE5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgendaQuotedSourceHeader(),
                  if (quotedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      quotedText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3A434D),
                        fontSize: 14,
                        height: 1.35,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.model.hasPlayableVideo)
              _buildAgendaQuotedVideoPreview()
            else if (widget.model.img.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildQuotedImageContent(widget.model.img),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaQuotedSourceHeader() {
    final sourceUserId = _quotedSourceFutureUserId;
    final sourcePostId = _quotedSourceFuturePostId;
    final future = _quotedSourceFuture;
    if (sourceUserId.isEmpty || future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final profile = (snapshot.data != null && snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : null) as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final sourcePostMap = snapshot.data != null && snapshot.data!.length > 1
            ? snapshot.data![1] as Map<String, PostsModel>?
            : null;
        final sourcePostData =
            sourcePostMap?[sourcePostId]?.toMap() ?? const <String, dynamic>{};
        String firstNonEmpty(List<dynamic> values, [String fallback = '']) {
          for (final value in values) {
            final text = (value ?? '').toString().trim();
            if (text.isNotEmpty) return text;
          }
          return fallback;
        }

        final username = firstNonEmpty([
          widget.model.quotedSourceUsername,
          profile['username'],
          sourcePostData['username'],
          sourcePostData['authorNickname'],
          profile['nickname'],
        ]);
        final displayName = firstNonEmpty([
          widget.model.quotedSourceDisplayName,
          profile['displayName'],
          profile['fullName'],
          profile['name'],
          sourcePostData['displayName'],
          sourcePostData['authorDisplayName'],
          sourcePostData['fullName'],
          sourcePostData['authorNickname'],
          sourcePostData['nickname'],
          profile['nickname'],
          profile['username'],
        ], username.isNotEmpty ? username : 'Kullanıcı');
        final avatarUrl = (widget.model.quotedSourceAvatarUrl.isNotEmpty
                ? widget.model.quotedSourceAvatarUrl
                : (profile['avatarUrl'] ??
                    sourcePostData['authorAvatarUrl'] ??
                    ''))
            .toString()
            .trim();
        final quotedTime = ((sourcePostData['izBirakYayinTarihi'] ??
                    sourcePostData['timeStamp']) ??
                0)
            .toString();
        final timeStamp =
            num.tryParse(quotedTime) ?? (sourcePostData['timeStamp'] ?? 0);
        final displayTime =
            timeStamp == 0 ? '' : timeAgoMetin(timeStamp).toString();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CachedUserAvatar(
              userId: sourceUserId,
              imageUrl: avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName.isEmpty ? 'Kullanıcı' : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  RozetContent(size: 13, userID: sourceUserId),
                  if (displayTime.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        displayTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuotedImageContent(List<String> images) {
    final outerRadius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildQuotedImageGrid(images),
    );
  }

  Widget _buildQuotedImageGrid(List<String> images) {
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 0.80,
          child: _buildImage(
            images[0],
            radius: BorderRadius.circular(12),
            showShareCta: false,
          ),
        );
      case 2:
        return _buildTwoImageGrid(images);
      case 3:
        return _buildThreeImageGrid(images);
      case 4:
      default:
        return buildFourImageGrid(images);
    }
  }

  Widget _buildAgendaQuotedVideoPreview() {
    final thumb = widget.model.thumbnail.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: _videoFallbackColor,
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: _videoFallbackColor,
                  ),
                )
              else
                const ColoredBox(color: _videoFallbackColor),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(
                      videoController?.value.duration ?? Duration.zero,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openQuotedOriginalPost() async {
    final originalPostId = widget.model.originalPostID.trim();
    if (originalPostId.isEmpty) {
      AppSnackbar('Bilgi', 'Kaynak gönderiye ulaşılamıyor.');
      return;
    }

    try {
      final model = await PostRepository.ensure().fetchPostById(
        originalPostId,
        preferCache: true,
      );

      if (model == null) {
        AppSnackbar('Bilgi', 'Kaynak gönderiye ulaşılamıyor.');
        return;
      }
      if (model.deletedPost) {
        AppSnackbar('Bilgi', 'Kaynak gönderi silinmiş.');
        return;
      }

      if (model.flood == false && model.floodCount > 1) {
        await Get.to(() => FloodListing(mainModel: model));
        return;
      }

      try {
        videoController?.pause();
      } catch (_) {}
      try {
        videoStateManager.pauseAllVideos(force: true);
      } catch (_) {}
      try {
        agendaController.pauseAll.value = false;
      } catch (_) {}
      await Get.to(() => SinglePost(model: model, showComments: false));
    } catch (_) {
      AppSnackbar('Bilgi', 'Kaynak gönderiye ulaşılamıyor.');
    }
  }

  Future<
      ({
        String userId,
        String displayName,
        String username,
        String avatarUrl
      })> _resolveQuotedSourceSnapshot() async {
    String pick(List<dynamic> values, [String fallback = '']) {
      for (final value in values) {
        final text = (value ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }

    final sourceUserId = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.userID.trim();

    String displayName = widget.model.quotedPost &&
            widget.model.quotedSourceDisplayName.trim().isNotEmpty
        ? widget.model.quotedSourceDisplayName.trim()
        : pick([
            controller.fullName.value,
            controller.nickname.value,
            controller.username.value,
            widget.model.authorNickname,
          ]);
    String username = widget.model.quotedPost &&
            widget.model.quotedSourceUsername.trim().isNotEmpty
        ? widget.model.quotedSourceUsername.trim()
        : pick([
            controller.username.value,
            controller.nickname.value,
            widget.model.authorNickname,
          ]);
    String avatarUrl = widget.model.quotedPost &&
            widget.model.quotedSourceAvatarUrl.trim().isNotEmpty
        ? widget.model.quotedSourceAvatarUrl.trim()
        : controller.avatarUrl.value.trim();

    if (sourceUserId.isNotEmpty) {
      try {
        final profileCache = Get.isRegistered<UserProfileCacheService>()
            ? Get.find<UserProfileCacheService>()
            : Get.put(UserProfileCacheService(), permanent: true);
        final profile = (await profileCache.getProfile(
              sourceUserId,
              preferCache: true,
              cacheOnly: false,
            )) ??
            const <String, dynamic>{};
        displayName = pick([
          displayName,
          profile['displayName'],
          profile['fullName'],
          profile['name'],
          profile['nickname'],
          profile['username'],
        ], displayName);
        username = pick([
          username,
          profile['username'],
          profile['nickname'],
        ], username);
        final resolvedAvatar = resolveAvatarUrl(profile).trim();
        if (resolvedAvatar.isNotEmpty &&
            resolvedAvatar != kDefaultAvatarUrl &&
            avatarUrl.trim().isEmpty) {
          avatarUrl = resolvedAvatar;
        }
      } catch (_) {}
    }

    return (
      userId: sourceUserId,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
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
      fontSize: 14,
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

  bool _hasStoryAvatar() {
    final storyUser = _resolveStoryUser();
    return storyUser != null && storyUser.stories.isNotEmpty;
  }

  void _openAvatarStoryOrProfile() {
    final storyUser = _resolveStoryUser();
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      videoController?.pause();
      final users =
          Get.find<StoryRowController>().users.toList(growable: false);
      Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: users,
          ))?.then((_) {
        videoController?.play();
      });
      return;
    }

    videoController?.pause();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final route = widget.model.userID == currentUid
        ? Get.to(() => ProfileView())
        : Get.to(() => SocialProfile(userID: widget.model.userID));
    route?.then((_) {
      videoController?.play();
    });
  }

  Widget _buildStoryAwareAvatar({
    required String userId,
    required String imageUrl,
    required double radius,
  }) {
    final hasStory = _hasStoryAvatar();
    final ringColors = hasStory
        ? const [
            Color(0xFFB7F3D0),
            Color(0xFF5AD39A),
            Color(0xFF20B26B),
            Color(0xFF12824D),
          ]
        : const [
            Color(0xFFB7D8FF),
            Color(0xFF6EB6FF),
            Color(0xFF2C8DFF),
            Color(0xFF0E5BFF),
          ];

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: hasStory ? 0.018 : 0),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: ringColors,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CachedUserAvatar(
            userId: userId,
            imageUrl: imageUrl,
            radius: radius,
          ),
        ),
      ),
      builder: (context, turns, child) {
        return Transform.rotate(
          angle: turns * 2 * 3.141592653589793,
          child: child,
        );
      },
    );
  }

  Widget headerUserInfoBar() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.nickname.value.trim();
    final handle = controller.nickname.value.trim().isNotEmpty
        ? controller.nickname.value.trim()
        : controller.username.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final displayTime = buildDisplayTime();
    final shouldHideFollow = primaryName.length +
            controller.nickname.value.length +
            displayTime.length >
        28;
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildStoryAwareAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 20,
                )),
          ),
          6.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: openProfile,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                primaryName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '@$handle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            RozetContent(size: 13, userID: widget.model.userID),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, right: 12),
                              child: Obx(
                                () {
                                  _relativeTimeTickService.tick.value;
                                  return Text(
                                    buildDisplayTime(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        widget.model.userID !=
                            FirebaseAuth.instance.currentUser!.uid &&
                        controller.avatarUrl.value != "" &&
                        !shouldHideFollow)
                      Obx(() => TextButton(
                            onPressed: controller.followLoading.value
                                ? null
                                : () {
                                    controller.followUser();
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: controller.followLoading.value
                                ? Container(
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(12)),
                                        border:
                                            Border.all(color: Colors.black)),
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 15),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.black),
                                        ),
                                      ),
                                    ),
                                  )
                                : Texts.followMeButtonBlack,
                          )),
                    const SizedBox(width: 7),
                    pulldownmenu(),
                  ],
                ),
                if ((widget.model.hasPlayableVideo ||
                        widget.model.img.isNotEmpty) &&
                    _ctaNavigationService
                        .sanitizeCaptionText(
                          widget.model.metin,
                          meta: widget.model.reshareMap,
                        )
                        .isNotEmpty)
                  _buildFeedCaption(
                    text: widget.model.metin.trim(),
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: outerRadius,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          GestureDetector(
            onTap: _openImageMediaOrFeedCta,
            onDoubleTap: () {
              controller.like();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: outerRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageContent(images),
            ),
          ),
          _buildIzBirakBlurOverlay(),
          _buildIzBirakBottomBar(),
          if (widget.model.floodCount > 1 && widget.model.flood == false)
            GestureDetector(
              onTap: () {
                Get.to(() => FloodListing(mainModel: widget.model));
              },
              child: Texts.colorfulFloodLeftSide,
            ),
          if ((widget.isReshared && widget.model.originalUserID.isEmpty) ||
              widget.model.originalUserID.isNotEmpty)
            Positioned(
              left: 8,
              bottom:
                  (widget.model.floodCount > 1 && widget.model.flood == false)
                      ? 26
                      : 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isReshared && widget.model.originalUserID.isEmpty)
                    _buildAgendaReshareOverlay(),
                  if (widget.model.originalUserID.isNotEmpty)
                    SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      textColor: Colors.white,
                      fontSize: 12,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgendaReshareOverlay() {
    if (widget.model.originalUserID.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.repeat,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          ReshareAttribution(
            controller: controller,
            model: widget.model,
            explicitReshareUserId: widget.reshareUserID,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(List<String> images) {
    if (_isIzBirakPost) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.92,
          child: _buildImage(
            images.first,
            radius: BorderRadius.circular(12),
            showShareCta: false,
          ),
        ),
      );
    }
    final type =
        _ctaNavigationService.resolveMeta(widget.model.reshareMap).type;
    final preserveScholarshipFrame =
        type == 'scholarship' && widget.model.img.length == 1;
    final singleImageAspectRatio = preserveScholarshipFrame
        ? widget.model.aspectRatio.toDouble().clamp(0.65, 1.8)
        : 0.80;

    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: singleImageAspectRatio,
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );

      case 2:
        return _buildTwoImageGrid(images);

      case 3:
        return _buildThreeImageGrid(images);

      case 4:
      default:
        return buildFourImageGrid(widget.model.img);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    // shrinkWrap: true yerine Column kullanarak her frame'de layout hesaplamasını engelle
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[0], radius: _getGridRadius(0)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[1], radius: _getGridRadius(1)))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[2], radius: _getGridRadius(2)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[3], radius: _getGridRadius(3)))),
          ],
        ),
      ],
    );
  }

  Widget _buildThreeImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // Kare yapı
          child: Row(
            children: [
              // Soldaki büyük görsel
              Expanded(
                flex: 1,
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Sağdaki iki küçük görsel
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwoImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(
    String url, {
    required BorderRadius radius,
    bool showShareCta = true,
  }) {
    final safeUrl = url.trim();
    if (safeUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: CachedNetworkImage(
              imageUrl: safeUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: _feedCacheWidth,
              memCacheHeight: (_feedCacheWidth * 1.4).round(),
              placeholder: (_, __) => const SizedBox.shrink(),
            ),
          ),
          if (widget.model.img.length == 1 && showShareCta)
            _buildFeedShareCta(),
        ],
      ),
    );
  }

  Widget _buildFeedShareCta() {
    if (_isIzBirakPost) {
      return const SizedBox.shrink();
    }
    final resolvedCta =
        _ctaNavigationService.resolveMeta(widget.model.reshareMap);
    final label = resolvedCta.label;
    final type = resolvedCta.type;
    final docId = resolvedCta.docId;
    if (label.isEmpty || type.isEmpty || docId.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = _feedCtaPaletteFor(type: type, docId: docId);

    return Positioned(
      right: 10,
      bottom: 10,
      child: GestureDetector(
        onTap: () =>
            _ctaNavigationService.openFromPostMeta(widget.model.reshareMap),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: palette.last.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _feedCtaPaletteFor({
    required String type,
    required String docId,
  }) {
    const palettes = <List<Color>>[
      <Color>[Color(0xFF20D67B), Color(0xFF119D57)],
      <Color>[Color(0xFFFF5CA8), Color(0xFFD81B60)],
      <Color>[Color(0xFFFFB238), Color(0xFFF26B1D)],
      <Color>[Color(0xFF2EC5FF), Color(0xFF0077D9)],
      <Color>[Color(0xFFB56CFF), Color(0xFF7B2CFF)],
    ];
    final seed = '$type:$docId'.codeUnits.fold<int>(0, (a, b) => a + b);
    return palettes[seed % palettes.length];
  }

  Future<void> _handleFeedUrlTap(String url) async {
    final handled = await _ctaNavigationService.openFromInternalUrl(url);
    if (handled) {
      return;
    }

    final uniqueKey = DateTime.now().millisecondsSinceEpoch.toString();
    await RedirectionLink().goToLink(url, uniqueKey: uniqueKey);
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }

  Widget pulldownmenu() {
    final canManagePost =
        widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            controller.canSendAdminPush;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();

            Get.to(() => PostCreator(
                  sharedVideoUrl: widget.model.playbackUrl,
                  sharedImageUrls: widget.model.img,
                  sharedAspectRatio: widget.model.aspectRatio.toDouble(),
                  sharedThumbnail: widget.model.thumbnail,
                  originalUserID:
                      PostStoryShareService.resolveOriginalUserId(widget.model),
                  originalPostID:
                      PostStoryShareService.resolveOriginalPostId(widget.model),
                  sharedAsPost: true,
                ))?.then((_) {
              videoController?.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();
            await PostStoryShareService.openStoryMakerForPost(widget.model);
            videoController?.play();
          },
          title: 'Hikayene ekle',
          icon: CupertinoIcons.sparkles,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostSharers(postID: widget.model.docID))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Gönderi olarak paylaşanlar',
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: () {
            controller.sendPost();
          },
          title: 'Gönder',
          icon: CupertinoIcons.paperplane,
        ),
        PullDownMenuItem(
          onTap: () {
            videoController?.pause();
            controller.gizle();
          },
          title: 'Gizle',
          icon: CupertinoIcons.eye_slash,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostCreator(
                    editMode: true,
                    editPost: widget.model,
                  ))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Düzenle',
            icon: CupertinoIcons.pencil_circle,
          ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              controller.sendAdminPushForPost().whenComplete(() {
                if (widget.shouldPlay) {
                  videoController?.play();
                }
              });
            },
            title: 'Push',
            icon: CupertinoIcons.bell,
          ),
        PullDownMenuItem(
          onTap: () async {
            final previewImage = widget.model.thumbnail.trim().isNotEmpty
                ? widget.model.thumbnail.trim()
                : (widget.model.img.isNotEmpty
                    ? widget.model.img.first.trim()
                    : null);
            final url = await ShortLinkService().getPostPublicUrl(
              postId: widget.model.docID,
              desc: widget.model.metin,
              imageUrl: previewImage,
            );

            await Clipboard.setData(ClipboardData(text: url));

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
          },
          title: 'Linki Kopyala',
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () async {
            await ShareActionGuard.run(() async {
              final previewImage = widget.model.thumbnail.trim().isNotEmpty
                  ? widget.model.thumbnail.trim()
                  : (widget.model.img.isNotEmpty
                      ? widget.model.img.first.trim()
                      : null);
              final url = await ShortLinkService().getPostPublicUrl(
                postId: widget.model.docID,
                desc: widget.model.metin,
                imageUrl: previewImage,
              );
              await ShareLinkService.shareUrl(
                url: url,
                title: 'TurqApp Gönderisi',
                subject: 'TurqApp Gönderisi',
              );
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (canManagePost)
          PullDownMenuItem(
            onTap: () {
              // 2) Videoyu durdur
              videoController?.pause();

              // 3) Alert’i göster ve kapandıktan sonra silinme durumuna göre videoyu devam ettir
              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                yesText: "Gönderiyi Sil",
                cancelText: "Vazgeç",
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                // Eğer silinmediyse videoyu tekrar başlat
                if (!controller.silindi.value) {
                  videoController?.play();
                }
              });
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoController?.pause();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoController?.play();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Şikayet Et',
            icon: CupertinoIcons.info,
            isDestructive: true,
          ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        alignment: Alignment.center,
        minimumSize: Size(0, 0),
        child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
      ),
    );
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final int visibility = widget.model.yorumVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final bool canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final Color displayColor = _actionColor;

      return AnimatedActionButton(
        enabled: canInteract,
        semanticsLabel: 'Yorumlar',
        onTap: canInteract ? controller.showPostCommentsBottomSheet : null,
        showTapArea: _showActionTapAreas,
        child: _iconAction(
          icon: CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 17,
        ),
      );
    });
  }

  Widget likeButton() {
    final bool isLiked =
        controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
    final Color likeColor = isLiked ? Colors.blueAccent : _actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Beğeniler',
      onTap: controller.like,
      showTapArea: _showActionTapAreas,
      onLongPress: () {
        videoController?.pause();
        Get.bottomSheet(
          Container(
            height: Get.height / 2,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: PostLikeListing(postID: widget.model.docID),
          ),
        ).then((_) {
          videoController?.play();
        });
      },
      child: _iconAction(
        icon: isLiked
            ? CupertinoIcons.hand_thumbsup_fill
            : CupertinoIcons.hand_thumbsup,
        color: likeColor,
        label: NumberFormatter.format(controller.likeCount.value),
        labelColor: likeColor,
        iconSize: 17,
        leadingTransformOffsetY: -2,
      ),
    );
  }

  Widget reshareButton() {
    return Obx(() {
      final int visibility = widget.model.paylasimVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final currentUserId = controller.userService.userId;
      final bool canReshare = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final bool isCurrentUsersReshareCard = currentUserId.isNotEmpty &&
          widget.reshareUserID?.trim() == currentUserId;
      final bool isReshared =
          controller.yenidenPaylasildiMi.value || isCurrentUsersReshareCard;
      final Color displayColor = isReshared ? Colors.green : _actionColor;

      return PullDownButton(
        itemBuilder: (context) => [
          PullDownMenuItem(
            onTap: canReshare ? _runSimpleReshare : null,
            title: isReshared ? 'Yeniden paylaşımı geri al' : 'Yeniden paylaş',
            icon: Icons.repeat,
          ),
          PullDownMenuItem(
            onTap: canReshare ? _openQuoteComposer : null,
            title: 'Alıntıla',
            icon: CupertinoIcons.quote_bubble,
          ),
        ],
        buttonBuilder: (context, showMenu) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: canReshare ? _openReshareUsersSheet : null,
          child: AnimatedActionButton(
            enabled: canReshare,
            semanticsLabel: 'Yeniden paylaş',
            onTap: canReshare ? showMenu : null,
            showTapArea: _showActionTapAreas,
            child: _iconAction(
              icon: Icons.repeat,
              color: displayColor,
              label: NumberFormatter.format(controller.retryCount.value),
              labelColor: displayColor,
            ),
          ),
        ),
      );
    });
  }

  void _runSimpleReshare() {
    controller.reshare();
    videoController?.play();
  }

  void _openReshareUsersSheet() {
    videoController?.pause();
    final targetPostId = widget.model.originalPostID.trim().isNotEmpty
        ? widget.model.originalPostID.trim()
        : widget.model.docID;
    Get.bottomSheet(
      PostReshareListing(postID: targetPostId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      videoController?.play();
    });
  }

  Future<void> _openQuoteComposer() async {
    String finalOriginalUserID;
    String finalOriginalPostID;
    final sourceSnapshot = await _resolveQuotedSourceSnapshot();
    final String resolvedQuotedText = widget.model.quotedPost &&
            widget.model.quotedOriginalText.trim().isNotEmpty
        ? widget.model.quotedOriginalText.trim()
        : widget.model.metin.trim();
    final String resolvedQuotedSourceUserID = widget.model.quotedPost &&
            widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : sourceSnapshot.userId;
    final String resolvedQuotedSourceDisplayName =
        sourceSnapshot.displayName.trim();
    final String resolvedQuotedSourceUsername = sourceSnapshot.username.trim();
    final String resolvedQuotedSourceAvatarUrl =
        sourceSnapshot.avatarUrl.trim();

    if (widget.model.originalUserID.isNotEmpty) {
      finalOriginalUserID = widget.model.originalUserID;
      finalOriginalPostID = widget.model.originalPostID;
    } else {
      finalOriginalUserID = widget.model.userID;
      finalOriginalPostID = widget.model.docID;
    }

    Get.to(() => PostCreator(
          sharedVideoUrl: widget.model.playbackUrl,
          sharedImageUrls: widget.model.img,
          sharedAspectRatio: widget.model.aspectRatio.toDouble(),
          sharedThumbnail: widget.model.thumbnail,
          originalUserID: finalOriginalUserID,
          originalPostID: finalOriginalPostID,
          sourcePostID: widget.model.docID,
          sharedAsPost: true,
          quotedPost: true,
          quotedOriginalText: resolvedQuotedText,
          quotedSourceUserID: resolvedQuotedSourceUserID,
          quotedSourceDisplayName: resolvedQuotedSourceDisplayName,
          quotedSourceUsername: resolvedQuotedSourceUsername,
          quotedSourceAvatarUrl: resolvedQuotedSourceAvatarUrl,
        ))?.then((_) {
      videoController?.play();
    });
  }

  Widget saveButton() {
    final bool isSaved = controller.saved.value == true;
    final Color displayColor = isSaved ? Colors.orange : _actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Kaydet',
      onTap: controller.save,
      showTapArea: _showActionTapAreas,
      child: _iconAction(
        icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        color: displayColor,
        label: NumberFormatter.format(controller.savedCount.value),
        labelColor: displayColor,
        iconSize: 17,
      ),
    );
  }

  Widget statButton() {
    return SizedBox(
      height: AnimatedActionButton.actionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                Icons.bar_chart,
                color: _actionColor,
                size: 20,
              ),
            ),
          ),
          2.pw,
          SizedBox(
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Text(
                NumberFormatter.format(controller.statsCount.value),
                style: const TextStyle(
                  color: _actionColor,
                  fontSize: 12,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sendButton() {
    if (_isBlackBadgeUser) {
      final alreadyFlagged = _flaggedPostIds.contains(widget.model.docID);
      if (alreadyFlagged) {
        return AnimatedActionButton(
          enabled: false,
          semanticsLabel: 'İşaretlendi',
          onTap: null,
          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
          showTapArea: _showActionTapAreas,
          child: SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.grey,
                size: _actionStyle.sendIconSize,
              ),
            ),
          ),
        );
      }

      return PullDownButton(
        itemBuilder: (context) => _flagReasons
            .map(
              (reason) => PullDownMenuItem(
                onTap: () async {
                  try {
                    final result = await Get.put(PostInteractionService())
                        .flagPostWithReason(
                      widget.model.docID,
                      reason: reason,
                    );
                    if (result.isOk) {
                      _flaggedPostIds.add(widget.model.docID);
                      if (mounted) setState(() {});
                    }
                    if (result.accepted) {
                      AppSnackbar('İşaretle', 'İşaretleme kaydedildi.');
                    } else if (result.alreadyFlagged) {
                      AppSnackbar('Bilgi', 'Bu gönderiyi zaten işaretlediniz.');
                    } else {
                      AppSnackbar('Hata', 'İşaretleme başarısız oldu.');
                    }
                  } catch (_) {
                    AppSnackbar('Hata', 'İşaretleme başarısız oldu.');
                  }
                },
                title: reason,
              ),
            )
            .toList(),
        buttonBuilder: (context, showMenu) => AnimatedActionButton(
          enabled: true,
          semanticsLabel: 'İşaretle',
          onTap: showMenu,
          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
          showTapArea: _showActionTapAreas,
          child: SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.amber,
                size: _actionStyle.sendIconSize,
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
      showTapArea: _showActionTapAreas,
      child: SizedBox(
        width: 20,
        height: AnimatedActionButton.actionHeight,
        child: Center(
          child: Icon(
            CupertinoIcons.paperplane,
            color: _actionColor,
            size: _actionStyle.sendIconSize,
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    Color? labelColor,
    double? iconSize,
    double leadingTransformOffsetY = 0,
  }) {
    return _actionContent(
      leading: Transform.translate(
        offset: Offset(0, leadingTransformOffsetY),
        child: Icon(
          icon,
          color: color,
          size: iconSize ?? _actionStyle.iconSize,
        ),
      ),
      label: label,
      labelColor: labelColor ?? color,
    );
  }

  Widget _actionContent({
    required Widget leading,
    String? label,
    Color? labelColor,
  }) {
    return ActionButtonContent(
      leading: leading,
      label: label,
      labelStyle: _actionStyle.textStyle.copyWith(
        color: labelColor ?? _actionStyle.textStyle.color,
      ),
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
