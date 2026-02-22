import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/StoryCommentUser/StoryCommentUser.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/StoryCommentsController.dart';

class StoryComments extends StatelessWidget {
  String storyID;
  String nickname;
  bool isMyStory;

  StoryComments(
      {super.key,
      required this.storyID,
      required this.nickname,
      required this.isMyStory});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
        StoryCommentsController(nickname: nickname, storyID: storyID),
        tag: storyID);
    // Klavye otomatik açılmasın: odak talep etmiyoruz.
    controller.getData();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey.withAlpha(50),
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                Obx(() {
                  return Text(
                    "Yorumlar (${controller.totalComment.value})",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratBold"),
                  );
                }),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey.withAlpha(50),
                  ),
                )
              ],
            ),
          ),
          Obx(() {
            return controller.list.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: controller.list.length,
                      itemBuilder: (context, index) {
                        final model = controller.list[index];
                        return StoryCommentUser(
                          model: model,
                          storyID: storyID,
                          isMyStory: isMyStory,
                        );
                      },
                    ),
                  )
                : Expanded(
                    child: Center(
                    child: EmptyRow(text: "Kimse yorum yapmadı"),
                  ));
          }),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: controller.commentTextfield,
                    focusNode: controller.commentFocus,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    inputFormatters: [LengthLimitingTextInputFormatter(280)],
                    decoration: InputDecoration(
                      hintText: "${controller.nickname} için yorum ekle..",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                      height: 1.8,
                    ),
                    onChanged: (_) {},
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  controller.setComment();
                },
                icon: Icon(CupertinoIcons.arrow_right_circle_fill,
                    color: Colors.black, size: 35),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              )
            ],
          )
        ],
      ),
    );
  }
}
