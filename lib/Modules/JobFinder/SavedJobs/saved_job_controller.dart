import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_job_controller_data_part.dart';
part 'saved_job_controller_runtime_part.dart';

class SavedJobsController extends GetxController {
  static SavedJobsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedJobsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedJobsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedJobsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedJobsController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;
  static const int _whereInChunkSize = 10;
  Position? _lastResolvedPosition;

  @override
  void onInit() {
    super.onInit();
    unawaited(_handleOnInit());
  }
}
