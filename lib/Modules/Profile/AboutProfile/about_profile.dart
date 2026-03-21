import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
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

  @override
  void initState() {
    super.initState();
    _controllerTag = 'about_profile_${widget.userID}_${identityHashCode(this)}';
    controller = Get.put(AboutProfileController(), tag: _controllerTag);
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
    if (Get.isRegistered<AboutProfileController>(tag: _controllerTag) &&
        identical(
          Get.find<AboutProfileController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<AboutProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Column(
            children: [
              BackButtons(text: "about_profile.title".tr),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipOval(
                        child: SizedBox(
                            width: 70,
                            height: 70,
                            child: controller.avatarUrl.value != ""
                                ? CachedNetworkImage(
                                    imageUrl: controller.avatarUrl.value,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: CupertinoActivityIndicator(
                                      color: Colors.grey,
                                    ),
                                  )),
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
                    fontFamily: "MontserratMedium"),
              ),
              Text(
                controller.fullName.value,
                style: TextStyle(
                    color: Colors.grey, fontSize: 15, fontFamily: "Montserrat"),
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
                      fontFamily: "MontserratMedium"),
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
                                  fontFamily: "MontserratMedium"),
                            )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
