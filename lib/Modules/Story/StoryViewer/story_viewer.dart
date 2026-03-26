import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import '../StoryRow/story_user_model.dart';
import 'user_story_content.dart';
import '../StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import '../StoryRow/story_row_controller.dart';

part 'story_viewer_shell_part.dart';
part 'story_viewer_story_part.dart';

class StoryViewer extends StatefulWidget {
  final StoryUserModel startedUser;
  final List<StoryUserModel> storyOwnerUsers;

  const StoryViewer({
    super.key,
    required this.startedUser,
    required this.storyOwnerUsers,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late PageController pageController;
  int currentPageIndex = 0;
  final Map<int, GlobalKey> _pageKeys = {};
  // Gesture thresholds (easily tweakable)
  final double dismissDeltaPx = 100;
  final double dismissVelocityPx = 500;
  final double openCommentDeltaPx = -100;
  final double openCommentVelocityPx = -500;
  // Vertical swipe-to-dismiss (page level)
  double _dragStartY = 0.0;
  double _dragOffsetY = 0.0;
  double _dragOpacity = 1.0;
  double _dragScale = 1.0;
  // Horizontal swipe-to-change user (custom threshold)
  double _dragStartX = 0.0;
  double _dragOffsetX = 0.0;
  late AnimationController _returnController;
  late Animation<double> _offsetAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  // Screenshot detection
  static const _screenshotChannel = MethodChannel('com.turqapp/screenshot');

  void _updateViewState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  @override
  void initState() {
    super.initState();
    maybeFindAgendaController()?.suspendPlaybackForOverlay();
    VideoStateManager.instance.pauseAllVideos(force: true);
    currentPageIndex = widget.storyOwnerUsers
        .indexWhere((u) => u.userID == widget.startedUser.userID);
    if (currentPageIndex < 0) currentPageIndex = 0;
    pageController = PageController(
      initialPage: currentPageIndex,
    );
    // İlk kullanıcı için sadece prefetch yap; read durumu gerçek izleme ile güncellenir.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final idx = currentPageIndex >= 0 ? currentPageIndex : 0;
        if (widget.storyOwnerUsers.isEmpty) return;
        _prefetchNext(idx);
      } catch (_) {}
    });

    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _offsetAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 1, end: 1).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 1, end: 1).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _returnController.addListener(() {
      setState(() {
        _dragOffsetY = _offsetAnim.value;
        _dragOpacity = _opacityAnim.value;
        _dragScale = _scaleAnim.value;
      });
    });

    // Screenshot detection setup
    _screenshotChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshot') {
        _onScreenshotDetected();
      }
    });
  }

  @override
  void dispose() {
    maybeFindAgendaController()?.resumePlaybackAfterOverlay();
    _returnController.dispose();
    pageController.dispose();
    _screenshotChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
