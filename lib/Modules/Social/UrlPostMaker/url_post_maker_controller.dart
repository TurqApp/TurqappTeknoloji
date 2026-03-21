import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:uuid/uuid.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:flutter/material.dart';
import '../../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../../Core/LocationFinderView/location_finder_view.dart';

class UrlPostMakerController extends GetxController {
  static UrlPostMakerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      UrlPostMakerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static UrlPostMakerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<UrlPostMakerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<UrlPostMakerController>(tag: tag);
  }

  TextEditingController textEditingController = TextEditingController();
  Rx<HLSVideoAdapter?> videoPlayerController = Rx<HLSVideoAdapter?>(null);
  RxBool isPlaying = false.obs;
  RxBool yorum = true.obs;
  RxBool isSharing = false.obs;
  RxString adres = "".obs;

  // Orijinal post bilgileri
  String? originalUserID;
  String? originalPostID;

  String _resolvePostLocationCity() {
    return CurrentUserService.instance.preferredLocationCity;
  }

  Future<void> getReadyVideoPlayer(String url) async {
    final ctrl = HLSVideoAdapter(url: url, autoPlay: false, loop: false);
    // Listener ekle
    ctrl.addListener(() {
      isPlaying.value = ctrl.value.isPlaying;
    });
    videoPlayerController.value = ctrl;
    isPlaying.value = ctrl.value.isPlaying;
  }

  @override
  void onClose() {
    videoPlayerController.value?.dispose();
    textEditingController.dispose();
    super.onClose();
  }

  Future<void> setData(
    List<String> imgs,
    String video,
    String thumbnail,
    double aspectRatio, {
    String? originalUserID,
    String? originalPostID,
    bool sharedAsPost = false,
  }) async {
    // Eğer zaten paylaşım işlemi devam ediyorsa, yeni işlem başlatma
    if (isSharing.value) return;

    isSharing.value = true;

    // Orijinal kullanıcı bilgilerini kaydet
    this.originalUserID = originalUserID;
    this.originalPostID = originalPostID;
    print(
        'UrlPostMakerController setData: originalUserID = $originalUserID, originalPostID = $originalPostID');

    try {
      GlobalLoaderController.ensure().isOn.value = true;
      final uuid = Uuid().v4();
      final normalizedAR = double.parse(aspectRatio.toStringAsFixed(4));
      final imageUrls =
          imgs.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
      final imgMap = imageUrls
          .map((url) => {
                'url': url,
                'aspectRatio': normalizedAR,
              })
          .toList();

      // Eğer "Gönderi olarak paylaş" ise, dinamik original bilgileri hesapla
      String finalOriginalUserID = "";
      String finalOriginalPostID = "";

      if (sharedAsPost && originalUserID != null) {
        // Burada originalUserID aslında paylaşılan postun userID'si
        // Eğer paylaşılan post zaten bir paylaşım ise, onun original bilgilerini almalıyız
        // Bu durumda ReshareHelper kullanarak doğru mantığı uygulayalım
        print(
            'UrlPostMaker: Creating shared post - need to determine original chain');
        finalOriginalUserID = originalUserID;
        finalOriginalPostID = originalPostID ?? "";
      }

      final locationCity = _resolvePostLocationCity();

      await FirebaseFirestore.instance.collection("Posts").doc(uuid).set({
        "arsiv": false,
        if (imageUrls.isEmpty) "aspectRatio": normalizedAR,
        "debugMode": false,
        "deletedPost": false,
        "deletedPostTime": 0,
        "flood": false,
        "floodCount": 1,
        "gizlendi": false,
        "img": imageUrls,
        "imgMap": imgMap,
        "isAd": false,
        "ad": false,
        "izBirakYayinTarihi": 0,
        "konum": "",
        "locationCity": locationCity,
        "mainFlood": uuid,
        "metin": textEditingController.text,
        "reshareMap": {
          "visibility": 0,
        },
        "scheduledAt": 0,
        "sikayetEdildi": false,
        "stabilized": false,
        "stats": {
          "commentCount": 0,
          "likeCount": 0,
          "reportedCount": 0,
          "retryCount": 0,
          "savedCount": 0,
          "statsCount": 0
        },
        "tags": [],
        "thumbnail": thumbnail,
        "timeStamp": DateTime.now().millisecondsSinceEpoch,
        "userID": CurrentUserService.instance.userId,
        "video": video,
        "hlsStatus": "none",
        "hlsMasterUrl": "",
        "hlsUpdatedAt": 0,
        "yorum": yorum.value,
        "yorumMap": {
          "visibility": yorum.value ? 0 : 3,
        },

        // Dinamik original bilgileri
        "originalUserID": finalOriginalUserID,
        "originalPostID": finalOriginalPostID,
        "sharedAsPost": sharedAsPost,
      });
      unawaited(
        TypesensePostService.instance.syncPostById(uuid).catchError((_) {}),
      );
      print(
          'UrlPostMakerController: Post saved with originalUserID: $originalUserID, originalPostID: $originalPostID');

      // Eğer bu bir "Gönderi olarak paylaş" ise, orijinal gönderi sahibinin postSharers koleksiyonuna bu paylaşımı kaydet
      if (sharedAsPost && finalOriginalUserID.isNotEmpty) {
        try {
          // postSharers alt koleksiyonunu güncellemek için orijinal post ID'sini bul
          String targetPostID = finalOriginalPostID.isNotEmpty
              ? finalOriginalPostID
              : originalPostID ?? "";

          if (targetPostID.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection("Posts")
                .doc(targetPostID)
                .collection("postSharers")
                .doc(CurrentUserService.instance.userId)
                .set({
              "userID": CurrentUserService.instance.userId,
              "timestamp": DateTime.now().millisecondsSinceEpoch,
              "sharedPostID": uuid, // Paylaşılan yeni post ID'si
              "quotedPost": false,
            });
            print(
                'postSharers updated for post: $targetPostID by user: ${CurrentUserService.instance.userId}');
          }
        } catch (e) {
          print('Error updating postSharers: $e');
          // Hata durumunda ana işlemi etkilemesin
        }
      }

      // Yeni oluşturulan postu AgendaController'a ekle
      final newPost = PostsModel(
        arsiv: false,
        aspectRatio: normalizedAR,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        docID: uuid,
        editTime: null,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: imageUrls,
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 0,
        stats: PostStats(),
        konum: "",
        locationCity: locationCity,
        mainFlood: uuid,
        metin: textEditingController.text,
        paylasGizliligi: 0,
        reshareMap: const {
          "visibility": 0,
        },
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        tags: const [],
        thumbnail: thumbnail,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
        userID: CurrentUserService.instance.userId,
        video: video,
        hlsStatus: 'none',
        hlsMasterUrl: '',
        hlsUpdatedAt: 0,
        yorum: yorum.value,
        yorumMap: {
          "visibility": yorum.value ? 0 : 3,
        },
        originalUserID: finalOriginalUserID,
        originalPostID: finalOriginalPostID,
      );

      final agendaController = AgendaController.maybeFind();
      if (agendaController != null) {
        agendaController.addUploadedPostsAtTop([newPost]);

        if (agendaController.scrollController.hasClients) {
          agendaController.scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }

      ProfileController.maybeFind()?.getLastPostAndAddToAllPosts();
      GlobalLoaderController.ensure().isOn.value = false;
      isSharing.value = false;
      Get.back();
    } catch (e) {
      GlobalLoaderController.ensure().isOn.value = false;
      isSharing.value = false;
      print('UrlPostMaker setData error: $e');
      // Hata durumunda kullanıcıya bilgi verilebilir
    }
  }

  Future<void> goToLocationMap() async {
    Get.to(() => LocationFinderView(
          submitButtonTitle: "Bu adresi kullan",
          backAdres: (v) {
            adres.value = v;
          },
          backLatLong: (_) {},
        ));
  }

  Future<void> showCommentOptions() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                  SizedBox(width: 12),
                  Text(
                    "comments.title".tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = true;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Herkes yorum yapabilir.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  yorum.value = false;
                },
                child: Container(
                  color: Colors.white.withAlpha(1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "post.comments_disabled_none".tr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !yorum.value
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }
}
