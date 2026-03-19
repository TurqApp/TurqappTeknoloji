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
part 'classic_content_body_part.dart';

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
  final arsivController = Get.put(ArchiveController());
  final PageController _pageController = PageController(keepPage: false);
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

  void _setCurrentPage(int value) {
    if (!mounted || _currentPage == value) return;
    setState(() => _currentPage = value);
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
      _setCurrentPage(next);
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
    if (oldWidget.model.docID != widget.model.docID) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(0);
      });
    }
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
}
