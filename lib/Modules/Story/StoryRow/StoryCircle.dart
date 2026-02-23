import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Agenda/AgendaController.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/StoryMaker.dart';
import 'package:turqappv2/Modules/Story/StoryRow/StoryRowController.dart';
import 'package:turqappv2/Modules/Story/StoryRow/StoryUserModel.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryViewer.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/StoryInteractionOptimizer.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/StoryMakerController.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/DeletedStories.dart';
import 'package:turqappv2/Themes/AppColors.dart';

class StoryCircle extends StatefulWidget {
  StoryUserModel model;
  List<StoryUserModel> users;

  StoryCircle({super.key, required this.model, required this.users});

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  final userStore = Get.find<FirebaseMyStore>();
  final userService = CurrentUserService.instance;
  final storeController = Get.find<StoryRowController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () {
                    final cont = Get.isRegistered<AgendaController>()
                        ? Get.find<AgendaController>()
                        : null;
                    final prevIndex = cont?.lastCenteredIndex;
                    cont?.centeredIndex.value = -1;
                    final myUserID = FirebaseAuth.instance.currentUser?.uid;
                    final isMe =
                        myUserID != null && widget.model.userID == myUserID;

                    // Eğer tıklanan çember bana aitse
                    if (isMe) {
                      // Story'im var mı? Model'deki story'leri kontrol et
                      final hasMyStory = widget.model.stories.isNotEmpty;

                      if (hasMyStory) {
                        // Kendi story'ime git - users listesinden değil, model'den al
                        Get.to(() => StoryViewer(
                            startedUser: widget.model,
                            storyOwnerUsers: widget.users))?.then((_) {
                          if (cont != null) {
                            cont.centeredIndex.value = prevIndex ?? 0;
                          }
                        });
                      } else {
                        // Story'im yok, StoryMaker'a git
                        Get.to(() => StoryMaker())?.then((_) {
                          if (cont != null) {
                            cont.centeredIndex.value = prevIndex ?? 0;
                          }
                        });
                      }
                    } else {
                      // Başkasına tıkladıysan, onun hikayesini aç
                      Get.to(() => StoryViewer(
                          startedUser: widget.model,
                          storyOwnerUsers: widget.users))?.then((_) {
                        if (cont != null) {
                          cont.centeredIndex.value = prevIndex ?? 0;
                        }
                      });
                    }
                  },
                  onLongPress: () {
                    final myId = FirebaseAuth.instance.currentUser?.uid;
                    final isMe = myId != null && widget.model.userID == myId;
                    if (isMe) {
                      // Uzun basınca silinmiş hikayeler – arka plan videolarını durdur
                      final agenda = Get.isRegistered<AgendaController>()
                          ? Get.find<AgendaController>()
                          : null;
                      final prevIndex = agenda?.lastCenteredIndex;
                      if (agenda != null) {
                        agenda.centeredIndex.value = -1;
                        agenda.pauseAll.value = true;
                      }
                      Get.to(() => DeletedStoriesView())?.then((_) {
                        if (agenda != null) {
                          agenda.pauseAll.value = false;
                          agenda.centeredIndex.value = prevIndex ?? 0;
                        }
                      });
                    }
                  },
                  child: Obx(() {
                    final myId = FirebaseAuth.instance.currentUser?.uid;
                    final isMe = myId != null && widget.model.userID == myId;
                    final hasStory = widget.model.stories.isNotEmpty;

                    // OPTİMİZE EDİLMİŞ CACHE'DEN HIZLI KONTROL
                    final allSeen = StoryInteractionOptimizer.to
                        .areAllStoriesSeenCached(
                            widget.model.userID, widget.model.stories);

                    final uploading =
                        StoryMakerController.isUploadingStory.value; // RxBool
                    final seenAtTick =
                        userStore.readStoriesTimes[widget.model.userID] ??
                            0; // RxMap depend
                    final isUploading = isMe && uploading;

                    final highlight = hasStory && !allSeen;

                    Widget avatarImage() {
                      // Use CachedUserAvatar for all users (instant for current user)
                      final imageUrl = isMe
                          ? (userService.currentUser?.pfImage ?? '')
                          : widget.model.pfImage;

                      if (imageUrl.isEmpty) {
                        return Container(color: Colors.grey.withAlpha(60));
                      }

                      return ClipRect(
                        child: CachedUserAvatar(
                          userId: widget.model.userID,
                          imageUrl: imageUrl,
                          radius: 100, // Large enough to fill container
                        ),
                      );
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: isUploading
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                )
                              : (highlight
                                  ? ShapeDecoration(
                                      shape: CircleBorder(),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.textBlue,
                                          AppColors.textPink,
                                          AppColors.textPink,
                                        ],
                                      ),
                                    )
                                  : BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.withAlpha(20),
                                      border: Border.all(
                                          color: Colors.grey.withAlpha(50),
                                          width: 2),
                                    )),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: avatarImage(),
                              ),
                            ),
                          ),
                        ),
                        if (isUploading)
                          Positioned.fill(child: StoryUploadingRing()),
                      ],
                    );
                  }),
                ),
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: (FirebaseAuth.instance.currentUser != null &&
                            widget.model.userID ==
                                FirebaseAuth.instance.currentUser!.uid)
                        ? GestureDetector(
                            onTap: () {
                              // Agenda'daki oynatmayi durdur ve StoryMaker'a git
                              final cont = Get.isRegistered<AgendaController>()
                                  ? Get.find<AgendaController>()
                                  : null;
                              final prevIndex = cont?.lastCenteredIndex;
                              cont?.centeredIndex.value = -1;

                              Get.to(() => StoryMaker())?.then((_) {
                                // Geri dönünce merkezdeki gönderiyi geri yükle
                                if (cont != null) {
                                  cont.centeredIndex.value = prevIndex ?? 0;
                                }
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.green),
                              child: Icon(
                                CupertinoIcons.add,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          )
                        : RozetContent(size: 20, userID: widget.model.userID))
              ],
            ),
          ),
        ),
        SizedBox(
          height: 3,
        ),
        Text(
          widget.model.nickname,
          style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: "MontserratMedium"),
        )
      ],
    );
  }
}

