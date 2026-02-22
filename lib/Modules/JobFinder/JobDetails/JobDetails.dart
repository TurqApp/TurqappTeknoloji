import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/AdmobKare.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/RedirectionLink.dart';
import 'package:turqappv2/Models/JobModel.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/JobContent.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/JobDetailsController.dart';
import 'package:turqappv2/Modules/Profile/Cv/Cv.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/ReportUser.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class JobDetails extends StatelessWidget {
  final JobModel model;
  JobDetails({super.key, required this.model});
  late final JobDetailsController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(JobDetailsController(model: model), tag: model.docID);
    controller.checkSaved(model.docID);
    controller.checkBasvuru(model.docID);
    controller.getSimilar(model.meslek);
    controller.getUserData(model.userID);

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
                  onPressed: () {
                    RedirectionLink().goToLink("https://turqapp.com");
                  },
                  icon: Icon(
                    CupertinoIcons.share,
                    color: Colors.black,
                    size: 25,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Obx(() {
                  return IconButton(
                    onPressed: () {
                      controller.toggleSave(controller.model.value.docID);
                    },
                    icon: Icon(
                      controller.saved.value
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color:
                          controller.saved.value ? Colors.orange : Colors.black,
                      size: 25,
                    ),
                    visualDensity: VisualDensity.compact,
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
                                child: GestureDetector(
                                  onTap: () => Get.to(JobDetails(model: model)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.blueAccent,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratMedium"),
                                                ),
                                                Text(
                                                  "${controller.model.value.kacKm.toStringAsFixed(2)} km • ${controller.model.value.city}, ${controller.model.value.town}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 12,
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
                          Text(
                            controller.model.value.isTanimi,
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
                                "Yan Haklar",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold"),
                              )
                            ],
                          ),
                          Text(
                            controller.model.value.yanHaklar.join(", "),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                child: GestureDetector(
                                  onTap: () {
                                    controller.showMapsSheet(
                                        controller.model.value.lat,
                                        controller.model.value.long);
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 220,
                                    child: AbsorbPointer(
                                      // Etkileşimi tamamen engeller
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: LatLng(
                                              controller.model.value.lat
                                                  .toDouble(),
                                              controller.model.value.long
                                                  .toDouble()),
                                          zoom: 14,
                                        ),
                                        zoomControlsEnabled:
                                            false, // Sağ alt zoom butonlarını kaldırır
                                        myLocationButtonEnabled:
                                            false, // Sağ alt konum butonunu kaldırır
                                        scrollGesturesEnabled:
                                            false, // Sürükleme kapalı
                                        rotateGesturesEnabled: false,
                                        tiltGesturesEnabled: false,
                                        zoomGesturesEnabled: false,
                                        mapToolbarEnabled:
                                            false, // Sağ üstteki rota ve benzeri araçları kaldırır
                                      ),
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
                          Text(
                            controller.model.value.about,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "Montserrat",
                            ),
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
                                  FirebaseAuth.instance.currentUser!.uid) {
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
                                        child: controller.pfImage.value != ""
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    controller.pfImage.value,
                                                fit: BoxFit.cover)
                                            : Center(
                                                child:
                                                    CupertinoActivityIndicator(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            controller.fullname.value,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          ),
                                          Text(
                                            "Profili Görüntüle",
                                            style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 15,
                                                fontFamily: "Montserrat"),
                                          ),
                                        ],
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
                                FirebaseAuth.instance.currentUser!.uid)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    controller.goToEdit();
                                  },
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      border: Border.all(
                                          color: Colors.grey.withAlpha(50)),
                                    ),
                                    child: Text(
                                      "İlanı Düzenle",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
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
        padding: EdgeInsets.zero, minimumSize: Size(0, 0),
        child: Icon(
          AppIcons.ellipsisVertical,
          color: Colors.black,
        ),
      ),
    );
  }
}
