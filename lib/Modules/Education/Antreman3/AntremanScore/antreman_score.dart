import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanScore/antreman_score_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_score_content_part.dart';
part 'antreman_score_widgets_part.dart';

class AntremanScore extends StatefulWidget {
  const AntremanScore({super.key});

  @override
  State<AntremanScore> createState() => _AntremanScoreState();
}

class _AntremanScoreState extends State<AntremanScore> {
  late final AntremanScoreController controller;
  final String currentUserID = CurrentUserService.instance.effectiveUserId;
  final ScrollController _scrollController = ScrollController();
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'antreman_score_${identityHashCode(this)}';
    controller = ensureAntremanScoreController(tag: _controllerTag);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final existing = maybeFindAntremanScoreController(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<AntremanScoreController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
