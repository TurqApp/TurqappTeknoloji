import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringApplicationReview/tutoring_application_review.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringReview/tutoring_review.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart'
    show getCurrentUserId;

class TutoringDetail extends StatelessWidget {
  TutoringDetail({super.key});

  final chatListingController = Get.put(ChatListingController());
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  @override
  Widget build(BuildContext context) {
    final TutoringDetailController controller = Get.put(
      TutoringDetailController(),
    );
    final SavedTutoringsController savedController =
        Get.isRegistered<SavedTutoringsController>()
            ? Get.find<SavedTutoringsController>()
            : Get.put(SavedTutoringsController());
    final TutoringController tutoringController =
        Get.isRegistered<TutoringController>()
            ? Get.find<TutoringController>()
            : Get.put(TutoringController());
    final String? currentUserId = getCurrentUserId();

    Future<void> openMentionProfile(String mention) async {
      final normalizedMention = mention.trim().replaceFirst('@', '');
      final handle = normalizedMention.toLowerCase();
      if (handle.isEmpty) return;

      String targetUid = '';
      try {
        final usernameDoc = await FirebaseFirestore.instance
            .collection('usernames')
            .doc(handle)
            .get();
        targetUid = (usernameDoc.data()?['uid'] ?? '').toString().trim();
      } catch (_) {}

      if (targetUid.isEmpty) {
        try {
          final byUsername = await FirebaseFirestore.instance
              .collection('users')
              .where('usernameLower', isEqualTo: handle)
              .limit(1)
              .get();
          if (byUsername.docs.isNotEmpty) {
            targetUid = byUsername.docs.first.id;
          }
        } catch (_) {}
      }

      if (targetUid.isEmpty) {
        try {
          final byNickname = await FirebaseFirestore.instance
              .collection('users')
              .where('nickname', isEqualTo: normalizedMention)
              .limit(1)
              .get();
          if (byNickname.docs.isNotEmpty) {
            targetUid = byNickname.docs.first.id;
          }
        } catch (_) {}
      }

      if (targetUid.isNotEmpty && targetUid != currentUserId) {
        await Get.to(() => SocialProfile(userID: targetUid));
      }
    }

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
                    Expanded(child: BackButtons(text: "Özel Ders")),
                    EducationFeedShareIconButton(
                      onTap: () =>
                          shareService.shareTutoring(controller.tutoring.value),
                      size: 30,
                      iconSize: 18,
                    ),
                    6.pw,
                    Obx(() {
                      final isSaved = savedController.savedTutoringIds.contains(
                        controller.tutoring.value.docID,
                      );
                      return EducationActionIconButton(
                        onTap: () async {
                          if (currentUserId != null) {
                            final success =
                                await tutoringController.toggleFavorite(
                              controller.tutoring.value.docID,
                              currentUserId,
                              isSaved,
                            );
                            if (!success) return;
                            if (isSaved) {
                              savedController.removeSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            } else {
                              savedController.addSavedTutoring(
                                controller.tutoring.value.docID,
                              );
                            }
                          } else {
                            log("User ID not found");
                          }
                        },
                        icon: isSaved
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                        size: 30,
                        iconSize: 18,
                        iconColor: isSaved ? Colors.orange : Colors.black87,
                      );
                    }),
                    6.pw,
                    pullDownMenu(controller),
                    10.pw,
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
                                    (controller.users[controller.tutoring.value
                                                .userID]?['nickname'] ??
                                            controller.users[controller.tutoring
                                                .value.userID]?['username'] ??
                                            controller.users[controller
                                                .tutoring
                                                .value
                                                .userID]?['displayName'] ??
                                            '')
                                        .toString(),
                                    style: TextStyles.bold16Black,
                                  ),
                                  4.pw,
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
                                ...controller
                                    .tutoring.value.availability!.entries
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
                                                  style: TextStyles.bold15Black,
                                                ),
                                              ),
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: entry.value
                                                      .map((time) => Container(
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
                              ClickableTextContent(
                                text: controller.tutoring.value.aciklama,
                                startWith7line: true,
                                fontSize: 15,
                                fontColor: Colors.black,
                                mentionColor: Colors.blue,
                                hashtagColor: Colors.blue,
                                urlColor: Colors.blue,
                                interactiveColor: Colors.blue,
                                onHashtagTap: (tag) {
                                  if (tag.trim().isEmpty) return;
                                  Get.to(() => TagPosts(tag: tag.trim()));
                                },
                                onUrlTap: (url) async {
                                  final uniqueKey = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  await RedirectionLink()
                                      .goToLink(url, uniqueKey: uniqueKey);
                                },
                                onMentionTap: openMentionProfile,
                              ),
                              16.ph,
                              // Teacher card
                              GestureDetector(
                                onTap: () {
                                  if (currentUserId !=
                                      controller.tutoring.value.userID) {
                                    Get.to(() => SocialProfile(
                                        userID: controller
                                            .tutoring.value.userID));
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.black, width: 1)),
                                  child: Row(
                                    children: [
                                      ClipOval(
                                        child: SizedBox(
                                          width: 35,
                                          height: 35,
                                          child: CachedNetworkImage(
                                            imageUrl: (controller.users[
                                                            controller.tutoring
                                                                .value.userID]
                                                        ?["avatarUrl"] ??
                                                    controller.users[controller
                                                            .tutoring
                                                            .value
                                                            .userID]
                                                        ?["avatarUrl"] ??
                                                    '')
                                                .toString(),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                (controller.users[controller
                                                                .tutoring
                                                                .value
                                                                .userID]
                                                            ?['nickname'] ??
                                                        controller.users[controller
                                                                .tutoring
                                                                .value
                                                                .userID]
                                                            ?['username'] ??
                                                        controller.users[
                                                                controller
                                                                    .tutoring
                                                                    .value
                                                                    .userID]
                                                            ?['displayName'] ??
                                                        '')
                                                    .toString(),
                                                style: TextStyles.bold16Black,
                                              ),
                                              4.pw,
                                              RozetContent(
                                                size: 14,
                                                userID: controller
                                                    .tutoring.value.userID
                                                    .toString(),
                                              ),
                                            ],
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
                                            controller.toggleBasvuru(controller
                                                .tutoring.value.docID);
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: controller.basvuruldu.value
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
                                        if (controller.tutoring.value.telefon ==
                                            true)
                                          8.pw,
                                        if (controller.tutoring.value.telefon ==
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
                                                  controller
                                                      .tutoring.value.userID]
                                              ?['phoneNumber'] as String?;
                                          if (phoneNumber != null) {
                                            final cleaned =
                                                phoneNumber.replaceAll(
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
                              _buildReviewsSection(controller, currentUserId),
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
      final totalReviews = controller.reviews.length;
      final ratingCounts = <int, int>{
        for (var star = 1; star <= 5; star++) star: 0,
      };
      for (final review in controller.reviews) {
        final rating = review.rating.clamp(1, 5);
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
      }

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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          else ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = ratingCounts[star] ?? 0;
                  final percent =
                      totalReviews == 0 ? 0.0 : count / totalReviews;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            "$star",
                            style: TextStyles.bold15Black,
                          ),
                        ),
                        4.pw,
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        8.pw,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        8.pw,
                        SizedBox(
                          width: 42,
                          child: Text(
                            "%${(percent * 100).round()}",
                            textAlign: TextAlign.right,
                            style: TextStyles.tutoringLocation,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            8.ph,
            ...controller.reviews.map((review) {
              final user = controller.reviewUsers[review.userID] ?? {};
              final name = (user['nickname'] ??
                      user['username'] ??
                      user['displayName'] ??
                      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                  .toString()
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
                              imageUrl: user['avatarUrl'] ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.person, size: 16),
                            ),
                          ),
                        ),
                        8.pw,
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child:
                                    Text(name, style: TextStyles.bold15Black),
                              ),
                              4.pw,
                              RozetContent(size: 12, userID: review.userID),
                            ],
                          ),
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
                      Text(review.comment, style: TextStyles.medium15Black),
                    ],
                  ],
                ),
              );
            }),
          ],
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
            height: (Get.height * 0.28).clamp(188.0, 218.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.similarList.length,
              itemBuilder: (context, index) {
                final item = controller.similarList[index];
                final user = controller.similarUsers[item.userID] ?? {};
                final name = (user['nickname'] ??
                        user['username'] ??
                        user['displayName'] ??
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                    .toString()
                    .trim();
                return GestureDetector(
                  onTap: () {
                    Get.off(() => TutoringDetail(), arguments: item);
                  },
                  child: Container(
                    width: (Get.width * 0.42).clamp(136.0, 160.0),
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                          child: SizedBox(
                            height: (Get.height * 0.125).clamp(84.0, 100.0),
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl:
                                  item.imgs != null && item.imgs!.isNotEmpty
                                      ? item.imgs!.first
                                      : '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(CupertinoIcons.photo),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.baslik,
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "$name ",
                                        style: TextStyles.tutoringBranch,
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: RozetContent(
                                          size: 12,
                                          userID: item.userID,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                2.ph,
                                Text(
                                  "${item.fiyat} ₺",
                                  style: TextStyles.bold15Black,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "İlana Git",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: "MontserratBold",
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget pullDownMenu(TutoringDetailController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.tutoring.value.userID,
                postID: controller.tutoring.value.docID,
                commentID: "",
              ),
            );
          },
          title: 'İlanı Bildir',
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
        ),
      ),
    );
  }
}
