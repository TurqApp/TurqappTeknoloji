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
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
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
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing_controller.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostReshareListing/post_reshare_listing.dart';
import 'package:turqappv2/Modules/Agenda/SinglePost/single_post.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_contoller.dart';
import 'package:turqappv2/Modules/Profile/LikedPosts/liked_posts_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../../Core/texts.dart';
import '../../../Themes/app_colors.dart';
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
part 'agenda_content_body_part.dart';

class AgendaContent extends PostContentBase {
  final bool hideVideoPoster;
  final bool suppressFloodBadge;
  const AgendaContent({
    super.key,
    required super.model,
    required super.isPreview,
    required super.shouldPlay,
    super.instanceTag,
    this.hideVideoPoster = false,
    this.suppressFloodBadge = false,
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
  static const Color _videoFallbackColor = Colors.black;
  static const EducationFeedCtaNavigationService _ctaNavigationService =
      EducationFeedCtaNavigationService();
  final arsivController = Get.put(ArchiveController());
  bool _isFullscreen = false;
  bool _pauseQueuedAfterBuild = false;
  late final RelativeTimeTickService _relativeTimeTickService;
  Future<List<dynamic>>? _quotedSourceFuture;
  String _quotedSourceFutureUserId = '';
  String _quotedSourceFuturePostId = '';

  String get _currentUid {
    final serviceUid = controller.userService.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
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

  void _setFullscreenState(bool value) {
    if (!mounted) return;
    setState(() => _isFullscreen = value);
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
