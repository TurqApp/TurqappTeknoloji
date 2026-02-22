import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Modules/Social/PostSharers/PostSharersController.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';

class PostSharers extends StatelessWidget {
  final String postID;

  const PostSharers({super.key, required this.postID});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostSharersController(postID: postID));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                BackButtons(text: "Gönderi olarak paylaşanlar"),
              ],
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                }

                if (controller.postSharers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.share,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Henüz kimse bu gönderiyi paylaşmamış",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.postSharers.length,
                  separatorBuilder: (context, index) => Divider(
                    indent: 10,
                    endIndent: 10,
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final sharer = controller.postSharers[index];
                    final userData = controller.usersData[sharer.userID];

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Get.to(() => SocialProfile(userID: sharer.userID));
                        },
                        child: ClipOval(
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: userData?['pfImageUrl'] != null &&
                                    userData!['pfImageUrl'].isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: userData['pfImageUrl'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        CupertinoIcons.person_fill,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        CupertinoIcons.person_fill,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      CupertinoIcons.person_fill,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          Get.to(() => SocialProfile(userID: sharer.userID));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userData?['fullName'] ??
                                      'Bilinmeyen Kullanıcı',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                Text(
                                  timeAgoMetin(sharer.timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '@${userData?['nickname'] ?? 'Bilinmeyen Kullanıcı'}',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 15,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
