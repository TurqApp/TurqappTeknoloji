import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';

part 'story_circle_content_part.dart';
part 'story_circle_painter_part.dart';

class StoryCircle extends StatefulWidget {
  final StoryUserModel model;
  final List<StoryUserModel> users;
  final bool isFirst;

  StoryCircle({
    super.key,
    required this.model,
    required this.users,
    this.isFirst = false,
  });

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle> {
  final userService = CurrentUserService.instance;
  StoryInteractionOptimizer get _storyOptimizer => StoryInteractionOptimizer.to;
  static const double _storyCircleSize = 74;
  static const double _storyAvatarRadius = 37;
  static const double _labelWidth = 78;
  static const double _addBadgeSize = 18;

  String get _currentUid => userService.effectiveUserId;

  @override
  Widget build(BuildContext context) => _buildStoryCircle(context);
}
