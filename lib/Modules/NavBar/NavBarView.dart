import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Themes/AppColors.dart';
import 'dart:math' as math;
import 'NavBarController.dart';
import 'package:turqappv2/Core/PageLineBar.dart';
import 'package:turqappv2/Modules/Explore/ExploreController.dart';
import 'package:turqappv2/Modules/Agenda/AgendaController.dart';
import 'package:turqappv2/Modules/Education/EducationController.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/UnreadMessagesController.dart';
import '../Agenda/AgendaView.dart';
import '../Explore/ExploreView.dart';
import '../Profile/MyProfile/ProfileView.dart';
import '../Education/EducationView.dart';
import '../Short/ShortView.dart';
import '../Short/ShortController.dart';
import '../Profile/Settings/SettingsController.dart';
import '../../Core/Widgets/OfflineIndicator.dart';

class NavBarView extends StatelessWidget {
  final selection = 0;

  NavBarView({super.key});
  final NavBarController controller = Get.put(NavBarController());
  final SettingsController settingController = Get.put(SettingsController());
  final FirebaseMyStore userStore = Get.find<FirebaseMyStore>();

  // Ensure controllers are available
  void _ensureControllersReady() {
    if (!Get.isRegistered<ExploreController>()) {
      Get.put(ExploreController());
    }
    if (!Get.isRegistered<AgendaController>()) {
      Get.put(AgendaController());
    }
    if (!Get.isRegistered<ShortController>()) {
      Get.put(ShortController());
    }
    if (!Get.isRegistered<EducationController>()) {
      Get.put(EducationController());
    }

    // ⚠️ CRITICAL FIX: Start UnreadMessagesController listeners after user is logged in
    // Note: startListeners() has internal guard against multiple calls
    if (Get.isRegistered<UnreadMessagesController>()) {
      final unreadController = Get.find<UnreadMessagesController>();
      unreadController.startListeners();
    }

    // Short controller hazır olduktan sonra preload'u gecikmesiz başlat
    if (Get.isRegistered<ShortController>()) {
      final shortController = Get.find<ShortController>();
      shortController.backgroundPreload().then((_) {
        print('[NavBar] Proaktif Short preload tamamlandı');
      }).catchError((e) {
        print('[NavBar] Proaktif Short preload hatası: $e');
      });
    }
  }

  late final AnimationController animationController;

  Future<bool> _handleBackNavigation() async {
    final hasEducation = settingController.educationScreenIsOn.value;
    final profileIndex = hasEducation ? 4 : 3;
    final educationIndex = hasEducation ? 3 : 0;

    if (controller.selectedIndex.value == profileIndex) {
      controller.changeIndex(educationIndex);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllersReady(); // Ensure all controllers are ready before building
    double targetCharCount = "TurqApp".length.toDouble();
    double fontSize = (Get.width / targetCharCount) * 1.3;
    return Obx(() {
      // Define pages and icons
      final pages = [
        // Hikayeler MyApp başlamadan önce yüklendiği için direkt göster
        AgendaView(),
        ExploreView(),
        Container(), // placeholder for shorts
        if (settingController.educationScreenIsOn.value) EducationView(),
        ProfileView(),
      ];
      final icons = [
        'assets/icons/house',
        'assets/icons/search',
        'assets/icons/play',
        if (settingController.educationScreenIsOn.value) 'assets/icons/sinav',
        'profile_dynamic',
      ];

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
            // Current page
            Column(
              children: [
                const OfflineIndicator(),
                Expanded(
                  child: pages[controller.selectedIndex.value],
                ),
              ],
            ),

            // Opening overlay (first boot only)
            // const Positioned.fill(child: OpeningOverlay()),

            AnimatedOpacity(
              opacity: controller.showBar.value ? 1 : 0.2,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  math.max(
                    0.0,
                    math.max(8.0, MediaQuery.of(context).viewPadding.bottom) - 10,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
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
                          final isSelected = controller.selectedIndex.value == i;
                          return TextButton(
                            style: ButtonStyle(
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              padding: WidgetStateProperty.all(EdgeInsets.zero),
                            ),
                            onPressed: () async {
                        // Eğer zaten AgendaView (index 0) aktifken House ikonuna basılırsa, en üste kaydır
                        if (i == 0 && controller.selectedIndex.value == 0) {
                          if (Get.isRegistered<AgendaController>()) {
                            final agendaCtrl = Get.find<AgendaController>();
                            if (agendaCtrl.scrollController.hasClients) {
                              agendaCtrl.scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                              );
                              return;
                            }
                          }
                          // Kayıtlı controller yoksa normal akışa düşer
                        }
                        // Explore sayfasındayken search ikonuna tekrar basılırsa: mevcut sekmenin en üstüne kaydır
                        if (i == 1 && controller.selectedIndex.value == 1) {
                          if (Get.isRegistered<ExploreController>()) {
                            final explore = Get.find<ExploreController>();
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
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut);
                              return;
                            }
                          }
                          // controller kayıtlı değilse normal akış
                        }
                        if (i != 2) {
                          if (i ==
                              (settingController.educationScreenIsOn.value
                                  ? 3
                                  : 2)) {
                            FocusScope.of(context).unfocus();
                            controller.changeIndex(i);
                          } else {
                            controller.changeIndex(i);
                          }
                        } else {
                          // Short ikonuna tıklandığında background preload başlat
                          final shortController = Get.find<ShortController>();

                          try {
                            await shortController.backgroundPreload();
                            print('[NavBar] Short preload tamamlandı');
                          } catch (e) {
                            print('[NavBar] Short preload hatası: $e');
                          }

                          await Get.to(() => const ShortView());
                        }
                            },
                            child: Builder(builder: (_) {
                              if (icons[i] == 'profile_dynamic') {
                                return Obx(() {
                                  final img = userStore.pfImage.value;
                                  final uploading =
                                      controller.uploadingPosts.value;
                                  const double size = 28;
                                  return AnimatedBuilder(
                                    animation:
                                        controller.animationController.value,
                                    builder: (_, __) {
                                      // Slightly faster sweep rotation
                                      final angle = controller
                                              .animationController.value.value *
                                          2 *
                                          math.pi *
                                          3;
                                      return _AvatarWithRing(
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
                                color: isSelected
                                    ? Colors.black
                                    : Colors.black.withOpacity(0.5),
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
              ],
            ),
          ),
        );
    });
  }
}

class _AvatarWithRing extends StatefulWidget {
  final String imageUrl;
  final double size;
  final bool isSelected;
  final bool uploading;
  final double angle; // radians
  const _AvatarWithRing({
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
    final avatar = CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: Colors.transparent,
      backgroundImage:
          widget.imageUrl.isNotEmpty ? NetworkImage(widget.imageUrl) : null,
      child: widget.imageUrl.isEmpty
          ? Icon(Icons.person,
              size: widget.size * 0.7,
              color: widget.isSelected
                  ? Colors.black
                  : Colors.black.withOpacity(0.5))
          : null,
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
              baseColor: Colors.grey.withOpacity(0.35),
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
