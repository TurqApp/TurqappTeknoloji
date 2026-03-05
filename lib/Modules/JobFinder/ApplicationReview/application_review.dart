import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/job_application_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: "Başvuranlar")],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (controller.applicants.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz başvuru yok",
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
                  padding: const EdgeInsets.only(top: 5),
                  itemBuilder: (context, index) {
                    final app = controller.applicants[index];
                    return _applicantCard(app, context);
                  },
                );
              }),
            ),
          ],
        ),
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
        final fetchedNickname = ((profile?['displayName'] ??
                profile?['username'] ??
                profile?['nickname'] ??
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
                        : 'Bilinmeyen Kullanıcı';
        final pfImage = ((profile?['avatarUrl'] ??
                    profile?['pfImage'] ??
                    profile?['photoURL'] ??
                    '') as String)
                .trim()
                .isNotEmpty
            ? ((profile?['avatarUrl'] ??
                    profile?['pfImage'] ??
                    profile?['photoURL'] ??
                    '') as String)
                .trim()
            : app.applicantPfImage;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: pfImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: pfImage, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.withAlpha(30),
                                child: const Icon(CupertinoIcons.person_fill,
                                    color: Colors.grey, size: 20),
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
                              fontFamily: "Montserrat",
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
                // CV preview button
                GestureDetector(
                  onTap: () => _showCvPreview(app.userID, name, context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.doc_text,
                            size: 16, color: Colors.blueAccent),
                        SizedBox(width: 6),
                        Text("CV Görüntüle",
                            style: TextStyle(
                                fontFamily: "MontserratMedium",
                                fontSize: 13,
                                color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Status actions
                Row(
                  children: [
                    if (app.status != 'accepted')
                      _actionButton("Kabul Et", Colors.green, () {
                        controller.updateStatus(app.userID, 'accepted');
                      }),
                    const SizedBox(width: 8),
                    if (app.status != 'reviewing' && app.status != 'accepted')
                      _actionButton("İncele", Colors.blue, () {
                        controller.updateStatus(app.userID, 'reviewing');
                      }),
                    const SizedBox(width: 8),
                    if (app.status != 'rejected')
                      _actionButton("Reddet", Colors.red, () {
                        controller.updateStatus(app.userID, 'rejected');
                      }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: "MontserratMedium",
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reviewing':
        bgColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue;
        break;
      case 'accepted':
        bgColor = Colors.green.withAlpha(25);
        textColor = Colors.green;
        break;
      case 'rejected':
        bgColor = Colors.red.withAlpha(25);
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        JobApplicationModel.statusText(status),
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
      Get.snackbar("CV Bulunamadı", "Bu kullanıcının CV'si mevcut değil",
          snackPosition: SnackPosition.BOTTOM);
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
                Text("E-posta: ${cv['mail']}",
                    style: const TextStyle(
                        fontFamily: "MontserratMedium", fontSize: 13)),
              ],
              if (cv['phone'] != null && cv['phone'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("Telefon: ${cv['phone']}",
                    style: const TextStyle(
                        fontFamily: "MontserratMedium", fontSize: 13)),
              ],
              if (cv['linkedin'] != null &&
                  cv['linkedin'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("LinkedIn: ${cv['linkedin']}",
                    style: const TextStyle(
                        fontFamily: "MontserratMedium",
                        fontSize: 13,
                        color: Colors.blueAccent)),
              ],
              // Schools
              if (cv['okullar'] != null &&
                  (cv['okullar'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Eğitim",
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
                const Text("İş Deneyimi",
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
                const Text("Beceriler",
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
                const Text("Diller",
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
                        Text("${e['languege']} ",
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
}
