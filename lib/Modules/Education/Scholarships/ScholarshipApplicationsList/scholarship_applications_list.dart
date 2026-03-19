import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsList/scholarship_applications_list_controller.dart';

class ScholarshipApplicationsList extends StatelessWidget {
  final String docID;
  final List<String> basvuranlar;

  const ScholarshipApplicationsList({
    super.key,
    required this.docID,
    required this.basvuranlar,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ScholarshipApplicationsListController(
        docID: docID,
        basvuranlar: basvuranlar,
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(
                text: 'scholarship.applications_title'.trParams({
              'count': '${basvuranlar.length}',
            })),
            Expanded(
              child: basvuranlar.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'scholarship.no_applications'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: controller.onRefresh,
                      child: ListView.builder(
                        itemCount: basvuranlar.length,
                        itemBuilder: (context, index) {
                          return ScholarshipApplicationsContent(
                            userID: basvuranlar[index],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
