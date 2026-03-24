import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';

import '../../Agenda/FloodListing/flood_listing.dart';

part 'saved_posts_content_part.dart';

class SavedPosts extends StatefulWidget {
  const SavedPosts({super.key});

  @override
  State<SavedPosts> createState() => _SavedPostsState();
}

class _SavedPostsState extends State<SavedPosts> {
  late SavedPostsController controller;
  bool _ownsController = false;
  late final String _pageLineBarTag =
      '${kSavedPostsPageLineBarTag}_${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    final existingController = SavedPostsController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SavedPostsController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(SavedPostsController.maybeFind(), controller)) {
      Get.delete<SavedPostsController>(force: true);
    }
    super.dispose();
  }

  Widget _buildSavedPostsShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "settings.saved_posts".tr),
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
                    _buildAgendaTab(
                      posts: controller.savedAgendas,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedPostsOnly,
                      emptyText: "saved_posts.no_saved_posts".tr,
                    ),
                    _buildAgendaTab(
                      posts: controller.savedSeries,
                      emptyText: "saved_posts.no_saved_series".tr,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSavedPostsShell(context);
  }
}
