import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/Services/education_feed_cta_navigation_service.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/relative_time_tick_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/post_story_share_service.dart';
import 'package:turqappv2/Core/Services/iz_birak_subscription_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
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
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';
import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/redirection_link.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/texts.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../../Themes/app_tokens.dart';
import '../../Social/PostSharers/post_sharers.dart';
import '../../SocialProfile/social_profile.dart';
import '../../PostCreator/post_creator.dart';
import '../TagPosts/tag_posts.dart';
import 'classic_content_controller.dart';

part 'classic_content_quote_part.dart';
part 'classic_content_media_part.dart';
part 'classic_content_header_actions_part.dart';
part 'classic_content_header_menu_part.dart';
part 'classic_content_header_interactions_part.dart';
part 'classic_content_body_part.dart';
part 'classic_content_helpers_part.dart';

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
    with
        PostContentBaseState<ClassicContent>,
        AutomaticKeepAliveClientMixin<ClassicContent> {
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
  final arsivController = ensureArchiveController();
  final PageController _pageController = PageController(keepPage: false);
  int _currentPage = 0;
  bool _isFullscreen = false;
  bool _isCaptionExpanded = false;
  bool _isQuoteExpanded = false;
  late final RelativeTimeTickService _relativeTimeTickService;
  Future<Map<String, dynamic>?>? _quotedSourceProfileFuture;
  String _quotedSourceProfileUserId = '';
  final Set<String> _avatarSyncLoggedHeaderDocIds = <String>{};

  String get _currentUid {
    final cachedUid =
        (controller.userService.currentUserRx.value?.userID ?? '').trim();
    if (cachedUid.isNotEmpty) return cachedUid;
    return controller.userService.authUserId.trim();
  }

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
    bindKeepAliveUpdater(updateKeepAlive);
    _relativeTimeTickService = RelativeTimeTickService.ensure();
    _refreshQuotedSourceProfileFuture();
  }

  @override
  bool get wantKeepAlive => shouldKeepVideoSurfaceAlive;

  static const EducationFeedCtaNavigationService _ctaNavigationService =
      EducationFeedCtaNavigationService();

  @override
  bool get enableBufferedAutoplay => false;

  static const double _reelPortraitFrameAspectRatio = 5 / 8;
  static const double _feedPortraitFrameAspectRatio = 4 / 5;
  static const double _squareFrameAspectRatio = 0.92;
  double? get _sharedFeedFrameAspectRatio {
    final type =
        _ctaNavigationService.resolveMeta(widget.model.reshareMap).type;
    if (widget.model.img.length != 1) {
      return null;
    }
    switch (type) {
      case 'market':
      case 'practice-exam':
      case 'tutoring':
      case 'job':
        return 1.0;
      case 'scholarship':
        return 4 / 3;
      default:
        return null;
    }
  }

  double get _resolvedClassicFrameAspectRatio {
    final sharedFeedAspectRatio = _sharedFeedFrameAspectRatio;
    if (sharedFeedAspectRatio != null) {
      return sharedFeedAspectRatio;
    }
    final raw = widget.model.aspectRatio.toDouble();
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                : (widget.model.hasRenderableVideoCard
                    ? videoBody(context)
                    : textOnlyBody(context))
        ],
      );
    });
  }
}
