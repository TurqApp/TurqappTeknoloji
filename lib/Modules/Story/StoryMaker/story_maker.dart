import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/icon_buttons.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'story_maker_controller.dart';
import 'story_sticker_sheet.dart';
import 'story_video.dart';
import 'text_editor_sheet.dart';

part 'story_maker_canvas_part.dart';
part 'story_maker_controls_part.dart';

class StoryMaker extends StatefulWidget {
  static const Map<String, String> _mediaLookLabels = <String, String>{
    'original': 'story.media_look.original',
    'clear': 'story.media_look.clear',
    'cinema': 'story.media_look.cinema',
    'vibe': 'story.media_look.vibe',
  };
  static const Map<String, IconData> _mediaLookIcons = <String, IconData>{
    'original': CupertinoIcons.circle,
    'clear': CupertinoIcons.sparkles,
    'cinema': CupertinoIcons.film,
    'vibe': CupertinoIcons.sun_max,
  };

  final String initialMediaUrl;
  final bool initialMediaIsVideo;
  final double initialMediaAspectRatio;
  final String initialSourceUserId;
  final String initialSourceDisplayName;

  StoryMaker({
    super.key,
    this.initialMediaUrl = '',
    this.initialMediaIsVideo = false,
    this.initialMediaAspectRatio = 9 / 16,
    this.initialSourceUserId = '',
    this.initialSourceDisplayName = '',
  });

  @override
  State<StoryMaker> createState() => _StoryMakerState();
}

class _StoryMakerState extends State<StoryMaker> {
  late final StoryMakerController controller;
  late final String _controllerTag;

  Map<String, String> get _mediaLookLabels => StoryMaker._mediaLookLabels;
  Map<String, IconData> get _mediaLookIcons => StoryMaker._mediaLookIcons;
  String get initialMediaUrl => widget.initialMediaUrl;
  bool get initialMediaIsVideo => widget.initialMediaIsVideo;
  double get initialMediaAspectRatio => widget.initialMediaAspectRatio;
  String get initialSourceUserId => widget.initialSourceUserId;
  String get initialSourceDisplayName => widget.initialSourceDisplayName;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'story_maker_${identityHashCode(this)}';
    controller = StoryMakerController.maybeFind(tag: _controllerTag) ??
        StoryMakerController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (StoryMakerController.maybeFind(tag: _controllerTag) != null &&
        identical(
          StoryMakerController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<StoryMakerController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.applySharedPostSeedIfNeeded(
      mediaUrl: initialMediaUrl,
      isVideo: initialMediaIsVideo,
      aspectRatio: initialMediaAspectRatio,
      sourceUserId: initialSourceUserId,
      sourceDisplayName: initialSourceDisplayName,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            topBar(),
            Expanded(child: playground()),
            mediaLookTools(),
            bottomTools(context),
          ],
        ),
      ),
    );
  }
}
