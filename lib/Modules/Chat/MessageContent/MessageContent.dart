import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Models/MessageModel.dart';
import 'package:turqappv2/Modules/Chat/MessageContent/MessageContentController.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/PhotoShorts.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import '../../../Core/Helpers/ClickableTextContent.dart';
import '../../../Core/Helpers/ImagePreview/ImagePreview.dart';
import '../../../Core/RedirectionLink.dart';
import '../../../Core/Texts.dart';
import '../../Agenda/FloodListing/FloodListing.dart';
import '../../Explore/ExploreController.dart';
import '../../Short/SingleShortView.dart';

class MessageContent extends StatelessWidget {
  final String mainID;
  final MessageModel model;
  final bool isLastMessage;
  MessageContent(
      {super.key,
      required this.mainID,
      required this.model,
      required this.isLastMessage});
  late final MessageContentController controller;
  final explore = Get.find<ExploreController>();
  @override
  Widget build(BuildContext context) {
    controller = Get.put(MessageContentController(model: model, mainID: mainID),
        tag: model.docID);
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        mainAxisAlignment:
            model.userID == FirebaseAuth.instance.currentUser!.uid
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (model.lat != 0) locationBar(),
          if (model.imgs.isNotEmpty) imageList(),
          if (model.metin != "") messageBubble(),
          if (model.kisiAdSoyad != "") contactInfoBar(),
          Obx(() {
            return postBody();
          }),
          timeBar(),
        ],
      ),
    );
  }

  Widget messageBubble() {
    return Row(
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (model.userID == FirebaseAuth.instance.currentUser!.uid)
          SizedBox(width: 100),
        Flexible(
          child: Column(
            crossAxisAlignment:
                model.userID == FirebaseAuth.instance.currentUser!.uid
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (model.lat != 0) {
                    controller.showMapsSheet();
                  }
                },
                onDoubleTap: () {
                  controller.likeImage();
                },
                onLongPress: () {
                  if (model.userID == FirebaseAuth.instance.currentUser!.uid) {
                    controller.deleteMessage();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        model.userID == FirebaseAuth.instance.currentUser!.uid
                            ? Colors.blueAccent
                            : Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        child: Text(
                          model.metin,
                          style: TextStyle(
                            color: model.userID ==
                                    FirebaseAuth.instance.currentUser!.uid
                                ? Colors.white
                                : Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                            decoration: model.lat != 0
                                ? TextDecoration.underline
                                : TextDecoration.none, // 👈 Alt çizgi eklendi
                            decorationColor: Colors
                                .white, // 👈 Alt çizgi rengi (isteğe bağlı)
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                      if (model.begeniler
                          .contains(FirebaseAuth.instance.currentUser!.uid))
                        Transform.translate(
                          offset: Offset(10, -10),
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.1), // Gölge rengi
                                  spreadRadius: 1, // Yayılma
                                  blurRadius: 6, // Yumuşaklık
                                  offset: Offset(0, 2), // Dikey konum
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.hand_thumbsup_fill,
                              color: Colors.blueAccent,
                              size: 15,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (model.userID != FirebaseAuth.instance.currentUser!.uid)
          SizedBox(width: 100),
      ],
    );
  }

  Widget imageList() {
    return Row(
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Obx(() {
          return Column(
            crossAxisAlignment:
                model.userID == FirebaseAuth.instance.currentUser!.uid
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              if (controller.showAllImages.value == false)
                Padding(
                  padding: EdgeInsets.only(right: 0),
                  child: Stack(
                    children: [
                      if (model.imgs.length > 1)
                        Transform.translate(
                          offset: Offset(10, -0),
                          child: Transform.rotate(
                            angle: 3 *
                                3.1415926535 /
                                180, // 10 derece radiana çevrildi
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[1],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (model.imgs.length > 2)
                        Transform.translate(
                          offset: Offset(-10, 0),
                          child: Transform.rotate(
                            angle: -3 *
                                3.1415926535 /
                                180, // 10 derece radiana çevrildi
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[2],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (controller.showAllImages.value == false &&
                              model.imgs.length > 1) {
                            controller.showAllImages.value = true;
                          }
                        },
                        onLongPress: () {
                          controller.deleteMessage();
                        },
                        onDoubleTap: () {
                          controller.likeImage();
                        },
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4), // gölge yönü
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: model.imgs[0],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (model.begeniler.contains(
                                FirebaseAuth.instance.currentUser!.uid))
                              Transform.translate(
                                offset: Offset(10, -10),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.1), // Gölge rengi
                                        spreadRadius: 1, // Yayılma
                                        blurRadius: 6, // Yumuşaklık
                                        offset: Offset(0, 2), // Dikey konum
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CupertinoIcons.hand_thumbsup_fill,
                                    color: Colors.blueAccent,
                                    size: 15,
                                  ),
                                ),
                              )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              else
                Column(
                  children: List.generate(model.imgs.length, (index) {
                    final img = model.imgs[index];
                    final isLast = index == model.imgs.length - 1;
                    return Column(
                      crossAxisAlignment:
                          model.userID == FirebaseAuth.instance.currentUser!.uid
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.to(() => ImagePreview(
                                  imgs: model.imgs,
                                  startIndex: index,
                                ));
                          },
                          onLongPress: () {
                            if (model.userID ==
                                FirebaseAuth.instance.currentUser!.uid) {
                              controller.deleteSingleImage(img);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PinchZoom(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: CachedNetworkImage(
                                      imageUrl: img,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isLast)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: TextButton(
                              onPressed: () {
                                controller.showAllImages.value = false;
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 5),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Fotoğrafları gizle",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 12,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          )
                      ],
                    );
                  }),
                )
            ],
          );
        })
      ],
    );
  }

  Widget locationBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            model.userID == FirebaseAuth.instance.currentUser!.uid
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              controller.showMapsSheet();
            },
            onLongPress: () {
              controller.deleteMessage();
            },
            onDoubleTap: () {
              controller.likeImage();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: AbsorbPointer(
                      // Etkileşimi tamamen engeller
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              model.lat.toDouble(), model.long.toDouble()),
                          zoom: 14,
                        ),
                        zoomControlsEnabled:
                            false, // Sağ alt zoom butonlarını kaldırır
                        myLocationButtonEnabled:
                            false, // Sağ alt konum butonunu kaldırır
                        scrollGesturesEnabled: false, // Sürükleme kapalı
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        mapToolbarEnabled:
                            false, // Sağ üstteki rota ve benzeri araçları kaldırır
                      ),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.location_solid,
                  color: Colors.red,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget contactInfoBar() {
    return Row(
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            controller.addContact();
          },
          onLongPress: () {
            controller.deleteMessage();
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.blueAccent)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.kisiAdSoyad,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      TextButton(
                        onPressed: () {
                          controller.addContact();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // İç boşluk yok
                          minimumSize: Size(0, 0), // Minimum boyut 0
                          tapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // Tıklama alanını küçült
                        ),
                        child: Text(
                          "Rehbere Ekle",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget timeBar() {
    return Column(
      children: [
        SizedBox(height: model.imgs.length > 1 ? 10 : 7),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: model.imgs.length > 1 ? 12 : 7),
          child: Row(
            mainAxisAlignment:
                model.userID == FirebaseAuth.instance.currentUser!.uid
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              if (model.userID == FirebaseAuth.instance.currentUser!.uid)
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        if (model.isRead)
                          Transform.translate(
                            offset: Offset(7, 0),
                            child: Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.green,
                              size: 10,
                            ),
                          ),
                        Icon(
                          CupertinoIcons.checkmark,
                          color: model.isRead ? Colors.green : Colors.grey,
                          size: 10,
                        ),
                      ],
                    )),
              Text(
                timeAgoMetin(model.timeStamp),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontFamily: "Montserrat",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget postBody() {
    final post = controller.postModel.value;

    // 1️⃣ controller null veya verisi henüz yüklenmemişse boş container döndür
    if (post == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: model.userID == FirebaseAuth.instance.currentUser!.uid
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () {
            controller.deleteMessage();
          },
          child: Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst profil satırı
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (controller.postModel.value!.userID !=
                              FirebaseAuth.instance.currentUser!.uid) {
                            Get.to(() => SocialProfile(
                                userID: controller.postModel.value!.userID));
                          }
                        },
                        child: ClipOval(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CachedNetworkImage(
                              imageUrl: controller.postPfImage.value,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.postModel.value!.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  Get.to(() => SocialProfile(
                                      userID:
                                          controller.postModel.value!.userID));
                                }
                              },
                              child: Text(
                                controller.postNickname.value,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            if (post.userID.isNotEmpty)
                              RozetContent(size: 12, userID: post.userID),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Metin
                if (post.metin.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                    child: ClickableTextContent(
                      fontSize: 14,
                      text: post.metin,
                      onUrlTap: (v) async {
                        final String uniqueKey =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        await RedirectionLink()
                            .goToLink(v, uniqueKey: uniqueKey);
                      },
                      onPlainTextTap: (v) {
                        final pmodel = controller.postModel.value!;
                        if (pmodel.floodCount >= 2) {
                          Get.to(() => FloodListing(mainModel: pmodel));
                        } else if (pmodel.floodCount <= 1 &&
                            pmodel.img.isNotEmpty) {
                          Get.to(() => PhotoShorts(
                              startModel: pmodel,
                              fetchedList: explore.explorePhotos));
                        } else if (pmodel.floodCount <= 1 &&
                            pmodel.hasPlayableVideo) {
                          Get.to(() => SingleShortView(
                                startModel: pmodel,
                                startList: explore.exploreVideos..shuffle(),
                              ))?.then((_) {});
                        }
                      },
                    ),
                  ),

                // Görsel
                if (post.img.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final pmodel = controller.postModel.value!;
                      if (pmodel.floodCount >= 2) {
                        Get.to(() => FloodListing(mainModel: pmodel));
                      } else if (pmodel.floodCount <= 1) {
                        Get.to(() => PhotoShorts(
                            startModel: pmodel,
                            fetchedList: explore.explorePhotos));
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: post.aspectRatio.toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: buildImageGrid(post.img),
                            ),
                            if (post.floodCount > 1) Texts.colorfulFlood,
                          ],
                        ),
                      ),
                    ),
                  )
                // Video (thumbnail gösterimi)
                else if (post.hasPlayableVideo)
                  GestureDetector(
                    onTap: () {
                      final pmodel = controller.postModel.value!;
                      if (pmodel.floodCount >= 2) {
                        Get.to(() => FloodListing(mainModel: pmodel));
                      } else if (pmodel.floodCount <= 1) {
                        Get.to(() => SingleShortView(
                              startModel: pmodel,
                              startList: explore.exploreVideos..shuffle(),
                            ))?.then((_) {});
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withAlpha(50)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: post.thumbnail,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Container(
                                    width: 35,
                                    height: 35,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withAlpha(100),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.play_fill,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (post.floodCount > 1) Texts.colorfulFlood,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final outerRadius = BorderRadius.circular(12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: outerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageContent(images),
    );
  }

  Widget _buildImageContent(List<String> images) {
    final pmodel = controller.postModel.value!;
    switch (images.length) {
      case 1:
        return AspectRatio(
          aspectRatio: pmodel.aspectRatio.toDouble(),
          child: _buildImage(images[0], radius: BorderRadius.circular(12)),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 1,
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
              SizedBox(width: 1), // spacing
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

      case 3:
        return AspectRatio(
          aspectRatio: 1,
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
              SizedBox(
                width: 1,
              ),
              Expanded(
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
                    SizedBox(
                      height: 1,
                    ),
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

      case 4:
      default:
        return buildFourImageGrid(pmodel.img);
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
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemBuilder: (context, index) {
        final radius = _getGridRadius(index);
        return _buildImage(images[index], radius: radius);
      },
    );
  }

  Widget _buildImage(String url, {required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200], // Arka plan sabit
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const CupertinoActivityIndicator(),
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
}
