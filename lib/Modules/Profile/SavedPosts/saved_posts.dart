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
    if (Get.isRegistered<SavedPostsController>()) {
      controller = Get.find<SavedPostsController>();
    } else {
      controller = Get.put(SavedPostsController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<SavedPostsController>()) {
      Get.delete<SavedPostsController>(force: true);
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
            BackButtons(text: "settings.saved_posts".tr),
            PageLineBar(
                barList: [
                  "common.all".tr,
                  "saved_posts.posts_tab".tr,
                  "saved_posts.series_tab".tr,
                ],
                pageName: _pageLineBarTag,
                pageController: controller.pageController),
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

  Widget _buildAgendaTab({
    required List<PostsModel> posts,
    required String emptyText,
  }) {
    if (controller.isLoading.value && posts.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.grey),
      );
    }
    if (posts.isEmpty) {
      return Center(child: EmptyRow(text: emptyText));
    }

    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: controller.refresh,
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 50),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 0.9,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final model = posts[index];
              final previewUrl = model.hasPlayableVideo
                  ? model.thumbnail
                  : (model.img.isNotEmpty ? model.img.first : '');
              return GestureDetector(
                onTap: () => _openSavedPost(posts, model),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 300,
                        memCacheHeight: 500,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.grey[300]),
                      )
                    else
                      Container(color: Colors.grey[300]),
                    if (model.hasPlayableVideo)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    if (model.floodCount > 1)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(170),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'saved_posts.series_badge'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openSavedPost(List<PostsModel> posts, PostsModel model) {
    if (model.floodCount > 1) {
      Get.to(() => FloodListing(mainModel: model));
      return;
    }
    if (model.hasPlayableVideo) {
      Get.to(() => SingleShortView(startList: posts, startModel: model));
      return;
    }
    Get.to(() => PhotoShorts(fetchedList: posts, startModel: model));
  }
}
