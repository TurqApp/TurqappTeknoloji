import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Core/Sizes.dart';
import 'package:turqappv2/Models/PostInteractionsModelsNew.dart';
import 'package:turqappv2/Modules/Social/Comments/PostCommentContentController.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Themes/AppColors.dart';
import 'package:turqappv2/Themes/AppFonts.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class PostCommentContent extends StatelessWidget {
  PostCommentContent({super.key, required this.model, required this.postID}) {
    Get.put(
      PostCommentContentController(model: model, postID: postID),
      tag: model.docID,
    );
  }

  final PostCommentModel model;
  final String postID;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostCommentContentController>(tag: model.docID);
    return Obx(() {
      final currentUID = FirebaseAuth.instance.currentUser?.uid;
      final hasLiked =
          currentUID != null && controller.likes.contains(currentUID);
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (model.userID != currentUID) {
                  Get.to(() => SocialProfile(userID: model.userID));
                }
              },
              child: ClipOval(
                child: SizedBox(
                  width: 35,
                  height: 35,
                  child: controller.pfImage.value.isNotEmpty
                      ? Image.network(
                          controller.pfImage.value,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
            12.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (model.userID != currentUID) {
                            Get.to(() => SocialProfile(userID: model.userID));
                          }
                        },
                        child: Text(
                          controller.nickname.value,
                          style: TextStyle(
                            color: AppColors.textBlack,
                            fontSize: FontSizes.size14,
                            fontFamily: AppFontFamilies.mbold,
                          ),
                        ),
                      ),
                      RozetContent(size: 12, userID: model.userID),
                      12.pw,
                      Text(
                        timeAgoMetin(model.timeStamp),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: FontSizes.dateTimeSize,
                        ),
                      ),
                    ],
                  ),
                  4.ph,
                  Text(
                    model.text,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: AppFontFamilies.mregular,
                    ),
                  ),
                  if (model.userID == currentUID)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(4, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showDeleteSheet(context, controller),
                      child: Text(
                        'Sil',
                        style: TextStyle(
                          color: AppColors.deleteText,
                          fontSize: FontSizes.dateTimeSize,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: controller.toggleLike,
              icon: Column(
                children: [
                  Icon(
                    hasLiked
                        ? CupertinoIcons.hand_thumbsup_fill
                        : CupertinoIcons.hand_thumbsup,
                    color: hasLiked ? Colors.blueAccent : Colors.black,
                    size: 20,
                  ),
                  if (controller.likes.isNotEmpty)
                    Text(
                      controller.likes.length.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showDeleteSheet(
      BuildContext context, PostCommentContentController controller) async {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Yorumunu Sil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                model.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await controller.deleteComment();
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Sil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
