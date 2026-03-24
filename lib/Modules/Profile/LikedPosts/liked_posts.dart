import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Core/Services/global_video_adapter_pool.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import '../../Agenda/AgendaContent/agenda_content.dart';
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
  final scrollController = ScrollController();
  late final String _pageLineBarTag =
      '${kLikedPostsPageLineBarTag}_${identityHashCode(this)}';

  int _estimatedCenteredIndex() {
    if (!scrollController.hasClients || controller.all.isEmpty) {
      return -1;
    }
    final position = scrollController.position;
    final estimatedItemExtent = (position.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final rawIndex = ((position.pixels + position.viewportDimension * 0.25) /
            estimatedItemExtent)
        .floor();
    return rawIndex.clamp(0, controller.all.length - 1);
  }

  @override
  void initState() {
    super.initState();
    final existingController = LikedPostControllers.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = LikedPostControllers.ensure();
      _ownsController = true;
    }

    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    if (_ownsController &&
        identical(LikedPostControllers.maybeFind(), controller)) {
      Get.delete<LikedPostControllers>(force: true);
    }
    super.dispose();
  }

  void _onScroll() {
    final nextIndex = _estimatedCenteredIndex();
    if (nextIndex < 0) return;
    if (controller.centeredIndex.value != nextIndex) {
      final previousIndex = controller.lastCenteredIndex;
      if (previousIndex != null &&
          previousIndex >= 0 &&
          previousIndex < controller.all.length &&
          previousIndex != nextIndex) {
        controller.disposeAgendaContentController(
          controller.all[previousIndex].docID,
        );
      }
      setState(() {
        controller.centeredIndex.value = nextIndex;
        controller.currentVisibleIndex.value = nextIndex;
        controller.lastCenteredIndex = nextIndex;
        controller.capturePendingCenteredEntry(preferredIndex: nextIndex);
      });
    }
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
                "common.videos".tr,
                "common.photos".tr,
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
                    _buildPostsTab(),
                    _buildVideosTab(),
                    _buildPhotosTab(),
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
