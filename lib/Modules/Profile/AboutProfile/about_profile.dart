import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/AboutProfile/about_profile_controller.dart';

class AboutProfile extends StatelessWidget {
  final String userID;
  AboutProfile({super.key, required this.userID});
  final controller = Get.put(AboutProfileController());

  @override
  Widget build(BuildContext context) {
    controller.getUserData(userID);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Column(
            children: [
              BackButtons(text: "Bu Hesap Hakkında"),
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
                      RozetContent(size: 20, userID: userID)
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
                  "Topluluğumuzun güvenilirliğini artırmak için TurqApp'taki hesaplarla ilgili bilgileri şeffaf bir şekilde paylaşıyoruz.",
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
                              "${formatTimeStampAyYil(controller.createdDate.value)} tarihinde katıldı",
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
