import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/Profile/BlockedUsers/blocked_users_controller.dart';

class BlockedUsers extends StatelessWidget {
  BlockedUsers({super.key});
  final controller = Get.put(BlockedUsersController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Engellenenler"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Obx(() {
                        if (controller.isLoading.value &&
                            controller.blockedUserDetails.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          );
                        }

                        if (controller.blockedUserDetails.isEmpty) {
                          return EmptyRow(text: "Hiç kimseyi engellemedin");
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.blockedUserDetails.length,
                          itemBuilder: (context, index) {
                            final user = controller.blockedUserDetails[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  user.avatarUrl.isNotEmpty
                                      ? ClipOval(
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CachedNetworkImage(
                                              imageUrl: user.avatarUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: Colors.grey.withAlpha(50),
                                              shape: BoxShape.circle),
                                          child: Icon(
                                            CupertinoIcons.person,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "${user.firstName} ${user.lastName}",
                                              style: TextStyle(
                                                fontFamily: "MontserratMedium",
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 3,
                                            ),
                                            RozetContent(
                                                size: 15, userID: user.userID)
                                          ],
                                        ),
                                        Text(
                                          user.nickname,
                                          style: TextStyle(
                                            fontFamily: "MontserratMedium",
                                            fontSize: 15,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      controller.askToUserAndRemoveBlock(
                                          user.userID, user.nickname);
                                    },
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.zero, // dış boşluk yok
                                      minimumSize:
                                          Size(0, 0), // minimum sınır yok
                                      tapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // tıklama alanı küçülür
                                      backgroundColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(50),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(8)),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      child: const Text(
                                        "Engeli Kaldır",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      })
                    ],
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
