import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/ScholarshipApplicationsContentController.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicantProfile extends StatelessWidget {
  final String userID;

  const ApplicantProfile({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ScholarshipApplicationsContentController(userID: userID),
      tag: userID,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: controller.fullName.value),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value ||
                    controller.isDetailsLoading.value) {
                  return Center(child: CupertinoActivityIndicator());
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(controller),
                        24.ph,
                        // Personal Information
                        _buildSectionTitle("Kişisel Bilgiler"),
                        _buildInfoCard([
                          _buildText("Ad Soyad", controller.fullName.value),
                          _buildClickableText(
                            "Mail Adresi",
                            controller.email.value,
                            isEmail: true,
                          ),
                          _buildClickableText(
                            "Telefon Numarası",
                            "+90${(controller.phoneNumber.value)}",
                            isPhone: true,
                          ),
                          _buildText("Ülke", controller.ulke.value),
                          _buildText("Nüfus İl", controller.nufusSehir.value),
                          _buildText("Nüfus İlçe", controller.nufusIlce.value),
                          _buildText(
                              "Doğum Tarihi", controller.dogumTarigi.value),
                          _buildText("Medeni Hal", controller.medeniHal.value),
                          _buildText("Cinsiyet", controller.cinsiyet.value),
                          _buildText(
                              "Engelli Raporu", controller.engelliRaporu.value),
                          _buildText(
                              "Çalışma Durumu", controller.calismaDurumu.value),
                        ]),
                        SizedBox(height: 24),
                        // Education Information
                        _buildSectionTitle("Eğitim Bilgileri"),
                        _buildInfoCard([
                          _buildText(
                              "Eğitim Düzeyi", controller.educationLevel.value),
                          _buildText("Üniversite", controller.universite.value),
                          _buildText("Fakülte", controller.fakulte.value),
                          _buildText("Bölüm", controller.bolum.value),
                        ]),
                        SizedBox(height: 24),
                        // Family Information
                        _buildSectionTitle("Aile Bilgileri"),
                        _buildInfoCard([
                          // Father Information
                          _buildText(
                              "Baba Hayatta mı?", controller.babaHayata.value),
                          if (controller.babaHayata.value.toLowerCase() !=
                              "hayır") ...[
                            _buildText("Baba Adı", controller.babaAdi.value),
                            _buildText(
                                "Baba Soyadı", controller.babaSoyadi.value),
                            _buildClickableText(
                              "Baba Telefon",
                              "+90${(controller.babaPhone.value)}",
                              isPhone: true,
                            ),
                            _buildText("Baba Meslek", controller.babaJob.value),
                            _buildText(
                                "Baba Gelir", controller.babaSalary.value),
                          ],
                          // Mother Information
                          _buildText(
                              "Anne Hayatta mı?", controller.anneHayata.value),
                          if (controller.anneHayata.value.toLowerCase() !=
                              "hayır") ...[
                            _buildText("Anne Adı", controller.anneAdi.value),
                            _buildText(
                                "Anne Soyadı", controller.anneSoyadi.value),
                            _buildClickableText(
                              "Anne Telefon",
                              "+90${(controller.annePhone.value)}",
                              isPhone: true,
                            ),
                            _buildText("Anne Meslek", controller.anneJob.value),
                            _buildText(
                                "Anne Gelir", controller.anneSalary.value),
                          ],
                          _buildText(
                              "Ev Mülkiyeti", controller.evMulkiyeti.value),
                          _buildText(
                              "İkamet Şehir", controller.ikametSehir.value),
                          _buildText(
                              "İkamet İlçe", controller.ikametIlce.value),
                        ]),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      ScholarshipApplicationsContentController controller) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => SocialProfile(userID: controller.userID),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blueAccent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: controller.pfImage.value.isNotEmpty
                        ? Image.network(
                            controller.pfImage.value,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CupertinoActivityIndicator(radius: 12);
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.withAlpha(50),
                                child: Icon(Icons.person, size: 30),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.withAlpha(50),
                            child: Icon(Icons.person, size: 30),
                          ),
                  ),
                ),
                16.pw,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          controller.fullName.value,
                          style: TextStyle(
                            fontFamily: "MontserratBold",
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        4.pw,
                        RozetContent(size: 15, userID: userID)
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "@${controller.nickname.value}",
                      style: TextStyles.tutoringBranch,
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              AppIcons.right,
              size: 22,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "MontserratBold",
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black26,
            width: 1,
          )),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildText(String title, String text) {
    if (text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "MontserratMedium",
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableText(String title, String text,
      {bool isPhone = false, bool isEmail = false}) {
    if (text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "MontserratMedium",
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () async {
                if (isPhone) {
                  final url = 'tel:$text';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    AppSnackbar('Hata', 'Telefon araması başlatılamadı');
                  }
                } else if (isEmail) {
                  final url = Uri.encodeFull('mailto:$text');
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  } else {
                    AppSnackbar('Hata', 'E-posta istemcisi açılamadı');
                  }
                }
              },
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: "MontserratMedium",
                  fontSize: 15,
                  color: Colors.blueAccent.shade400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
