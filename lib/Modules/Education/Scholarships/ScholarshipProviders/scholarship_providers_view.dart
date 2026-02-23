import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_controller.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class ScholarshipProvidersView extends StatelessWidget {
  ScholarshipProvidersView({super.key});

  final ScholarshipProvidersController controller = Get.put(
    ScholarshipProvidersController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Burs Verenler"),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => controller.providers.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Burs veren bulunamadı.',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontFamily: 'MontserratMedium',
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: controller.providers.length,
                                        itemBuilder: (context, index) {
                                          final provider =
                                              controller.providers[index];
                                          return GestureDetector(
                                            onTap: () {
                                              final currentUserId = FirebaseAuth
                                                  .instance.currentUser?.uid;
                                              if (provider['userID'] ==
                                                  currentUserId) {
                                                null;
                                              } else {
                                                Get.to(
                                                  () => SocialProfile(
                                                    userID: provider['userID'],
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.grey.withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      25,
                                                    ),
                                                    child: SizedBox(
                                                      width: 50,
                                                      height: 50,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          provider['pfImage']
                                                                  .isNotEmpty
                                                              ? Image.network(
                                                                  provider[
                                                                      'pfImage'],
                                                                  width: 50,
                                                                  height: 50,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  loadingBuilder:
                                                                      (
                                                                    context,
                                                                    child,
                                                                    loadingProgress,
                                                                  ) {
                                                                    if (loadingProgress ==
                                                                        null) {
                                                                      return child;
                                                                    }
                                                                    return CupertinoActivityIndicator();
                                                                  },
                                                                  errorBuilder:
                                                                      (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return SizedBox
                                                                        .shrink();
                                                                  },
                                                                )
                                                              : SizedBox
                                                                  .shrink(),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  12.pw,
                                                  // Nickname
                                                  Text(
                                                    provider['nickname'],
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontFamily:
                                                          'MontserratBold',
                                                    ),
                                                  ),
                                                  // Rozet
                                                  Expanded(
                                                    child: RozetContent(
                                                      size: 16,
                                                      userID:
                                                          provider['userID'],
                                                    ),
                                                  ),
                                                  // Right Arrow
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 8,
                                                    ),
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .right_chevron,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
