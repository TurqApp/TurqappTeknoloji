import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/scholarship_applications_content_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_navigation_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class ScholarshipApplicationsContent extends StatefulWidget {
  final String userID;

  const ScholarshipApplicationsContent({super.key, required this.userID});

  @override
  State<ScholarshipApplicationsContent> createState() =>
      _ScholarshipApplicationsContentState();
}

class _ScholarshipApplicationsContentState
    extends State<ScholarshipApplicationsContent> {
  late final ScholarshipApplicationsContentController controller;
  late final String _controllerTag;
  late final bool _ownsController;

  String get userID => widget.userID;

  @override
  void initState() {
    super.initState();
    _controllerTag =
        'scholarship_application_tile_${widget.userID}_${identityHashCode(this)}';
    final existing = maybeFindScholarshipApplicationsContentController(
      tag: _controllerTag,
    );
    _ownsController = existing == null;
    controller = existing ??
        ensureScholarshipApplicationsContentController(
          tag: _controllerTag,
          userID: widget.userID,
        );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindScholarshipApplicationsContentController(
              tag: _controllerTag),
          controller,
        )) {
      Get.delete<ScholarshipApplicationsContentController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(15),
            child: AppStateView.loading(),
          );
        }

        return GestureDetector(
          onTap: () {
            ScholarshipNavigationService.openApplicantProfile(userID);
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                )),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CachedUserAvatar(
                    userId: userID,
                    imageUrl: controller.avatarUrl.value,
                    radius: 25,
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
                  color: Colors.black,
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
