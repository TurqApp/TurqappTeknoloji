import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import '../StoryRow/story_user_model.dart';
import 'user_story_content.dart';
import '../StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import '../StoryRow/story_row_controller.dart';

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

  @override
  void initState() {
    super.initState();
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
      } catch (_) {
      }
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
    _returnController.dispose();
    pageController.dispose();
    _screenshotChannel.setMethodCallHandler(null);
    super.dispose();
  }

  void _onUserStoryFinished(int currentIndex) {
    // Kullanıcının tüm hikayeleri bitirildi - son görülme zamanını güncelle
    _markUserAsFullyViewed(currentIndex);

    final isLastUser = currentIndex == widget.storyOwnerUsers.length - 1;
    if (!isLastUser) {
      // Bir sonraki kullanıcıya geç
      final nextIndex = currentIndex + 1;
      if (nextIndex < widget.storyOwnerUsers.length) {
        pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      } else {
        _refreshStoryRowAndExit();
      }
    } else {
      _refreshStoryRowAndExit();
    }
  }

  void _refreshStoryRowAndExit() async {
    try {
      // Story Row'ı yenile
      await StoryRowController.refreshStoriesGlobally();
      print("🔄 Story row refreshed after viewing stories");
    } catch (_) {
    } finally {
      Get.back();
    }
  }

  void _onPrevUserRequested(int currentIndex) {
    final isFirstUser = currentIndex == 0;
    if (!isFirstUser) {
      // Bir önceki kullanıcıya geç
      final prevIndex = currentIndex - 1;
      if (prevIndex >= 0) {
        pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      } else {
        Get.back();
      }
    } else {
      // İlk kullanıcı, ilk story, sola basılırsa çık
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragStart: (details) {
          _dragStartY = details.localPosition.dy;
        },
        onVerticalDragUpdate: (details) {
          final delta = details.localPosition.dy - _dragStartY;
          setState(() {
            _dragOffsetY = delta.clamp(-200.0, 300.0);
            final ratioY = (_dragOffsetY.abs() / 300.0).clamp(0.0, 1.0);
            final ratioX = (_dragOffsetX.abs() / 300.0).clamp(0.0, 1.0);
            final ratio = ratioX > ratioY ? ratioX : ratioY;
            _dragOpacity = 1.0 - (0.5 * ratio);
            _dragScale = 1.0 - (0.05 * ratio);
          });
        },
        onVerticalDragEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dy;
          final deltaY = _dragOffsetY;
          if (deltaY > dismissDeltaPx ||
              (deltaY > (dismissDeltaPx / 2) && velocity > dismissVelocityPx)) {
            Get.back();
          } else if (deltaY < openCommentDeltaPx ||
              (deltaY < (openCommentDeltaPx / 2) &&
                  velocity < openCommentVelocityPx)) {
            // Upward swipe -> open comments for current story
            // Reset transform before opening
            setState(() {
              _dragOffsetY = 0.0;
              _dragOffsetX = 0.0;
              _dragOpacity = 1.0;
              _dragScale = 1.0;
            });
            HapticFeedback.lightImpact();
            try {
              final key = _pageKeys[currentPageIndex];
              final st = key?.currentState;
              // Use dynamic to call method defined in child state
              (st as dynamic)?.openCommentsFromParent?.call();
            } catch (e) {
              // ignore
            }
          } else {
            _animateBack();
          }
        },
        onHorizontalDragStart: (details) {
          _dragStartX = details.localPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          final delta = details.localPosition.dx - _dragStartX;
          setState(() {
            _dragOffsetX = delta.clamp(-200.0, 200.0);
            final ratioY = (_dragOffsetY.abs() / 300.0).clamp(0.0, 1.0);
            final ratioX = (_dragOffsetX.abs() / 300.0).clamp(0.0, 1.0);
            final ratio = ratioX > ratioY ? ratioX : ratioY;
            _dragOpacity = 1.0 - (0.08 * ratio);
            _dragScale = 1.0 - (0.03 * ratio);
          });
        },
        onHorizontalDragEnd: (details) {
          final vx = details.velocity.pixelsPerSecond.dx;
          final dx = _dragOffsetX;
          final pass = dx.abs() > 120 || vx.abs() > 800;
          if (pass) {
            if (dx < 0) {
              // next user
              final next = currentPageIndex + 1;
              if (next < widget.storyOwnerUsers.length) {
                pageController.nextPage(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut);
              } else {
                _refreshStoryRowAndExit();
              }
            } else {
              // prev user
              final prev = currentPageIndex - 1;
              if (prev >= 0) {
                pageController.previousPage(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut);
              } else {
                Get.back();
              }
            }
          }
          setState(() {
            _dragOffsetX = 0.0;
            _dragScale = 1.0;
            _dragOpacity = 1.0;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Transform.translate(
            offset: Offset(_dragOffsetX, _dragOffsetY),
            child: Transform.scale(
              scale: _dragScale,
              child: Opacity(
                opacity: _dragOpacity,
                child: PageView.builder(
                  controller: pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.storyOwnerUsers.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPageIndex = index;
                    });
                    // Sonraki kullanıcıyı prefetch et
                    _prefetchNext(index);
                  },
                  itemBuilder: (context, pageIndex) {
                    final currentUser = widget.storyOwnerUsers[pageIndex];
                    final startIdx = _computeStartIndex(currentUser);
                    final key =
                        _pageKeys.putIfAbsent(pageIndex, () => GlobalKey());
                    return UserStoryContent(
                      key: key,
                      user: currentUser,
                      initialStoryIndex: startIdx,
                      onUserStoryFinished: () =>
                          _onUserStoryFinished(pageIndex),
                      onPrevUserRequested: () =>
                          _onPrevUserRequested(pageIndex),
                      onSwipeNextUser: () {
                        final next = pageIndex + 1;
                        if (next < widget.storyOwnerUsers.length) {
                          pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        } else {
                          _refreshStoryRowAndExit();
                        }
                      },
                      onSwipePrevUser: () {
                        final prev = pageIndex - 1;
                        if (prev >= 0) {
                          pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        } else {
                          Get.back();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onScreenshotDetected() {
    try {
      final uid = (() {
        final serviceUid = CurrentUserService.instance.userId.trim();
        if (serviceUid.isNotEmpty) return serviceUid;
        return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      })();
      if (uid.isEmpty) return;
      if (currentPageIndex >= widget.storyOwnerUsers.length) return;
      final storyOwner = widget.storyOwnerUsers[currentPageIndex];
      // Kendi hikayemi screenshot'lamak bir sey yapmaz
      if (storyOwner.userID == uid) return;
      // Firestore'a screenshot kaydi yaz
      if (storyOwner.stories.isNotEmpty) {
        final currentStoryId = storyOwner.stories.first.id;
        StoryRepository.ensure().addScreenshotEvent(
          currentStoryId,
          userId: uid,
        );
      }
    } catch (_) {
    }
  }

  void _animateBack() {
    _returnController.reset();
    final startOffset = _dragOffsetY;
    final startOpacity = _dragOpacity;
    final startScale = _dragScale;
    _offsetAnim = Tween<double>(begin: startOffset, end: 0).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: startOpacity, end: 1).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: startScale, end: 1).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOut));
    _returnController.forward();
  }

  void _prefetchNext(int index) async {
    // Sonraki kullanıcıların ilk görsel/gif öğesini önbelleğe al
    try {
      final isWifi = await ConnectivityHelper.isWifi();
      final count = isWifi ? 3 : 1;
      for (int i = 1; i <= count; i++) {
        final next = index + i;
        if (next >= widget.storyOwnerUsers.length) break;
        final nextUser = widget.storyOwnerUsers[next];
        if (nextUser.stories.isEmpty) continue;
        final firstStory = nextUser.stories.first;
        final firstImage = firstStory.elements.firstWhere(
          (e) =>
              e.type == StoryElementType.image ||
              e.type == StoryElementType.gif,
          orElse: () => firstStory.elements.isNotEmpty
              ? firstStory.elements.first
              : StoryElement(
                  type: StoryElementType.text,
                  content: '',
                  width: 0,
                  height: 0,
                  position: const Offset(0, 0),
                ),
        );
        if (firstImage.type == StoryElementType.image ||
            firstImage.type == StoryElementType.gif) {
          final file = await TurqImageCacheManager.instance
              .getSingleFile(firstImage.content);
          final provider = FileImage(File(file.path));
          precacheImage(provider, context).catchError((_) {});
        }
      }
    } catch (_) {}
  }

  /// Kullanıcının tüm hikayelerini bitirdikten sonra çağrılır
  void _markUserAsFullyViewed(int index) async {
    try {
      final uid = (() {
        final serviceUid = CurrentUserService.instance.userId.trim();
        if (serviceUid.isNotEmpty) return serviceUid;
        return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      })();
      if (uid.isNotEmpty && index < widget.storyOwnerUsers.length) {
        final user = widget.storyOwnerUsers[index];
        final targetUserId = user.userID;

        if (user.stories.isNotEmpty) {
          // En son hikayenin zamanını al
          final latestStoryTime = _latestStoryMillis(user);
          final latestStoryId = user.stories.first.id;

          // Debounced local cache/pending write durumunu da senkronize et.
          await StoryInteractionOptimizer.to.markStoryViewed(
            targetUserId,
            latestStoryId,
            latestStoryTime,
          );

          await StoryRepository.ensure().markUserStoriesFullyViewed(
            currentUid: uid,
            targetUserId: targetUserId,
            latestStoryTime: latestStoryTime,
          );

          // Story Row'ı yenile (reactive güncelleme için)
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (_) {
    }
  }

  int _latestStoryMillis(StoryUserModel user) {
    if (user.stories.isEmpty) return 0;
    // StoryRowController now sorts user stories newest-to-oldest
    return user.stories.first.createdAt.millisecondsSinceEpoch;
  }

  int _computeStartIndex(StoryUserModel user) {
    // Yeni hikaye solda/başta açılmalı.
    return 0;
  }
}
