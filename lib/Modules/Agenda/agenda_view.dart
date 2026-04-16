import 'dart:async';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/feed_playback_selection_policy.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Modules/InAppNotifications/notification_post_types.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../Models/posts_model.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader.dart';
import 'package:turqappv2/Modules/Agenda/ClassicContent/classic_content.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_create_fab.dart';
import 'package:turqappv2/Modules/Agenda/widgets/feed_inbox_actions_row.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../Themes/app_fonts.dart';
import '../../Themes/app_colors.dart';
import '../../Core/Widgets/app_header_action_button.dart';
import '../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import '../../Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import '../Chat/ChatListing/chat_listing.dart';
import '../InAppNotifications/in_app_notifications.dart';
import '../InAppNotifications/in_app_notifications_controller.dart';
import '../RecommendedUserList/recommended_user_list.dart';
import '../RecommendedUserList/recommended_user_list_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import 'AgendaContent/agenda_content.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

part 'agenda_view_feed_part.dart';
part 'agenda_view_header_part.dart';

class AgendaView extends StatelessWidget {
  AgendaView({super.key});
  static bool _androidVisibilityTuned = false;
  static bool _feedEntryWarmQueued = false;
  static bool _primarySurfaceBootstrapQueued = false;
  static int _feedRefreshInvocationCount = 0;
  static final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  static Future<bool> showFeedRefreshIndicator() async {
    final state = _refreshIndicatorKey.currentState;
    if (state == null) return false;
    final beforeInvocation = _feedRefreshInvocationCount;
    await state.show();
    return _feedRefreshInvocationCount > beforeInvocation;
  }

  static void markFeedRefreshIndicatorInvoked() {
    _feedRefreshInvocationCount += 1;
  }

  AgendaController get controller {
    return ensureAgendaController();
  }

  GlobalLoaderController get loader {
    return GlobalLoaderController.ensure();
  }

  RecommendedUserListController get recommendedController {
    return ensureRecommendedUserListController();
  }

  UnreadMessagesController get unreadController {
    return ensureUnreadMessagesController();
  }

  InAppNotificationsController get notificationsController {
    return InAppNotificationsController.ensure();
  }

  void _queueFeedEntryWarmWhenReady() {
    if (_feedEntryWarmQueued) return;
    _feedEntryWarmQueued = true;

    void attemptWarm({int attempt = 0}) {
      final delay = attempt == 0
          ? const Duration(milliseconds: 900)
          : const Duration(milliseconds: 1200);
      Future<void>.delayed(delay, () {
        if (controller.isClosed) {
          _feedEntryWarmQueued = false;
          return;
        }
        final prefetch = maybeFindPrefetchScheduler();
        final readyThreshold = ReadBudgetRegistry.feedReadyForNavCount;
        final renderReady = controller.renderFeedEntries.isNotEmpty;
        final startupReady =
            prefetch != null && prefetch.feedReadyCount >= readyThreshold;
        if (!renderReady || !startupReady) {
          if (attempt < 8) {
            attemptWarm(attempt: attempt + 1);
          }
          return;
        }
        unawaited(ensureAdmobBannerWarmupService().warmForFeedEntry());
      });
    }

    attemptWarm();
  }

  @override
  Widget build(BuildContext context) {
    if (!_primarySurfaceBootstrapQueued) {
      _primarySurfaceBootstrapQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.isClosed) return;
        unawaited(controller.onPrimarySurfaceVisible());
      });
    }
    if (!_feedEntryWarmQueued) {
      _queueFeedEntryWarmWhenReady();
    }
    if (GetPlatform.isAndroid && !_androidVisibilityTuned) {
      // Feed'de fazla sık visibility callback'i scroll sırasında jank üretebiliyor.
      VisibilityDetectorController.instance.updateInterval =
          const Duration(milliseconds: 160);
      _androidVisibilityTuned = true;
    }

    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      key: const ValueKey(IntegrationTestKeys.screenFeed),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topInset + 7,
              color: Colors.white,
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _buildRefreshableFeed(context),
                ),
              ],
            ),
          ),
          _buildStartupWarmPreloadLayer(),
          _buildCreateFab(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalLoader(),
          ),
        ],
      ),
    );
  }
}

