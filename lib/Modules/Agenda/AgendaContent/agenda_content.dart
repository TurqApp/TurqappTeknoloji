import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Widgets/animated_action_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/post_like_listing.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Modules/EditPost/edit_post.dart';
import 'package:turqappv2/Modules/Profile/Archives/archives_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/Social/UrlPostMaker/url_post_maker.dart';
import 'package:turqappv2/Modules/Social/PostSharers/post_sharers.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../../../Core/formatters.dart';
import '../../../Core/functions.dart';
import '../../../Core/Helpers/ImagePreview/image_preview.dart';
import '../../../Core/rozet_content.dart';
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
  final arsivController = Get.put(ArchiveController());
  final videoStateManager = VideoStateManager.instance;

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
    // Gizli, arşivli veya silindi ise videoyu durdur
    if (controller.gizlendi.value ||
        controller.arsiv.value ||
        controller.silindi.value) {
      videoController?.pause();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerUserInfoBar(),
        // Metin varsa göster
        if (widget.model.metin.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 8),
            child: ClickableTextContent(
              startWith7line: true,
              showEllipsisOverlay: true,
              fontSize: 14,
              interactiveColor: Colors.blue,
              text: widget.model.metin.trim(),
              onHashtagTap: (tag) {
                videoController?.pause();
                Get.to(() => TagPosts(tag: tag))?.then((_) {
                  if (mounted) {
                    setState(() {
                      videoController?.play();
                    });
                  }
                });
              },
              onUrlTap: (v) async {
                videoController?.pause();
                final uniqueKey =
                    DateTime.now().millisecondsSinceEpoch.toString();
                await RedirectionLink().goToLink(v, uniqueKey: uniqueKey);
                videoController?.play();
              },
              onPlainTextTap: (_) async {
                if (widget.isPreview) {
                  videoController?.pause();
                  await Get.to(() =>
                      ImagePreview(imgs: widget.model.img, startIndex: 0));
                  videoController?.play();
                } else {
                  if (widget.model.floodCount > 1) {
                    videoController?.pause();
                    Get.to(() => FloodListing(mainModel: widget.model));
                    await videoController?.play();
                  } else {
                    videoController?.pause();
                    await Get.to(() =>
                        ImagePreview(imgs: widget.model.img, startIndex: 0));
                    videoController?.play();
                  }
                }
              },
              onMentionTap: (mention) {
                FirebaseFirestore.instance
                    .collection("users")
                    .where("nickname", isEqualTo: mention)
                    .get()
                    .then((snap) async {
                  agendaController.centeredIndex.value = -1;
                  agendaController.pauseAll.value = true;
                  if (snap.docs.isEmpty) {
                    AppSnackbar(
                        'Bulunamadı', '@$mention için kullanıcı bulunamadı');
                    agendaController.pauseAll.value = false;
                    return;
                  }
                  final doc = snap.docs.first;
                  final currentId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentId != null && doc.id != currentId) {
                    videoController?.pause();
                    await Get.to(() => SocialProfile(userID: doc.id));
                    videoController?.play();
                  } else {
                    agendaController.pauseAll.value = false;
                  }
                });
              },
            ),
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(width: 45),
                Expanded(
                  child: Builder(builder: (_) {
                    // Video oynatım frame'i sabit: içerik frame'e zoom/crop ile oturur.
                    const double displayAspect = 0.80;
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: displayAspect,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Thumbnail arka plan (video yüklenene kadar görünür)
                            if (widget.model.thumbnail.isNotEmpty)
                              Positioned.fill(
                                child: Image.network(
                                  widget.model.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: const Color(0xFFE8E8E8)),
                                ),
                              )
                            else
                              Container(color: const Color(0xFFE8E8E8)),
                            // Video
                            SizedBox.expand(
                              child: GestureDetector(
                                onTap: () async {
                                  if (widget.isPreview) {
                                    final currentPos =
                                        await _resolveCurrentVideoPosition();

                                    final listForFullscreen =
                                        await _buildFullscreenStartList();

                                    // Tam ekrana geçerken centeredIndex'i temizle
                                    agendaController.centeredIndex.value = -1;
                                    setState(() {});

                                    final res =
                                        await Get.to(() => SingleShortView(
                                              startModel: widget.model,
                                              startList: listForFullscreen,
                                              initialPosition: currentPos,
                                              injectedController:
                                                  videoController,
                                            ));

                                    if (!mounted) return;
                                    setState(() {});

                                    // Geri dönünce centeredIndex'i geri yükle
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
                                    if (vc != null && vc.value.isInitialized) {
                                      if (res is Map &&
                                          res['docID'] == widget.model.docID) {
                                        final int? ms =
                                            res['positionMs'] as int?;
                                        if (ms != null) {
                                          await vc.seekTo(
                                              Duration(milliseconds: ms));
                                          if (widget.shouldPlay) {
                                            vc.play();
                                            vc.setVolume(
                                                agendaController.isMuted.value
                                                    ? 0
                                                    : 1);
                                          }
                                          return;
                                        }
                                      }
                                      // Geri dönüşte oynat
                                      if (widget.shouldPlay) {
                                        tryAutoPlayWhenBuffered();
                                      }
                                    }
                                  } else {
                                    if (controller.model.floodCount > 1) {
                                      videoController?.pause();
                                      await Get.to(() => FloodListing(
                                          mainModel: widget.model));
                                      if (widget.shouldPlay)
                                        videoController?.play();
                                    } else {
                                      final currentPos =
                                          await _resolveCurrentVideoPosition();
                                      final listForFullscreen =
                                          await _buildFullscreenStartList();

                                      // Tam ekrana geçerken centeredIndex'i temizle
                                      agendaController.centeredIndex.value = -1;
                                      setState(() {});

                                      final res =
                                          await Get.to(() => SingleShortView(
                                                startModel: widget.model,
                                                startList: listForFullscreen,
                                                initialPosition: currentPos,
                                                injectedController:
                                                    videoController,
                                              ));

                                      if (!mounted) return;
                                      setState(() {});

                                      // Geri dönünce centeredIndex'i geri yükle
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
                                              vc.setVolume(
                                                  agendaController.isMuted.value
                                                      ? 0
                                                      : 1);
                                            }
                                            return;
                                          }
                                        }
                                        // Geri dönüşte oynat
                                        if (widget.shouldPlay) {
                                          tryAutoPlayWhenBuffered();
                                        }
                                      }
                                    }
                                  }
                                },
                                child: Builder(builder: (_) {
                                  if (videoController == null) {
                                    final thumb = widget.model.thumbnail;
                                    if (thumb.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Image.network(
                                      thumb,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const SizedBox.shrink();
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    );
                                  }
                                  return videoController!.buildPlayer(
                                    key: ValueKey(
                                        'agenda-${widget.model.docID}-${videoController.hashCode}'),
                                    aspectRatio: displayAspect,
                                    useAspectRatio: false,
                                  );
                                }),
                              ),
                            ),
                            // Süre göstergesi + Replay butonu — sadece video state değiştiğinde rebuild
                            if (videoController != null)
                              ValueListenableBuilder<HLSVideoValue>(
                                valueListenable: videoValueNotifier,
                                builder: (_, v, __) {
                                  if (!v.isInitialized)
                                    return const SizedBox.shrink();
                                  final remaining = v.duration - v.position;
                                  final safeRemaining = remaining.isNegative
                                      ? Duration.zero
                                      : remaining;
                                  final isEnded = remaining.inMilliseconds <= 0;
                                  return Stack(
                                    children: [
                                      // Süre göstergesi
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
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
                                      // Replay butonu
                                      if (isEnded)
                                        Positioned.fill(
                                          child: Center(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                iconSize: 48,
                                                color: Colors.white,
                                                onPressed: () {
                                                  videoController!
                                                    ..seekTo(Duration.zero)
                                                    ..play();
                                                },
                                                icon: const Icon(
                                                    AppIcons.playFilled,
                                                    color: Colors.white,
                                                    size: 32),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            // Tamamlandı butonu
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
                                        ?.then((_) => videoController?.play());
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
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Kes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Ses butonu
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: agendaController.isMuted.toggle,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Obx(() {
                                    return Icon(
                                      agendaController.isMuted.value
                                          ? CupertinoIcons.volume_off
                                          : CupertinoIcons.volume_up,
                                      color: Colors.white,
                                      size: 20,
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

        // Resimler
        if (widget.model.img.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 45),
            child: buildImageGrid(widget.model.img),
          ),

        // Gönderi olarak paylaş etiketi (butonların üstünde)
        // Eğer yeniden paylaşım ise orijinal kullanıcı bilgisini göster
        if (widget.model.originalUserID.isNotEmpty)
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
        Obx(() {
          // Çıkış esnasında currentUser null olabilir; güvenli koruma
          final me = FirebaseAuth.instance.currentUser;
          if (me == null) return const SizedBox.shrink();
          return Transform.translate(
            offset: const Offset(17, 0),
            child: SizedBox(
              width: double.infinity,
              child: Row(
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
            ),
          );
        }),
      ],
    );
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
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.model.userID != FirebaseAuth.instance.currentUser!.uid) {
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
                  radius: 19,
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
                              controller.fullName.value.replaceAll("  ", " "),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ),
                        RozetContent(size: 13, userID: widget.model.userID),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 12),
                          child: Text(
                            controller.editTime.value != 0
                                ? "${timeAgoMetin(controller.editTime.value)} düzenlendi"
                                : timeAgoMetin(
                                    widget.model.izBirakYayinTarihi != 0
                                        ? widget.model.izBirakYayinTarihi
                                        : widget.model.timeStamp),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
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
                      controller.pfImage.value != "")
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
                                      border: Border.all(color: Colors.black)),
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
              Text(
                "@${controller.nickname.value}",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "Montserrat",
                ),
              ),
            ],
          ),
        ),
      ],
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
        return AspectRatio(
          aspectRatio: widget.model.aspectRatio.toDouble(),
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
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildImage(images[index], radius: radius);
      },
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

            Get.to(() => UrlPostMaker(
                  video: widget.model.playbackUrl,
                  aspectRatio: widget.model.aspectRatio.toDouble(),
                  imgs: widget.model.img,
                  thumbnail: widget.model.thumbnail,
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
              Get.to(() => EditPost(post: widget.model))?.then((_) {
                videoController?.play();
              });
            },
            title: 'Düzenle',
            icon: CupertinoIcons.pencil_circle,
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
          icon: CupertinoIcons.share,
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
        child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
      ),
    );
  }

  Widget commentButton(BuildContext context) {
    final bool canInteract = widget.model.yorum;
    final Color displayColor = canInteract ? Colors.black : Colors.grey;

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
      ),
    );
  }

  Widget likeButton() {
    final bool isLiked =
        controller.likes.contains(FirebaseAuth.instance.currentUser!.uid);
    final Color likeColor = isLiked ? Colors.blueAccent : Colors.black;

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
      ),
    );
  }

  Widget reshareButton() {
    final bool canReshare = widget.model.paylasGizliligi != 2;
    final bool isReshared = controller.yenidenPaylasildiMi.value;
    final Color displayColor =
        canReshare ? (isReshared ? Colors.green : Colors.black) : Colors.grey;

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
  }

  Widget saveButton() {
    final bool isSaved = controller.saved.value == true;
    final Color displayColor = isSaved ? Colors.orange : Colors.black;

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
      ),
    );
  }

  Widget statButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bar_chart,
          color: Colors.black,
          size: 20,
        ),
        2.pw,
        Text(
          NumberFormatter.format(controller.statsCount.value),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontFamily: "MontserratMedium",
          ),
        ),
      ],
    );
  }

  Widget sendButton() {
    return AnimatedActionButton(
      enabled: true,
      semanticsLabel: 'Paylaş',
      onTap: controller.sendPost,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      showTapArea: _showActionTapAreas,
      child: Icon(
        CupertinoIcons.paperplane,
        color: Colors.black,
        size: _actionStyle.sendIconSize,
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    Color? labelColor,
    double? iconSize,
  }) {
    return _actionContent(
      leading:
          Icon(icon, color: color, size: iconSize ?? _actionStyle.iconSize),
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
