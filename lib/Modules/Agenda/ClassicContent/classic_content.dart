import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/Services/education_feed_cta_navigation_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/relative_time_tick_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/ring_upload_progress_indicator.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Core/Repositories/username_lookup_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/Components/post_state_messages.dart';
import '../Common/post_content_base.dart';
import '../Common/post_content_controller.dart';
import '../Common/post_action_style.dart';
import 'package:turqappv2/Modules/Agenda/Common/reshare_attribution.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/post_reshare_listing.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/post_interaction_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';
import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/redirection_link.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/texts.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../Social/PostSharers/post_sharers.dart';
import '../../Profile/MyProfile/profile_view.dart';
import '../../SocialProfile/social_profile.dart';
import '../../PostCreator/post_creator.dart';
import '../TagPosts/tag_posts.dart';
import 'classic_content_controller.dart';

class ClassicContent extends PostContentBase {
  const ClassicContent({
    super.key,
    required super.model,
    required super.isPreview,
    required super.shouldPlay,
    bool isYenidenPaylasilanPost = false,
    super.reshareUserID,
  }) : super(
          isReshared: isYenidenPaylasilanPost,
          showComments: false,
          showArchivePost: false,
        );

  @override
  PostContentController createController() =>
      ClassicContentController(model: model);

  @override
  State<ClassicContent> createState() => _ClassicContentState();
}

