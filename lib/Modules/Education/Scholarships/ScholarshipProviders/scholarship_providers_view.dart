import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipProviders/scholarship_providers_controller.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class ScholarshipProvidersView extends StatefulWidget {
  ScholarshipProvidersView({super.key});

  @override
  State<ScholarshipProvidersView> createState() =>
      _ScholarshipProvidersViewState();
}

class _ScholarshipProvidersViewState extends State<ScholarshipProvidersView> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final ScholarshipProvidersController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'scholarship_providers_${identityHashCode(this)}';
    final existing = maybeFindScholarshipProvidersController(
      tag: _controllerTag,
    );
    _ownsController = existing == null;
    controller =
        existing ?? ensureScholarshipProvidersController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindScholarshipProvidersController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<ScholarshipProvidersController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "scholarship.providers_title".tr),
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
                                          'scholarship.providers_empty'.tr,
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
                                              if (provider['userID'] ==
                                                  _currentUid) {
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
                                                      child: CachedUserAvatar(
                                                        imageUrl: provider[
                                                            'avatarUrl'],
                                                        radius: 25,
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
