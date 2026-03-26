import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SavedPracticeExams/saved_practice_exams_controller.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavlari_controller_data_part.dart';
part 'deneme_sinavlari_controller_facade_part.dart';
part 'deneme_sinavlari_controller_runtime_part.dart';

class DenemeSinavlariController extends GetxController {
  static DenemeSinavlariController ensure({
    bool permanent = false,
  }) =>
      _ensureDenemeSinavlariController(permanent: permanent);

  static DenemeSinavlariController? maybeFind() =>
      _maybeFindDenemeSinavlariController();

  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_practice_exam_listing_selection';
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PracticeExamSnapshotRepository _practiceExamSnapshotRepository =
      PracticeExamSnapshotRepository.ensure();
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  var list = <SinavModel>[].obs;
  var okul = false.obs;
  var showButons = false.obs;
  var ustBar = true.obs;
  var showOkulAlert = false.obs;
  var isLoading = true.obs;
  var isSearchLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  final RxInt listingSelection = 1.obs;
  final RxBool listingSelectionReady = false.obs;
  final ScrollController scrollController = ScrollController();
  double _previousOffset = 0.0;
  final RxDouble scrollOffset = 0.0.obs;
  final RxString searchQuery = ''.obs;
  final RxList<SinavModel> searchResults = <SinavModel>[].obs;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = ReadBudgetRegistry.practiceExamHomeInitialLimit;
  StreamSubscription<CachedResource<List<SinavModel>>>? _homeSnapshotSub;
  Timer? _searchDebounce;
  int _searchToken = 0;

  bool get hasActiveSearch => _hasActivePracticeExamSearch(this);

  @override
  void onInit() {
    super.onInit();
    _handleDenemeSinavlariInit(this);
  }

  @override
  void onClose() {
    _handleDenemeSinavlariClose(this);
    super.onClose();
  }
}
