import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/full_screen_image_viewer.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Services/education_question_bank_navigation_service.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments.dart';
import 'package:turqappv2/Modules/Education/Antreman3/antreman_controller.dart';
import 'package:turqappv2/Modules/Education/Antreman3/Complaint/complaint.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'question_content_shell_part.dart';
part 'question_content_shell_content_part.dart';
part 'question_content_shell_layout_part.dart';
part 'question_content_item_part.dart';

const _antremanLgsType = 'LGS';

class QuestionContent extends StatefulWidget {
  QuestionContent({super.key});

  final AntremanController controller = ensureAntremanController();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final ScrollController _scrollController = ScrollController();

  @override
  State<QuestionContent> createState() => _QuestionContentState();
}

class _QuestionContentState extends State<QuestionContent> {
  late final VoidCallback _scrollListener;

  void _scheduleScreenReEnter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.onScreenReEnter();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollListener = () {
      if (!widget._scrollController.hasClients) return;
      final position = widget._scrollController.position;
      if (position.pixels >= position.maxScrollExtent * 0.8 &&
          widget.controller.loadingProgress.value >= 1.0) {
        widget.controller.fetchMoreQuestions();
      }
    };
    widget._scrollController.addListener(_scrollListener);
    _scheduleScreenReEnter();
  }

  @override
  void didUpdateWidget(covariant QuestionContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget._scrollController, widget._scrollController)) {
      oldWidget._scrollController.removeListener(_scrollListener);
      oldWidget._scrollController.dispose();
      widget._scrollController.addListener(_scrollListener);
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      _scheduleScreenReEnter();
    }
  }

  @override
  void dispose() {
    widget._scrollController.removeListener(_scrollListener);
    widget._scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget._buildPage(context);
}
