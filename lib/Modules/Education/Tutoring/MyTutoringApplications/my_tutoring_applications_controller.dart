import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyTutoringApplicationsController extends GetxController {
  static MyTutoringApplicationsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringApplicationsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringApplicationsController? maybeFind({String? tag}) {
    if (!Get.isRegistered<MyTutoringApplicationsController>(tag: tag)) {
      return null;
    }
    return Get.find<MyTutoringApplicationsController>(tag: tag);
  }

  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<TutoringApplicationModel> applications =
      <TutoringApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    final cached = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'myTutoringApplications',
      orderByField: 'timeStamp',
      descending: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applications.value = cached
          .map((doc) => TutoringApplicationModel.fromMap(doc.data, doc.id))
          .toList();
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tutoring:applications:$uid',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(loadApplications(silent: true, forceRefresh: true));
      }
      return;
    }
    await loadApplications();
  }

  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || applications.isEmpty) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myTutoringApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      applications.value = items
          .map((doc) => TutoringApplicationModel.fromMap(doc.data, doc.id))
          .toList();
      SilentRefreshGate.markRefreshed('tutoring:applications:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String tutoringDocID) async {
    try {
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;

      await _tutoringRepository.cancelApplication(
        tutoringId: tutoringDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.tutoringDocID == tutoringDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myTutoringApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.tutoringDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}
  }
}
