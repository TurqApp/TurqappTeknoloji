import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/ring_upload_progress_indicator.dart';
import 'package:turqappv2/Modules/Agenda/Components/post_state_messages.dart';
import '../Common/post_content_base.dart';
import '../Common/post_content_controller.dart';
import '../Common/post_action_style.dart';
import 'package:turqappv2/Modules/Agenda/Common/reshare_attribution.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../../Core/BottomSheets/no_yes_alert.dart';
import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/texts.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../Social/PostSharers/post_sharers.dart';
import '../../SocialProfile/social_profile.dart';
import '../../PostCreator/post_creator.dart';
import 'classic_content_controller.dart';

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
  static const PostActionStyle _actionStyle = PostActionStyle.classic();
  static const Color _actionColor = Color(0xFF6F7A85);
  final arsivController = Get.put(ArchiveController());
  final ShortController shortsController = Get.find<ShortController>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final bool _isFullscreen = false;
  bool _isCaptionExpanded = false;

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      VideoStateManager.instance.pauseAllVideos();
    } catch (_) {}
  }

  @override
  bool get enableBufferedAutoplay => false;

  static const double _contentAspectRatio = 0.80;

  @override
  void onPostInitialized() {
    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (next != _currentPage) {
        setState(() => _currentPage = next);
      }
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
    if (widget.shouldPlay != oldWidget.shouldPlay &&
        videoController?.value.isInitialized == true) {
      if (widget.shouldPlay) {
        videoController!
          ..setLooping(true)
          ..play();
      } else {
        videoController?.pause();
      }
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    try {
      controller.getLikes();
      controller.getSaved();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Gizli, arşivli veya silindi ise videoyu durdur
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value) {
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

  Widget textOnlyBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onDoubleTap: () => controller.like(),
            onTap: () {
              if (widget.model.floodCount > 1) {
                Get.to(() => FloodListing(mainModel: widget.model));
              }
            },
            child: Stack(
              children: [
                Positioned(
                  left: 15,
                  top: 0,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    widget.model.metin.trim(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 0,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 56,
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                // SharedPostLabel - text içeriğinin sol altına
                if (widget.model.originalUserID.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 15,
                    child: SharedPostLabel(
                      originalUserID: widget.model.originalUserID,
                      // sharedAsPost removed
                      fontSize: 12,
                      textColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Reshare attribution (single instance - fixed triple rendering bug)
        if (widget.isReshared)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 58, child: Center(child: commentButton(context))),
              SizedBox(width: 58, child: Center(child: likeButton())),
              SizedBox(width: 58, child: Center(child: saveButton())),
              SizedBox(width: 58, child: Center(child: reshareButton())),
              SizedBox(width: 58, child: Center(child: statButton())),
              SizedBox(width: 58, child: Center(child: sendButton())),
            ],
          ),
        ),
        3.ph,
      ],
    );
  }

  Widget _buildFeedCaption({
    required String text,
    required Color color,
  }) {
    const baseStyle = TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: "Montserrat",
      height: 1.25,
    );
    final textStyle = baseStyle.copyWith(color: color);
    const suffix = " devamı";

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 7,
        )..layout(maxWidth: constraints.maxWidth);

        if (_isCaptionExpanded || !painter.didExceedMaxLines) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isCaptionExpanded) {
                setState(() => _isCaptionExpanded = true);
              }
            },
            child: Text(text, style: textStyle),
          );
        }

        int low = 0;
        int high = text.length;
        int best = 0;
        while (low <= high) {
          final mid = (low + high) ~/ 2;
          final candidate = text.substring(0, mid).trimRight();
          final candidatePainter = TextPainter(
            text: TextSpan(
              children: [
                TextSpan(text: candidate, style: textStyle),
                const TextSpan(
                  text: suffix,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontFamily: "MontserratMedium",
                    height: 1.25,
                  ),
                ),
              ],
            ),
            textDirection: TextDirection.ltr,
            maxLines: 7,
          )..layout(maxWidth: constraints.maxWidth);

          if (candidatePainter.didExceedMaxLines) {
            high = mid - 1;
          } else {
            best = mid;
            low = mid + 1;
          }
        }

        final collapsed = text.substring(0, best).trimRight();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isCaptionExpanded = true),
          child: RichText(
            maxLines: 7,
            overflow: TextOverflow.clip,
            text: TextSpan(
              children: [
                TextSpan(text: collapsed, style: textStyle),
                const TextSpan(
                  text: suffix,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontFamily: "MontserratMedium",
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget imgBody(BuildContext context) {
    final hasHeaderSubline = widget.model.metin.trim().isNotEmpty;
    final mediaTopSpacing = hasHeaderSubline ? 4.0 : 0.0;
    final actionTopSpacing = hasHeaderSubline ? 2.0 : 0.0;
    final mediaVisualLift = hasHeaderSubline ? 0.0 : -6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          return headerUserInfoBar();
        }),
        if (widget.model.img.length == 1)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: GestureDetector(
                onTap: () {
                  _pauseFeedBeforeFullscreen();
                  final visibleList = agendaController.agendaList
                      .where((val) =>
                          val.deletedPost == false &&
                          val.arsiv == false &&
                          val.gizlendi == false &&
                          val.img.isNotEmpty)
                      .toList();

                  if (widget.isPreview) {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  } else if (widget.model.floodCount > 1) {
                    Get.to(() => FloodListing(mainModel: widget.model));
                  } else {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  }
                },
                onDoubleTap: () {
                  controller.like();
                },
                child: AspectRatio(
                  aspectRatio: widget.model.aspectRatio.toDouble(),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: widget.model.img.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.model.floodCount > 1)
                                Texts.colorfulFlood,
                              if (widget.model.originalUserID.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: SharedPostLabel(
                                    originalUserID: widget.model.originalUserID,
                                    fontSize: 12,
                                    textColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: GestureDetector(
                onTap: () {
                  _pauseFeedBeforeFullscreen();
                  final visibleList = agendaController.agendaList
                      .where((val) =>
                          val.deletedPost == false &&
                          val.arsiv == false &&
                          val.gizlendi == false &&
                          val.img.isNotEmpty)
                      .toList();

                  if (widget.isPreview) {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  } else if (widget.model.floodCount > 1) {
                    Get.to(FloodListing(mainModel: widget.model));
                  } else {
                    Get.to(() => PhotoShorts(
                          fetchedList: visibleList,
                          startModel: widget.model,
                        ));
                  }
                },
                onDoubleTap: () {
                  controller.like();
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.model.img.length,
                        itemBuilder: (context, index) {
                          final img = widget.model.img[index];
                          return CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.model.floodCount > 1)
                                Texts.colorfulFlood,
                              SharedPostLabel(
                                originalUserID: widget.model.originalUserID,
                                fontSize: 12,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List.generate(widget.model.img.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 6 : 5,
                              height: isActive ? 6 : 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.white : Colors.white54,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.model.hasPlayableVideo || widget.model.img.isNotEmpty)
          buildPollCard(),
        if (!widget.model.hasPlayableVideo && widget.model.img.isEmpty)
          buildPollCard(),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: buildUploadIndicator(),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Transform.translate(
                offset: const Offset(2, 0),
                child: commentButton(context),
              ),
              Transform.translate(
                offset: const Offset(2, 0),
                child: likeButton(),
              ),
              Transform.translate(
                offset: const Offset(2, 0),
                child: reshareButton(),
              ),
              Transform.translate(
                offset: const Offset(2, 0),
                child: statButton(),
              ),
              Transform.translate(
                offset: const Offset(2, 0),
                child: saveButton(),
              ),
              sendButton(),
            ],
          ),
        ),
        3.ph,
      ],
    );
  }

  Widget buildPollCard() {
    return Obx(() {
      final model = controller.currentModel.value ?? widget.model;
      final poll = model.poll;
      if (poll.isEmpty) return const SizedBox.shrink();
      final options = (poll['options'] is List) ? poll['options'] as List : [];
      if (options.isEmpty) return const SizedBox.shrink();

      final totalVotes =
          (poll['totalVotes'] is num) ? poll['totalVotes'] as num : 0;
      final uid = controller.userService.userId;
      final userVotes = poll['userVotes'] is Map
          ? Map<String, dynamic>.from(poll['userVotes'])
          : <String, dynamic>{};
      final userVoteRaw = userVotes[uid];
      final int? userVote = userVoteRaw is num
          ? userVoteRaw.toInt()
          : int.tryParse('${userVoteRaw ?? ''}');

      final createdAt = (poll['createdAt'] ?? model.timeStamp) as num;
      final durationHours = (poll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      final expired = DateTime.now().millisecondsSinceEpoch > expiresAt;
      final canVote = !expired && userVote == null;
      final showResults = userVote != null || expired;

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(options.length, (i) {
                final text = (options[i]['text'] ?? '').toString();
                final votes = (options[i]['votes'] ?? 0) as num;
                final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
                final label = '${String.fromCharCode(65 + i)}) ';
                final isSelected = userVote == i;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: canVote ? () => controller.votePoll(i) : null,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.blue.withAlpha(18) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$label$text',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showResults)
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Toplam ${totalVotes.toInt()} oy',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _pollRemainingLabel(
                      expired: expired,
                      expiresAtMs: expiresAt,
                    ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Widget buildUploadIndicator() {
    final uploadService = Get.isRegistered<UploadQueueService>()
        ? Get.find<UploadQueueService>()
        : Get.put(UploadQueueService());

    return Obx(() {
      QueuedUpload? item;
      for (final q in uploadService.queue) {
        if (q.id == widget.model.docID &&
            (q.status == UploadStatus.pending ||
                q.status == UploadStatus.uploading)) {
          item = q;
          break;
        }
      }

      double? progress;
      if (item != null) {
        progress = item.progress;
      } else {
        final hasVideo = widget.model.hasPlayableVideo ||
            widget.model.video.trim().isNotEmpty ||
            widget.model.hlsMasterUrl.trim().isNotEmpty ||
            widget.model.thumbnail.trim().isNotEmpty;
        final hlsNotReady = widget.model.hlsStatus != 'ready' ||
            widget.model.hlsMasterUrl.trim().isEmpty;
        if (hasVideo && hlsNotReady) {
          final startMs = widget.model.hlsUpdatedAt > 0
              ? widget.model.hlsUpdatedAt.toInt()
              : widget.model.timeStamp.toInt();
          final elapsedMin =
              ((DateTime.now().millisecondsSinceEpoch - startMs) / 60000)
                  .clamp(0, 30);
          progress = 0.9 + (elapsedMin / 30) * 0.09;
        }
      }

      if (progress == null) return const SizedBox.shrink();
      if (progress <= 0) {
        progress = 0.02;
      }
      return RingUploadProgressIndicator(
        isUploading: true,
        progress: progress,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload,
            size: 12,
            color: Colors.black54,
          ),
        ),
      );
    });
  }

  String _pollRemainingLabel(
      {required bool expired, required int expiresAtMs}) {
    if (expired) return 'Süre Doldu';
    final remainingMs = expiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return 'Süre Doldu';
    final totalMinutes = (remainingMs / 60000).floor();
    final totalHours = (totalMinutes / 60).floor();
    final days = (totalHours / 24).floor();
    if (days >= 1) return '$days g';
    final hours = totalHours;
    final minutes = totalMinutes % 60;
    return '$hours sa $minutes dk';
  }

  Widget videoBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VisibilityDetector(
          key: Key('classic-media-${widget.model.docID}'),
          onVisibilityChanged: (info) {
            reportMediaVisibility(info.visibleFraction);
          },
          child: Stack(
            children: [
              if (videoController != null)
                Stack(
                  children: [
                    // Video Player
                    GestureDetector(
                      onTap: null,
                      onDoubleTap: () {
                        controller.like();
                      },
                      child: AspectRatio(
                        aspectRatio: _contentAspectRatio,
                        child: _isFullscreen
                            ? const SizedBox.shrink()
                            : videoController!.buildPlayer(
                                key: ValueKey(
                                    'classic-${widget.model.docID}-${videoController.hashCode}'),
                                aspectRatio: _contentAspectRatio,
                                useAspectRatio: false,
                              ),
                      ),
                    ),
                    // Thumbnail overlay - video hazır olana kadar göster
                    ValueListenableBuilder<HLSVideoValue>(
                      valueListenable: videoValueNotifier,
                      builder: (_, v, child) {
                        if (v.isInitialized && v.position > Duration.zero) {
                          return const SizedBox.shrink();
                        }
                        return child!;
                      },
                      child: AspectRatio(
                        aspectRatio: _contentAspectRatio,
                        child: widget.model.thumbnail.isNotEmpty
                            ? Image.network(
                                widget.model.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: const Color(0xFFE8E8E8)),
                              )
                            : Container(color: const Color(0xFFE8E8E8)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: buildUploadIndicator(),
                    ),
                  ],
                )
              else
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: _contentAspectRatio,
                      child: Container(
                        color: const Color(0xFFE8E8E8),
                        child: widget.model.thumbnail.isEmpty
                            ? null
                            : Image.network(
                                widget.model.thumbnail,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox.shrink();
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: buildUploadIndicator(),
                    ),
                  ],
                ),

              // Süre göstergesi + Replay — sadece video state değiştiğinde rebuild
              if (videoController != null)
                ValueListenableBuilder<HLSVideoValue>(
                  valueListenable: videoValueNotifier,
                  builder: (_, v, __) {
                    if (!v.isInitialized) return const SizedBox.shrink();
                    final remaining = v.duration - v.position;
                    final safeRemaining =
                        remaining.isNegative ? Duration.zero : remaining;
                    return Stack(
                      children: [
                        Positioned(
                          top: 50,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(safeRemaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              if (videoController != null && widget.model.floodCount > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Texts.colorfulFloodForVideo,
                ),

              if (isVideoFromCache)
                Positioned(
                  left: 8,
                  bottom: (widget.model.floodCount > 1) ? 26 : 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.green,
                    ),
                  ),
                ),

              if (widget.model.originalUserID.isNotEmpty)
                Positioned(
                  left: 8,
                  bottom: isVideoFromCache
                      ? ((widget.model.floodCount > 1) ? 52 : 34)
                      : ((widget.model.floodCount > 1) ? 26 : 8),
                  child: SharedPostLabel(
                    originalUserID: widget.model.originalUserID,
                    textColor: Colors.white,
                    fontSize: 12,
                  ),
                ),

              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    agendaController.isMuted.toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Obx(() => Icon(
                          agendaController.isMuted.value
                              ? CupertinoIcons.volume_off
                              : CupertinoIcons.volume_up,
                          color: Colors.white,
                          size: 16,
                        )),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: headerUserInfoWhite(),
              ),
            ],
          ),
        ),
        // Alt-sol: yeniden paylaşıldı etiketi (video)
        if (widget.isReshared)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/reshare.webp",
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  ReshareAttribution(
                    controller: controller,
                    model: widget.model,
                    explicitReshareUserId: widget.reshareUserID,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          ),
        // OriginalUserAttribution for video
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.model.floodCount > 1) Texts.colorfulFlood,
              SharedPostLabel(
                originalUserID: widget.model.originalUserID,
                // sharedAsPost removed
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            commentButton(context),
            likeButton(),
            reshareButton(),
            saveButton(),
            statButton(),
            sendButton(),
          ],
        ),
      ],
    );
  }

  Widget headerUserInfoBar() {
    final displayTime = controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final shouldHideFollow = controller.fullName.value.length +
            controller.nickname.value.length +
            displayTime.length >
        28;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                videoController?.pause();
                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            child: Obx(() => controller.pfImage.isNotEmpty
                ? CachedUserAvatar(
                    userId: widget.model.userID,
                    imageUrl: controller.pfImage.value,
                    radius: 20, // 40px diameter / 2
                  )
                : const SizedBox.shrink()),
          ),
          7.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  videoController?.pause();
                                  Get.to(() => SocialProfile(
                                      userID: widget.model.userID))?.then((v) {
                                    videoController?.play();
                                  });
                                }
                              },
                              child: Text(
                                controller.fullName.value.replaceAll("  ", " "),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          RozetContent(size: 13, userID: widget.model.userID),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '@${controller.nickname.value}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6, right: 12),
                            child: Text(
                              displayTime,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        widget.model.userID !=
                            FirebaseAuth.instance.currentUser!.uid &&
                        !shouldHideFollow)
                      Transform.translate(
                        offset: Offset(0, 5),
                        child: Obx(() => TextButton(
                              onPressed: controller.followLoading.value
                                  ? null
                                  : () {
                                      controller.followUser();
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: controller.followLoading.value
                                  ? Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.black)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.black),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Texts.followMeButtonBlack,
                            )),
                      ),
                    7.pw,
                    pulldownmenu(Colors.black),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  )
                else if ((widget.model.hasPlayableVideo ||
                        widget.model.img.isNotEmpty) &&
                    widget.model.metin.trim().isNotEmpty)
                  _buildFeedCaption(
                    text: widget.model.metin.trim(),
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget headerUserInfoWhite() {
    final displayTime = controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final shouldHideFollow = controller.fullName.value.length +
            controller.nickname.value.length +
            displayTime.length >
        28;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 11, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (widget.model.userID !=
                  FirebaseAuth.instance.currentUser!.uid) {
                videoController?.pause();
                Get.to(() => SocialProfile(userID: widget.model.userID))
                    ?.then((v) {
                  videoController?.play();
                });
              }
            },
            child: Obx(() => controller.pfImage.isNotEmpty
                ? CachedUserAvatar(
                    userId: widget.model.userID,
                    imageUrl: controller.pfImage.value,
                    radius: 20, // 40px diameter / 2
                  )
                : const SizedBox.shrink()),
          ),
          7.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  videoController?.pause();
                                  Get.to(() => SocialProfile(
                                      userID: widget.model.userID))?.then((v) {
                                    videoController?.play();
                                  });
                                }
                              },
                              child: Text(
                                controller.fullName.value.replaceAll("  ", " "),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          RozetContent(size: 12, userID: widget.model.userID),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '@${controller.nickname.value}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: "Montserrat",
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6, right: 12),
                            child: Text(
                              displayTime,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        !shouldHideFollow)
                      Transform.translate(
                        offset: Offset(0, 5),
                        child: Obx(() => TextButton(
                              onPressed: controller.followLoading.value
                                  ? null
                                  : () {
                                      controller.followUser();
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: controller.followLoading.value
                                  ? Container(
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          border:
                                              Border.all(color: Colors.white)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 15),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Texts.followMeButtonWhite,
                            )),
                      ),
                    7.pw,
                    pulldownmenu(Colors.white),
                  ],
                ),
                if (widget.model.konum != "")
                  Text(
                    widget.model.konum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: "Montserrat",
                    ),
                  )
                else if ((widget.model.hasPlayableVideo ||
                        widget.model.img.isNotEmpty) &&
                    widget.model.metin.trim().isNotEmpty)
                  _buildFeedCaption(
                    text: widget.model.metin.trim(),
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pulldownmenu(Color color) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () async {
            videoController?.pause();

            // Dinamik paylaşım zinciri: eğer bu post zaten bir paylaşım ise ana kaynağı koru
            String finalOriginalUserID;
            String finalOriginalPostID;

            if (widget.model.originalUserID.isNotEmpty) {
              // Bu post zaten bir paylaşım, ana kaynağı koru
              finalOriginalUserID = widget.model.originalUserID;
              finalOriginalPostID = widget.model.originalPostID;
            } else {
              // İlk kez paylaşılıyor, bu postun sahibi ana kaynak olacak
              finalOriginalUserID = widget.model.userID;
              finalOriginalPostID = widget.model.docID;
            }

            Get.to(() => PostCreator(
                  sharedVideoUrl: widget.model.playbackUrl,
                  sharedAspectRatio: widget.model.aspectRatio.toDouble(),
                  sharedThumbnail: widget.model.thumbnail,
                  originalUserID: finalOriginalUserID,
                  originalPostID: finalOriginalPostID,
                  sharedAsPost: true,
                ))?.then((_) {
              videoController?.play();
            });
          },
          title: 'Gönderi olarak yayınla',
          icon: CupertinoIcons.add_circled,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostSharers(postID: widget.model.docID))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Gönderi olarak paylaşanlar',
            icon: CupertinoIcons.person_2,
          ),
        PullDownMenuItem(
          onTap: () {
            controller.sendPost();
          },
          title: 'Gönder',
          icon: CupertinoIcons.paperplane,
        ),
        PullDownMenuItem(
          onTap: () {
            videoController?.pause();
            controller.gizle();
          },
          title: 'Gizle',
          icon: CupertinoIcons.eye_slash,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            FirebaseAuth.instance.currentUser!.uid ==
                "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2")
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => PostCreator(
                    editMode: true,
                    editPost: widget.model,
                  ))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Düzenle',
            icon: CupertinoIcons.pencil_circle,
          ),
        if (controller.canSendAdminPush)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              controller.sendAdminPushForPost().whenComplete(() {
                if (widget.shouldPlay) {
                  videoController?.play();
                }
              });
            },
            title: 'Push',
            icon: CupertinoIcons.bell,
          ),
        PullDownMenuItem(
          onTap: () async {
            final previewImage = widget.model.thumbnail.trim().isNotEmpty
                ? widget.model.thumbnail.trim()
                : (widget.model.img.isNotEmpty
                    ? widget.model.img.first.trim()
                    : null);
            final url = await ShortLinkService().getPostPublicUrl(
              postId: widget.model.docID,
              title: 'TurqApp Gönderisi',
              desc: widget.model.metin,
              imageUrl: previewImage,
            );

            await Clipboard.setData(ClipboardData(text: url));

            AppSnackbar("Kopyalandı", "Bağlantı linki panoya kopyalandı");
            print(widget.model.docID);
          },
          title: 'Linki Kopyala',
          icon: CupertinoIcons.doc_on_doc,
        ),
        PullDownMenuItem(
          onTap: () async {
            await ShareActionGuard.run(() async {
              final previewImage = widget.model.thumbnail.trim().isNotEmpty
                  ? widget.model.thumbnail.trim()
                  : (widget.model.img.isNotEmpty
                      ? widget.model.img.first.trim()
                      : null);
              final url = await ShortLinkService().getPostPublicUrl(
                postId: widget.model.docID,
                title: 'TurqApp Gönderisi',
                desc: widget.model.metin,
                imageUrl: previewImage,
              );
              await SharePlus.instance.share(ShareParams(text: url));
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            FirebaseAuth.instance.currentUser!.uid ==
                "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2")
          PullDownMenuItem(
            onTap: () {
              // 2) Videoyu durdur
              videoController?.pause();

              // 3) Alert’i göster ve kapandıktan sonra silinme durumuna göre videoyu devam ettir
              noYesAlert(
                title: "Gönderiyi Sil",
                message: "Bu gönderiyi silmek istediğinizden emin misiniz?",
                yesText: "Gönderiyi Sil",
                cancelText: "Vazgeç",
                onYesPressed: () {
                  controller.sil();
                },
              ).then((_) {
                // Eğer silinmediyse videoyu tekrar başlat
                if (!controller.silindi.value) {
                  videoController?.play();
                }
              });
            },
            title: 'Sil',
            icon: CupertinoIcons.trash,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == false &&
            (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
                FirebaseAuth.instance.currentUser!.uid ==
                    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2"))
          PullDownMenuItem(
            onTap: () {
              controller.arsivle();
              videoController?.pause();
            },
            title: "Arşivle",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (controller.arsiv.value == false &&
            controller.model.arsiv == true &&
            (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
                FirebaseAuth.instance.currentUser!.uid ==
                    "jp4ZnrD0CpX7VYkDNTGHeZvgwYA2"))
          PullDownMenuItem(
            onTap: () {
              controller.arsivdenCikart();
              videoController?.play();
            },
            title: "Arşivden Çıkart",
            icon: CupertinoIcons.doc_text_viewfinder,
            isDestructive: true,
          ),
        if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid)
          PullDownMenuItem(
            onTap: () {
              videoController?.pause();
              Get.to(() => ReportUser(
                  userID: widget.model.userID,
                  postID: widget.model.docID,
                  commentID: ""))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Şikayet Et',
            icon: CupertinoIcons.info,
            isDestructive: true,
          ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.6,
        alignment: Alignment.center,
        minimumSize: Size(0, 0),
        child: Icon(Icons.more_vert, color: color, size: 22),
      ),
    );
  }

  Widget reshareButton() {
    return Obx(() {
      final int visibility = widget.model.paylasimVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final bool canReshare = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final bool isReshared = controller.yenidenPaylasildiMi.value;
      final Color displayColor = isReshared ? Colors.green : _actionColor;

      return AnimatedActionButton(
        enabled: canReshare,
        semanticsLabel: 'Yeniden paylaş',
        onTap: canReshare ? controller.reshare : null,
        child: _iconAction(
          icon: _actionStyle.reshareIcon ?? Icons.repeat,
          iconSize: _actionStyle.iconSize,
          color: displayColor,
          label: NumberFormatter.format(controller.retryCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget commentButton(BuildContext context) {
    return Obx(() {
      final int visibility = widget.model.yorumVisibility;
      final bool isOwner = controller.userService.userId == widget.model.userID;
      final bool canInteract = isOwner ||
          visibility == 0 ||
          (visibility == 1 && controller.userService.isVerified) ||
          (visibility == 2 && controller.isFollowing.value);
      final Color displayColor = _actionColor;

      return AnimatedActionButton(
        enabled: canInteract,
        semanticsLabel: 'Yorumlar',
        onTap: canInteract
            ? () {
                videoController?.pause();
                controller.showPostCommentsBottomSheet(
                  onClosed: () => videoController?.play(),
                );
              }
            : null,
        child: _iconAction(
          icon: CupertinoIcons.bubble_left,
          color: displayColor,
          label: NumberFormatter.format(controller.commentCount.value),
          labelColor: displayColor,
          iconSize: 17,
        ),
      );
    });
  }

  Widget likeButton() {
    return Obx(() {
      final bool isLiked =
          controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
      final Color displayColor = isLiked ? Colors.blueAccent : _actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Beğeniler',
        onTap: controller.like,
        onLongPress: () {
          videoController?.pause();
          Get.bottomSheet(
            Container(
              height: Get.height / 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18),
                  topLeft: Radius.circular(18),
                ),
              ),
              child: PostLikeListing(postID: widget.model.docID),
            ),
          ).then((_) {
            videoController?.play();
          });
        },
        child: _iconAction(
          icon: isLiked
              ? CupertinoIcons.hand_thumbsup_fill
              : CupertinoIcons.hand_thumbsup,
          iconSize: 17,
          color: displayColor,
          label: NumberFormatter.format(controller.likeCount.value),
          labelColor: displayColor,
          leadingTransformOffsetY: -2,
        ),
      );
    });
  }

  Widget saveButton() {
    return Obx(() {
      final bool isSaved = controller.saved.value == true;
      final Color displayColor = isSaved ? Colors.orange : _actionColor;

      return AnimatedActionButton(
        enabled: true,
        semanticsLabel: 'Kaydet',
        onTap: controller.save,
        child: _iconAction(
          icon:
              isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
          iconSize: 17,
          color: displayColor,
          label: NumberFormatter.format(controller.savedCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget statButton() {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Obx(() => SizedBox(
            height: AnimatedActionButton.actionHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: AnimatedActionButton.actionHeight,
                  child: Center(
                    child: Icon(Icons.bar_chart, color: _actionColor, size: 20),
                  ),
                ),
                2.pw,
                SizedBox(
                  height: AnimatedActionButton.actionHeight,
                  child: Center(
                    child: Text(
                      NumberFormatter.format(controller.statsCount.value),
                      style: const TextStyle(
                        color: _actionColor,
                        fontSize: 12,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
      child: SizedBox(
        width: 20,
        height: AnimatedActionButton.actionHeight,
        child: Center(
          child: Icon(
            CupertinoIcons.paperplane,
            color: _actionColor,
            size: _actionStyle.sendIconSize,
          ),
        ),
      ),
    );
  }

  Widget gonderiGizlendi(BuildContext context) {
    return PostHiddenMessage(
      onUndo: () {
        controller.gizlemeyiGeriAl();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return PostArchivedMessage(
      onUndo: () {
        controller.arsivdenCikart();
        videoController?.play();
      },
      videoController: videoController,
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return const PostDeletedMessage();
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    Color? labelColor,
    double? iconSize,
    double leadingTransformOffsetY = 0,
  }) {
    return _actionContent(
      leading: Transform.translate(
        offset: Offset(0, leadingTransformOffsetY),
        child: Icon(
          icon,
          color: color,
          size: iconSize ?? _actionStyle.iconSize,
        ),
      ),
      label: label,
      labelColor: labelColor ?? color,
    );
  }

  Widget _actionContent({
    required Widget leading,
    String? label,
    Color? labelColor,
  }) {
    return ActionButtonContent(
      leading: leading,
      label: label,
      labelStyle: _actionStyle.textStyle.copyWith(
        color: labelColor ?? _actionStyle.textStyle.color,
      ),
      gap: 2,
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
