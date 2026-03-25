import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';

part 'scholarships_controller_data_part.dart';
part 'scholarships_controller_actions_part.dart';
part 'scholarships_controller_models_part.dart';
part 'scholarships_controller_runtime_part.dart';

class ScholarshipsController extends GetxController {
  static const String _listingSelectionPrefKeyPrefix =
      'scholarship_listing_selection';

  static ScholarshipsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ScholarshipsController(), permanent: permanent);
  }

  static ScholarshipsController? maybeFind() {
    final isRegistered = Get.isRegistered<ScholarshipsController>();
    if (!isRegistered) return null;
    return Get.find<ScholarshipsController>();
  }

  static const int _shortLinkPrefetchLimit = 6;
  static const String _defaultOgImage =
      'https://cdn.turqapp.com/og/default.jpg';

  final FollowRepository _followRepository = FollowRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final ScholarshipSnapshotRepository _scholarshipSnapshotRepository =
      ScholarshipSnapshotRepository.ensure();
  final ScrollController scrollController = ScrollController();
  final RxList<Map<String, dynamic>> allScholarships =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> visibleScholarships =
      <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, bool> likedScholarships = <String, bool>{}.obs;
  final RxMap<String, bool> bookmarkedScholarships = <String, bool>{}.obs;
  final List<RxBool> isExpandedList = [];
  final RxMap<String, bool> followedUsers = <String, bool>{}.obs;
  final RxMap<String, bool> followLoading = <String, bool>{}.obs;
  final Set<String> _likedByCurrentUser = <String>{};
  final Set<String> _bookmarkedByCurrentUser = <String>{};
  final Map<String, String> _shortLinkCache = <String, String>{};
  final Set<String> _shortLinkInFlight = <String>{};
  DateTime? lastRefresh;
  final RxMap<int, RxInt> pageIndices = <int, RxInt>{}.obs;
  final RxDouble scrollOffset = 0.0.obs;
  final RxBool listingSelectionReady = false.obs;
  final RxInt listingSelection = 0.obs;
  final RxBool hasMoreData = true.obs;
  final RxInt totalCount = 0.obs;
  Timer? _searchDebounce;
  final int minSearchLength = 2;
  int _searchRequestToken = 0;
  int _typesensePage = 0;
  StreamSubscription<CachedResource<ScholarshipListingSnapshot>>?
      _homeSnapshotSub;
  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
