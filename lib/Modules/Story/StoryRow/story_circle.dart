import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';

class StoryCircle extends StatefulWidget {
  final StoryUserModel model;
  final List<StoryUserModel> users;
  final bool isFirst;

  StoryCircle({
    super.key,
    required this.model,
    required this.users,
    this.isFirst = false,
  });

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  final userService = CurrentUserService.instance;
  StoryInteractionOptimizer get _storyOptimizer => StoryInteractionOptimizer.to;
  static const double _storyCircleSize = 74;
  static const double _storyAvatarRadius = 37;
  static const double _labelWidth = 78;
  static const double _addBadgeSize = 18;

  String get _currentUid => userService.effectiveUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: _storyCircleSize,
          height: _storyCircleSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  final cont = AgendaController.maybeFind();
                  final prevIndex = cont?.lastCenteredIndex;
                  cont?.lastCenteredIndex = prevIndex;
                  cont?.centeredIndex.value = -1;
                  final myUserID = _currentUid;
                  final isMe =
                      myUserID.isNotEmpty && widget.model.userID == myUserID;

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
                          cont.resumeFeedPlayback();
                        }
                      });
                    } else {
                      // Story'im yok, StoryMaker'a git
                      Get.to(() => StoryMaker())?.then((_) {
                        if (cont != null) {
                          cont.resumeFeedPlayback();
                        }
                      });
                    }
                  } else {
                    // Başkasına tıkladıysan, onun hikayesini aç
                    Get.to(() => StoryViewer(
                        startedUser: widget.model,
                        storyOwnerUsers: widget.users))?.then((_) {
                      if (cont != null) {
                        cont.resumeFeedPlayback();
                      }
                    });
                  }
                },
                onLongPress: () {
                  final myId = _currentUid;
                  final isMe = myId.isNotEmpty && widget.model.userID == myId;
                  if (isMe) {
                    // Uzun basınca silinmiş hikayeler – arka plan videolarını durdur
                    final agenda = AgendaController.maybeFind();
                    final prevIndex = agenda?.lastCenteredIndex;
                    if (agenda != null) {
                      agenda.lastCenteredIndex = prevIndex;
                      agenda.centeredIndex.value = -1;
                      agenda.pauseAll.value = true;
                    }
                    if (DeletedStoriesController.maybeFind() != null) {
                      Get.delete<DeletedStoriesController>(force: true);
                    }
                    Get.to(() => const DeletedStoriesView())?.then((_) {
                      if (agenda != null) {
                        agenda.pauseAll.value = false;
                        agenda.resumeFeedPlayback();
                      }
                    });
                  }
                },
                child: Obx(() {
                  final myId = _currentUid;
                  final isMe = myId.isNotEmpty && widget.model.userID == myId;
                  final hasStory = widget.model.stories.isNotEmpty;

                  // OPTİMİZE EDİLMİŞ CACHE'DEN HIZLI KONTROL
                  final allSeen = _storyOptimizer.areAllStoriesSeenCached(
                    widget.model.userID,
                    widget.model.stories,
                  );

                  final uploading =
                      StoryMakerController.isUploadingStory.value; // RxBool
                  final isUploading = isMe && uploading;

                  final highlight = hasStory && !allSeen;

                  Widget avatarImage() {
                    // Use CachedUserAvatar for all users (instant for current user)
                    final imageUrl =
                        isMe ? userService.avatarUrl : widget.model.avatarUrl;
                    return ClipRect(
                      child: CachedUserAvatar(
                        userId: widget.model.userID,
                        imageUrl: imageUrl,
                        radius: _storyAvatarRadius,
                        backgroundColor: Colors.transparent,
                        placeholder: const DefaultAvatar(
                          radius: _storyAvatarRadius,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    );
                  }

                  final baseRingDecoration = BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withAlpha(20),
                    border:
                        Border.all(color: Colors.grey.withAlpha(50), width: 2),
                  );

                  const highlightRingDecoration = ShapeDecoration(
                    shape: CircleBorder(),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB7D8FF),
                        Color(0xFF6EB6FF),
                        Color(0xFF2C8DFF),
                        Color(0xFF0E5BFF),
                      ],
                    ),
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.isFirst && hasStory)
                        Positioned(
                          left: -34,
                          top: (_storyCircleSize / 2) - 2,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 30),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, width, child) {
                              return Container(
                                width: width,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFB7D8FF).withAlpha(0),
                                      const Color(0xFF6EB6FF),
                                      const Color(0xFF0E5BFF),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Container(
                        decoration: highlight
                            ? highlightRingDecoration
                            : baseRingDecoration,
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
                  child: (_currentUid.isNotEmpty &&
                          widget.model.userID == _currentUid)
                      ? GestureDetector(
                          onTap: () {
                            // Agenda'daki oynatmayi durdur ve StoryMaker'a git
                            final cont = AgendaController.maybeFind();
                            final prevIndex = cont?.lastCenteredIndex;
                            cont?.lastCenteredIndex = prevIndex;
                            cont?.centeredIndex.value = -1;

                            Get.to(() => StoryMaker())?.then((_) {
                              // Geri dönünce merkezdeki gönderiyi geri yükle
                              if (cont != null) {
                                cont.resumeFeedPlayback();
                              }
                            });
                          },
                          child: Container(
                            width: _addBadgeSize,
                            height: _addBadgeSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.green),
                            child: Icon(
                              CupertinoIcons.add,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink())
            ],
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: _labelWidth,
          child: Text(
            widget.model.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              height: 1,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
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
      ..color = Colors.black.withValues(alpha: 0.10)
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
        Colors.blue.withValues(alpha: 0.8),
        Colors.purple.withValues(alpha: 0.9),
        Colors.pink.withValues(alpha: 0.7),
        Colors.blue.withValues(alpha: 0.8),
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
