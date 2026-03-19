import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
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
                        _buildSectionTitle(
                          'scholarship.applicant.personal_section'.tr,
                        ),
                        _buildInfoCard([
                          _buildText(
                            'scholarship.applicant.full_name'.tr,
                            controller.fullName.value,
                          ),
                          _buildClickableText(
                            'scholarship.applicant.email'.tr,
                            controller.email.value,
                            isEmail: true,
                          ),
                          _buildClickableText(
                            'scholarship.applicant.phone'.tr,
                            "+90${(controller.phoneNumber.value)}",
                            isPhone: true,
                          ),
                          _buildText(
                            'scholarship.applicant.country'.tr,
                            controller.ulke.value,
                          ),
                          _buildText(
                            'scholarship.applicant.registry_city'.tr,
                            controller.nufusSehir.value,
                          ),
                          _buildText(
                            'scholarship.applicant.registry_district'.tr,
                            controller.nufusIlce.value,
                          ),
                          _buildText(
                            'scholarship.applicant.birth_date'.tr,
                            controller.dogumTarigi.value,
                          ),
                          _buildText(
                            'scholarship.applicant.marital_status'.tr,
                            controller.medeniHal.value,
                          ),
                          _buildText(
                            'scholarship.applicant.gender'.tr,
                            controller.cinsiyet.value,
                          ),
                          _buildText(
                            'scholarship.applicant.disability_report'.tr,
                            controller.engelliRaporu.value,
                          ),
                          _buildText(
                            'scholarship.applicant.employment_status'.tr,
                            controller.calismaDurumu.value,
                          ),
                        ]),
                        SizedBox(height: 24),
                        // Education Information
                        _buildSectionTitle(
                          'scholarship.applicant.education_section'.tr,
                        ),
                        _buildInfoCard([
                          _buildText(
                            'scholarship.applicant.education_level'.tr,
                            controller.educationLevel.value,
                          ),
                          _buildText(
                            'scholarship.applicant.university'.tr,
                            controller.universite.value,
                          ),
                          _buildText(
                            'scholarship.applicant.faculty'.tr,
                            controller.fakulte.value,
                          ),
                          _buildText(
                            'scholarship.applicant.department'.tr,
                            controller.bolum.value,
                          ),
                        ]),
                        SizedBox(height: 24),
                        // Family Information
                        _buildSectionTitle(
                          'scholarship.applicant.family_section'.tr,
                        ),
                        _buildInfoCard([
                          // Father Information
                          _buildText(
                            'scholarship.applicant.father_alive'.tr,
                            controller.babaHayata.value,
                          ),
                          if (controller.babaHayata.value.toLowerCase() !=
                              "hayır") ...[
                            _buildText(
                              'scholarship.applicant.father_name'.tr,
                              controller.babaAdi.value,
                            ),
                            _buildText(
                              'scholarship.applicant.father_surname'.tr,
                              controller.babaSoyadi.value,
                            ),
                            _buildClickableText(
                              'scholarship.applicant.father_phone'.tr,
                              "+90${(controller.babaPhone.value)}",
                              isPhone: true,
                            ),
                            _buildText(
                              'scholarship.applicant.father_job'.tr,
                              controller.babaJob.value,
                            ),
                            _buildText(
                              'scholarship.applicant.father_income'.tr,
                              controller.babaSalary.value,
                            ),
                          ],
                          // Mother Information
                          _buildText(
                            'scholarship.applicant.mother_alive'.tr,
                            controller.anneHayata.value,
                          ),
                          if (controller.anneHayata.value.toLowerCase() !=
                              "hayır") ...[
                            _buildText(
                              'scholarship.applicant.mother_name'.tr,
                              controller.anneAdi.value,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_surname'.tr,
                              controller.anneSoyadi.value,
                            ),
                            _buildClickableText(
                              'scholarship.applicant.mother_phone'.tr,
                              "+90${(controller.annePhone.value)}",
                              isPhone: true,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_job'.tr,
                              controller.anneJob.value,
                            ),
                            _buildText(
                              'scholarship.applicant.mother_income'.tr,
                              controller.anneSalary.value,
                            ),
                          ],
                          _buildText(
                            'scholarship.applicant.home_ownership'.tr,
                            controller.evMulkiyeti.value,
                          ),
                          _buildText(
                            'scholarship.applicant.residence_city'.tr,
                            controller.ikametSehir.value,
                          ),
                          _buildText(
                            'scholarship.applicant.residence_district'.tr,
                            controller.ikametIlce.value,
                          ),
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
            color: Colors.black,
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
                    child: controller.avatarUrl.value.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: controller.avatarUrl.value,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CupertinoActivityIndicator(radius: 12),
                            errorWidget: (context, url, error) {
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
              color: Colors.black,
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
                    AppSnackbar(
                      'common.error'.tr,
                      'scholarship.applicant.phone_open_failed'.tr,
                    );
                  }
                } else if (isEmail) {
                  final url = Uri.encodeFull('mailto:$text');
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  } else {
                    AppSnackbar(
                      'common.error'.tr,
                      'scholarship.applicant.email_open_failed'.tr,
                    );
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
