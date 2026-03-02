import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'my_applications_controller.dart';

class MyApplications extends StatelessWidget {
  MyApplications({super.key});
  final controller = Get.put(MyApplicationsController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (controller.applications.isEmpty) {
        return EmptyRow(text: "Henüz başvuru yapmadınız");
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: controller.applications.length,
        itemBuilder: (context, index) {
          final app = controller.applications[index];
          return _applicationCard(app, context);
        },
      );
    });
  }

  Widget _applicationCard(JobApplicationModel app, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: app.companyLogo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: app.companyLogo,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.withAlpha(30),
                        child: const Icon(CupertinoIcons.building_2_fill,
                            color: Colors.grey, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.jobTitle.isNotEmpty ? app.jobTitle : "İş İlanı",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.companyName,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusChip(app.status),
                      const Spacer(),
                      Text(
                        _formatDate(app.timeStamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (app.status == 'pending')
              IconButton(
                onPressed: () => _showCancelDialog(app.jobDocID, context),
                icon: const Icon(CupertinoIcons.xmark_circle,
                    color: Colors.red, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
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
      default: // pending
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

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  void _showCancelDialog(String jobDocID, BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Başvuruyu İptal Et",
            style: TextStyle(fontFamily: "MontserratBold", fontSize: 16)),
        content: const Text("Bu başvuruyu iptal etmek istediğinize emin misiniz?",
            style: TextStyle(fontFamily: "MontserratMedium", fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Vazgeç",
                style: TextStyle(fontFamily: "MontserratMedium")),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelApplication(jobDocID);
            },
            child: const Text("İptal Et",
                style: TextStyle(
                    color: Colors.red, fontFamily: "MontserratBold")),
          ),
        ],
      ),
    );
  }
}
