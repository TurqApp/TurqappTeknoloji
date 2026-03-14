import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'dart:math' as math;
import 'nav_bar_controller.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Services/deep_link_service.dart';
import '../Agenda/agenda_view.dart';
import '../Explore/explore_view.dart';
import '../Profile/MyProfile/profile_view.dart';
import '../Education/education_view.dart';
import '../Short/short_view.dart';
import '../Short/short_controller.dart';
import '../Story/StoryRow/story_row_controller.dart';
import '../Profile/Settings/settings_controller.dart';
import '../../Core/Widgets/cached_user_avatar.dart';
import '../../Core/Widgets/offline_indicator.dart';

class NavBarView extends StatelessWidget {
  final selection = 0;
  static bool _controllersPrepared = false;

  NavBarView({super.key}) {
    _ensureControllersReady();
  }
  final NavBarController controller = Get.isRegistered<NavBarController>()
      ? Get.find<NavBarController>()
      : Get.put(NavBarController());
  final SettingsController settingController =
      Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>()
          : Get.put(SettingsController());
  final DeepLinkService? deepLinkService =
      Get.isRegistered<DeepLinkService>() ? Get.find<DeepLinkService>() : null;

  // Ensure controllers are available
  void _ensureControllersReady() {
    final isIOS = GetPlatform.isIOS;
    if (!Get.isRegistered<AgendaController>()) {
      Get.put(AgendaController());
    }
    if (!isIOS && !Get.isRegistered<StoryRowController>()) {
      Get.put(StoryRowController());
    }

    // Deep link çözümleme her NavBar açılışında tetiklensin.
    // (Yeniden login senaryosunda _controllersPrepared true kalsa bile)
    if (!isIOS && Get.isRegistered<DeepLinkService>()) {
      Get.find<DeepLinkService>().start();
    }

    // Controller registration should always be enforced (Android lifecycle can dispose lazies).
    // Keep one-time side effects below behind static guard.
    if (_controllersPrepared) return;

    // ⚠️ CRITICAL FIX: Start UnreadMessagesController listeners after user is logged in
    // Note: startListeners() has internal guard against multiple calls
    if (!isIOS && Get.isRegistered<UnreadMessagesController>()) {
      final unreadController = Get.find<UnreadMessagesController>();
      unreadController.startListeners();
    }

    _controllersPrepared = true;
  }

  late final AnimationController animationController;

  Widget _buildSelectedPage() {
    final hasEducation = settingController.educationScreenIsOn.value;
    final selected = controller.selectedIndex.value;

    if (selected == 0) return AgendaView();
    if (selected == 1) return ExploreView();
    if (selected == 2) return Container(); // shorts placeholder
    if (hasEducation) {
      if (selected == 3) return EducationView();
      return ProfileView();
    }
    return ProfileView();
  }

