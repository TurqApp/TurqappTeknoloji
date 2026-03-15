part of 'job_details.dart';

extension JobDetailsBodyPart on JobDetails {
  @override
  Widget buildContent(BuildContext context) {
    final controller =
        Get.put(JobDetailsController(model: model), tag: model.docID);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: BackButtons(text: "İş Detayı")),
                EducationFeedShareIconButton(
                  onTap: () => shareService.shareJob(controller.model.value),
                  size: 30,
                  iconSize: 18,
                ),
                Obx(() {
                  return EducationActionIconButton(
                    onTap: () {
                      controller.toggleSave(controller.model.value.docID);
                    },
                    icon: controller.saved.value
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    size: 30,
                    iconSize: 18,
                    iconColor:
                        controller.saved.value ? Colors.orange : Colors.black87,
                  );
                }),
                pullDownMenu(),
                10.pw,
              ],
            ),
            Obx(() {
              return Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                                child: SizedBox(
                                    width: 65,
                                    height: 65,
                                    child: CachedNetworkImage(
                                      imageUrl: controller.model.value.logo,
                                      fit: BoxFit.cover,
                                    )),
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.model.value.meslek,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratBold"),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                controller.model.value.brand,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium"),
                                              ),
                                              Text(
                                                "${controller.model.value.kacKm.toStringAsFixed(2)} km • ${controller.model.value.city}, ${controller.model.value.town}",
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontFamily: "Montserrat",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          // İlan Başlığı (varsa)
                          if (controller.model.value.ilanBasligi.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "İlan Başlığı",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold"),
                                  ),
                                  Text(
                                    controller.model.value.ilanBasligi,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "Montserrat"),
                                  ),
                                ],
                              ),
                            ),
                          // Deneyim Seviyesi + Pozisyon Sayısı + Başvuru Sayısı
                          if (controller
                                  .model.value.deneyimSeviyesi.isNotEmpty ||
                              controller.model.value.pozisyonSayisi > 1 ||
                              controller.model.value.applicationCount > 0 ||
                              controller.model.value.viewCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (controller
                                      .model.value.deneyimSeviyesi.isNotEmpty)
                                    _infoChip(
                                      CupertinoIcons.briefcase,
                                      controller.model.value.deneyimSeviyesi,
                                    ),
                                  if (controller.model.value.pozisyonSayisi > 1)
                                    _infoChip(
                                      CupertinoIcons.person_2,
                                      "${controller.model.value.pozisyonSayisi} kişi",
                                    ),
                                  if (controller.model.value.applicationCount >
                                      0)
                                    _infoChip(
                                      CupertinoIcons.doc_text,
                                      "${controller.model.value.applicationCount} başvuru",
                                    ),
                                  if (controller.model.value.viewCount > 0)
                                    _infoChip(
                                      CupertinoIcons.eye,
                                      "${controller.model.value.viewCount} görüntülenme",
                                    ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              Text(
                                "İş Tanımı",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          ClickableTextContent(
                            text: controller.model.value.isTanimi,
                            startWith7line: true,
                            fontSize: 13,
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
                            onMentionTap: (mention) =>
                                _openMentionProfile(mention),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Text(
                                "Yan Haklar",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                controller.model.value.yanHaklar.map((hak) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  hak,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: "MontserratMedium"),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Text(
                                "Çalışma Zamanı",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          Text(
                            controller.model.value.calismaTuru.join(", "),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "Montserrat"),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Text(
                                "Maaş Bilgisi",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          Text(
                            controller.model.value.maas1.toInt() != 0
                                ? "${NumberFormat.decimalPattern('tr_TR').format(controller.model.value.maas1)}₺ - ${NumberFormat.decimalPattern('tr_TR').format(controller.model.value.maas2)}₺"
                                : "Belirtilmedi",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "Montserrat",
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          _buildLocationPreview(context),
                          if (controller.model.value.adres.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              controller.model.value.adres,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                          ],
                          SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Text(
                                "İşveren",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          ClickableTextContent(
                            text: controller.model.value.about,
                            startWith7line: true,
                            fontSize: 13,
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
                            onMentionTap: (mention) =>
                                _openMentionProfile(mention),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Text(
                                "İlan Tarihi",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          Text(
                            timeAgoMetin(controller.model.value.timeStamp),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "Montserrat",
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          AdmobKare(),
                          SizedBox(
                            height: 12,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (model.userID !=
                                  (FirebaseAuth.instance.currentUser?.uid ??
                                      '')) {
                                Get.to(
                                    () => SocialProfile(userID: model.userID));
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  border: Border.all(color: Colors.blueAccent)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: controller.avatarUrl.value
                                                .trim()
                                                .isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: controller
                                                    .avatarUrl.value
                                                    .trim(),
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const DefaultAvatar(
                                                  radius: 25,
                                                ),
                                              )
                                            : const DefaultAvatar(
                                                radius: 25,
                                              ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                controller.nickname.value,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium"),
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            RozetContent(
                                              size: 14,
                                              userID:
                                                  controller.model.value.userID,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.grey,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomActionSection(controller),
                    16.ph,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildReviewsSection(controller),
                    ),
                    16.ph,
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: _buildSimilarSection(controller),
                    ),
                    20.ph,
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