class _ClassicContentState extends State<ClassicContent>
    with PostContentBaseState<ClassicContent> {
  final PostRepository _postRepository = PostRepository.ensure();
  static const PostActionStyle _actionStyle = PostActionStyle(
    iconSize: 22,
    textStyle: TextStyle(
      color: Color(0xFF47515C),
      fontSize: 16,
      fontFamily: 'MontserratMedium',
    ),
    reshareIcon: Icons.repeat,
    sendIconSize: 20,
    rowSpacing: 0,
  );
  static const Color _actionColor = Color(0xFF47515C);
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
  final arsivController = Get.put(ArchiveController());
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFullscreen = false;
  bool _isCaptionExpanded = false;
  bool _isQuoteExpanded = false;
  late final RelativeTimeTickService _relativeTimeTickService;
  Future<Map<String, dynamic>?>? _quotedSourceProfileFuture;
  String _quotedSourceProfileUserId = '';

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
    _refreshQuotedSourceProfileFuture();
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
    const fallback = ColoredBox(color: Colors.transparent);
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

  ShortController get shortsController => Get.isRegistered<ShortController>()
      ? Get.find<ShortController>()
      : Get.put(ShortController());

  bool get _isBlackBadgeUser {
    final raw = (controller.userService.currentUser?.rozet ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i');
    return raw == 'siyah' || raw == 'black';
  }

  static const EducationFeedCtaNavigationService _ctaNavigationService =
      EducationFeedCtaNavigationService();

  Future<void> _openMentionProfile(String mention) async {
    final targetUid =
        await UsernameLookupRepository.ensure().findUidForHandle(mention) ?? '';
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (targetUid.isNotEmpty && targetUid != currentUid) {
      await Get.to(() => SocialProfile(userID: targetUid));
    }
  }

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      VideoStateManager.instance.pauseAllVideos();
    } catch (_) {}
  }

  void _openImageMedia() {
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
    } else if (widget.model.floodCount > 1) {
      Get.to(() => FloodListing(mainModel: widget.model));
    } else {
      Get.to(() => PhotoShorts(
            fetchedList: visibleList,
            startModel: widget.model,
          ));
    }
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
    _openImageMedia();
  }

  void _prepareVideoFullscreenTransition() {
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

    if (candidates.isEmpty) return [widget.model];

    final ids = candidates.map((p) => p.docID).toList();
    final fetched = await _postRepository.fetchPostsByIds(ids);
    final freshById = <String, PostsModel>{};
    fetched.forEach((key, model) {
      if (model.deletedPost == false &&
          model.arsiv == false &&
          model.gizlendi == false &&
          model.hasPlayableVideo) {
        freshById[key] = model;
      }
    });

    final List<PostsModel> ordered = candidates
        .map<PostsModel>((p) => freshById[p.docID] ?? p)
        .where((p) => p.hasPlayableVideo)
        .toList();

    if (ordered.any((p) => p.docID == widget.model.docID)) {
      return ordered;
    }
    return [widget.model, ...ordered];
  }

  Future<void> _openVideoMedia() async {
    if (_shouldBlurIzBirakPost) {
      videoController?.pause();
      return;
    }
    if (widget.model.floodCount > 1) {
      videoController?.pause();
      await Get.to(() => FloodListing(mainModel: widget.model));
      if (widget.shouldPlay) {
        videoController?.play();
      }
      return;
    }

    final currentPos = await _resolveCurrentVideoPosition();
    final listForFullscreen = await _buildFullscreenStartList();

    _prepareVideoFullscreenTransition();
    _pauseFeedBeforeFullscreen();
    setPauseBlocked(true);
    if (mounted) {
      setState(() => _isFullscreen = true);
    }

    final res = await Get.to(() => SingleShortView(
          startModel: widget.model,
          startList: listForFullscreen,
          initialPosition: currentPos,
          injectedController: videoController,
        ));

    setPauseBlocked(false);
    if (mounted) {
      setState(() => _isFullscreen = false);
    }

    if (!mounted) return;

    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.centeredIndex.value = modelIndex;
      agendaController.lastCenteredIndex = modelIndex;
    }

    final vc = videoController;
    if (vc != null && vc.value.isInitialized) {
      if (res is Map && res['docID'] == widget.model.docID) {
        final int? ms = res['positionMs'] as int?;
        if (ms != null) {
          await vc.seekTo(Duration(milliseconds: ms));
          if (widget.shouldPlay) {
            vc.play();
            vc.setVolume(agendaController.isMuted.value ? 0 : 1);
          }
          return;
        }
      }
      if (widget.shouldPlay) {
        tryAutoPlayWhenBuffered();
      }
    }
  }

  Widget _buildMediaTapOverlay({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
  }) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildClassicReshareOverlay({required double bottom}) {
    if (!widget.isReshared || widget.model.originalUserID.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 8,
      bottom: bottom,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicAvatar({
    required String userId,
    required String imageUrl,
    double radius = 16.5,
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
            colors: ringColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
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

  Widget _buildClassicWhiteBadge(double size) {
    return Transform.translate(
      offset: const Offset(0, -1),
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: Colors.white,
              size: size,
            ),
            Icon(
              CupertinoIcons.check_mark,
              color: Colors.black87,
              size: size * 0.42,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicOverlayFollowButton({required bool loading}) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 72),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(color: Colors.white),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    "Takip Et",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "MontserratMedium",
                      fontSize: 14,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicMediaHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: headerUserInfoWhite(),
    );
  }

  @override
  bool get enableBufferedAutoplay => false;

  static const double _reelPortraitFrameAspectRatio = 5 / 8;
  static const double _feedPortraitFrameAspectRatio = 4 / 5;
  static const double _squareFrameAspectRatio = 0.92;
  bool get _shouldPreserveScholarshipShareFrame {
    final type =
        _ctaNavigationService.resolveMeta(widget.model.reshareMap).type;
    return type == 'scholarship' && widget.model.img.length == 1;
  }

  double get _resolvedClassicFrameAspectRatio {
    final raw = widget.model.aspectRatio.toDouble();
    if (_shouldPreserveScholarshipShareFrame && raw > 0) {
      return raw.clamp(0.65, 1.8);
    }
    if (raw <= 0) return _squareFrameAspectRatio;
    if (raw < 0.7) return _reelPortraitFrameAspectRatio;
    if (raw < 0.9) return _feedPortraitFrameAspectRatio;
    return _squareFrameAspectRatio;
  }

  @override
  void onPostInitialized() {
    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (next != _currentPage) {
        setState(() => _currentPage = next);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassicContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSourceUserId = oldWidget.model.quotedSourceUserID.trim().isNotEmpty
        ? oldWidget.model.quotedSourceUserID.trim()
        : oldWidget.model.originalUserID.trim();
    final newSourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    if (oldSourceUserId != newSourceUserId) {
      _refreshQuotedSourceProfileFuture();
    }
    if (widget.shouldPlay != oldWidget.shouldPlay &&
        videoController?.value.isInitialized == true) {
      if (_shouldBlurIzBirakPost) {
        videoController?.pause();
      } else if (widget.shouldPlay) {
        videoController!
          ..setLooping(true)
          ..play();
      } else {
        videoController?.pause();
      }
    }
  }

  void _refreshQuotedSourceProfileFuture() {
    final sourceUserId = widget.model.quotedSourceUserID.trim().isNotEmpty
        ? widget.model.quotedSourceUserID.trim()
        : widget.model.originalUserID.trim();
    _quotedSourceProfileUserId = sourceUserId;
    if (sourceUserId.isEmpty) {
      _quotedSourceProfileFuture = null;
      return;
    }

    final profileCache = Get.isRegistered<UserProfileCacheService>()
        ? Get.find<UserProfileCacheService>()
        : Get.put(UserProfileCacheService());
    _quotedSourceProfileFuture = profileCache.getProfile(
      sourceUserId,
      preferCache: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gizli, arşivli veya silindi ise videoyu durdur
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value ||
        _shouldBlurIzBirakPost) {
      videoController?.pause();
    }
    return Obx(() {
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
            widget.model.img.isNotEmpty
                ? imgBody(context)
                : (widget.model.hasPlayableVideo
                    ? videoBody(context)
                    : textOnlyBody(context))
        ],
      );
    });
  }

  Widget textOnlyBody(BuildContext context) {
    final sanitizedCaption = _ctaNavigationService.sanitizeCaptionText(
      widget.model.metin,
      meta: widget.model.reshareMap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onDoubleTap: () => controller.like(),
            onTap: () {
              if (widget.model.floodCount > 1) {
                Get.to(() => FloodListing(mainModel: widget.model));
              }
            },
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    sanitizedCaption,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 0,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                // SharedPostLabel - text içeriğinin sol altına
                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 15,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      fontSize: 12,
                      textColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 58, child: Center(child: commentButton(context))),
              SizedBox(width: 58, child: Center(child: likeButton())),
              SizedBox(width: 58, child: Center(child: saveButton())),
              SizedBox(width: 58, child: Center(child: reshareButton())),
              SizedBox(width: 58, child: Center(child: statButton())),
              SizedBox(width: 58, child: Center(child: sendButton())),
            ],
          ),
        ),
        3.ph,
      ],
    );
  }

  Widget _buildClassicInlineCaption({
    required String nickname,
    required String text,
  }) {
    const nameStyle = TextStyle(
      color: Color(0xFF20252B),
      fontSize: 14,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );
    const bodyStyle = TextStyle(
      color: Color(0xFF20252B),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const moreStyle = TextStyle(
      color: Color(0xFF6E7680),
      fontSize: 14,
      fontFamily: 'Montserrat',
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          children: [
            TextSpan(text: nickname, style: nameStyle),
            const TextSpan(text: '  '),
            ...ClickableTextController.buildSpans(
              text: text,
              plainStyle: bodyStyle,
              urlStyle: bodyStyle.copyWith(color: Colors.blue),
              hashtagStyle: bodyStyle.copyWith(color: Colors.blue),
              mentionStyle: bodyStyle.copyWith(color: Colors.blue),
              onUrlTap: (url) => RedirectionLink().goToLink(url),
              onHashtagTap: (tag) {
                if (tag.trim().isEmpty) return;
                Get.to(() => TagPosts(tag: tag.trim()));
              },
              onMentionTap: (mention) {
                unawaited(_openMentionProfile(mention));
              },
            ),
          ],
        );

        final painter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: constraints.maxWidth);

        final exceeds = painter.didExceedMaxLines;

        Widget content = RichText(
          text: span,
          maxLines: _isCaptionExpanded ? null : 2,
          overflow:
              _isCaptionExpanded ? TextOverflow.visible : TextOverflow.clip,
        );

        if (!_isCaptionExpanded && exceeds) {
          content = Stack(
            children: [
              RichText(
                text: span,
                maxLines: 2,
                overflow: TextOverflow.clip,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 8),
                  child: const Text('...devamı', style: moreStyle),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: exceeds
              ? () {
                  setState(() {
                    _isCaptionExpanded = !_isCaptionExpanded;
                  });
                }
              : null,
          child: content,
        );
      },
    );
  }

  Widget _buildClassicQuotedText(
    String text, {
    required String sourceUserId,
  }) {
    const bodyStyle = TextStyle(
      color: Color(0xFF8A9199),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const moreStyle = TextStyle(
      color: Color(0xFF8A9199),
      fontSize: 13,
      fontFamily: 'Montserrat',
      height: 1.35,
    );
    const nickStyle = TextStyle(
      color: Color(0xFF4B5561),
      fontSize: 13,
      fontFamily: 'MontserratBold',
      height: 1.35,
    );

    String resolveSourceNickname(Map<String, dynamic>? profile) {
      final raw = (profile?['nickname'] ??
              profile?['displayName'] ??
              profile?['username'] ??
              '')
          .toString()
          .trim();
      if (raw.isNotEmpty) return raw;
      final fallback =
          widget.model.quotedSourceUserID.trim() == widget.model.userID
              ? (controller.username.value.trim().isNotEmpty
                  ? controller.username.value.trim()
                  : controller.nickname.value.trim())
              : '';
      return fallback;
    }

    final future = sourceUserId.trim() == _quotedSourceProfileUserId
        ? _quotedSourceProfileFuture
        : null;

    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, snapshot) {
        final sourceNickname = resolveSourceNickname(snapshot.data);
        final quotedSpan = <InlineSpan>[
          if (sourceNickname.isNotEmpty)
            TextSpan(text: '$sourceNickname ', style: nickStyle),
          TextSpan(text: text, style: bodyStyle),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(children: quotedSpan),
              textDirection: TextDirection.ltr,
              maxLines: 2,
            )..layout(maxWidth: constraints.maxWidth);

            final exceeds = painter.didExceedMaxLines;

            Widget content = RichText(
              text: TextSpan(children: quotedSpan),
              maxLines: _isQuoteExpanded ? null : 2,
              overflow:
                  _isQuoteExpanded ? TextOverflow.visible : TextOverflow.clip,
            );

            if (!_isQuoteExpanded && exceeds) {
              content = Stack(
                children: [
                  RichText(
                    text: TextSpan(children: quotedSpan),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(left: 8),
                      child: const Text('...devamı', style: moreStyle),
                    ),
                  ),
                ],
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: exceeds
                  ? () {
                      setState(() {
                        _isQuoteExpanded = !_isQuoteExpanded;
                      });
                    }
                  : null,
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _buildClassicActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 15, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          commentButton(context),
          likeButton(),
          reshareButton(),
          statButton(),
          saveButton(),
          sendButton(),
        ],
      ),
    );
  }

  String _buildClassicBottomTimeLabel() {
    final sourceMs = controller.editTime.value != 0
        ? controller.editTime.value
        : (widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final publishedAt = DateTime.fromMillisecondsSinceEpoch(sourceMs.toInt());
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes.clamp(1, 59);
      return '$minutes dakika önce';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    }

    const months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    final monthLabel = months[publishedAt.month - 1];
    if (publishedAt.year == now.year) {
      return '${publishedAt.day} $monthLabel';
    }
    return '${publishedAt.day} $monthLabel ${publishedAt.year}';
  }

  Widget _buildClassicMetaSection() {
    final caption = _ctaNavigationService.sanitizeCaptionText(
      widget.model.metin,
      meta: widget.model.reshareMap,
    );
    final hasCaption = caption.isNotEmpty;
    final quotedText = widget.model.quotedOriginalText.trim();
    final hasQuotedText = widget.model.quotedPost && quotedText.isNotEmpty;
    final captionNickname = controller.username.value.trim().isNotEmpty
        ? controller.username.value.trim()
        : controller.nickname.value.trim();
    final displayTime = _buildClassicBottomTimeLabel();

    if (!widget.isReshared &&
        !hasQuotedText &&
        !hasCaption &&
        widget.model.poll.isEmpty &&
        displayTime.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasQuotedText)
            _buildClassicQuotedText(
              quotedText,
              sourceUserId: widget.model.quotedSourceUserID.trim(),
            ),
          if (hasQuotedText && hasCaption) const SizedBox(height: 4),
          if (hasCaption)
            _buildClassicInlineCaption(
              nickname: captionNickname,
              text: caption,
            ),
          Padding(
            padding: EdgeInsets.only(
              top: (hasQuotedText || hasCaption) ? 6 : 0,
            ),
            child: Text(
              displayTime,
              style: const TextStyle(
                color: Color(0xFF8A9199),
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          if (widget.model.poll.isNotEmpty) buildPollCard(),
        ],
      ),
    );
  }

  Widget imgBody(BuildContext context) {
    final hasHeaderSubline = _ctaNavigationService
        .sanitizeCaptionText(
          widget.model.metin,
          meta: widget.model.reshareMap,
        )
        .isNotEmpty;
    final mediaTopSpacing = hasHeaderSubline ? 4.0 : 0.0;
    final actionTopSpacing = hasHeaderSubline ? 2.0 : 0.0;
    final mediaVisualLift = hasHeaderSubline ? 0.0 : -6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isIzBirakPost)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 0.92,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: widget.model.img.first,
                          fit: BoxFit.cover,
                          memCacheWidth: _feedCacheWidth,
                          memCacheHeight: _feedCacheHeightForAspectRatio(0.92),
                        ),
                      ),
                      _buildMediaTapOverlay(
                        onTap: _openImageMediaOrFeedCta,
                        onDoubleTap: controller.like,
                      ),
                      _buildIzBirakBlurOverlay(),
                      _buildIzBirakBottomBar(),
                      _buildClassicMediaHeader(),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (widget.model.img.length == 1)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: AspectRatio(
                aspectRatio: _resolvedClassicFrameAspectRatio,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: widget.model.img.first,
                        fit: BoxFit.cover,
                        memCacheWidth: _feedCacheWidth,
                        memCacheHeight: _feedCacheHeightForAspectRatio(
                          _resolvedClassicFrameAspectRatio,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.model.floodCount > 1)
                              Texts.colorfulFlood,
                          ],
                        ),
                        const SizedBox(),
                      ],
                    ),
                    if (widget.model.originalUserID.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: widget.model.floodCount > 1 ? 26 : 8,
                        child: SharedPostLabel(
                          originalUserID: widget.model.originalUserID,
                          sourceUserID: widget.model.quotedPost
                              ? widget.model.quotedSourceUserID
                              : '',
                          labelSuffix:
                              widget.model.quotedPost ? 'alıntılandı' : '',
                          textColor: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    _buildClassicReshareOverlay(
                      bottom: widget.model.originalUserID.isNotEmpty
                          ? (widget.model.floodCount > 1 ? 52 : 34)
                          : (widget.model.floodCount > 1 ? 26 : 8),
                    ),
                    _buildFeedShareCta(),
                    _buildMediaTapOverlay(
                      onTap: _openImageMediaOrFeedCta,
                      onDoubleTap: controller.like,
                    ),
                    _buildClassicMediaHeader(),
                  ],
                ),
              ),
            ),
          )
        else
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: AspectRatio(
                aspectRatio: 1 / 1.2,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.model.img.length,
                      itemBuilder: (context, index) {
                        final img = widget.model.img[index];
                        return CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          memCacheWidth: _feedCacheWidth,
                          memCacheHeight: _feedCacheHeightForAspectRatio(
                            1 / 1.2,
                          ),
                        );
                      },
                    ),
                    if (widget.model.floodCount > 1)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Texts.colorfulFlood,
                        ),
                      ),
                    if (widget.model.originalUserID.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: widget.model.floodCount > 1 ? 34 : 8,
                        child: SharedPostLabel(
                          originalUserID: widget.model.originalUserID,
                          sourceUserID: widget.model.quotedPost
                              ? widget.model.quotedSourceUserID
                              : '',
                          labelSuffix:
                              widget.model.quotedPost ? 'alıntılandı' : '',
                          textColor: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    _buildClassicReshareOverlay(
                      bottom: widget.model.originalUserID.isNotEmpty
                          ? (widget.model.floodCount > 1 ? 60 : 34)
                          : (widget.model.floodCount > 1 ? 34 : 8),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            List.generate(widget.model.img.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 6 : 5,
                            height: isActive ? 6 : 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          );
                        }),
                      ),
                    ),
                    _buildFeedShareCta(),
                    _buildMediaTapOverlay(
                      onTap: _openImageMediaOrFeedCta,
                      onDoubleTap: controller.like,
                    ),
                    _buildClassicMediaHeader(),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: _buildClassicActionRow(context),
        ),
        _buildClassicMetaSection(),
        3.ph,
      ],
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

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
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

  Widget videoBody(BuildContext context) {
    final frameAspectRatio =
        _isIzBirakPost ? 0.92 : _resolvedClassicFrameAspectRatio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VisibilityDetector(
          key: Key('classic-media-${widget.model.docID}'),
          onVisibilityChanged: (info) {
            reportMediaVisibility(info.visibleFraction);
          },
          child: AspectRatio(
            aspectRatio: frameAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_shouldBlurIzBirakPost) ...[
                  _buildVideoThumbnail(aspectRatio: frameAspectRatio),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),
                ] else if (videoController != null) ...[
                  IgnorePointer(
                    ignoring: true,
                    child: _isFullscreen
                        ? const SizedBox.shrink()
                        : videoController!.buildPlayer(
                            key: ValueKey(
                                'classic-${widget.model.docID}-${videoController.hashCode}'),
                            aspectRatio: frameAspectRatio,
                            useAspectRatio: false,
                          ),
                  ),
                  // Thumbnail overlay - video hazır olana kadar göster
                  ValueListenableBuilder<HLSVideoValue>(
                    valueListenable: videoValueNotifier,
                    builder: (_, v, child) {
                      if (v.hasRenderedFirstFrame) {
                        return const SizedBox.shrink();
                      }
                      return child!;
                    },
                    child: AspectRatio(
                      aspectRatio: frameAspectRatio,
                      child: _buildVideoThumbnail(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),
                ] else
                  widget.model.thumbnail.isEmpty
                      ? const SizedBox.expand()
                      : _buildVideoThumbnail(),
                if (videoController == null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: buildUploadIndicator(),
                  ),

                // Süre göstergesi + Replay — sadece video state değiştiğinde rebuild
                if (videoController != null && !_shouldBlurIzBirakPost)
                  ValueListenableBuilder<HLSVideoValue>(
                    valueListenable: videoValueNotifier,
                    builder: (_, v, __) {
                      if (!v.isInitialized) return const SizedBox.shrink();
                      final remaining = v.duration - v.position;
                      final safeRemaining =
                          remaining.isNegative ? Duration.zero : remaining;
                      return Positioned(
                        top: 50,
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

                if (videoController != null &&
                    !_shouldBlurIzBirakPost &&
                    widget.model.floodCount > 1)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Texts.colorfulFloodForVideo,
                  ),

                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    left: 8,
                    bottom: (widget.model.floodCount > 1) ? 26 : 8,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      sourceUserID: widget.model.quotedPost
                          ? widget.model.quotedSourceUserID
                          : '',
                      labelSuffix: widget.model.quotedPost ? 'alıntılandı' : '',
                      textColor: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                _buildClassicReshareOverlay(
                  bottom: widget.model.originalUserID.isNotEmpty
                      ? ((widget.model.floodCount > 1) ? 52 : 34)
                      : ((widget.model.floodCount > 1) ? 26 : 8),
                ),

                _buildMediaTapOverlay(
                  onTap: _openVideoMedia,
                  onDoubleTap: controller.like,
                ),
                _buildIzBirakBlurOverlay(),
                _buildIzBirakBottomBar(),
                if (!_isIzBirakPost)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        agendaController.isMuted.toggle();
                        final vc = videoController;
                        if (vc != null && vc.value.isInitialized) {
                          vc.setVolume(agendaController.isMuted.value ? 0 : 1);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Obx(() => Icon(
                              agendaController.isMuted.value
                                  ? CupertinoIcons.volume_off
                                  : CupertinoIcons.volume_up,
                              color: Colors.white,
                              size: 16,
                            )),
                      ),
                    ),
                  ),
                _buildClassicMediaHeader(),
              ],
            ),
          ),
        ),
        _buildClassicActionRow(context),
        _buildClassicMetaSection(),
      ],
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
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildClassicAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                  radius: 20, // 40px diameter / 2
                )),
          ),
          7.pw,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
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
                                    const SizedBox(width: 4),
                                    RozetContent(
                                        size: 13, userID: widget.model.userID),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 6, right: 12),
                                      child: Obx(
                                        () {
                                          _relativeTimeTickService.tick.value;
                                          return Text(
                                            buildDisplayTime(),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '@$handle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ],
                          )),
                    ),
                    if (widget.model.userID !=
                        FirebaseAuth.instance.currentUser!.uid)
                      Obx(() {
                        if (controller.isFollowing.value) {
                          return const SizedBox.shrink();
                        }
                        return Transform.translate(
                          offset: const Offset(0, -5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: TextButton(
                                onPressed: controller.followLoading.value
                                    ? null
                                    : () {
                                        controller.followUser();
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: controller.followLoading.value
                                    ? Container(
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(12)),
                                            border: Border.all(
                                                color: Colors.black)),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15),
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
                              ),
                            ),
                          ),
                        );
                      }),
                    7.pw,
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: pulldownmenu(Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerUserInfoWhite() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.username.value.trim();
    final handle = controller.username.value.trim().isNotEmpty
        ? controller.username.value.trim()
        : controller.nickname.value.trim();
    String buildDisplayTime() => controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    void openProfile() {
      if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
        videoController?.pause();
        Get.to(() => SocialProfile(userID: widget.model.userID))?.then((v) {
          videoController?.play();
        });
      }
    }

    final textShadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openAvatarStoryOrProfile,
            child: Obx(() => _buildClassicAvatar(
                  userId: widget.model.userID,
                  imageUrl: controller.avatarUrl.value,
                )),
          ),
          7.pw,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        primaryName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: "MontserratBold",
                                          shadows: textShadow,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildClassicWhiteBadge(13),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 6, right: 12),
                                      child: Obx(
                                        () {
                                          _relativeTimeTickService.tick.value;
                                          return Text(
                                            buildDisplayTime(),
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                              fontSize: 12,
                                              fontFamily: "MontserratMedium",
                                              shadows: textShadow,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '@$handle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12,
                                  fontFamily: "Montserrat",
                                  shadows: textShadow,
                                ),
                              ),
                            ],
                          )),
                    ),
                    if (widget.model.userID !=
                        FirebaseAuth.instance.currentUser!.uid)
                      Obx(() {
                        if (controller.isFollowing.value) {
                          return const SizedBox.shrink();
                        }
                        return Transform.translate(
                          offset: const Offset(0, -5),
                          child: SizedBox(
                            height: 24,
                            child: Center(
                              child: TextButton(
                                onPressed: controller.followLoading.value
                                    ? null
                                    : () {
                                        controller.followUser();
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _buildClassicOverlayFollowButton(
                                  loading: controller.followLoading.value,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    7.pw,
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: pulldownmenu(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: "Montserrat",
                      shadows: textShadow,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pulldownmenu(Color color) {
    final canManagePost =
        widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            controller.canSendAdminPush;
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();

            // Dinamik paylaşım zinciri: eğer bu post zaten bir paylaşım ise ana kaynağı koru
            String finalOriginalUserID;
            String finalOriginalPostID;

            if (widget.model.originalUserID.isNotEmpty) {
              // Bu post zaten bir paylaşım, ana kaynağı koru
              finalOriginalUserID = widget.model.originalUserID;
              finalOriginalPostID = widget.model.originalPostID;
            } else {
              // İlk kez paylaşılıyor, bu postun sahibi ana kaynak olacak
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
                  sharedAsPost: true,
                ))?.then((_) {
              videoController?.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
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
        child: Icon(Icons.more_vert, color: color, size: 22),
      ),
    );
  }

  void _runSimpleReshare() {
    controller.reshare();
    videoController?.play();
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
            child: _iconAction(
              icon: _actionStyle.reshareIcon ?? Icons.repeat,
              iconSize: _actionStyle.iconSize,
              color: displayColor,
              label: NumberFormatter.format(controller.retryCount.value),
              labelColor: displayColor,
            ),
          ),
        ),
      );
    });
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
        onTap: canInteract
            ? () {
                videoController?.pause();
                controller.showPostCommentsBottomSheet(
                  onClosed: () => videoController?.play(),
                );
              }
            : null,
        child: _iconAction(
          icon: CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 19,
        ),
      );
    });
  }

  Widget likeButton() {
    return Obx(() {
      final bool isLiked =
          controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
      final Color displayColor = isLiked ? Colors.blueAccent : _actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Beğeniler',
        onTap: controller.like,
        onLongPress: _openLikeListing,
        longPressDuration: const Duration(milliseconds: 220),
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          iconSize: 19,
          color: displayColor,
          label: NumberFormatter.format(controller.likeCount.value),
          labelColor: displayColor,
          leadingTransformOffsetY: -2,
        ),
      );
    });
  }

  void _openLikeListing() {
    videoController?.pause();
    Get.bottomSheet(
      PostLikeListing(postID: widget.model.docID),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      videoController?.play();
    });
  }

  Widget saveButton() {
    return Obx(() {
      final bool isSaved = controller.saved.value == true;
      final Color displayColor = isSaved ? Colors.orange : _actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Kaydet',
        onTap: controller.save,
        child: _iconAction(
          icon:
              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          iconSize: 19,
          color: displayColor,
          label: NumberFormatter.format(controller.savedCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget statButton() {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Obx(() => SizedBox(
            height: AnimatedActionButton.actionHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: AnimatedActionButton.actionHeight,
                  child: Center(
                    child: Icon(Icons.bar_chart, color: _actionColor, size: 22),
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
          )),
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

  Widget gonderiGizlendi(BuildContext context) {
    return PostHiddenMessage(
      onUndo: () {
        controller.gizlemeyiGeriAl();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return PostArchivedMessage(
      onUndo: () {
        controller.arsivdenCikart();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return const PostDeletedMessage();
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
      gap: 2,
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
