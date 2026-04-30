import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'tutoring_application_review_controller.dart';

part 'tutoring_application_review_content_part.dart';
part 'tutoring_application_review_actions_part.dart';

class TutoringApplicationReview extends StatefulWidget {
  final String tutoringDocID;
  final String tutoringTitle;

  const TutoringApplicationReview({
    super.key,
    required this.tutoringDocID,
    required this.tutoringTitle,
  });

  @override
  State<TutoringApplicationReview> createState() =>
      _TutoringApplicationReviewState();
}

class _TutoringApplicationReviewState extends State<TutoringApplicationReview> {
  late final TutoringApplicationReviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = maybeFindTutoringApplicationReviewController(
          tag: widget.tutoringDocID,
        ) ==
        null;
    controller = ensureTutoringApplicationReviewController(
      tutoringDocID: widget.tutoringDocID,
      tag: widget.tutoringDocID,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindTutoringApplicationReviewController(
            tag: widget.tutoringDocID,
          ),
          controller,
        )) {
      Get.delete<TutoringApplicationReviewController>(
        tag: widget.tutoringDocID,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }
}
