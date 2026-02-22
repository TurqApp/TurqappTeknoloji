import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Models/OgrenciModel.dart';
import 'SearchUserContentController.dart';

class SearchUserContent extends StatelessWidget {
  final OgrenciModel model;
  final bool isSearch;

  const SearchUserContent({super.key, required this.model, required this.isSearch});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      SearchUserContentController(userID: model.userID),
      tag: model.userID,
      permanent: false,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
          child: GestureDetector(
            onTap: controller.goToProfile,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withAlpha(50)),
                  ),
                  child: ClipOval(
                    child: model.pfImage != ""
                        ? SizedBox(
                      width: 40,
                      height: 40,
                      child: CachedNetworkImage(
                        imageUrl: model.pfImage,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.nickname,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),

                            RozetContent(size: 14, userID: model.userID)
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${model.firstName.trimRight()} ${model.lastName.trimRight()}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isSearch)
                  TextButton(
                    onPressed: controller.removeFromLastSearch,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      minimumSize: const Size(4, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 20,
                      color: Colors.grey,
                    ),
                  )
                else Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.blueAccent,
                  size: 15,
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15, left: 65),
          child: SizedBox(
            height: 1,
            child: Divider(color: Colors.grey.withAlpha(20)),
          ),
        ),
      ],
    );
  }
}
