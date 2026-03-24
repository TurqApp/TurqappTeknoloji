import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_utils.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'application_review_controller.dart';

part 'application_review_content_part.dart';
part 'application_review_cv_part.dart';

class ApplicationReview extends StatefulWidget {
  final String jobDocID;
  final String jobTitle;

  const ApplicationReview({
    super.key,
    required this.jobDocID,
    required this.jobTitle,
  });

  @override
  State<ApplicationReview> createState() => _ApplicationReviewState();
}

class _ApplicationReviewState extends State<ApplicationReview> {
  late final String _tag;
  late final ApplicationReviewController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _tag =
        'job_application_review_${widget.jobDocID}_${identityHashCode(this)}';
    _ownsController = ApplicationReviewController.maybeFind(tag: _tag) == null;
    controller = ApplicationReviewController.ensure(
      jobDocID: widget.jobDocID,
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          ApplicationReviewController.maybeFind(tag: _tag),
          controller,
        )) {
      Get.delete<ApplicationReviewController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle("pasaj.job_finder.applicants".tr),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value && controller.applicants.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (controller.applicants.isEmpty) {
            return Center(
              child: Text(
                "pasaj.job_finder.no_applicants".tr,
                style: const TextStyle(
                  fontFamily: "MontserratMedium",
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.applicants.length,
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
            itemBuilder: (context, index) {
              final app = controller.applicants[index];
              return _applicantCard(app, context);
            },
          );
        }),
      ),
    );
  }
}