class StoryUploadingRing extends StatefulWidget {
  final double strokeWidth;
  const StoryUploadingRing({super.key, this.strokeWidth = 2});

  @override
  State<StoryUploadingRing> createState() => _StoryUploadingRingState();
}

class _StoryUploadingRingState extends State<StoryUploadingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final angle = _controller.value * 2 * math.pi * 3; // faster sweep
        return CustomPaint(
          painter: _StoryRingPainter(
            angle: angle,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _StoryRingPainter extends CustomPainter {
  final double angle; // radians
  final double strokeWidth;
  _StoryRingPainter({required this.angle, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 2.5;

    // Base ring
    final basePaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = SweepGradient(
        colors: [
          AppColors.primaryColor,
          AppColors.secondColor,
        ],
      ).createShader(rect);

    const arcLen = math.pi * 0.9; // ~162 degrees
    canvas.drawArc(rect, angle, arcLen, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _StoryRingPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.strokeWidth != strokeWidth;
  }
}

class FluidCirclePainter extends CustomPainter {
  final double pulseValue;

  FluidCirclePainter(this.pulseValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 3;
    final radius = baseRadius + (pulseValue * 2); // Breathing effect

    // Create gradient shader
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: [
        Colors.blue.withOpacity(0.8),
        Colors.purple.withOpacity(0.9),
        Colors.pink.withOpacity(0.7),
        Colors.blue.withOpacity(0.8),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = gradient.createShader(rect);

    // Main stroke
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + (pulseValue) // Dynamic thickness
      ..strokeCap = StrokeCap.round;

    // Draw main circle
    canvas.drawCircle(center, radius, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3.0 + (pulseValue * 2));

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(FluidCirclePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
