import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/Services/ConversationId.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Chat/Chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/ChatListingController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/TutoringDetailController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/SavedTutoringsController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringController.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/CreateTutoringView.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String? getCurrentUserId() {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId?.isNotEmpty == true) {
      return userId;
    } else {
      print("User ID is empty, possibly not loaded yet");
      return null;
    }
  } catch (e) {
    print("Error getting userID: $e");
    return null;
  }
}

class TutoringDetail extends StatelessWidget {
  TutoringDetail({super.key});

  final chatListingController = Get.put(ChatListingController());

  @override
  Widget build(BuildContext context) {
    final TutoringDetailController controller = Get.put(
      TutoringDetailController(),
    );
    final SavedTutoringsController savedController =
        Get.find<SavedTutoringsController>();
    final TutoringController tutoringController =
        Get.find<TutoringController>();
    final String? currentUserId = getCurrentUserId();

    Future<void> deleteTutoring(String docId) async {
      try {
        await FirebaseFirestore.instance
            .collection('OzelDersVerenler')
            .doc(docId)
            .delete();
        Get.back(); // Ekranı kapat
        AppSnackbar("Başarılı", "İlan silindi!");
      } catch (e) {
        AppSnackbar("Hata", "İlan silinirken bir hata oluştu.");
        log("Error deleting tutoring: $e");
      }
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CupertinoActivityIndicator());
          } else {
            final tutoring = controller.tutoring.value;
            var isSaved = false.obs;
            isSaved.value = savedController.savedTutoringIds.contains(
              tutoring.docID,
            );

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BackButtons(text: "Özel Ders"),
                    Obx(() {
                      final isSaved = savedController.savedTutoringIds.contains(
                        controller.tutoring.value.docID,
                      );
                      return IconButton(
                        onPressed: () async {
                          if (currentUserId != null) {
                            if (isSaved) {
                              savedController.removeSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            } else {
                              savedController.addSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            }
                            await tutoringController.toggleFavorite(
                              controller.tutoring.value.docID,
                              currentUserId,
                              isSaved,
                            );
                            if (isSaved) {
                              savedController.removeSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            } else if (!controller.tutoring.value.favorites
                                .contains(currentUserId)) {
                              savedController.addSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            }
                          } else {
                            log("User ID not found");
                          }
                        },
                        icon: Icon(
                          isSaved ? AppIcons.saved : AppIcons.save,
                          color: isSaved ? Colors.orange : null,
                        ),
                      );
                    }),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.tutoring.value.imgs != null &&
                            controller.tutoring.value.imgs!.isNotEmpty)
                          Column(
                            children: [
                              SizedBox(
                                width: Get.width,
                                child: CarouselSlider(
                                  options: CarouselOptions(
                                    enlargeCenterPage: false,
                                    autoPlay: false,
                                    enableInfiniteScroll: false,
                                    viewportFraction: 1.0,
                                    aspectRatio: 1.0,
                                    onPageChanged: (index, reason) {
                                      controller.carouselCurrentIndex.value =
                                          index;
                                    },
                                  ),
                                  items: controller.tutoring.value.imgs!.map((
                                    imgUrl,
                                  ) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return SizedBox(
                                          width: Get.width,
                                          child: AspectRatio(
                                            aspectRatio: 1.0,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.zero,
                                              child: CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                placeholder: (context, url) =>
                                                    CupertinoActivityIndicator(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(
                                                  CupertinoIcons.photo,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Nokta klavuzunu manuel olarak ekleme
                              Container(
                                margin: EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    controller.tutoring.value.imgs!.length,
                                    (index) {
                                      return Container(
                                        width: 8.0,
                                        height: 8.0,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: controller.carouselCurrentIndex
                                                      .value ==
                                                  index
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.tutoring.value.baslik,
                                style: TextStyles.bold16Black,
                              ),
                              appDivider(),
                              Row(
                                children: [
                                  Text(
                                    "${controller.users[controller.tutoring.value.userID]?['firstName'] ?? ''} ${controller.users[controller.tutoring.value.userID]?['lastName'] ?? ''}",
                                    style: TextStyles.bold16Black,
                                  ),
                                  RozetContent(
                                    size: 14,
                                    userID: controller.tutoring.value.userID
                                        .toString(),
                                  ),
                                ],
                              ),
                              appDivider(),
                              Text(
                                controller.tutoring.value.brans,
                                style: TextStyles.tutoringBranch,
                              ),
                              appDivider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.location_solid,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      2.pw,
                                      Text(
                                        "${controller.tutoring.value.sehir}/${controller.tutoring.value.ilce}",
                                        style: TextStyles.tutoringLocation,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${controller.tutoring.value.fiyat} ₺",
                                    style: TextStyles.bold16Black,
                                  ),
                                ],
                              ),
                              appDivider(),
                              Text(
                                controller.tutoring.value.aciklama,
                                style: TextStyles.medium15Black,
                              ),
                              16.ph,
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blueAccent, width: 1)),
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentUserId !=
                                        controller.tutoring.value.userID) {
                                      Get.to(() => SocialProfile(
                                          userID: tutoring.userID));
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      ClipOval(
                                        child: SizedBox(
                                          width: 35,
                                          height: 35,
                                          child: CachedNetworkImage(
                                            imageUrl: controller.users[
                                                controller.tutoring.value
                                                    .userID]?["pfImage"],
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CupertinoActivityIndicator(),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) => Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      8.pw,
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "${controller.users[controller.tutoring.value.userID]?['firstName'] ?? ''} ${controller.users[controller.tutoring.value.userID]?['lastName'] ?? ''}",
                                                style: TextStyles.bold16Black,
                                              ),
                                              RozetContent(
                                                size: 14,
                                                userID: controller
                                                    .tutoring.value.userID
                                                    .toString(),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "@${controller.users[controller.tutoring.value.userID]?['nickname'] ?? ''} ",
                                            style: TextStyles.tutoringBranch,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              16.ph,
                              Row(
                                children: [
                                  if (currentUserId != null &&
                                      currentUserId ==
                                          controller.tutoring.value.userID)
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Get.to(
                                            () => CreateTutoringView(),
                                            arguments:
                                                controller.tutoring.value,
                                          );
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.black,
                                          ),
                                          child: Text(
                                            "İlanı Düzenle",
                                            style: TextStyles.bold16White,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (currentUserId != null &&
                                      currentUserId ==
                                          controller.tutoring.value.userID)
                                    8.pw,
                                  if (currentUserId != null &&
                                      currentUserId ==
                                          controller.tutoring.value.userID)
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          noYesAlert(
                                            title: "İlanı Sil",
                                            message:
                                                "Bu özel ders ilanınızı silmek istediğinizden emin misiniz?",
                                            onYesPressed: () {
                                              deleteTutoring(
                                                controller.tutoring.value.docID,
                                              );
                                            },
                                          );
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.red,
                                          ),
                                          child: Text(
                                            "İlanı Sil",
                                            style: TextStyles.bold16White,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (currentUserId != null &&
                                      currentUserId !=
                                          controller.tutoring.value.userID)
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          final sohbet = chatListingController
                                              .list
                                              .firstWhereOrNull(
                                            (val) =>
                                                val.userID ==
                                                controller
                                                    .tutoring.value.userID,
                                          );

                                          if (sohbet != null) {
                                            Get.to(
                                              () => ChatView(
                                                chatID: sohbet.chatID,
                                                userID: controller
                                                    .tutoring.value.userID,
                                                isNewChat: false,
                                              ),
                                            );
                                          } else {
                                            final chatId = buildConversationId(
                                              currentUserId,
                                              controller.tutoring.value.userID,
                                            );
                                            Get.to(
                                              () => ChatView(
                                                chatID: chatId,
                                                userID: controller
                                                    .tutoring.value.userID,
                                                isNewChat: true,
                                              ),
                                            );
                                            chatListingController.getList();
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.black,
                                          ),
                                          child: Text(
                                            "Mesaj Gönder",
                                            style: TextStyles.bold16White,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (currentUserId != null &&
                                      currentUserId !=
                                          controller.tutoring.value.userID &&
                                      controller.tutoring.value.telefon == true)
                                    8.pw,
                                  if (currentUserId != null &&
                                      currentUserId !=
                                          controller.tutoring.value.userID &&
                                      controller.tutoring.value.telefon == true)
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final phoneNumber = controller.users[
                                                  controller
                                                      .tutoring.value.userID]
                                              ?['phoneNumber'] as String?;
                                          if (phoneNumber != null) {
                                            await launchUrl(
                                              Uri.parse('tel:$phoneNumber'),
                                            );
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Colors.green,
                                          ),
                                          child: Text(
                                            "Ara",
                                            style: TextStyles.bold16White,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}
