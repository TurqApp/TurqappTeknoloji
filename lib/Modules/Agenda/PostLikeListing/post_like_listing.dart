import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Agenda/PostLikeListing/PostLikeContent/post_like_content.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import 'post_like_listing_controller.dart';

class PostLikeListing extends StatelessWidget {
  final String postID;
  PostLikeListing({super.key, required this.postID});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PostLikeListingController>(tag: postID)
        ? Get.find<PostLikeListingController>(tag: postID)
        : Get.put(PostLikeListingController(postID: postID), tag: postID);
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxSheetHeight = screenHeight - safeTop - 20;
    final desiredHeight = (screenHeight * 0.52).clamp(320.0, maxSheetHeight);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: desiredHeight,
            margin: EdgeInsets.fromLTRB(10, 10, 10, safeBottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 4,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  header(),
                  const SizedBox(height: 14),
                  TurqSearchBar(
                    controller: controller.searchController,
                    hintText: 'Ara',
                    onChanged: controller.onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() {
                      final items = controller.filteredUsers;
                      if (controller.users.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz beğeni yok',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        );
                      }
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 18),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return PostLikeContent(item: items[index]);
                        },
                      );
                    }),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        12.pw,
        const Text(
          "Beğenme",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: "MontserratBold",
          ),
        ),
        12.pw,
        Expanded(
          child: Divider(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        )
      ],
    );
  }
}
