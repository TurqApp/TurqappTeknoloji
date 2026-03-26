import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import '../../Agenda/FloodListing/flood_listing.dart';
import 'liked_posts_controller.dart';

part 'liked_posts_content_part.dart';

class LikedPosts extends StatefulWidget {
  const LikedPosts({super.key});

  @override
  State<LikedPosts> createState() => _LikedPostsState();
}

class _LikedPostsState extends State<LikedPosts> {
  late LikedPostControllers controller;
  bool _ownsController = false;
  late final String _pageLineBarTag =
      '${kLikedPostsPageLineBarTag}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    final existingController = maybeFindLikedPostControllers();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureLikedPostControllers();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindLikedPostControllers(), controller)) {
      Get.delete<LikedPostControllers>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.liked_posts".tr),
            PageLineBar(
              barList: [
                "common.all".tr,
                "saved_posts.posts_tab".tr,
                "saved_posts.series_tab".tr,
              ],
              pageName: _pageLineBarTag,
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                return PageView(
                  controller: controller.pageController,
                  onPageChanged: (v) {
                    syncPageLineBarSelection(_pageLineBarTag, v);
                  },
                  children: [
                    _buildGridTab(
                      posts: controller.likedAll,
                      emptyText: "liked_posts.no_posts".tr,
                    ),
                    _buildGridTab(
                      posts: controller.likedPostsOnly,
                      emptyText: "liked_posts.no_posts".tr,
                    ),
                    _buildGridTab(
                      posts: controller.likedSeries,
                      emptyText: "liked_posts.no_series".tr,
                    ),
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
