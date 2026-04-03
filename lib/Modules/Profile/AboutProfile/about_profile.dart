import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile_controller.dart';

class AboutProfile extends StatefulWidget {
  final String userID;
  const AboutProfile({super.key, required this.userID});

  @override
  State<AboutProfile> createState() => _AboutProfileState();
}

class _AboutProfileState extends State<AboutProfile> {
  late final AboutProfileController controller;
  late final String _controllerTag;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'about_profile_${widget.userID}_${identityHashCode(this)}';
    final existingController =
        maybeFindAboutProfileController(tag: _controllerTag);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureAboutProfileController(tag: _controllerTag);
      _ownsController = true;
    }
    controller.getUserData(widget.userID);
  }

  @override
  void didUpdateWidget(covariant AboutProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userID != widget.userID) {
      controller.getUserData(widget.userID);
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindAboutProfileController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<AboutProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Widget _buildAboutProfileShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() => _buildAboutProfileContent()),
      ),
    );
  }

  Widget _buildAboutProfileContent() {
    return Column(
      children: [
        BackButtons(text: "about_profile.title".tr),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CachedUserAvatar(
                    userId: widget.userID,
                    imageUrl: controller.avatarUrl.value,
                    radius: 35,
                  ),
                ),
                RozetContent(size: 20, userID: widget.userID)
              ],
            )
          ],
        ),
        SizedBox(
          height: 15,
        ),
        Text(
          controller.nickname.value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        Text(
          controller.fullName.value,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontFamily: "Montserrat",
          ),
        ),
        SizedBox(
          height: 12,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "about_profile.description".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 25,
                color: Colors.black,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.createdDate.value != "")
                      Text(
                        "about_profile.joined_on".trParams(
                          <String, String>{
                            'date': formatTimeStampAyYil(
                              controller.createdDate.value,
                            ),
                          },
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAboutProfileShell(context);
  }
}
