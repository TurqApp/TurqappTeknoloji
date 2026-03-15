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
import 'package:turqappv2/Core/Services/post_story_share_service.dart';
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

part 'classic_content_quote_part.dart';
part 'classic_content_media_part.dart';
part 'classic_content_header_actions_part.dart';

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

  void _setCaptionExpanded(bool value) {
    setState(() {
      _isCaptionExpanded = value;
    });
  }

  void _setQuoteExpanded(bool value) {
    setState(() {
      _isQuoteExpanded = value;
    });
  }

  void _setFullscreen(bool value) {
    setState(() {
      _isFullscreen = value;
    });
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
                      showBackdrop: true,
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

                _buildClassicReshareOverlay(
                  bottom: widget.model.originalUserID.isNotEmpty
                      ? ((widget.model.floodCount > 1) ? 52 : 34)
                      : ((widget.model.floodCount > 1) ? 26 : 8),
                ),

                _buildMediaTapOverlay(
                  onTap: _openVideoMedia,
                  onDoubleTap: controller.like,
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

  void _refreshFlaggedPostState() {
    if (!mounted) return;
    setState(() {});
  }
}
