part of 'tutoring_detail.dart';

extension TutoringDetailBodyPart on TutoringDetail {
  Widget buildContent(BuildContext context) {
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
      if (normalizedMention.isEmpty) return;
      final targetUid =
          await UsernameLookupRepository.ensure().findUidForHandle(mention) ??
              '';

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
      } catch (_) {
        AppSnackbar("Hata", "İlan silinirken bir hata oluştu.");
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
                                        userID:
                                            controller.tutoring.value.userID));
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
}
