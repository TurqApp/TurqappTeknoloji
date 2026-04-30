import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/page_line_bar.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart'
    show StoryModel;

part 'deleted_stories_grid_part.dart';
part 'deleted_stories_strip_part.dart';

class DeletedStoriesView extends StatefulWidget {
  const DeletedStoriesView({super.key});

  @override
  State<DeletedStoriesView> createState() => _DeletedStoriesViewState();
}

class _DeletedStoriesViewState extends State<DeletedStoriesView> {
  late final DeletedStoriesController controller;
  late final String _pageLineBarTag =
      '${kDeletedStoriesPageLineBarTag}_${identityHashCode(this)}';
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existingController = maybeFindDeletedStoriesController();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureDeletedStoriesController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindDeletedStoriesController(), controller)) {
      Get.delete<DeletedStoriesController>(force: true);
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
            BackButtons(text: 'story.deleted_stories.title'.tr),
            PageLineBar(
              barList: [
                'story.deleted_stories.tab_deleted'.tr,
                'story.deleted_stories.tab_expired'.tr,
              ],
              pageName: _pageLineBarTag,
              pageController: controller.pageController,
            ),
            Expanded(
              child: Obx(() {
                if (controller.list.isEmpty && controller.isLoading.value) {
                  return const AppStateView.loading(title: '');
                }
                return RefreshIndicator(
                  backgroundColor: Colors.black,
                  color: Colors.white,
                  onRefresh: () => controller.refresh(),
                  child: controller.list.isEmpty
                      ? _EmptyState()
                      : _TabbedContent(
                          controller: controller,
                          pageLineBarTag: _pageLineBarTag,
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeDeletedTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
  if (diff.inHours < 24) return '${diff.inHours}s';
  return '${diff.inDays}g';
}
