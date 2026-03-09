import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/clickable_text_content.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details_controller.dart';
import 'package:turqappv2/Modules/Agenda/TagPosts/tag_posts.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class JobDetails extends StatelessWidget {
  final JobModel model;
  JobDetails({super.key, required this.model});
  late final JobDetailsController controller;

  Future<void> _openMentionProfile(String mention) async {
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

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (targetUid.isNotEmpty && targetUid != currentUid) {
      await Get.to(() => SocialProfile(userID: targetUid));
    }
  }

  bool _hasValidCoordinates(JobModel job) {
    if (!job.lat.isFinite || !job.long.isFinite) return false;
    if (job.lat == 0 || job.long == 0) return false;
    if (job.lat < -90 || job.lat > 90) return false;
    if (job.long < -180 || job.long > 180) return false;
    return true;
  }

  Widget _buildLocationPreview(BuildContext context) {
    final hasLocation = _hasValidCoordinates(controller.model.value);
    final canUseNativeMap = hasLocation;
    final location = LatLng(
      controller.model.value.lat,
      controller.model.value.long,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: GestureDetector(
            onTap: hasLocation
                ? () {
                    controller.showMapsSheet(
                      controller.model.value.lat,
                      controller.model.value.long,
                    );
                  }
                : null,
            child: SizedBox(
              width: double.infinity,
              height: (MediaQuery.of(context).size.height * 0.28)
                  .clamp(180.0, 220.0),
              child: canUseNativeMap
                  ? AbsorbPointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: location,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('job_location'),
                            position: location,
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F5F7),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasLocation
                                ? CupertinoIcons.location_solid
                                : CupertinoIcons.location_slash,
                            color: hasLocation ? Colors.red : Colors.grey,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasLocation
                                ? 'Haritada Aç'
                                : 'Konum bilgisi bulunamadı',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          if (hasLocation)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Apple Haritalar veya diğer uygulamalarda aç',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (canUseNativeMap)
          const Icon(
            CupertinoIcons.location_solid,
            color: Colors.red,
            size: 30,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    controller = Get.put(JobDetailsController(model: model), tag: model.docID);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: BackButtons(text: "İş Detayı")),
                IconButton(
                  onPressed: controller.shareJob,
                  icon: Icon(
                    CupertinoIcons.share_up,
                    color: Colors.black,
                    size: 22,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Obx(() {
                  return Transform.translate(
                    offset: const Offset(0, 0),
                    child: IconButton(
                      onPressed: () {
                        controller.toggleSave(controller.model.value.docID);
                      },
                      icon: Icon(
                        controller.saved.value
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                        color: controller.saved.value
                            ? Colors.orange
                            : Colors.black,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
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
                                        child: CachedNetworkImage(
                                          imageUrl: controller.avatarUrl.value
                                                  .trim()
                                                  .isNotEmpty
                                              ? controller.avatarUrl.value
                                                  .trim()
                                              : kDefaultAvatarUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                            CupertinoIcons.person_fill,
                                            color: Colors.grey,
                                          ),
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
                    Obx(() {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (controller.model.value.userID ==
                                (FirebaseAuth.instance.currentUser?.uid ?? ''))
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: controller.goToEdit,
                                            child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "İlanı Düzenle",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: controller
                                                .goToApplicationReview,
                                            child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2F2F2F),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "Başvurular",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        noYesAlert(
                                          title: "İlanı Yayından Kaldır",
                                          message:
                                              "Bu ilanı yayından kaldırmak istediğinizden emin misiniz?",
                                          yesText: "Kaldır",
                                          cancelText: "Vazgeç",
                                          onYesPressed: () async {
                                            try {
                                              await controller.unpublishAd();
                                              AppSnackbar(
                                                "Başarılı",
                                                "İlan yayından kaldırıldı.",
                                              );
                                            } catch (e) {
                                              AppSnackbar(
                                                "Hata",
                                                "İlan kaldırılamadı: $e",
                                                backgroundColor:
                                                    Colors.red.withAlpha(40),
                                              );
                                            }
                                          },
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "İlanı Yayından Kaldır",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          // CV kontrolü burada yapılıyor
                                          await controller.cvCheck();
                                          if (controller.basvuruldu.value) {
                                            AppSnackbar(
                                              "Bilgi",
                                              "Bu ilana zaten başvuru yaptınız.",
                                              snackPosition: SnackPosition.TOP,
                                              backgroundColor:
                                                  Colors.grey.withAlpha(50),
                                              colorText: Colors.black,
                                              duration: Duration(seconds: 3),
                                            );
                                          } else if (!controller.cvVar.value) {
                                            Get.bottomSheet(
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      "Özgeçmiş Gerekli",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      "İş başvurusu yapabilmek için özgeçmişinizi doldurmanız gerekiyor.",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        Get.to(() => Cv());
                                                      },
                                                      child: Container(
                                                        height: 50,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          12)),
                                                        ),
                                                        child: Text(
                                                          "Özgeçmiş Oluştur",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Get.back(); // Vazgeç
                                                      },
                                                      child: Container(
                                                        height: 50,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey
                                                              .withAlpha(50),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Text(
                                                          "Vazgeç",
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              isScrollControlled: true,
                                            );
                                          } else {
                                            Get.bottomSheet(
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      "Başvuru Gönder",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 18,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      "Özgeçmişiniz hazır.\nBaşvurmak istediğinizden emin misiniz?",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        Get.to(() => Cv());
                                                      },
                                                      child: Container(
                                                        height: 50,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.blueAccent,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          12)),
                                                        ),
                                                        child: Text(
                                                          "Özgeçmişi Düzenle",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Get.back(); // Vazgeç
                                                            },
                                                            child: Container(
                                                              height: 50,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .withAlpha(
                                                                        50),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: const Text(
                                                                "Vazgeç",
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 15,
                                                                  fontFamily:
                                                                      "MontserratBold",
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child:
                                                              GestureDetector(
                                                            onTap: () async {
                                                              await controller
                                                                  .toggleBasvuru(
                                                                      model
                                                                          .docID);
                                                              Get.back();
                                                            },
                                                            child: Container(
                                                              height: 50,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color: Colors
                                                                    .black,
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            12)),
                                                              ),
                                                              child: const Text(
                                                                "Başvur",
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 15,
                                                                  fontFamily:
                                                                      "MontserratBold",
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              isScrollControlled: true,
                                            );
                                          }
                                        },
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: controller.basvuruldu.value
                                                ? Colors.grey.withAlpha(50)
                                                : Colors.black,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(12)),
                                            border: Border.all(
                                              color: controller.basvuruldu.value
                                                  ? Colors.grey.withAlpha(50)
                                                  : Colors.black,
                                            ),
                                          ),
                                          child: Text(
                                            controller.basvuruldu.value
                                                ? "Başvuru Yapıldı"
                                                : "Başvur",
                                            style: TextStyle(
                                              color: controller.basvuruldu.value
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (controller.basvuruldu.value)
                                      const SizedBox(width: 12),
                                    if (controller.basvuruldu.value)
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            noYesAlert(
                                              title: "Başvuru İptali",
                                              message:
                                                  "Başvurunuzu iptal etmek istediğinizden emin misiniz?",
                                              cancelText: "Vazgeç",
                                              yesText: "İptal Et",
                                              onYesPressed: () async {
                                                await controller
                                                    .toggleBasvuru(model.docID);
                                                AppSnackbar("Bilgi",
                                                    "Başvurunuz iptal edildi.");
                                              },
                                            );
                                          },
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)),
                                              border:
                                                  Border.all(color: Colors.red),
                                            ),
                                            child: Text(
                                              "Başvuru İptal",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    // Padding(
                    //   padding:
                    //       EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    //   child: SizedBox(
                    //       height: 2,
                    //       child: Divider(color: Colors.grey.withAlpha(50))),
                    // ),
                    15.ph,
                    if (controller.list.isNotEmpty &&
                        controller.list.any(
                            (doc) => doc.docID != controller.model.value.docID))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                Text(
                                  "Benzer İlanlar",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                )
                              ],
                            ),
                          ),
                          for (var doc in controller.list)
                            if (doc.docID != controller.model.value.docID)
                              JobContent(model: doc, isGrid: false),
                        ],
                      ),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }

  Widget pullDownMenu() {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(() => ReportUser(
                userID: controller.model.value.userID,
                postID: controller.model.value.docID,
                commentID: ""));
          },
          title: 'İlanı Bildir',
          icon: CupertinoIcons.exclamationmark_circle,
        ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        minimumSize: Size(0, 0),
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
        ),
      ),
    );
  }
}
