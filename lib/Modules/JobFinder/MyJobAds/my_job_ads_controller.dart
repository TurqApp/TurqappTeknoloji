import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/job_model.dart';

part 'my_job_ads_controller_data_part.dart';
part 'my_job_ads_controller_lifecycle_part.dart';
part 'my_job_ads_controller_actions_part.dart';

class MyJobAdsController extends GetxController {
  static MyJobAdsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyJobAdsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyJobAdsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyJobAdsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyJobAdsController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  final pageController = PageController();
  final isLoadingActive = true.obs;
  final isLoadingDeactive = true.obs;
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  bool _sameJobEntries(List<JobModel> current, List<JobModel> next) {
    final currentKeys = current
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  Future<void> getActive({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getActiveImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> getDeactive({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getDeactiveImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
