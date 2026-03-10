import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Services/education_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsList/scholarship_applications_list.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scholarship_detail_controller.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

class ScholarshipDetailView extends GetView<ScholarshipDetailController> {
  ScholarshipDetailView({super.key});

  final ScholarshipsController scholarshipsController = Get.put(
    ScholarshipsController(),
  );
  final EducationFeedPostShareService shareService =
      const EducationFeedPostShareService();

  @override
  Widget build(BuildContext context) {
    final ScholarshipDetailController controller =
        Get.find<ScholarshipDetailController>();

    final scholarshipData = Get.arguments as Map<String, dynamic>?;
    if (scholarshipData == null || scholarshipData['model'] == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Hata: Burs verisi bulunamadı.",
            style: TextStyle(fontSize: 16, fontFamily: "MontserratMedium"),
          ),
        ),
      );
    }

    final IndividualScholarshipsModel baseModel =
        scholarshipData['model'] as IndividualScholarshipsModel;
    final String type = 'bireysel';
    final String scholarshipDocId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    final Map<String, dynamic> userData =
        (scholarshipData['userData'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    final userImage = (userData['avatarUrl'] ?? '').toString();
    final userNick = (userData['displayName'] ??
            userData['username'] ??
            userData['nickname'] ??
            'Kullanıcı')
        .toString();
    controller.initializeFollowState(userData['userID']?.toString() ?? '');

    // Yeni ScrollController tanımlıyoruz
    final ScrollController detailScrollController = ScrollController();

    return Obx(() {
      final model = controller.resolvedModel.value ?? baseModel;
      final universityCount = model.universiteler.length;
      if (controller.hiddenUniversityCount.value !=
          (universityCount > 10 ? universityCount - 10 : 0)) {
        controller.hiddenUniversityCount.value =
            universityCount > 10 ? universityCount - 10 : 0;
      }

      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: BackButtons(text: "Burs Detayı")),
                    EducationFeedShareIconButton(
                      onTap: () => shareService.shareScholarship(
                        scholarshipData,
                      ),
                      size: 30,
                      iconSize: 18,
                    ),
                    if (userData['userID']?.toString() ==
                        FirebaseAuth.instance.currentUser?.uid)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 10),
                        child: IconButton(
                          icon: Icon(
                            CupertinoIcons.trash,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            noYesAlert(
                              title: "Bursu Sil",
                              message:
                                  "Bu bursu silmek istediğinizden emin misiniz?",
                              onYesPressed: () async {
                                await controller.deleteScholarship(
                                  scholarshipData['docId'] ??
                                      scholarshipData['scholarshipId'] ??
                                      '',
                                  type,
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      10.pw,
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: detailScrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (model.img.isNotEmpty)
                          Column(
                            children: [
                              model.img2.isNotEmpty
                                  ? Column(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: PageView.builder(
                                            itemCount: 2,
                                            itemBuilder: (context, pageIndex) {
                                              final imageUrl = pageIndex == 0
                                                  ? model.img
                                                  : model.img2;
                                              return CachedNetworkImage(
                                                memCacheHeight: 1000,
                                                imageUrl: imageUrl,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Center(
                                                  child:
                                                      CupertinoActivityIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                            onPageChanged: (pageIndex) {
                                              controller
                                                  .updatePageIndex(pageIndex);
                                            },
                                          ),
                                        ),
                                        8.ph,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              List.generate(2, (dotIndex) {
                                            return Obx(
                                              () => Container(
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: controller
                                                              .currentPageIndex
                                                              .value ==
                                                          dotIndex
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    )
                                  : AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: CachedNetworkImage(
                                        imageUrl: model.img,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: CupertinoActivityIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 40,
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
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: userData['userID']?.toString() !=
                                            FirebaseAuth
                                                .instance.currentUser?.uid
                                        ? () => Get.to(
                                              SocialProfile(
                                                userID: userData['userID']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            )
                                        : null,
                                    child: CircleAvatar(
                                        radius: 15,
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            memCacheHeight: 500,
                                            imageUrl: userImage,
                                            placeholder: (context, url) =>
                                                CupertinoActivityIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                            width: 30,
                                            height: 30,
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                                  ),
                                  8.pw,
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: userData['userID']?.toString() !=
                                              FirebaseAuth
                                                  .instance.currentUser?.uid
                                          ? () => Get.to(
                                                SocialProfile(
                                                  userID: userData['userID']
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              )
                                          : null,
                                      child: Text(
                                        userNick,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: "MontserratBold",
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (userData['userID']?.toString() !=
                                      FirebaseAuth.instance.currentUser?.uid)
                                    RozetContent(
                                      size: 14,
                                      userID:
                                          userData['userID']?.toString() ?? '',
                                    ),
                                  Spacer(),
                                  if (userData['userID']?.toString() !=
                                      FirebaseAuth.instance.currentUser?.uid)
                                    Obx(
                                      () => ScaleTap(
                                        enabled:
                                            !controller.isFollowLoading.value,
                                        onPressed: () async {
                                          final currentUser =
                                              FirebaseAuth.instance.currentUser;
                                          if (currentUser == null) {
                                            AppSnackbar(
                                              "Hata!",
                                              "Lütfen oturum açın.",
                                            );
                                            return;
                                          }
                                          final followedId =
                                              userData['userID']?.toString() ??
                                                  '';
                                          if (followedId.isNotEmpty) {
                                            await controller.toggleFollowStatus(
                                              followedId,
                                            );
                                          } else {
                                            AppSnackbar(
                                              "Hata!",
                                              "Takip edilecek kullanıcı bulunamadı.",
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: controller.isFollowing.value
                                                ? Colors.white
                                                : Colors.black,
                                            border: Border.all(
                                              width: 1,
                                              color: Colors.black,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: controller
                                                  .isFollowLoading.value
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      controller
                                                              .isFollowing.value
                                                          ? Colors.black
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  controller.isFollowing.value
                                                      ? 'Takip Ediyorsun'
                                                      : 'Takip Et',
                                                  style: TextStyle(
                                                    color: controller
                                                            .isFollowing.value
                                                        ? Colors.black
                                                        : Colors.white,
                                                    fontSize: 12,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              16.ph,
                              Text(
                                "${model.baslik} 2025-2026 BURS BAŞVURULARI",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              8.ph,
                              Text(
                                model.aciklama,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                              appDivider(),
                              if (model.basvuruKosullari.isNotEmpty) ...[
                                _buildDetail('Başvuru Koşulları',
                                    model.basvuruKosullari),
                                appDivider(),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "İlan Yayınlanma Tarihi",
                                    style: TextStyles.bold18Black,
                                  ),
                                  Text(
                                    controller.formatTimestamp(model.timeStamp),
                                    style: TextStyles.rBlack16,
                                  ),
                                ],
                              ),
                              appDivider(),
                              _buildDetail(
                                'Başvuru Tarihleri',
                                '${model.baslangicTarihi} - ${model.bitisTarihi}',
                              ),
                              if (model.belgeler.isNotEmpty) ...[
                                appDivider(),
                                _buildDetail(
                                  'Gerekli Belgeler',
                                  model.belgeler.map((e) => '• $e').join('\n'),
                                ),
                              ],
                              if (model.aylar.isNotEmpty) ...[
                                appDivider(),
                                _buildDetail(
                                  'Burs Verilecek Aylar',
                                  model.aylar.map((ay) => '• $ay').join('\n'),
                                ),
                              ],
                              // appDivider(),
                              // _buildDetail(
                              //   'Eğitim Kitlesi',
                              //   '• ${model.egitimKitlesi.isNotEmpty ? model.egitimKitlesi : 'Belirtilmemiş'}',
                              // ),
                              // ...[
                              //   appDivider(),
                              //   _buildDetail(
                              //     'Eğitim Düzeyi',
                              //     model.altEgitimKitlesi.isNotEmpty
                              //         ? '• ${model.altEgitimKitlesi.join('\n• ')}'
                              //         : 'Belirtilmemiş',
                              //   ),
                              // ],
                              if (model.universiteler.isNotEmpty) ...[
                                appDivider(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Üniversiteler',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        if (model.universiteler.length > 10)
                                          Obx(
                                            () => GestureDetector(
                                              onTap: () {
                                                controller
                                                    .toggleUniversityList();
                                                controller.hiddenUniversityCount
                                                    .refresh();
                                              },
                                              child: Text(
                                                controller.showAllUniversities
                                                        .value
                                                    ? 'Daha az göster'
                                                    : 'Tümünü Göster',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    8.ph,
                                    Obx(
                                      () => Text(
                                        controller.showAllUniversities.value
                                            ? model.universiteler
                                                .map((e) => '• $e')
                                                .join('\n')
                                            : model.universiteler
                                                .take(10)
                                                .map((e) => '• $e')
                                                .join('\n'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: "Montserrat",
                                        ),
                                      ),
                                    ),
                                    if (model.universiteler.length > 10)
                                      Obx(
                                        () => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              controller.toggleUniversityList();
                                              controller.hiddenUniversityCount
                                                  .refresh();
                                            },
                                            child: Text(
                                              controller
                                                      .showAllUniversities.value
                                                  ? 'Daha az göster'
                                                  : '+${controller.hiddenUniversityCount.value} üniversite daha',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              ...[
                                appDivider(),
                                _buildDetail(
                                  'Diğer Bilgiler',
                                  '• Mükerrer Durumu: ${model.mukerrerDurumu.isNotEmpty ? model.mukerrerDurumu : 'Belirtilmemiş'}\n'
                                      '• Geri Ödeme Durumu: ${model.geriOdemeli.isNotEmpty ? model.geriOdemeli : 'Belirtilmemiş'}',
                                ),
                              ],
                              ...[
                                appDivider(),
                                _buildDetail(
                                    "Başvuru Nasıl Yapılacak?",
                                    model.basvuruYapilacakYer == 'TurqApp'
                                        ? Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      "Başvurular TurqApp üzerinden ",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "ALINMAKTADIR.",
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      "Başvurular TurqApp üzerinden ",
                                                  style: TextStyle(
                                                    fontFamily: "Montserrat",
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "ALINMAMAKTADIR.",
                                                  style: TextStyle(
                                                    color: Colors.red.shade700,
                                                    fontFamily:
                                                        "MontserratBold",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                              ],
                              appDivider(),
                              Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.black, width: 1)),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: userData['userID']?.toString() !=
                                              FirebaseAuth
                                                  .instance.currentUser?.uid
                                          ? () => Get.to(
                                                SocialProfile(
                                                  userID: userData['userID']
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              )
                                          : null,
                                      child: CircleAvatar(
                                        radius: 35,
                                        child: userImage.isNotEmpty
                                            ? ClipOval(
                                                child: CachedNetworkImage(
                                                  memCacheHeight: 500,
                                                  imageUrl: userImage,
                                                  placeholder: (context, url) =>
                                                      CupertinoActivityIndicator(),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(Icons.error),
                                                  width: 72,
                                                  height: 72,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(Icons.person, size: 36),
                                      ),
                                    ),
                                    12.pw,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${userData['firstName']} ${userData['lastName'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: userData['userID']
                                                          ?.toString() !=
                                                      FirebaseAuth.instance
                                                          .currentUser?.uid
                                                  ? () => Get.to(
                                                        SocialProfile(
                                                          userID: userData[
                                                                      'userID']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                      )
                                                  : null,
                                              child: Text(
                                                userNick,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: "MontserratBold",
                                                ),
                                              ),
                                            ),
                                            RozetContent(
                                              size: 14,
                                              userID: userData['userID']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            String urlString = model.website;

                                            // URL yoksa kullanıcıya bildir
                                            if (urlString.trim().isEmpty) {
                                              AppSnackbar(
                                                "Uyarı!",
                                                "Bu burs için bir başvuru bağlantısı bulunmamaktadır.",
                                              );
                                              return;
                                            }

                                            // Şema ekleme (http/https)
                                            if (!urlString
                                                    .startsWith('http://') &&
                                                !urlString
                                                    .startsWith('https://')) {
                                              urlString = 'https://$urlString';
                                            }

                                            final url = Uri.parse(urlString);

                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              AppSnackbar(
                                                "Hata!",
                                                "Web sitesi açılamadı. Lütfen geçerli bir URL girin.",
                                              );
                                            }
                                          },
                                          child: Text(
                                            'Web sitesini ziyaret et',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontFamily: "Montserrat",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              16.ph,
                              Obx(() {
                                final isLoading = controller.isLoading.value;
                                final isOwnScholarship =
                                    userData['userID']?.toString() ==
                                        FirebaseAuth.instance.currentUser?.uid;

                                // Tarih kontrolü
                                bool isExpired = false;
                                {
                                  if (model.bitisTarihi.isNotEmpty) {
                                    final df = DateFormat('dd.MM.yyyy');
                                    try {
                                      final d = df.parse(model.bitisTarihi);
                                      final endOfDay = DateTime(
                                          d.year, d.month, d.day, 23, 59, 59);
                                      isExpired =
                                          DateTime.now().isAfter(endOfDay);
                                    } catch (e) {
                                      print('Tarih parse hatası: $e');
                                      isExpired = false;
                                    }
                                  }
                                }

                                if (isOwnScholarship) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: AdmobKare(
                                          key: ValueKey('sch-detail-ad-owner'),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: isLoading
                                                  ? null
                                                  : () async {
                                                      final scholarshipId =
                                                          scholarshipDocId;
                                                      if (scholarshipId
                                                          .isEmpty) {
                                                        AppSnackbar(
                                                          'Hata',
                                                          'Burs ID bulunamadı.',
                                                        );
                                                        return;
                                                      }
                                                      List<String> basvuranlar =
                                                          [];
                                                      final doc =
                                                          await ScholarshipFirestorePath
                                                                  .doc(
                                                                      scholarshipId)
                                                              .get();
                                                      if (doc.exists) {
                                                        basvuranlar = List<
                                                            String>.from(doc
                                                                    .data()?[
                                                                'basvurular'] ??
                                                            []);
                                                      }
                                                      Get.to(
                                                        () =>
                                                            ScholarshipApplicationsList(
                                                          docID:
                                                              scholarshipDocId,
                                                          basvuranlar:
                                                              basvuranlar,
                                                        ),
                                                      );
                                                    },
                                              child: Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade900,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: isLoading
                                                    ? CupertinoActivityIndicator()
                                                    : scholarshipDocId.isEmpty
                                                        ? Text(
                                                            "Başvurular (0)",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyles
                                                                .bold16White,
                                                          )
                                                        : FutureBuilder<
                                                            QuerySnapshot>(
                                                            future: ScholarshipFirestorePath
                                                                    .doc(
                                                                        scholarshipDocId)
                                                                .collection(
                                                                    'Basvurular')
                                                                .get(),
                                                            builder:
                                                                (ctx, snap) {
                                                              final count = snap
                                                                      .hasData
                                                                  ? snap
                                                                      .data!
                                                                      .docs
                                                                      .length
                                                                  : 0;
                                                              return Text(
                                                                "Başvurular ($count)",
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyles
                                                                    .bold16White,
                                                              );
                                                            },
                                                          ),
                                              ),
                                            ),
                                          ),
                                          10.pw,
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: isLoading
                                                  ? null
                                                  : () {
                                                      // Ensure fresh controller instance for edit screen
                                                      Get.delete<
                                                              CreateScholarshipController>(
                                                          force: true);
                                                      Get.to(
                                                        () =>
                                                            CreateScholarshipView(),
                                                        arguments: {
                                                          'scholarshipData':
                                                              scholarshipData,
                                                          'scholarshipId':
                                                              scholarshipData[
                                                                  'docId'],
                                                        },
                                                      );
                                                    },
                                              child: Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: isLoading
                                                    ? CupertinoActivityIndicator()
                                                    : Text(
                                                        'Bursu Düzenle',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
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
                                  );
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: AdmobKare(
                                        key: ValueKey('sch-detail-ad-apply'),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap:
                                                isExpired ||
                                                        isLoading ||
                                                        controller
                                                            .allreadyApplied
                                                            .value
                                                    ? null
                                                    : () async {
                                                        if (model.basvuruURL
                                                            .isNotEmpty) {
                                                          String urlString =
                                                              model.basvuruURL;
                                                          if (!urlString
                                                                  .startsWith(
                                                                      'http://') &&
                                                              !urlString.startsWith(
                                                                  'https://')) {
                                                            urlString =
                                                                'https://$urlString';
                                                          }
                                                          final url = Uri.parse(
                                                              urlString);
                                                          if (await canLaunchUrl(
                                                              url)) {
                                                            await launchUrl(
                                                                url);
                                                          } else {
                                                            AppSnackbar("Hata!",
                                                                "Web sitesi açılamadı. Lütfen geçerli bir URL girin.");
                                                          }
                                                        } else {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return Scaffold(
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                body: Center(
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CupertinoActivityIndicator(
                                                                          color:
                                                                              Colors.grey),
                                                                      SizedBox(
                                                                          height:
                                                                              10),
                                                                      Text(
                                                                        "Bilgiler kontrol ediliyor",
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          fontFamily:
                                                                              "MontserratMedium",
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );

                                                          if (controller
                                                              .applyReady
                                                              .value) {
                                                            await controller
                                                                .applyForScholarship(
                                                              scholarshipData[
                                                                      'docId'] ??
                                                                  scholarshipData[
                                                                      'scholarshipId'] ??
                                                                  '',
                                                              type,
                                                            );
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            await controller
                                                                .checkIfUserAlreadyApplied(
                                                                    scholarshipData);
                                                          } else {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            showModalBottomSheet(
                                                              backgroundColor:
                                                                  Colors.white,
                                                              context: context,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .vertical(
                                                                            top:
                                                                                Radius.circular(16)),
                                                              ),
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              20),
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        "Bilgilerin Eksik",
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              18,
                                                                          fontFamily:
                                                                              "MontserratBold",
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              10),
                                                                      Text(
                                                                        "Kişisel, Okul ve Aile bilgilerini doldurmadan burslara başvuru yapamazsınız!",
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              15,
                                                                          fontFamily:
                                                                              "MontserratMedium",
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              20),
                                                                      Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                GestureDetector(
                                                                              onTap: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                              child: Container(
                                                                                height: 50,
                                                                                alignment: Alignment.center,
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.grey.withAlpha(50),
                                                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                                                ),
                                                                                child: Text(
                                                                                  "Vazgeç",
                                                                                  style: TextStyle(
                                                                                    color: Colors.black,
                                                                                    fontSize: 15,
                                                                                    fontFamily: "MontserratBold",
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              width: 12),
                                                                          Expanded(
                                                                            child:
                                                                                GestureDetector(
                                                                              onTap: () async {
                                                                                Navigator.of(context).pop();
                                                                                scholarshipsController.settings(context);
                                                                                controller.checkUserApplicationReadiness();
                                                                              },
                                                                              child: Container(
                                                                                height: 50,
                                                                                alignment: Alignment.center,
                                                                                decoration: BoxDecoration(
                                                                                  color: Colors.black,
                                                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                                                ),
                                                                                child: Text(
                                                                                  "Bilgilerimi Güncelle",
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
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          }
                                                        }
                                                      },
                                            child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isExpired
                                                    ? Colors.red.shade700
                                                    : controller.allreadyApplied
                                                            .value
                                                        ? Colors.grey
                                                        : Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: isLoading
                                                  ? CupertinoActivityIndicator()
                                                  : Text(
                                                      isExpired
                                                          ? 'Başvuru Kapandı'
                                                          : controller
                                                                  .allreadyApplied
                                                                  .value
                                                              ? 'Başvuru Yaptın'
                                                              : 'Başvur',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratBold",
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        if (controller.allreadyApplied.value &&
                                            !isExpired &&
                                            !isOwnScholarship) ...[
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: isLoading
                                                  ? null
                                                  : () {
                                                      noYesAlert(
                                                        title:
                                                            "Başvuruyu İptal Et",
                                                        message:
                                                            "Bu burs başvurusunu iptal etmek istediğinizden emin misiniz?",
                                                        cancelText: "Vazgeç",
                                                        yesText: "İptal Et",
                                                        yesButtonColor:
                                                            CupertinoColors
                                                                .destructiveRed,
                                                        onYesPressed: () async {
                                                          await controller
                                                              .cancelApplication(
                                                            scholarshipData[
                                                                    'docId'] ??
                                                                scholarshipData[
                                                                    'scholarshipId'] ??
                                                                '',
                                                            type,
                                                          );
                                                        },
                                                      );
                                                    },
                                              child: Container(
                                                height: 50,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: isLoading
                                                    ? CupertinoActivityIndicator()
                                                    : Text(
                                                        'Başvuru İptal Et',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontFamily:
                                                              "MontserratBold",
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (controller.detailLoading.value)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ScrollTotopButton(
              scrollController: detailScrollController, // Yeni ScrollController
              visibilityThreshold: 200,
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildDetail(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.bold18Black),
        4.ph,
        value is String ? Text(value, style: TextStyles.rBlack16) : value,
      ],
    );
  }
}
