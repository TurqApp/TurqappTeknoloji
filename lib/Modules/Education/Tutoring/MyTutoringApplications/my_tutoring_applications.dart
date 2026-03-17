import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'my_tutoring_applications_controller.dart';

class MyTutoringApplications extends StatelessWidget {
  MyTutoringApplications({super.key});
  final controller = Get.put(MyTutoringApplicationsController());

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
        title: const Text(
          'Başvurularım',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => controller.loadApplications(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            children: [
              if (controller.applications.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyRow(text: "Henüz özel ders başvurusu yapmadınız"),
                )
              else
                ...controller.applications.map(_applicationCard),
            ],
          ),
        );
      }),
    );
  }

  Widget _applicationCard(TutoringApplicationModel app) {
    final status = app.status;
    final canCancel = status == 'pending';

    return Container(
      margin: const EdgeInsets.fromLTRB(15, 6, 15, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: app.tutorImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: app.tutorImage,
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
                  app.tutoringTitle.isNotEmpty ? app.tutoringTitle : 'Özel Ders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.tutorName.isNotEmpty ? app.tutorName : 'Eğitmen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statusChip(status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(
                          app.statusUpdatedAt > 0
                              ? app.statusUpdatedAt
                              : app.timeStamp,
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          canCancel
              ? AppHeaderActionButton(
                  onTap: () => _showCancelDialog(app.tutoringDocID),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Color(0xFFB91C1C),
                    size: 18,
                  ),
                )
              : AppHeaderActionButton(
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 18,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: const Icon(
        CupertinoIcons.person_fill,
        color: Colors.grey,
        size: 24,
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
        TutoringApplicationModel.statusText(status),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: "MontserratMedium",
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewing':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return CupertinoIcons.check_mark_circled_solid;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      case 'reviewing':
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.xmark;
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  void _showCancelDialog(String tutoringDocID) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Başvuruyu İptal Et",
          style: TextStyle(fontFamily: "MontserratBold", fontSize: 16),
        ),
        content: const Text(
          "Bu başvuruyu iptal etmek istediğinize emin misiniz?",
          style: TextStyle(fontFamily: "MontserratMedium", fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Vazgeç",
              style: TextStyle(fontFamily: "MontserratMedium"),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelApplication(tutoringDocID);
            },
            child: const Text(
              "İptal Et",
              style: TextStyle(
                color: Colors.red,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
