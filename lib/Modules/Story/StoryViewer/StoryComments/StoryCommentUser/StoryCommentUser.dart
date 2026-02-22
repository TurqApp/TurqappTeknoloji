import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/StoryCommentsController.dart';
import '../../../../../Core/RozetContent.dart';
import '../../../../../Models/StoryCommentModel.dart';
import '../../../../SocialProfile/SocialProfile.dart';
import 'StoryCommentUserController.dart';

class StoryCommentUser extends StatelessWidget {
  StoryCommentModel model;
  String storyID;
  bool isMyStory;

  StoryCommentUser(
      {super.key,
      required this.model,
      required this.storyID,
      required this.isMyStory});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryCommentUserController(), tag: model.userID);
    controller.getUserData(model.userID);
    return Obx(() {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey.withAlpha(1)),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (model.userID !=
                          FirebaseAuth.instance.currentUser!.uid) {
                        Get.to(() => SocialProfile(userID: model.userID));
                      }
                    },
                    child: ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: controller.pfImage.value != ""
                            ? CachedNetworkImage(
                                imageUrl: controller.pfImage.value,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (model.userID !=
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  Get.to(() =>
                                      SocialProfile(userID: model.userID));
                                }
                              },
                              child: Text(
                                controller.nickname.value,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: "MontserratBold"),
                              ),
                            ),
                            RozetContent(size: 14, userID: model.userID),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                timeAgoMetin(model.timeStamp),
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium"),
                              ),
                            )
                          ],
                        ),
                        Text(
                          model.metin,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: "MontserratMedium"),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  if (isMyStory ||
                      model.userID == FirebaseAuth.instance.currentUser!.uid)
                    Transform.translate(
                      offset: Offset(0, -10),
                      child: IconButton(
                        onPressed: () {
                          noYesAlert(
                              title: "Sil",
                              message:
                                  "Bu yorumu silmek istediğinizden emin misiniz ?",
                              onYesPressed: () {
                                final store = Get.find<StoryCommentsController>(
                                    tag: storyID);
                                final index = store.list.indexOf(model);
                                store.list.removeAt(index);
                                store.totalComment.value--;
                                FirebaseFirestore.instance
                                    .collection("Stories")
                                    .doc(storyID)
                                    .collection("Yorumlar")
                                    .doc(model.docID)
                                    .delete();
                              });
                        },
                        icon: Icon(CupertinoIcons.trash,
                            color: Colors.black, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        splashRadius: 18,
                      ),
                    )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: SizedBox(
                height: 2,
                child: Divider(
                  color: Colors.grey.withAlpha(20),
                )),
          )
        ],
      );
    });
  }
}
