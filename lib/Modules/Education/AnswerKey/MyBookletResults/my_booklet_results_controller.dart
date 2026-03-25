import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/optical_form_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/Education/booklet_result_model.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_booklet_results_controller_runtime_part.dart';

class MyBookletResultsController extends GetxController {
  static MyBookletResultsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MyBookletResultsController(), permanent: permanent);
  }

  static MyBookletResultsController? maybeFind() {
    final isRegistered = Get.isRegistered<MyBookletResultsController>();
    if (!isRegistered) return null;
    return Get.find<MyBookletResultsController>();
  }

  final OpticalFormRepository _opticalFormRepository =
      OpticalFormRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <BookletResultModel>[].obs;
  final optikSonuclari = <OpticalFormModel>[].obs;
  final selection = 0.obs;
  final isLoading = true.obs;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapResults());
  }

  void setSelection(int value) {
    selection.value = value;
  }

  Future<void> _bootstrapResults() =>
      MyBookletResultsControllerRuntimePart(this).bootstrapResults();

  Future<void> fetchBookletResults({bool forceRefresh = false}) =>
      MyBookletResultsControllerRuntimePart(this)
          .fetchBookletResults(forceRefresh: forceRefresh);

  /// collectionGroup query ile N+1 problemi çözüldü.
  /// Eski: tüm OptikKodlar çek → her biri için Yanitlar/{uid} oku (N+1)
  /// Yeni: collectionGroup("Yanitlar") ile uid dokümanlarını bul → parent OptikKodlar'ı batch çek
  Future<void> fetchOptikSonuclari({bool forceRefresh = false}) =>
      MyBookletResultsControllerRuntimePart(this)
          .fetchOptikSonuclari(forceRefresh: forceRefresh);

  Future<void> refreshData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      MyBookletResultsControllerRuntimePart(this).refreshData(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  void _assignBookletResults(List<UserSubcollectionEntry> snapshot) =>
      MyBookletResultsControllerRuntimePart(this)
          .assignBookletResults(snapshot);
}
