import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Sizes.dart';
import 'package:turqappv2/Modules/Social/Comments/PostCommentContent.dart';
import 'package:turqappv2/Modules/Social/Comments/PostCommentController.dart';
import 'package:turqappv2/Themes/AppColors.dart';
import 'package:turqappv2/Themes/AppFonts.dart';

import '../../../Services/FirebaseMyStore.dart';

class PostComments extends StatefulWidget {
  final String postID;
  final String collection;
  final String userID;
  final Function(bool increment)? onCommentCountChange;

  const PostComments({
    super.key,
    required this.postID,
    required this.userID,
    required this.collection,
    this.onCommentCountChange,
  });

  @override
  State<PostComments> createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {
  late final PostCommentController controller;
  final user = Get.find<FirebaseMyStore>();
  final emojis = ["❤️", "🙌🏻", "🔥", "👏🏻", "😎", "👍🏻", "😍", "🥳"];
  final textEditingController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PostCommentController(
        postID: widget.postID,
        userID: widget.userID,
        collection: widget.collection,
        onCommentCountChange: widget.onCommentCountChange,
      ),
      tag: widget.postID,
    );

    focusNode.requestFocus();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // <<< Prevent the layout from resizing when keyboard opens
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Stack(
            children: [
              // Main sheet
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    header(),
                    // Comment list or placeholder
                    Expanded(
                      child: controller.list.isNotEmpty
                          ? ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: controller.list.length,
                              itemBuilder: (ctx, i) => Column(
                                children: [
                                  PostCommentContent(
                                    model: controller.list[i],
                                    postID: widget.postID,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 60, top: 5, bottom: 5),
                                    child: SizedBox(
                                      height: 1,
                                      child: Divider(
                                        color: Colors.grey.withAlpha(20),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.black54,
                                      size: 30,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "İlk yorumu sen yap...",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                        fontFamily: "Montserrat",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Emoji row
                    Container(
                      color: Colors.grey.withAlpha(0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: emojis.map((e) {
                          return GestureDetector(
                            onTap: () {
                              textEditingController.text += e;
                              setState(() {});
                            },
                            child:
                                Text(e, style: const TextStyle(fontSize: 28)),
                          );
                        }).toList(),
                      ),
                    ),

                    // Placeholder for space under the input row
                    const SizedBox(height: 75),
                  ],
                ),
              ),

              inputRow()
            ],
          );
        }),
      ),
    );
  }

  Widget header() {
    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
            ],
          ),
        ),

        // Title
        Text(
          "Yorumlar",
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: FontSizes.size15,
            fontFamily: AppFontFamilies.mbold,
          ),
        ),
      ],
    );
  }

  Widget inputRow() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              child: SizedBox(
                width: 40,
                height: 40,
                child: user.pfImage.value.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.pfImage.value,
                        fit: BoxFit.cover,
                      )
                    : const CupertinoActivityIndicator(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 70),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  inputFormatters: [LengthLimitingTextInputFormatter(280)],
                  decoration: InputDecoration(
                    hintText:
                        "${controller.postUserNickname.value} için yorum ekle..",
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
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            if (textEditingController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.yorumYap(
                    context,
                    textEditingController.text,
                    onComplete: () {
                      textEditingController.clear();
                      setState(() {});
                    },
                  );
                  setState(() {});
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
