import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class ScholarshipApplicationsContent extends StatelessWidget {
  final String userID;

  const ScholarshipApplicationsContent({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ScholarshipApplicationsContentController(userID: userID),
      tag: userID,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.all(15),
            child: CupertinoActivityIndicator(),
          );
        }

        return GestureDetector(
          onTap: () {
            Get.to(() => ApplicantProfile(userID: userID));
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueAccent,
                  width: 1,
                )),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: controller.pfImage.value.isNotEmpty
                        ? Image.network(
                            controller.pfImage.value,
                            fit: BoxFit.cover,
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return CupertinoActivityIndicator(
                                radius: 8,
                              );
                            },
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                color: Colors.grey.withAlpha(50),
                                child: Icon(Icons.person, size: 20),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.withAlpha(50),
                            child: Icon(Icons.person, size: 20),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.fullName.value,
                            style: TextStyles.bold15Black,
                          ),
                          4.pw,
                          RozetContent(size: 13, userID: userID),
                        ],
                      ),
                      Text(
                        controller.nickname.value,
                        style: TextStyles.tutoringBranch,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
