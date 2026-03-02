import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringReview/tutoring_review.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart'
    show getCurrentUserId;

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
            .collection('educators')
            .doc(docId)
            .delete();
        Get.back();
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
                                              ? Colors.black
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
                              // Title + ended badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.tutoring.value.baslik,
                                      style: TextStyles.bold16Black,
                                    ),
                                  ),
                                  if (controller.tutoring.value.ended == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Yayında Değil",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontFamily: 'MontserratBold',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              appDivider(),
                              // Teacher name + rating
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
                                  if (controller.tutoring.value.verified ==
                                      true) ...[
                                    4.pw,
                                    Icon(Icons.verified,
                                        size: 16, color: Colors.blue),
                                  ],
                                  Spacer(),
                                  if (controller.tutoring.value.averageRating !=
                                      null)
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 16, color: Colors.amber),
                                        2.pw,
                                        Text(
                                          "${controller.tutoring.value.averageRating}",
                                          style: TextStyles.bold16Black,
                                        ),
                                        if (controller
                                                .tutoring.value.reviewCount !=
                                            null)
                                          Text(
                                            " (${controller.tutoring.value.reviewCount})",
                                            style: TextStyles.tutoringLocation,
                                          ),
                                      ],
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
                              // View count for owner
                              if (currentUserId != null &&
                                  currentUserId ==
                                      controller.tutoring.value.userID &&
                                  controller.tutoring.value.viewCount != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.eye,
                                          size: 14, color: Colors.grey),
                                      4.pw,
                                      Text(
                                        "${controller.tutoring.value.viewCount} görüntülenme",
                                        style: TextStyles.tutoringLocation,
                                      ),
                                      if (controller.tutoring.value
                                              .applicationCount !=
                                          null) ...[
                                        12.pw,
                                        Icon(CupertinoIcons.doc_text,
                                            size: 14, color: Colors.grey),
                                        4.pw,
                                        Text(
                                          "${controller.tutoring.value.applicationCount} başvuru",
                                          style: TextStyles.tutoringLocation,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              appDivider(),
                              // Availability grid
                              if (controller.tutoring.value.availability !=
                                      null &&
                                  controller.tutoring.value.availability!
                                      .isNotEmpty) ...[
                                Text("Müsaitlik",
                                    style: TextStyles.bold16Black),
                                8.ph,
                                ...controller.tutoring.value.availability!
                                    .entries
                                    .map((entry) => Padding(
                                          padding: EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  entry.key,
                                                  style: TextStyles
                                                      .bold15Black,
                                                ),
                                              ),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: entry.value
                                                      .map((time) =>
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade200,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Text(
                                                              time,
                                                              style: TextStyle(
                                                                  fontSize: 12),
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                appDivider(),
                              ],
                              Text(
                                controller.tutoring.value.aciklama,
                                style: TextStyles.medium15Black,
                              ),
                              16.ph,
                              // Teacher card
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.black, width: 1)),
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentUserId !=
                                        controller.tutoring.value.userID) {
                                      Get.to(() => SocialProfile(
                                          userID: controller
                                              .tutoring.value.userID));
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
                                                        controller
                                                            .tutoring
                                                            .value
                                                            .userID]
                                                    ?["pfImage"] ??
                                                '',
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
                              // ── Owner buttons ──
                              if (currentUserId != null &&
                                  currentUserId ==
                                      controller.tutoring.value.userID)
                                Column(
                                  children: [
                                    Row(
                                      children: [
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.black,
                                              ),
                                              child: Text(
                                                "İlanı Düzenle",
                                                style: TextStyles.bold16White,
                                              ),
                                            ),
                                          ),
                                        ),
                                        8.pw,
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              Get.to(() =>
                                                  TutoringApplicationReview(
                                                    tutoringDocID: controller
                                                        .tutoring.value.docID,
                                                    tutoringTitle: controller
                                                        .tutoring.value.baslik,
                                                  ));
                                            },
                                            child: Container(
                                              alignment: Alignment.center,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: const Color(0xFF2F2F2F),
                                              ),
                                              child: Text(
                                                "Başvurular",
                                                style: TextStyles.bold16White,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    8.ph,
                                    // Unpublish button
                                    if (controller.tutoring.value.ended != true)
                                      InkWell(
                                        onTap: () {
                                          noYesAlert(
                                            title: "Yayından Kaldır",
                                            message:
                                                "Bu ilanı yayından kaldırmak istediğinizden emin misiniz?",
                                            onYesPressed: () async {
                                              await controller
                                                  .unpublishTutoring();
                                              Get.back();
                                              AppSnackbar("Başarılı",
                                                  "İlan yayından kaldırıldı.");
                                            },
                                          );
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: Colors.orange,
                                          ),
                                          child: Text(
                                            "Yayından Kaldır",
                                            style: TextStyles.bold16White,
                                          ),
                                        ),
                                      ),
                                    8.ph,
                                    InkWell(
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.red,
                                        ),
                                        child: Text(
                                          "İlanı Sil",
                                          style: TextStyles.bold16White,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              // ── Visitor buttons ──
                              if (currentUserId != null &&
                                  currentUserId !=
                                      controller.tutoring.value.userID)
                                Column(
                                  children: [
                                    // Apply button
                                    Obx(() => InkWell(
                                          onTap: () {
                                            controller.toggleBasvuru(
                                                controller
                                                    .tutoring.value.docID);
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color:
                                                  controller.basvuruldu.value
                                                      ? Colors.orange
                                                      : Colors.green,
                                            ),
                                            child: Text(
                                              controller.basvuruldu.value
                                                  ? "Başvuruldu"
                                                  : "Başvur",
                                              style: TextStyles.bold16White,
                                            ),
                                          ),
                                        )),
                                    8.ph,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              final sohbet =
                                                  chatListingController.list
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
                                                final chatId =
                                                    buildConversationId(
                                                  currentUserId,
                                                  controller
                                                      .tutoring.value.userID,
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.black,
                                              ),
                                              child: Text(
                                                "Mesaj Gönder",
                                                style: TextStyles.bold16White,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (controller
                                                .tutoring.value.telefon ==
                                            true)
                                          8.pw,
                                        if (controller
                                                .tutoring.value.telefon ==
                                            true)
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final phoneNumber =
                                                    controller.users[controller
                                                                .tutoring
                                                                .value
                                                                .userID]
                                                            ?['phoneNumber']
                                                        as String?;
                                                if (phoneNumber != null) {
                                                  await launchUrl(
                                                    Uri.parse(
                                                        'tel:$phoneNumber'),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                    // WhatsApp button
                                    if (controller.tutoring.value.whatsapp ==
                                        true) ...[
                                      8.ph,
                                      InkWell(
                                        onTap: () async {
                                          final phoneNumber = controller.users[
                                                      controller.tutoring.value
                                                          .userID]
                                                  ?['phoneNumber']
                                              as String?;
                                          if (phoneNumber != null) {
                                            final cleaned = phoneNumber
                                                .replaceAll(
                                                    RegExp(r'[^0-9]'), '');
                                            await launchUrl(
                                              Uri.parse(
                                                  'https://wa.me/$cleaned'),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: const Color(0xFF25D366),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.chat,
                                                  color: Colors.white,
                                                  size: 20),
                                              8.pw,
                                              Text(
                                                "WhatsApp",
                                                style: TextStyles.bold16White,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              // ── Reviews Section ──
                              16.ph,
                              _buildReviewsSection(
                                  controller, currentUserId),
                              // ── Similar listings ──
                              16.ph,
                              _buildSimilarSection(controller),
                              30.ph,
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

  Widget _buildReviewsSection(
      TutoringDetailController controller, String? currentUserId) {
    return Obx(() {
      final canReview = currentUserId != null &&
          currentUserId != controller.tutoring.value.userID;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Değerlendirmeler", style: TextStyles.bold16Black),
              if (canReview)
                GestureDetector(
                  onTap: () {
                    showTutoringReviewBottomSheet(
                      docID: controller.tutoring.value.docID,
                      controller: controller,
                    );
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Değerlendir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
            ],
          ),
          8.ph,
          if (controller.reviews.isEmpty)
            Text(
              "Henüz değerlendirme yok.",
              style: TextStyles.tutoringLocation,
            )
          else
            ...controller.reviews.map((review) {
              final user = controller.reviewUsers[review.userID] ?? {};
              final name =
                  '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                      .trim();
              final isOwn = currentUserId == review.userID;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CachedNetworkImage(
                              imageUrl: user['pfImage'] ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.person, size: 16),
                            ),
                          ),
                        ),
                        8.pw,
                        Expanded(
                          child: Text(name,
                              style: TextStyles.bold15Black),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        if (isOwn) ...[
                          4.pw,
                          GestureDetector(
                            onTap: () {
                              controller.deleteReview(
                                controller.tutoring.value.docID,
                                review.reviewID,
                              );
                            },
                            child: Icon(CupertinoIcons.trash,
                                size: 16, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      6.ph,
                      Text(review.comment,
                          style: TextStyles.medium15Black),
                    ],
                  ],
                ),
              );
            }),
        ],
      );
    });
  }

  Widget _buildSimilarSection(TutoringDetailController controller) {
    return Obx(() {
      if (controller.similarList.isEmpty) return SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benzer İlanlar", style: TextStyles.bold16Black),
          8.ph,
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.similarList.length,
              itemBuilder: (context, index) {
                final item = controller.similarList[index];
                final user =
                    controller.similarUsers[item.userID] ?? {};
                final name =
                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                        .trim();
                return GestureDetector(
                  onTap: () {
                    Get.off(() => TutoringDetail(), arguments: item);
                  },
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: item.imgs != null &&
                                      item.imgs!.isNotEmpty
                                  ? item.imgs!.first
                                  : '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(
                                color: Colors.grey.shade200,
                                child: Icon(CupertinoIcons.photo),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.baslik,
                                style: TextStyles.bold15Black,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              2.ph,
                              Text(
                                name,
                                style: TextStyles.tutoringBranch,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              2.ph,
                              Text(
                                "${item.fiyat} ₺",
                                style: TextStyles.bold15Black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
