import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_circle.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';

part 'story_row_content_part.dart';
part 'story_row_placeholder_part.dart';

class StoryRow extends StatefulWidget {
  const StoryRow({super.key});
  static const double _storyRowHeight = 90;
  static const double _storyRowLeadingPadding = 10;
  static const double _storyRowItemSpacing = 10;

  @override
  State<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends State<StoryRow> {
  late final StoryRowController controller;
  final ScrollController _scrollController = ScrollController();
  bool _ownsController = false;

  StoryInteractionOptimizer get _storyOptimizer =>
      ensureStoryInteractionOptimizer();

  @override
  void initState() {
    super.initState();
    final existingController = maybeFindStoryRowController();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureStoryRowController();
      _ownsController = true;
    }
    _scrollController.addListener(_handleStoryRowScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleStoryRowScroll);
    _scrollController.dispose();
    if (_ownsController &&
        identical(maybeFindStoryRowController(), controller)) {
      Get.delete<StoryRowController>();
    }
    super.dispose();
  }

  void _handleStoryRowScroll() {
    if (!_scrollController.hasClients || controller.users.isEmpty) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0 || position.pixels <= 0) {
      return;
    }
    if (position.extentAfter > 240) {
      return;
    }
    controller.maybeLoadMoreStories(
      visibleIndex: controller.users.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) => _buildStoryRow(context);
}
