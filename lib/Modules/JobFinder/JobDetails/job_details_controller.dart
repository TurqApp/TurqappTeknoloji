import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_action_tile.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/job_review_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../JobCreator/job_creator.dart';
import '../ApplicationReview/application_review.dart';

part 'job_details_controller_data_part.dart';
part 'job_details_controller_actions_part.dart';

class JobDetailsController extends GetxController {
  static JobDetailsController ensure({
    required JobModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      JobDetailsController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static JobDetailsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<JobDetailsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<JobDetailsController>(tag: tag);
  }

  final Rx<JobModel> model;
  final saved = false.obs;
  final basvuruldu = false.obs;
  final cvVar = false.obs;
  final nickname = ''.obs;
  final avatarUrl = kDefaultAvatarUrl.obs;
  final fullname = ''.obs;
  final RxList<JobModel> list = <JobModel>[].obs;
  final reviews = <JobReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final CvRepository _cvRepository = CvRepository.ensure();
  final JobHomeSnapshotRepository _jobHomeSnapshotRepository =
      JobHomeSnapshotRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  JobDetailsController({required JobModel model}) : model = model.obs;

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  void _handleOnInit() {
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    unawaited(refreshJob());
    unawaited(cvCheck());
    unawaited(getUserData(model.value.userID));
    unawaited(checkSaved(model.value.docID));
    unawaited(checkBasvuru(model.value.docID));
    unawaited(bootstrapSimilar());
    unawaited(bootstrapReviews());
    unawaited(incrementViewCount());
  }
}
