import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeGrid/deneme_grid_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeGrid extends StatelessWidget {
  final SinavModel model;
  final Function getData;

  const DenemeGrid({super.key, required this.model, required this.getData});

  Future<void> _shareExam() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || model.userID == currentUid;
    if (!canShareFeed) {
      AppSnackbar("Yetki", "Sadece admin ve ilan sahibi paylaşabilir.");
      return;
    }
    final shareId = 'practice-exam:${model.docID}';
    final shortTail =
        model.docID.length >= 8 ? model.docID.substring(0, 8) : model.docID;
    final fallbackId = 'practice-exam-$shortTail';
    final fallbackUrl = 'https://turqapp.com/e/$fallbackId';

    try {
      await ShareActionGuard.run(() async {
        String shortUrl = '';
        try {
          shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: model.sinavAdi,
            desc: model.sinavAciklama.isNotEmpty
                ? model.sinavAciklama
                : '${model.sinavTuru} online sinav',
            imageUrl: model.cover.isNotEmpty ? model.cover : null,
          );
        } catch (_) {
          shortUrl = fallbackUrl;
        }

        if (shortUrl.trim().isEmpty ||
            shortUrl.trim() == 'https://turqapp.com') {
          shortUrl = fallbackUrl;
        }

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: model.sinavAdi,
          subject: model.sinavAdi,
        );
      });
    } catch (_) {
      AppSnackbar("Hata", "Paylaşım başlatılamadı");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final canShareFeed =
        AdminAccessService.isKnownAdminSync() || model.userID == currentUid;
    final DenemeGridController controller = Get.put(
      DenemeGridController(),
      tag: model.docID,
    );
    controller.initData(model);

    return GestureDetector(
      onTap: () {
        if (model.userID == FirebaseAuth.instance.currentUser!.uid) {
          Get.dialog(
            AlertDialog(
              title: Text(
                model.sinavAdi,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              content: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: Image.network(model.cover),
              ),
              backgroundColor: Colors.white,
              actions: [
                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.to(() => DenemeSinaviPreview(model: model));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "Görüntüle",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.purpleAccent,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
                4.ph,
                GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "Sınavı Sil",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    Future.delayed(Duration(milliseconds: 300), () {
                      noYesAlert(
                        title: "Sınavı Sil",
                        message:
                            "Bu sınavı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!",
                        cancelText: "Vazgeç",
                        yesText: "Sınavı Sil",
                        onYesPressed: () {
                          FirebaseFirestore.instance
                              .collection("practiceExams")
                              .doc(model.docID)
                              .delete();
                          getData();
                        },
                      );
                    });
                  },
                ),
                4.ph,
                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.to(() => SinavHazirla(sinavModel: model));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "Sınavı Düzenle",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.indigo,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
                4.ph,
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    alignment: Alignment.center,
                    height: 40,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "Vazgeç",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          Get.to(() => DenemeSinaviPreview(model: model));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (model.userID != FirebaseAuth.instance.currentUser!.uid) {
                  Get.to(() => SocialProfile(userID: model.userID));
                }
              },
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Obx(
                        () => ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                          child: SizedBox(
                            width: 23,
                            height: 23,
                            child: controller.isLoadingProfile.value
                                ? CupertinoActivityIndicator(
                                    color: Colors.indigo,
                                    radius: 8,
                                  )
                                : controller.pfImage.value.isNotEmpty
                                    ? Image.network(
                                        controller.pfImage.value,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                          ),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => Text(
                                  controller.isLoadingProfile.value
                                      ? 'Yükleniyor...'
                                      : controller.nickname.value.isEmpty
                                          ? 'Kullanıcı Bulunamadı'
                                          : controller.nickname.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            RozetContent(size: 13, userID: model.userID),
                          ],
                        ),
                      ),
                      if (canShareFeed)
                        GestureDetector(
                          onTap: _shareExam,
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.share_up,
                              color: Colors.black87,
                              size: 17,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  if (model.cover.isNotEmpty)
                    Image.network(
                      model.cover,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    Center(
                      child: CupertinoActivityIndicator(
                        color: Colors.black,
                        radius: 10,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    model.sinavAdi,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.sinavTuru,
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                      Text(
                        formatTimestamp(model.timeStamp.toInt()),
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 13,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    model.sinavAciklama,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  SizedBox(height: 4),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_pin_circle_outlined,
                          color: Colors.indigo,
                          size: 20,
                        ),
                        SizedBox(width: 5),
                        Text(
                          controller.isLoadingApplicants.value
                              ? 'Yükleniyor...'
                              : (controller.toplamBasvuru.value * 3) / 1000000 >
                                      1
                                  ? "${((controller.toplamBasvuru.value * 3) / 1000000).toStringAsFixed(2)}M Başvuru"
                                  : (controller.toplamBasvuru.value * 3) /
                                              1000 >
                                          1
                                      ? "${((controller.toplamBasvuru.value * 3) / 1000).toStringAsFixed(1)}B Başvuru"
                                      : "${controller.toplamBasvuru.value * 3} Başvuru",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Obx(
                    () => Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.currentTime.value <
                                controller.examTime.value -
                                    controller.fifteenMinutes
                            ? Colors.green
                            : controller.currentTime.value >=
                                        controller.examTime.value -
                                            controller.fifteenMinutes &&
                                    controller.currentTime.value <
                                        controller.examTime.value
                                ? Colors.purple
                                : controller.currentTime.value >=
                                            controller.examTime.value &&
                                        controller.currentTime.value <
                                            model.bitis
                                    ? Colors.grey
                                    : Colors.pink,
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          String displayText;
                          if (controller.currentTime.value <
                              controller.examTime.value -
                                  controller.fifteenMinutes) {
                            displayText = "Hemen Başvur";
                          } else if (controller.currentTime.value >=
                                  controller.examTime.value -
                                      controller.fifteenMinutes &&
                              controller.currentTime.value <
                                  controller.examTime.value) {
                            displayText = "Başvuruya Kapandı.";
                          } else if (controller.currentTime.value >=
                                  controller.examTime.value &&
                              controller.currentTime.value < model.bitis) {
                            displayText = "Sınav Başladı";
                          } else {
                            displayText = "Hemen Başla";
                          }

                          return Text(
                            displayText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
