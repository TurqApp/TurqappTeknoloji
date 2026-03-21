import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'tutoring_application_review_controller.dart';

class TutoringApplicationReview extends StatefulWidget {
  final String tutoringDocID;
  final String tutoringTitle;

  const TutoringApplicationReview({
    super.key,
    required this.tutoringDocID,
    required this.tutoringTitle,
  });

  @override
  State<TutoringApplicationReview> createState() =>
      _TutoringApplicationReviewState();
}

class _TutoringApplicationReviewState extends State<TutoringApplicationReview> {
  late final TutoringApplicationReviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TutoringApplicationReviewController>(
      tag: widget.tutoringDocID,
    )) {
      controller = Get.find<TutoringApplicationReviewController>(
        tag: widget.tutoringDocID,
      );
      _ownsController = false;
    } else {
      controller = Get.put(
        TutoringApplicationReviewController(
          tutoringDocID: widget.tutoringDocID,
        ),
        tag: widget.tutoringDocID,
      );
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<TutoringApplicationReviewController>(
          tag: widget.tutoringDocID,
        ) &&
        identical(
          Get.find<TutoringApplicationReviewController>(
            tag: widget.tutoringDocID,
          ),
          controller,
        )) {
      Get.delete<TutoringApplicationReviewController>(
        tag: widget.tutoringDocID,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('tutoring.applicants_title'.tr),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.applicants.isEmpty) {
            return Center(
              child: Text(
                'tutoring.no_applications'.tr,
                style: const TextStyle(
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

  Widget _applicantCard(TutoringApplicationModel app, BuildContext context) {
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
                : app.tutorName.isNotEmpty
                    ? app.tutorName
                    : fetchedNickname.isNotEmpty
                        ? fetchedNickname
                : 'common.unknown_user'.tr;
        final avatarUrl = (profile?['avatarUrl'] as String?)?.trim().isNotEmpty ==
                true
            ? (profile?['avatarUrl'] as String).trim()
            : app.tutorImage;

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _fallbackAvatar(),
                              )
                            : _fallbackAvatar(),
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
                          const SizedBox(height: 4),
                          Text(
                            fetchedNickname.isNotEmpty
                                ? '@$fetchedNickname'
                                : 'tutoring.application_label'.tr,
                            style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                const SizedBox(height: 10),
                if (app.status == 'pending' || app.status == 'reviewing') ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => Get.to(
                              () => SocialProfile(userID: app.userID),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.withAlpha(120),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'common.open_profile'.tr,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              'common.reject'.tr,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              'common.accept'.tr,
                              style: const TextStyle(
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
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Get.to(
                        () => SocialProfile(userID: app.userID),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.withAlpha(120),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Profili Aç',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: const Icon(
        CupertinoIcons.person_fill,
        color: Colors.grey,
        size: 20,
      ),
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
        TutoringApplicationModel.statusText(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }
}
