import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turqappv2/Core/FullScreenImageViewer.dart';
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Models/Education/QuestionBankModel.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/AntremanCommentsController.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Themes/AppIcons.dart';

class AntremanComments extends StatelessWidget {
  final QuestionBankModel question;

  const AntremanComments({super.key, required this.question});

  Rect getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(
      position.dx + size.width - 100,
      position.dy,
      size.width,
      size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AntremanCommentsController(question));
    final double maxHeight = MediaQuery.of(context).size.height * 0.95;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Yorumlar",
              style: TextStyles.textFieldTitle.copyWith(fontSize: 20),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (controller.comments.isEmpty) {
                  return Center(child: Text("Henüz yorum yok."));
                }
                return ListView.builder(
                  controller: controller.scrollController,
                  itemCount: controller.comments.length,
                  itemBuilder: (context, index) {
                    final comment = controller.comments[index];
                    final GlobalKey commentKey = GlobalKey();
                    final userInfo = controller.userInfoCache[comment.userID] ??
                        {'pfImage': '', 'nickname': 'Bilinmeyen Kullanıcı'};
                    controller.fetchUserInfo(comment.userID);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 10),
                          key: commentKey,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: userInfo['pfImage'].isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        userInfo['pfImage'],
                                      )
                                    : null,
                                child: userInfo['pfImage'].isEmpty
                                    ? Icon(
                                        CupertinoIcons.person,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userInfo['nickname'],
                                          style: TextStyles.bold20Black
                                              .copyWith(fontSize: 14),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          controller.getTimeAgo(
                                            comment.timeStamp,
                                          ),
                                          style: TextStyles.textFieldTitle
                                              .copyWith(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      comment.metin,
                                      style: TextStyles.textFieldTitle.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    if (comment.photoUrl != null)
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(
                                            () => FullScreenImageViewer(
                                              imageUrl: comment.photoUrl!,
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: comment.photoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                CupertinoActivityIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            controller.replyingToCommentDocID
                                                .value = comment.docID;
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            foregroundColor: Colors.grey,
                                          ),
                                          child: Text(
                                            "Yanıtla",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Obx(() {
                                          final replyList = controller
                                                  .replies[comment.docID] ??
                                              [];
                                          if (replyList.isEmpty) {
                                            return SizedBox.shrink();
                                          }
                                          final isVisible =
                                              controller.repliesVisible[
                                                      comment.docID] ??
                                                  false;
                                          return TextButton(
                                            onPressed: () => controller
                                                .toggleRepliesVisibility(
                                              comment.docID,
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              foregroundColor: Colors.grey,
                                            ),
                                            child: Text(
                                              isVisible
                                                  ? "Yanıtları gizle"
                                                  : "${replyList.length} yanıtı gör",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          comment.begeniler.contains(
                                            controller.userID,
                                          )
                                              ? AppIcons.liked
                                              : AppIcons.like,
                                          color: comment.begeniler.contains(
                                            controller.userID,
                                          )
                                              ? Colors.blue
                                              : Colors.black,
                                        ),
                                        onPressed: () =>
                                            controller.toggleLikeComment(
                                          comment.docID,
                                          comment,
                                        ),
                                      ),
                                      Text(
                                        "${comment.begeniler.length}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.ellipsis_vertical,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      final position = getWidgetPosition(
                                        commentKey,
                                      );
                                      if (comment.userID == controller.userID) {
                                        showPullDownButton(
                                            context,
                                            [
                                              PullDownMenuItem(
                                                title: 'Düzenle',
                                                icon:
                                                    CupertinoIcons.create_solid,
                                                iconColor: Colors.black,
                                                onTap: () {
                                                  controller
                                                      .startEditingComment(
                                                    comment.docID,
                                                    comment.metin,
                                                  );
                                                },
                                              ),
                                              PullDownMenuItem(
                                                title: 'Sil',
                                                icon: CupertinoIcons
                                                    .delete_simple,
                                                iconColor: Colors.red,
                                                onTap: () =>
                                                    controller.deleteComment(
                                                  comment.docID,
                                                ),
                                              ),
                                            ],
                                            position);
                                      } else {
                                        showPullDownButton(
                                            context,
                                            [
                                              PullDownMenuItem(
                                                title: 'Şikayet Et',
                                                icon: CupertinoIcons.question,
                                                iconColor: Colors.black,
                                                onTap: null,
                                              ),
                                            ],
                                            position);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final replyList =
                              controller.replies[comment.docID] ?? [];
                          if (replyList.isEmpty) return SizedBox.shrink();
                          final isVisible =
                              controller.repliesVisible[comment.docID] ?? false;
                          if (!isVisible) return SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(left: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: replyList.map((reply) {
                                final GlobalKey replyKey = GlobalKey();
                                final replyUserInfo =
                                    controller.userInfoCache[reply.userID] ??
                                        {
                                          'pfImage': '',
                                          'nickname': 'Bilinmeyen Kullanıcı',
                                        };
                                controller.fetchUserInfo(reply.userID);

                                return Container(
                                  key: replyKey,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundImage:
                                            replyUserInfo['pfImage'].isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    replyUserInfo['pfImage'],
                                                  )
                                                : null,
                                        child: replyUserInfo['pfImage'].isEmpty
                                            ? Icon(
                                                CupertinoIcons.person,
                                                size: 15,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  replyUserInfo['nickname'],
                                                  style: TextStyles
                                                      .textFieldTitle
                                                      .copyWith(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  controller.getTimeAgo(
                                                    reply.timeStamp,
                                                  ),
                                                  style: TextStyles
                                                      .textFieldTitle
                                                      .copyWith(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              reply.metin,
                                              style: TextStyles.textFieldTitle
                                                  .copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                            if (reply.photoUrl != null)
                                              GestureDetector(
                                                onTap: () {
                                                  Get.to(
                                                    () => FullScreenImageViewer(
                                                      imageUrl: reply.photoUrl!,
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: reply.photoUrl!,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context,
                                                              url) =>
                                                          CupertinoActivityIndicator(),
                                                      errorWidget: (
                                                        context,
                                                        url,
                                                        error,
                                                      ) =>
                                                          Icon(
                                                        Icons.error,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  reply.begeniler.contains(
                                                    controller.userID,
                                                  )
                                                      ? CupertinoIcons
                                                          .hand_thumbsup_fill
                                                      : CupertinoIcons
                                                          .hand_thumbsup,
                                                  color:
                                                      reply.begeniler.contains(
                                                    controller.userID,
                                                  )
                                                          ? Colors.blue
                                                          : Colors.black,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    controller.toggleLikeReply(
                                                  comment.docID,
                                                  reply.docID,
                                                  reply,
                                                ),
                                              ),
                                              Text(
                                                "${reply.begeniler.length}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              CupertinoIcons.ellipsis_vertical,
                                              color: Colors.black,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              final position =
                                                  getWidgetPosition(
                                                replyKey,
                                              );
                                              if (reply.userID ==
                                                  controller.userID) {
                                                showPullDownButton(
                                                    context,
                                                    [
                                                      PullDownMenuItem(
                                                        title: 'Düzenle',
                                                        onTap: () {
                                                          controller
                                                              .startEditingReply(
                                                            comment.docID,
                                                            reply.docID,
                                                            reply.metin,
                                                          );
                                                        },
                                                      ),
                                                      PullDownMenuItem(
                                                        title: 'Sil',
                                                        onTap: () => controller
                                                            .deleteReply(
                                                          comment.docID,
                                                          reply.docID,
                                                        ),
                                                      ),
                                                    ],
                                                    position);
                                              } else {
                                                showPullDownButton(
                                                  context,
                                                  [
                                                    PullDownMenuItem(
                                                      title: 'Şikayet Et',
                                                      onTap: null,
                                                    ),
                                                  ],
                                                  position,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              }),
            ),
            Obx(() {
              final userInfo = controller.userInfoCache[controller.userID] ??
                  {'pfImage': '', 'nickname': 'Bilinmeyen Kullanıcı'};
              controller.fetchUserInfo(controller.userID);

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    decoration: BoxDecoration(color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Text("❤️", style: TextStyle(fontSize: 24)),
                        onPressed: () {
                          controller.commentController.text += "❤️";
                        },
                      ),
                      IconButton(
                        icon: Text(
                          "🙌🏻",
                          style: TextStyle(fontSize: 24),
                        ),
                        onPressed: () {
                          controller.commentController.text += "🙌🏻";
                        },
                      ),
                      IconButton(
                        icon: Text("🔥", style: TextStyle(fontSize: 24)),
                        onPressed: () {
                          controller.commentController.text += "🔥";
                        },
                      ),
                      IconButton(
                        icon: Text("😎", style: TextStyle(fontSize: 24)),
                        onPressed: () {
                          controller.commentController.text += "😎";
                        },
                      ),
                      IconButton(
                        icon: Text(
                          "👍🏻",
                          style: TextStyle(fontSize: 24),
                        ),
                        onPressed: () {
                          controller.commentController.text += "👍🏻";
                        },
                      ),
                      IconButton(
                        icon: Text("😍", style: TextStyle(fontSize: 24)),
                        onPressed: () {
                          controller.commentController.text += "😍";
                        },
                      ),
                      IconButton(
                        icon: Text("🥳", style: TextStyle(fontSize: 24)),
                        onPressed: () {
                          controller.commentController.text += "🥳";
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundImage: userInfo['pfImage'].isNotEmpty
                              ? CachedNetworkImageProvider(
                                  userInfo['pfImage'],
                                )
                              : null,
                          child: userInfo['pfImage'].isEmpty
                              ? Icon(CupertinoIcons.person, size: 15)
                              : null,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.replyingToCommentDocID.value
                                      .isNotEmpty ||
                                  controller
                                      .editingCommentDocID.value.isNotEmpty ||
                                  controller.editingReplyDocID.value.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      if (controller.replyingToCommentDocID
                                              .value.isNotEmpty &&
                                          controller.editingCommentDocID.value
                                              .isEmpty &&
                                          controller
                                              .editingReplyDocID.value.isEmpty)
                                        Obx(() {
                                          final replyingComment =
                                              controller.comments.firstWhere(
                                            (c) =>
                                                c.docID ==
                                                controller
                                                    .replyingToCommentDocID
                                                    .value,
                                            orElse: () => Comment(
                                              docID: '',
                                              userID: '',
                                              metin: '',
                                              timeStamp: 0,
                                              begeniler: [],
                                            ),
                                          );
                                          final replyUserInfo =
                                              controller.userInfoCache[
                                                      replyingComment.userID] ??
                                                  {
                                                    'pfImage': '',
                                                    'nickname':
                                                        'Bilinmeyen Kullanıcı',
                                                  };
                                          controller.fetchUserInfo(
                                            replyingComment.userID,
                                          );
                                          return Text(
                                            "${replyUserInfo['nickname']} kişisine yanıt",
                                            style: TextStyles.textFieldTitle
                                                .copyWith(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }),
                                      if (controller.editingCommentDocID.value
                                              .isNotEmpty ||
                                          controller.editingReplyDocID.value
                                              .isNotEmpty)
                                        Text(
                                          "Düzenle",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      Spacer(),
                                      if (controller.editingCommentDocID.value
                                              .isNotEmpty ||
                                          controller.editingReplyDocID.value
                                              .isNotEmpty)
                                        TextButton(
                                          onPressed: () =>
                                              controller.cancelEditing(),
                                          child: Text(
                                            "İptal",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              Obx(() {
                                if (controller.selectedImage.value != null &&
                                    controller
                                        .editingCommentDocID.value.isEmpty &&
                                    controller
                                        .editingReplyDocID.value.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Stack(
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                8,
                                              ),
                                              child: Image.file(
                                                controller.selectedImage.value!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          right: 0,
                                          child: IconButton(
                                            icon: Icon(
                                              CupertinoIcons.xmark,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () => controller
                                                .selectedImage.value = null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              }),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(vertical: 5),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: TextField(
                                        focusNode: controller.focusNode,
                                        controller:
                                            controller.commentController,
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: controller
                                                      .replyingToCommentDocID
                                                      .value
                                                      .isEmpty &&
                                                  controller.editingCommentDocID
                                                      .value.isEmpty &&
                                                  controller.editingReplyDocID
                                                      .value.isEmpty
                                              ? "Yaz.."
                                              : controller.editingCommentDocID
                                                          .value.isNotEmpty ||
                                                      controller
                                                          .editingReplyDocID
                                                          .value
                                                          .isNotEmpty
                                                  ? "Yorumu düzenle"
                                                  : "Yaz..",
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.all(0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    return (controller
                                                .isTextFieldNotEmpty.value ||
                                            controller.selectedImage.value !=
                                                null)
                                        ? IconButton(
                                            icon: Icon(
                                              CupertinoIcons.paperplane_fill,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              if (controller.editingCommentDocID
                                                  .value.isNotEmpty) {
                                                controller.editComment(
                                                  controller.editingCommentDocID
                                                      .value,
                                                  controller
                                                      .commentController.text,
                                                );
                                              } else if (controller
                                                  .editingReplyDocID
                                                  .value
                                                  .isNotEmpty) {
                                                controller.editReply(
                                                  controller
                                                      .replyingToCommentDocID
                                                      .value,
                                                  controller
                                                      .editingReplyDocID.value,
                                                  controller
                                                      .commentController.text,
                                                );
                                              } else if (controller
                                                  .replyingToCommentDocID
                                                  .value
                                                  .isEmpty) {
                                                controller.addComment();
                                              } else {
                                                controller.addReply(
                                                  controller
                                                      .replyingToCommentDocID
                                                      .value,
                                                );
                                              }
                                            },
                                          )
                                        : SizedBox.shrink();
                                  }),
                                  PullDownButton(
                                    itemBuilder: (context) => [
                                      PullDownMenuItem(
                                        title: 'Galeriden Seç',
                                        icon: CupertinoIcons.photo,
                                        onTap: () async {
                                          await controller
                                              .pickImageFromGallery();
                                        },
                                      ),
                                      PullDownMenuItem(
                                        title: 'Fotoğraf Çek',
                                        icon: CupertinoIcons.photo_camera,
                                        onTap: () async {
                                          await controller
                                              .pickImageFromCamera();
                                        },
                                      ),
                                    ],
                                    buttonBuilder: (context, showMenu) =>
                                        IconButton(
                                      icon: Icon(
                                        CupertinoIcons.add_circled,
                                        color: Colors.blue,
                                      ),
                                      onPressed: controller.editingCommentDocID
                                                  .value.isEmpty &&
                                              controller.editingReplyDocID.value
                                                  .isEmpty
                                          ? showMenu
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void showPullDownButton(
    BuildContext context,
    List<PullDownMenuItem> items,
    Rect position,
  ) {
    showPullDownMenu(context: context, items: items, position: position);
  }
}
