import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/ring_upload_progress_indicator.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/rozet_content.dart';
import '../../../Core/Services/upload_queue_service.dart';
import '../../../Core/texts.dart';
import '../../SocialProfile/social_profile.dart';
import '../Common/post_content_base.dart';
import '../Common/post_content_controller.dart';
import '../Common/reshare_attribution.dart';
import '../Common/post_action_style.dart';
import 'agenda_content_controller.dart';

class AgendaContent extends PostContentBase {
  const AgendaContent({
    super.key,
    required super.model,
    required super.isPreview,
    required super.shouldPlay,
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
  final arsivController = Get.put(ArchiveController());
  bool _isFullscreen = false;
  bool _pauseQueuedAfterBuild = false;
  bool _isCaptionExpanded = false;

  void _pauseFeedBeforeFullscreen() {
    try {
      videoController?.pause();
    } catch (_) {}
    try {
      videoStateManager.pauseAllVideos();
    } catch (_) {}
  }

  void _prepareVideoFullscreenTransition() {
    // Geçişte aynı controller'ı fullscreen'e enjekte edeceğiz.
    // Pause çağırmayıp yalnızca feed tarafındaki bir kerelik auto-pause'u atlat.
    markSkipNextPause();
  }

  Future<Duration> _resolveCurrentVideoPosition() async {
    final vc = videoController;
    if (vc != null) {
      try {
        final pos = vc.value.position;
        if (pos > Duration.zero) return pos;
      } catch (_) {}

      try {
        final seconds = await vc.hlsController.getCurrentTime();
        if (seconds > 0) {
          return Duration(milliseconds: (seconds * 1000).round());
        }
      } catch (_) {}
    }

    final savedState = videoStateManager.getVideoState(widget.model.docID);
    return savedState?.position ?? Duration.zero;
  }

  Future<List<PostsModel>> _buildFullscreenStartList() async {
    final candidates = agendaController.agendaList
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    if (candidates.isEmpty) {
      return [widget.model];
    }

    final ids = candidates.map((p) => p.docID).toSet().toList();
    final freshById = <String, PostsModel>{};

    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await FirebaseFirestore.instance
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final model = PostsModel.fromMap(doc.data(), doc.id);
        if (model.deletedPost == false &&
            model.arsiv == false &&
            model.gizlendi == false &&
            model.hasPlayableVideo) {
          freshById[doc.id] = model;
        }
      }
    }

    final refreshed = candidates
        .map((p) => freshById[p.docID] ?? p)
        .where((p) =>
            p.deletedPost == false &&
            p.arsiv == false &&
            p.gizlendi == false &&
            p.hasPlayableVideo)
        .toList();

    final tapped = freshById[widget.model.docID] ?? widget.model;
    final rest = refreshed.where((p) => p.docID != tapped.docID).toList()
      ..shuffle();

    return [tapped, ...rest];
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
    // Build sırasında doğrudan pause() çağırmak Obx'i yeniden kirletebilir.
    // Bu yüzden pause işlemini frame sonuna erteliyoruz.
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value) {
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

  Widget mainbody() {
    final hasHeaderSubline =
        widget.model.konum != "" || widget.model.metin.trim().isNotEmpty;
    final mediaTopSpacing = hasHeaderSubline ? 4.0 : 0.0;
    final actionTopSpacing = hasHeaderSubline ? 2.0 : 0.0;
    final mediaVisualLift = hasHeaderSubline ? 0.0 : -6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        if (!widget.model.hasPlayableVideo && widget.model.img.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 45),
            child: buildPollCard(),
          ),

        // Konum varsa göster
        if (widget.model.konum != "")
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 40),
            child: Row(
              children: [
                Icon(CupertinoIcons.map_pin, color: Colors.red, size: 20),
                SizedBox(width: 3),
                Text(
                  widget.model.konum,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: "MontserratMedium"),
                )
              ],
            ),
          ),

        // Video varsa göster
        if (widget.model.hasPlayableVideo)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing),
              child: Row(
                children: [
                  const SizedBox(width: 45),
                  Expanded(
                    child: Builder(builder: (_) {
                      const double displayAspect = 0.80;
                      return VisibilityDetector(
                        key: Key('agenda-media-${widget.model.docID}'),
                        onVisibilityChanged: (info) {
                          reportMediaVisibility(info.visibleFraction);
                        },
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: displayAspect,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SizedBox.expand(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (widget.isPreview) {
                                        final currentPos =
                                            await _resolveCurrentVideoPosition();
                                        final listForFullscreen =
                                            await _buildFullscreenStartList();

                                        _prepareVideoFullscreenTransition();
                                        _pauseFeedBeforeFullscreen();
                                        setPauseBlocked(true);
                                        if (mounted) {
                                          setState(() => _isFullscreen = true);
                                        }
                                        final res =
                                            await Get.to(() => SingleShortView(
                                                  startModel: widget.model,
                                                  startList: listForFullscreen,
                                                  initialPosition: currentPos,
                                                  injectedController:
                                                      videoController,
                                                ));
                                        setPauseBlocked(false);
                                        if (mounted) {
                                          setState(() => _isFullscreen = false);
                                        }

                                        if (!mounted) return;

                                        final modelIndex = agendaController
                                            .agendaList
                                            .indexWhere((p) =>
                                                p.docID == widget.model.docID);
                                        if (modelIndex >= 0) {
                                          agendaController.centeredIndex.value =
                                              modelIndex;
                                          agendaController.lastCenteredIndex =
                                              modelIndex;
                                        }

                                        final vc = videoController;
                                        if (vc != null &&
                                            vc.value.isInitialized) {
                                          if (res is Map &&
                                              res['docID'] ==
                                                  widget.model.docID) {
                                            final int? ms =
                                                res['positionMs'] as int?;
                                            if (ms != null) {
                                              await vc.seekTo(
                                                  Duration(milliseconds: ms));
                                              if (widget.shouldPlay) {
                                                vc.play();
                                                vc.setVolume(agendaController
                                                        .isMuted.value
                                                    ? 0
                                                    : 1);
                                              }
                                              return;
                                            }
                                          }
                                          if (widget.shouldPlay) {
                                            tryAutoPlayWhenBuffered();
                                          }
                                        }
                                      } else {
                                        if (controller.model.floodCount > 1) {
                                          videoController?.pause();
                                          await Get.to(() => FloodListing(
                                              mainModel: widget.model));
                                          if (widget.shouldPlay) {
                                            videoController?.play();
                                          }
                                        } else {
                                          final currentPos =
                                              await _resolveCurrentVideoPosition();
                                          final listForFullscreen =
                                              await _buildFullscreenStartList();

                                          _prepareVideoFullscreenTransition();
                                          _pauseFeedBeforeFullscreen();
                                          setPauseBlocked(true);
                                          if (mounted) {
                                            setState(
                                                () => _isFullscreen = true);
                                          }
                                          final res = await Get.to(() =>
                                              SingleShortView(
                                                startModel: widget.model,
                                                startList: listForFullscreen,
                                                initialPosition: currentPos,
                                                injectedController:
                                                    videoController,
                                              ));
                                          setPauseBlocked(false);
                                          if (mounted) {
                                            setState(
                                                () => _isFullscreen = false);
                                          }

                                          if (!mounted) return;

                                          final modelIndex = agendaController
                                              .agendaList
                                              .indexWhere((p) =>
                                                  p.docID ==
                                                  widget.model.docID);
                                          if (modelIndex >= 0) {
                                            agendaController.centeredIndex
                                                .value = modelIndex;
                                            agendaController.lastCenteredIndex =
                                                modelIndex;
                                          }

                                          final vc = videoController;
                                          if (vc != null &&
                                              vc.value.isInitialized) {
                                            if (res is Map &&
                                                res['docID'] ==
                                                    widget.model.docID) {
                                              final int? ms =
                                                  res['positionMs'] as int?;
                                              if (ms != null) {
                                                await vc.seekTo(
                                                    Duration(milliseconds: ms));
                                                if (widget.shouldPlay) {
                                                  vc.play();
                                                  vc.setVolume(agendaController
                                                          .isMuted.value
                                                      ? 0
                                                      : 1);
                                                }
                                                return;
                                              }
                                            }
                                            if (widget.shouldPlay) {
                                              tryAutoPlayWhenBuffered();
                                            }
                                          }
                                        }
                                      }
                                    },
                                    child: Builder(builder: (_) {
                                      final thumb = widget.model.thumbnail;
                                      if (videoController == null) {
                                        if (thumb.isEmpty) {
                                          return Container(
                                              color: const Color(0xFFE8E8E8));
                                        }
                                        return Image.network(
                                          thumb,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                                color: const Color(0xFFE8E8E8));
                                          },
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              Container(
                                                  color:
                                                      const Color(0xFFE8E8E8)),
                                        );
                                      }
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _isFullscreen
                                              ? const SizedBox.shrink()
                                              : videoController!.buildPlayer(
                                                  key: ValueKey(
                                                      'agenda-${widget.model.docID}-${videoController.hashCode}'),
                                                  aspectRatio: displayAspect,
                                                  useAspectRatio: false,
                                                ),
                                          ValueListenableBuilder<HLSVideoValue>(
                                            valueListenable: videoValueNotifier,
                                            builder: (_, v, child) {
                                              if (v.isInitialized &&
                                                  v.position > Duration.zero) {
                                                return const SizedBox.shrink();
                                              }
                                              return child!;
                                            },
                                            child: thumb.isNotEmpty
                                                ? Image.network(
                                                    thumb,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      color: const Color(
                                                          0xFFE8E8E8),
                                                    ),
                                                  )
                                                : Container(
                                                    color:
                                                        const Color(0xFFE8E8E8),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: buildUploadIndicator(),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                if (videoController != null)
                                  ValueListenableBuilder<HLSVideoValue>(
                                    valueListenable: videoValueNotifier,
                                    builder: (_, v, __) {
                                      if (!v.isInitialized) {
                                        return const SizedBox.shrink();
                                      }
                                      final remaining = v.duration - v.position;
                                      final safeRemaining = remaining.isNegative
                                          ? Duration.zero
                                          : remaining;
                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                if (widget.model.flood == false &&
                                    widget.model.floodCount > 1)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        videoController?.pause();
                                        Get.to(() => FloodListing(
                                                mainModel: widget.model))
                                            ?.then(
                                                (_) => videoController?.play());
                                      },
                                      child: Texts.colorfulFloodLeftSide,
                                    ),
                                  ),
                                if (isVideoFromCache)
                                  Positioned(
                                    left: 8,
                                    bottom: (widget.model.flood == false &&
                                            widget.model.floodCount > 1)
                                        ? 26
                                        : 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
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
                                        ? ((widget.model.flood == false &&
                                                widget.model.floodCount > 1)
                                            ? 52
                                            : 34)
                                        : ((widget.model.flood == false &&
                                                widget.model.floodCount > 1)
                                            ? 26
                                            : 8),
                                    child: SharedPostLabel(
                                      originalUserID:
                                          widget.model.originalUserID,
                                      textColor: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: agendaController.isMuted.toggle,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Obx(() {
                                        return Icon(
                                          agendaController.isMuted.value
                                              ? CupertinoIcons.volume_off
                                              : CupertinoIcons.volume_up,
                                          color: Colors.white,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

        // Resimler
        if (widget.model.img.isNotEmpty)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing, left: 45),
              child: buildImageGrid(widget.model.img),
            ),
          ),
        if (widget.model.hasPlayableVideo || widget.model.img.isNotEmpty)
          Transform.translate(
            offset: Offset(0, mediaVisualLift),
            child: Padding(
              padding: EdgeInsets.only(top: mediaTopSpacing, left: 45),
              child: buildPollCard(),
            ),
          ),

        // Gönderi olarak paylaş etiketi (butonların üstünde)
        // Eğer yeniden paylaşım ise orijinal kullanıcı bilgisini göster
        if (widget.model.originalUserID.isNotEmpty &&
            !widget.model.hasPlayableVideo)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 45, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: SharedPostLabel(
                    originalUserID: widget.model.originalUserID,
                    fontSize: 12,
                    textColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

        // Yeniden paylaşıldı etiketi (alt-sol)
        if (widget.isReshared)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 45, right: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 18,
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
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Alt butonlar
        Padding(
          padding: EdgeInsets.only(top: actionTopSpacing),
          child: Obx(() {
            final me = FirebaseAuth.instance.currentUser;
            if (me == null) return const SizedBox.shrink();
            return Transform.translate(
              offset: const Offset(17, 0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: commentButton(context)),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: likeButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: reshareButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: statButton()),
                        )),
                    SizedBox(
                        width: 58,
                        child: Transform.translate(
                          offset: const Offset(2, 0),
                          child: Center(child: saveButton()),
                        )),
                    SizedBox(width: 58, child: Center(child: sendButton())),
                  ],
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: buildUploadIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedCaption({
    required String text,
    required Color color,
  }) {
    const baseStyle = TextStyle(
      color: Colors.black,
      fontSize: 15,
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
                    fontSize: 15,
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
                    fontSize: 15,
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

      final createdAt = (poll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (poll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      final expired = DateTime.now().millisecondsSinceEpoch > expiresAt;
      final canVote = !expired && userVote == null;
      final showResults = userVote != null || expired;

      return Container(
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

  Widget gonderiGizlendi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            12.ph,
            const Text(
              "Gönderi Gizlendi",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(
                color: Colors.grey,
              ),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
            GestureDetector(
              onTap: () {
                controller.gizlemeyiGeriAl();
                videoController?.play();
              },
              child: const Text(
                "Geri Al",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiArsivlendi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Gönderi Arşivlendi",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
            GestureDetector(
              onTap: () {
                controller.arsivdenCikart();
                videoController?.play();
              },
              child: const Text(
                "Geri Al",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget gonderiSilindi(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Colors.green,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Gönderi Sildiniz",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Divider(color: Colors.grey),
            ),
            SizedBox(
              height: 7,
            ),
            const Text(
              "Bu gönderi artık yayında değil.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black, fontSize: 12, fontFamily: "Montserrat"),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget headerUserInfoBar() {
    final primaryName = controller.fullName.value.trim().isNotEmpty
        ? controller.fullName.value.replaceAll("  ", " ")
        : controller.nickname.value.trim();
    final handle = controller.nickname.value.trim().isNotEmpty
        ? controller.nickname.value.trim()
        : controller.username.value.trim();
    final displayTime = controller.editTime.value != 0
        ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
        : timeAgoMetin(widget.model.izBirakYayinTarihi != 0
            ? widget.model.izBirakYayinTarihi
            : widget.model.timeStamp);
    final shouldHideFollow = primaryName.length +
            controller.nickname.value.length +
            displayTime.length >
        28;

    return Padding(
      padding: const EdgeInsets.only(top: 3),
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
                    radius: 20,
                  )
                : const SizedBox.shrink()),
          ),
          6.pw,
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
                                  Get.to(SocialProfile(
                                          userID: widget.model.userID))
                                      ?.then((v) {
                                    videoController?.play();
                                  });
                                }
                              },
                              child: Text(
                                primaryName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '@$handle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
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
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ),
                          RozetContent(size: 13, userID: widget.model.userID),
                        ],
                      ),
                    ),
                    if (controller.isFollowing.value == false &&
                        widget.model.userID !=
                            FirebaseAuth.instance.currentUser!.uid &&
                        controller.pfImage.value != "" &&
                        !shouldHideFollow)
                      Obx(() => TextButton(
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
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 15),
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
                    const SizedBox(width: 7),
                    pulldownmenu(),
                  ],
                ),
                if ((widget.model.hasPlayableVideo ||
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

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        GestureDetector(
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
            } else {
              if (widget.model.floodCount > 1) {
                Get.to(FloodListing(mainModel: widget.model));
              } else {
                Get.to(() => PhotoShorts(
                      fetchedList: visibleList,
                      startModel: widget.model,
                    ));
              }
            }
          },
          onDoubleTap: () {
            controller.like();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: outerRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(images),
          ),
        ),
        if (widget.model.floodCount > 1 && widget.model.flood == false)
          GestureDetector(
            onTap: () {
              Get.to(() => FloodListing(mainModel: widget.model));
            },
            child: Texts.colorfulFloodLeftSide,
          )
      ],
    );
  }

  Widget _buildImageContent(List<String> images) {
    switch (images.length) {
      case 1:
        final double modelAspect = widget.model.aspectRatio.toDouble();
        final double singleImageAspect = (modelAspect > 0 && modelAspect < 1)
            ? 0.80
            : (modelAspect > 0 ? modelAspect : 1.0);
        return AspectRatio(
          aspectRatio: singleImageAspect,
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );

      case 2:
        return _buildTwoImageGrid(images);

      case 3:
        return _buildThreeImageGrid(images);

      case 4:
      default:
        return buildFourImageGrid(widget.model.img);
    }
  }

  Widget buildFourImageGrid(List<String> images) {
    // shrinkWrap: true yerine Column kullanarak her frame'de layout hesaplamasını engelle
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[0], radius: _getGridRadius(0)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[1], radius: _getGridRadius(1)))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[2], radius: _getGridRadius(2)))),
            const SizedBox(width: 2),
            Expanded(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImage(images[3], radius: _getGridRadius(3)))),
          ],
        ),
      ],
    );
  }

  Widget _buildThreeImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size, // Kare yapı
          child: Row(
            children: [
              // Soldaki büyük görsel
              Expanded(
                flex: 1,
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Sağdaki iki küçük görsel
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildImage(
                        images[1],
                        radius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: _buildImage(
                        images[2],
                        radius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwoImageGrid(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(
                child: _buildImage(
                  images[0],
                  radius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImage(
                  images[1],
                  radius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String url, {required BorderRadius radius}) {
    final safeUrl = url.trim();
    if (safeUrl.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200], // Arka plan sabit
        child: CachedNetworkImage(
          imageUrl: safeUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  BorderRadius _getGridRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
      default:
        return BorderRadius.zero;
    }
  }

  Widget pulldownmenu() {
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
            AdminAccessService.isKnownAdminSync())
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
                desc: widget.model.metin,
                imageUrl: previewImage,
              );
              await ShareLinkService.shareUrl(
                url: url,
                title: 'TurqApp Gönderisi',
                subject: 'TurqApp Gönderisi',
              );
            });
          },
          title: 'Paylaş',
          icon: CupertinoIcons.share_up,
        ),
        if (widget.model.userID == FirebaseAuth.instance.currentUser!.uid ||
            AdminAccessService.isKnownAdminSync())
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
                AdminAccessService.isKnownAdminSync()))
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
                AdminAccessService.isKnownAdminSync()))
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
        child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
      ),
    );
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
        onTap: canInteract ? controller.showPostCommentsBottomSheet : null,
        showTapArea: _showActionTapAreas,
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
    final bool isLiked =
        controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
    final Color likeColor = isLiked ? Colors.blueAccent : _actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Beğeniler',
      onTap: controller.like,
      showTapArea: _showActionTapAreas,
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
        color: likeColor,
        label: NumberFormatter.format(controller.likeCount.value),
        labelColor: likeColor,
        iconSize: 17,
        leadingTransformOffsetY: -2,
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
        showTapArea: _showActionTapAreas,
        child: _iconAction(
          icon: Icons.repeat,
          color: displayColor,
          label: NumberFormatter.format(controller.retryCount.value),
          labelColor: displayColor,
        ),
      );
    });
  }

  Widget saveButton() {
    final bool isSaved = controller.saved.value == true;
    final Color displayColor = isSaved ? Colors.orange : _actionColor;

    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Kaydet',
      onTap: controller.save,
      showTapArea: _showActionTapAreas,
      child: _iconAction(
        icon: isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        color: displayColor,
        label: NumberFormatter.format(controller.savedCount.value),
        labelColor: displayColor,
        iconSize: 17,
      ),
    );
  }

  Widget statButton() {
    return SizedBox(
      height: AnimatedActionButton.actionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: AnimatedActionButton.actionHeight,
            child: Center(
              child: Icon(
                Icons.bar_chart,
                color: _actionColor,
                size: 20,
              ),
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
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
      showTapArea: _showActionTapAreas,
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
    );
  }

  String _formatDuration(Duration position) {
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