  Future<bool> _handleBackNavigation() async {
    final hasEducation = settingController.educationScreenIsOn.value;
    final profileIndex = hasEducation ? 4 : 3;
    final educationIndex = hasEducation ? 3 : 0;

    if (hasEducation && controller.selectedIndex.value == educationIndex) {
      if (!Get.isRegistered<EducationController>()) {
        return false;
      }
      final educationController = Get.find<EducationController>();
      if (educationController.canExitToFeed) {
        controller.changeIndex(0);
      } else {
        educationController.handleBackFromEducation();
      }
      return false;
    }

    if (controller.selectedIndex.value == profileIndex) {
      controller.changeIndex(educationIndex);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                const OfflineIndicator(),
                Expanded(
                  child: Obx(() => _buildSelectedPage()),
                ),
              ],
            ),
            Obx(() {
              if (controller.selectedIndex.value != 0) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: MediaQuery.of(context).padding.top - 3,
                    color: Colors.white,
                  ),
                ),
              );
            }),
            Obx(() {
              final icons = [
                'assets/icons/house',
                'assets/icons/search',
                'assets/icons/play',
                if (settingController.educationScreenIsOn.value)
                  'assets/icons/sinav',
                'profile_dynamic',
              ];
              final showBar = controller.showBar.value;

              return AnimatedSlide(
                offset: showBar ? Offset.zero : const Offset(0, 1.2),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: showBar ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !showBar,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        math.max(
                          0.0,
                          math.max(8.0,
                                  MediaQuery.of(context).viewPadding.bottom) -
                              (GetPlatform.isIOS ? 20 : 10),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(icons.length, (i) {
                                final isSelected =
                                    controller.selectedIndex.value == i;
                                return TextButton(
                                  style: ButtonStyle(
                                    overlayColor: WidgetStateProperty.all(
                                        Colors.transparent),
                                    padding: WidgetStateProperty.all(
                                        EdgeInsets.zero),
                                  ),
                                  onPressed: () async {
                                    if (i == 0 &&
                                        controller.selectedIndex.value == 0) {
                                      if (Get.isRegistered<
                                          AgendaController>()) {
                                        final agendaCtrl =
                                            Get.find<AgendaController>();
                                        if (agendaCtrl
                                            .scrollController.hasClients) {
                                          agendaCtrl.scrollController.animateTo(
                                            0,
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.easeOut,
                                          );
                                          return;
                                        }
                                      }
                                    }
                                    if (i == 1 &&
                                        controller.selectedIndex.value == 1) {
                                      if (Get.isRegistered<
                                          ExploreController>()) {
                                        final explore =
                                            Get.find<ExploreController>();
                                        int tab = 0;
                                        try {
                                          tab = Get.find<PageLineBarController>(
                                                  tag: 'Explore')
                                              .selection
                                              .value;
                                        } catch (_) {}
                                        ScrollController? sc;
                                        switch (tab) {
                                          case 0:
                                            sc = explore.exploreScroll;
                                            break;
                                          case 1:
                                            sc = explore.floodsScroll;
                                            break;
                                          case 2:
                                            sc = explore.videoScroll;
                                            break;
                                          case 3:
                                            sc = explore.photoScroll;
                                            break;
                                          default:
                                            sc = explore.exploreScroll;
                                        }
                                        if (sc.hasClients) {
                                          sc.animateTo(0,
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              curve: Curves.easeOut);
                                          return;
                                        }
                                      }
                                    }
                                    if (i != 2) {
                                      if (i ==
                                          (settingController
                                                  .educationScreenIsOn.value
                                              ? 3
                                              : 2)) {
                                        FocusScope.of(context).unfocus();
                                        controller.changeIndex(i);
                                      } else {
                                        controller.changeIndex(i);
                                      }
                                    } else {
                                      final shortController =
                                          Get.isRegistered<ShortController>()
                                              ? Get.find<ShortController>()
                                              : Get.put(ShortController());

                                      if (shortController.shorts.isEmpty) {
                                        shortController
                                            .backgroundPreload()
                                            .catchError((_) {});
                                      }

                                      await Get.to(() => const ShortView());
                                    }
                                  },
                                  child: Builder(builder: (_) {
                                    if (icons[i] == 'profile_dynamic') {
                                      return Obx(() {
                                        CurrentUserService
                                            .instance.currentUserRx.value;
                                        final authUid = FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '';
                                        final userId = CurrentUserService
                                                .instance.userId.isNotEmpty
                                            ? CurrentUserService.instance.userId
                                            : authUid;
                                        final img = CurrentUserService
                                            .instance.avatarUrl;
                                        final uploading =
                                            controller.uploadingPosts.value;
                                        const double size = 28;
                                        return AnimatedBuilder(
                                          animation: controller
                                              .animationController.value,
                                          builder: (_, __) {
                                            final angle = controller
                                                    .animationController
                                                    .value
                                                    .value *
                                                2 *
                                                math.pi *
                                                3;
                                            return _AvatarWithRing(
                                              userId: userId,
                                              imageUrl: img,
                                              size: size,
                                              isSelected: isSelected,
                                              uploading: uploading,
                                              angle: angle,
                                            );
                                          },
                                        );
                                      });
                                    }
                                    return SvgPicture.asset(
                                      '${icons[i]}${isSelected ? '_fill.svg' : '.svg'}',
                                      height: i <= 1 ? 25 : 28,
                                      colorFilter: ColorFilter.mode(
                                        isSelected
                                            ? Colors.black
                                            : Colors.black
                                                .withValues(alpha: 0.5),
                                        BlendMode.srcIn,
                                      ),
                                    );
                                  }),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithRing extends StatefulWidget {
  final String userId;
  final String imageUrl;
  final double size;
  final bool isSelected;
  final bool uploading;
  final double angle; // radians
  const _AvatarWithRing({
    required this.userId,
    required this.imageUrl,
    required this.size,
    required this.isSelected,
    required this.uploading,
    required this.angle,
  });

  @override
  State<_AvatarWithRing> createState() => _AvatarWithRingState();
}

class _AvatarWithRingState extends State<_AvatarWithRing> {
  double _scale = 1.0;
  late String _stableUserId;
  late String _stableImageUrl;

  @override
  void initState() {
    super.initState();
    _stableUserId = widget.userId.trim();
    _stableImageUrl = widget.imageUrl.trim();
  }

  @override
  void didUpdateWidget(covariant _AvatarWithRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextUserId = widget.userId.trim();
    final nextImageUrl = widget.imageUrl.trim();
    if (nextUserId.isNotEmpty) {
      _stableUserId = nextUserId;
    }
    if (nextImageUrl.isNotEmpty) {
      _stableImageUrl = nextImageUrl;
    }
  }

  void _down(PointerDownEvent e) {
    setState(() => _scale = 0.75);
  }

  void _up(PointerUpEvent e) {
    setState(() => _scale = 1.0);
  }

  void _cancel(PointerCancelEvent e) {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CachedUserAvatar(
      userId: _stableUserId.isNotEmpty ? _stableUserId : widget.userId,
      imageUrl: _stableImageUrl.isNotEmpty ? _stableImageUrl : widget.imageUrl,
      radius: widget.size / 2,
      backgroundColor: Colors.transparent,
      placeholder: DefaultAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.transparent,
        iconColor: widget.isSelected
            ? Colors.black
            : Colors.black.withValues(alpha: 0.5),
        padding: EdgeInsets.all(widget.size * 0.18),
      ),
      errorWidget: DefaultAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.transparent,
        iconColor: widget.isSelected
            ? Colors.black
            : Colors.black.withValues(alpha: 0.5),
        padding: EdgeInsets.all(widget.size * 0.18),
      ),
    );

    // Two-pixel gap around avatar
    final ringSize = widget.size + 8; // 4px padding each side approx

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: CustomPaint(
            painter: _RingPainter(
              baseColor: Colors.grey.withValues(alpha: 0.35),
              uploading: widget.uploading,
              angle: widget.angle,
            ),
            child: Center(child: avatar),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color baseColor;
  final bool uploading;
  final double angle;

  _RingPainter({
    required this.baseColor,
    required this.uploading,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 1.5;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    // Base gray ring always visible
    canvas.drawCircle(center, radius, basePaint);

    if (uploading) {
      // Sweep arc
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = SweepGradient(
          colors: [AppColors.primaryColor, AppColors.secondColor],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final arcLength = math.pi * 0.9; // ~162 degrees
      final start = angle;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, arcLength, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.uploading != uploading ||
        oldDelegate.angle != angle;
  }
}