class _FeedStartupWarmPreloadLayer extends StatelessWidget {
  const _FeedStartupWarmPreloadLayer({
    required this.posts,
  });

  final List<PostsModel> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 6,
          height: 6,
          child: Stack(
            children: [
              for (int index = 0; index < posts.length; index++)
                Positioned(
                  left: (index % 2) * 2.0,
                  top: (index ~/ 2) * 2.0,
                  width: 2,
                  height: 2,
                  child: _FeedStartupWarmPreloadSlot(
                    key: ValueKey('startup-warm-${posts[index].docID}'),
                    model: posts[index],
                    onPrepared: () => ensureAgendaController()
                        .markStartupWarmPlayerPrepared(posts[index].docID),
                    onFirstFrame: () => ensureAgendaController()
                        .markStartupWarmPlayerFirstFrame(posts[index].docID),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedStartupWarmPreloadSlot extends StatefulWidget {
  const _FeedStartupWarmPreloadSlot({
    super.key,
    required this.model,
    required this.onPrepared,
    required this.onFirstFrame,
  });

  final PostsModel model;
  final VoidCallback onPrepared;
  final VoidCallback onFirstFrame;

  @override
  State<_FeedStartupWarmPreloadSlot> createState() =>
      _FeedStartupWarmPreloadSlotState();
}

class _FeedStartupWarmPreloadSlotState extends State<_FeedStartupWarmPreloadSlot> {
  final GlobalVideoAdapterPool _adapterPool = ensureGlobalVideoAdapterPool();
  HLSVideoAdapter? _adapter;
  bool _reportedPrepared = false;
  bool _reportedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    _bindAdapter();
  }

  @override
  void didUpdateWidget(covariant _FeedStartupWarmPreloadSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.docID != widget.model.docID ||
        oldWidget.model.playbackUrl != widget.model.playbackUrl) {
      _unbindAdapter();
      _bindAdapter();
    }
  }

  void _bindAdapter() {
    final cacheKey = 'feed:${widget.model.docID.trim()}';
    if (cacheKey.trim().isEmpty || widget.model.playbackUrl.trim().isEmpty) {
      return;
    }
    final useLocalProxy = defaultTargetPlatform != TargetPlatform.android;
    _reportedPrepared = false;
    _reportedFirstFrame = false;
    _adapter = _adapterPool.acquire(
      cacheKey: cacheKey,
      url: widget.model.playbackUrl,
      autoPlay: false,
      loop: true,
      useLocalProxy: useLocalProxy,
    );
    _adapter?.addListener(_handleAdapterUpdate);
    unawaited(_adapter?.setVolume(0.0) ?? Future<void>.value());
  }

  void _unbindAdapter() {
    final adapter = _adapter;
    if (adapter == null) return;
    adapter.removeListener(_handleAdapterUpdate);
    unawaited(_adapterPool.release(adapter));
    _adapter = null;
  }

  void _handleAdapterUpdate() {
    final adapter = _adapter;
    if (adapter == null) return;
    final value = adapter.value;
    if (!_reportedPrepared && value.isInitialized) {
      _reportedPrepared = true;
      widget.onPrepared();
    }
    if (!_reportedFirstFrame && value.hasRenderedFirstFrame) {
      _reportedFirstFrame = true;
      widget.onFirstFrame();
    }
  }

  @override
  void dispose() {
    _unbindAdapter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adapter = _adapter;
    if (adapter == null) return const SizedBox.shrink();
    return ClipRect(
      child: Opacity(
        opacity: 0.01,
        child: adapter.buildPlayer(
          key: ValueKey('startup-warm-player-${widget.model.docID}'),
          aspectRatio: 9 / 16,
          useAspectRatio: false,
          overrideAutoPlay: false,
          isPrimaryFeedSurface: true,
          suppressLoadingOverlay: true,
        ),
      ),
    );
  }
}
