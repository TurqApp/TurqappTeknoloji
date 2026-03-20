import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'application_review_controller.dart';

class ApplicationReview extends StatelessWidget {
  final String jobDocID;
  final String jobTitle;

  ApplicationReview({
    super.key,
    required this.jobDocID,
    required this.jobTitle,
  });

  late final controller = Get.put(
    ApplicationReviewController(jobDocID: jobDocID),
    tag: jobDocID,
  );

  String _localizedCvLanguage(dynamic rawValue) {
    final raw = (rawValue ?? '').toString().trim();
    switch (raw.toLowerCase()) {
      case 'cv.language.english':
      case 'english':
      case 'ingilizce':
        return 'cv.language.english'.tr;
      case 'cv.language.german':
      case 'german':
      case 'almanca':
        return 'cv.language.german'.tr;
      case 'cv.language.french':
      case 'french':
      case 'fransızca':
      case 'fransizca':
        return 'cv.language.french'.tr;
      case 'cv.language.spanish':
      case 'spanish':
      case 'ispanyolca':
        return 'cv.language.spanish'.tr;
      case 'cv.language.arabic':
      case 'arabic':
      case 'arapça':
      case 'arapca':
        return 'cv.language.arabic'.tr;
      case 'cv.language.turkish':
      case 'turkish':
      case 'türkçe':
      case 'turkce':
        return 'cv.language.turkish'.tr;
      case 'cv.language.russian':
      case 'russian':
      case 'rusça':
      case 'rusca':
        return 'cv.language.russian'.tr;
      case 'cv.language.italian':
      case 'italian':
      case 'italyanca':
        return 'cv.language.italian'.tr;
      case 'cv.language.korean':
      case 'korean':
      case 'korece':
        return 'cv.language.korean'.tr;
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          "pasaj.job_finder.applicants".tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: "MontserratBold",
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value && controller.applicants.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.applicants.isEmpty) {
            return Center(
              child: Text(
                "pasaj.job_finder.no_applicants".tr,
                style: TextStyle(
                  fontFamily: "MontserratMedium",
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: controller.applicants.length,
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
            itemBuilder: (context, index) {
              final app = controller.applicants[index];
              return _applicantCard(app, context);
            },
          );
        }),
      ),
    );
  }

  Widget _applicantCard(JobApplicationModel app, BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: controller.getApplicantProfile(app.userID),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final fetchedName = profile != null
            ? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                .trim()
            : '';
        final fetchedNickname = ((profile?['nickname'] ??
                profile?['username'] ??
                profile?['displayName'] ??
                '') as String)
            .trim();
        final name = fetchedName.isNotEmpty
            ? fetchedName
            : app.applicantName.isNotEmpty
                ? app.applicantName
                : app.applicantNickname.isNotEmpty
                    ? app.applicantNickname
                    : fetchedNickname.isNotEmpty
                        ? fetchedNickname
                        : 'pasaj.job_finder.unknown_user'.tr;
        final avatarUrl = ((profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    '') as String)
                .trim()
                .isNotEmpty
            ? ((profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    profile?['avatarUrl'] ??
                    '') as String)
                .trim()
            : app.applicantPfImage;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Get.to(() => SocialProfile(userID: app.userID)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.withAlpha(30),
                                  child: const Icon(CupertinoIcons.person_fill,
                                      color: Colors.grey, size: 20),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: "MontserratBold",
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            _formatDate(app.timeStamp),
                            style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(app.status),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCvPreview(app.userID, name, context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x14000000)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      CupertinoIcons.doc_text,
                      size: 16,
                      color: Colors.black,
                    ),
                    label: Text(
                      "pasaj.job_finder.view_cv".tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "MontserratBold",
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (app.status == 'pending' || app.status == 'reviewing') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {
                              controller.updateStatus(app.userID, 'rejected');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.withAlpha(120),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'pasaj.job_finder.reject'.tr,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (app.status != 'reviewing') ...[
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.updateStatus(
                                    app.userID, 'reviewing');
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey.withAlpha(120),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'pasaj.job_finder.review'.tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              controller.updateStatus(app.userID, 'accepted');
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'pasaj.job_finder.accept'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = const Color(0xFFEAF2FF);
        textColor = const Color(0xFF2F6FED);
        break;
      case 'accepted':
        bgColor = const Color(0xFFEAF7EE);
        textColor = const Color(0xFF2D8A45);
        break;
      case 'rejected':
        bgColor = const Color(0xFFFCECEC);
        textColor = const Color(0xFFC64242);
        break;
      default:
        bgColor = const Color(0xFFFCF4E4);
        textColor = const Color(0xFFB57911);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }

  void _showCvPreview(String userID, String name, BuildContext context) async {
    final cv = await controller.getApplicantCV(userID);
    if (cv == null) {
      AppSnackbar(
        "pasaj.job_finder.cv_not_found_title".tr,
        "pasaj.job_finder.cv_not_found_body".tr,
      );
      return;
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${cv['firstName'] ?? ''} ${cv['lastName'] ?? ''}",
                style: const TextStyle(
                  fontFamily: "MontserratBold",
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              if ((cv['about'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  cv['about'] ?? '',
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
              if (cv['mail'] != null && cv['mail'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("${'account_center.email'.tr}: ${cv['mail']}",
                    style: const TextStyle(
                        fontFamily: "MontserratMedium", fontSize: 13)),
              ],
              if (cv['phone'] != null && cv['phone'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("${'common.phone'.tr}: ${cv['phone']}",
                    style: const TextStyle(
                        fontFamily: "MontserratMedium", fontSize: 13)),
              ],
              // Schools
              if (cv['okullar'] != null &&
                  (cv['okullar'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("pasaj.job_finder.education".tr,
                    style: TextStyle(
                        fontFamily: "MontserratBold",
                        fontSize: 15,
                        color: Colors.black)),
                const SizedBox(height: 8),
                ...(cv['okullar'] as List).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${e['school']} - ${e['branch']} (${e['lastYear']})",
                      style: const TextStyle(
                          fontFamily: "MontserratMedium", fontSize: 13),
                    ),
                  );
                }),
              ],
              // Experience
              if (cv['deneyim'] != null &&
                  (cv['deneyim'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("pasaj.job_finder.experience".tr,
                    style: TextStyle(
                        fontFamily: "MontserratBold",
                        fontSize: 15,
                        color: Colors.black)),
                const SizedBox(height: 8),
                ...(cv['deneyim'] as List).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${e['position']} - ${e['company']} (${e['year1']}-${e['year2']})",
                          style: const TextStyle(
                              fontFamily: "MontserratMedium", fontSize: 13),
                        ),
                        if ((e['description'] as String?)?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              e['description'],
                              style: TextStyle(
                                  fontFamily: "Montserrat",
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              // Skills
              if (cv['skills'] != null &&
                  (cv['skills'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("pasaj.job_finder.skills".tr,
                    style: TextStyle(
                        fontFamily: "MontserratBold",
                        fontSize: 15,
                        color: Colors.black)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: (cv['skills'] as List).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(s.toString(),
                          style: const TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 12,
                              color: Colors.blueAccent)),
                    );
                  }).toList(),
                ),
              ],
              // Languages
              if (cv['diller'] != null &&
                  (cv['diller'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("pasaj.job_finder.languages".tr,
                    style: TextStyle(
                        fontFamily: "MontserratBold",
                        fontSize: 15,
                        color: Colors.black)),
                const SizedBox(height: 8),
                ...(cv['diller'] as List).map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text("${_localizedCvLanguage(e['languege'])} ",
                            style: const TextStyle(
                                fontFamily: "MontserratMedium", fontSize: 13)),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < (e['level'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: i < (e['level'] ?? 0)
                                      ? Colors.amber
                                      : Colors.grey,
                                  size: 14,
                                )),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'reviewing':
        return 'pasaj.job_finder.status.reviewing'.tr;
      case 'accepted':
        return 'pasaj.job_finder.status.accepted'.tr;
      case 'rejected':
        return 'pasaj.job_finder.status.rejected'.tr;
      default:
        return 'pasaj.job_finder.status.pending'.tr;
    }
  }
}
