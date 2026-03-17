import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_icon_surface.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviPreview/deneme_sinavi_preview_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/DenemeSinaviYap/deneme_sinavi_yap.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class DenemeSinaviPreview extends StatelessWidget {
  final SinavModel model;
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  const DenemeSinaviPreview({super.key, required this.model});

  Widget buildExamInfo() {
    final controller = Get.find<DenemeSinaviPreviewController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: Get.width,
          height: Get.width,
          child: CachedNetworkImage(
            imageUrl: controller.model.cover,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Text(
              "Kapak resmi yüklenemedi.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.model.sinavAdi,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              8.ph,
              Text(
                controller.model.sinavAciklama,
                style: TextStyle(
                  height: 1.6,
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sınav Türü",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      Text(
                        "${controller.model.sinavTuru} Sınavı",
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sınav Tarihi ve Saati",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      Text(
                        formatTimestamp(controller.model.timeStamp.toInt()),
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sınav Süresi",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                      Text(
                        "${controller.model.bitisDk} dk",
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              20.ph,
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.black, width: 1)),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: controller.model.userID ==
                                  FirebaseAuth.instance.currentUser!.uid
                              ? null
                              : () {
                                  Get.to(
                                    () => SocialProfile(
                                        userID: controller.model.userID),
                                  );
                                },
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CachedNetworkImage(
                                imageUrl: controller.avatarUrl.value,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        12.pw,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: controller.model.userID ==
                                        FirebaseAuth.instance.currentUser!.uid
                                    ? null
                                    : () {
                                        Get.to(
                                          () => SocialProfile(
                                              userID: controller.model.userID),
                                        );
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        controller.nickname.value.isEmpty
                                            ? "Kullanıcı Yükleniyor"
                                            : controller.nickname.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.pink,
                                          fontSize: 16,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                    ),
                                    const Text(' '),
                                    RozetContent(
                                      size: 16,
                                      userID: controller.model.userID,
                                    ),
                                  ],
                                ),
                              ),
                              4.ph,
                              controller.model.userID !=
                                      FirebaseAuth.instance.currentUser!.uid
                                  ? GestureDetector(
                                      onTap: controller.model.userID ==
                                              FirebaseAuth
                                                  .instance.currentUser!.uid
                                          ? null
                                          : () {
                                              Get.to(
                                                () => SocialProfile(
                                                    userID: controller
                                                        .model.userID),
                                              );
                                            },
                                      child: Text(
                                        "Profili Görüntüle",
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontSize: 14,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Profili Görüntüle",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              20.ph,
              GestureDetector(
                onTap: () {
                  if (controller.currentTime.value <
                      controller.examTime.value - controller.fifteenMinutes) {
                    controller.addBasvuru();
                  } else if (controller.currentTime.value >=
                          controller.examTime.value -
                              controller.fifteenMinutes &&
                      controller.currentTime.value <
                          controller.examTime.value) {
                    AppSnackbar(
                      "Başvuruya Kapanmıştır!",
                      "Başvurular sınav tarihinden 15 dk önce kapanacaktır.",
                    );
                  } else if (controller.currentTime.value >=
                          controller.examTime.value &&
                      controller.currentTime.value < controller.model.bitis) {
                    if (controller.sinavaGirebilir.value) {
                      if (controller.dahaOnceBasvurdu.value) {
                        Get.to(
                          () => DenemeSinaviYap(
                            model: controller.model,
                            sinaviBitir: controller.sinaviBitirAlert,
                            showGecersizAlert: controller.showGecersizAlert,
                            uyariAtla: false,
                          ),
                        );
                      } else {
                        AppSnackbar(
                          "Başvuru Yapmadın!",
                          "Başvuru yapılmayan sınavlara katılamazsın. Sadece başvuru yapanlar katılabilir.",
                        );
                      }
                    } else {
                      AppSnackbar(
                        "Sınava Giremezsiniz!",
                        "Bu sınava giriş hakkınız bulunmuyor. Daha önce bu sınavda geçersiz sayıldınız. Sınav sonlanmadan sınava bir daha giremezsiniz!",
                      );
                    }
                  } else {
                    if (controller.model.public) {
                      Get.to(
                        () => DenemeSinaviYap(
                          model: controller.model,
                          sinaviBitir: controller.sinaviBitirAlert,
                          showGecersizAlert: controller.showGecersizAlert,
                          uyariAtla: true,
                        ),
                      );
                    } else {
                      AppSnackbar(
                        "Sınav Bitti!",
                        "Bir sonraki sınavlara başvurabilirsiniz. Bu sınav sonlanmıştır.",
                      );
                    }
                  }
                },
                child: Obx(() => Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.currentTime.value <
                                controller.examTime.value -
                                    controller.fifteenMinutes
                            ? Colors.teal
                            : controller.currentTime.value >=
                                        controller.examTime.value -
                                            controller.fifteenMinutes &&
                                    controller.currentTime.value <
                                        controller.examTime.value
                                ? Colors.purple
                                : controller.currentTime.value >=
                                            controller.examTime.value &&
                                        controller.currentTime.value <
                                            controller.model.bitis
                                    ? Colors.black
                                    : controller.currentTime.value >=
                                                controller.examTime.value &&
                                            controller.currentTime.value >
                                                controller.model.bitis &&
                                            controller.model.public == false
                                        ? Colors.red
                                        : Colors.indigo,
                        borderRadius: BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        controller.currentTime.value <
                                controller.examTime.value -
                                    controller.fifteenMinutes
                            ? (controller.dahaOnceBasvurdu.value
                                ? "Başvuru Yapıldı"
                                : "Hemen Başvur")
                            : controller.currentTime.value >=
                                        controller.examTime.value -
                                            controller.fifteenMinutes &&
                                    controller.currentTime.value <
                                        controller.examTime.value
                                ? "Başvuruya Kapandı.\n${((controller.examTime.value - controller.currentTime.value) / (60 * 1000)).floor()} dk sonra başlayacak."
                                : controller.currentTime.value >=
                                            controller.examTime.value &&
                                        controller.currentTime.value <
                                            controller.model.bitis
                                    ? "Sınav Başladı"
                                    : controller.currentTime.value >=
                                                controller.examTime.value &&
                                            controller.currentTime.value >
                                                controller.model.bitis &&
                                            controller.model.public == false
                                        ? "Sınav Bitti"
                                        : "Hemen Başla",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.6,
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    )),
              ),
              controller.model.userID != FirebaseAuth.instance.currentUser!.uid
                  ? SizedBox.shrink()
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DenemeSinaviPreviewController(model: model));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: BackButtons(text: "Sınav Hakkında")),
                    EducationFeedShareIconButton(
                      onTap: () => shareService.sharePracticeExam(model),
                      size: AppIconSurface.kSize,
                      iconSize: AppIconSurface.kIconSize,
                    ),
                    6.pw,
                    Obx(
                      () => AppHeaderActionButton(
                        onTap: controller.toggleSaved,
                        child: Icon(
                          controller.isSaved.value
                              ? CupertinoIcons.bookmark_fill
                              : CupertinoIcons.bookmark,
                          size: AppIconSurface.kIconSize,
                          color: controller.isSaved.value
                              ? Colors.orange
                              : Colors.black87,
                        ),
                      ),
                    ),
                    6.pw,
                    pullDownMenu(controller),
                    10.pw,
                  ],
                ),
                Expanded(
                  child: Obx(
                    () => controller.isLoading.value
                        ? Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : controller.isInitialized.value &&
                                controller.nickname.value.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.black,
                                        size: 40,
                                      ),
                                      10.ph,
                                      Text(
                                        "Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin veya sınav sahibini kontrol edin.",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                color: Colors.white,
                                backgroundColor: Colors.black,
                                onRefresh: controller.refreshData,
                                child: ListView(children: [buildExamInfo()]),
                              ),
                  ),
                ),
              ],
            ),
            Obx(
              () => controller.showSucces.value
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        GestureDetector(
                          onTap: () => controller.showSucces.value = false,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        Container(
                          height: (Get.height * 0.28).clamp(190.0, 220.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(18),
                              topLeft: Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Başvurun Tamamlandı!",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                      ],
                                    ),
                                    15.ph,
                                    Text(
                                      "Sınavdan önce size bildirim göndererek gerekli hatırlatmaları yapacağız. Başarılar diliyoruz!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    15.ph,
                                    GestureDetector(
                                      onTap: () => Get.back(),
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          "Tamam",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget pullDownMenu(DenemeSinaviPreviewController controller) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          onTap: () {
            Get.to(
              () => ReportUser(
                userID: controller.model.userID,
                postID: controller.model.docID,
                commentID: "",
              ),
            );
          },
          title: 'Sınavı Bildir',
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
