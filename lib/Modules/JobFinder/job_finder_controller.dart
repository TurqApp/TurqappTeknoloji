import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Repositories/job_home_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_localization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Core/BottomSheets/list_bottom_sheet.dart';
import '../../Models/cities_model.dart';
import '../../Themes/app_assets.dart';

part 'job_finder_controller_data_part.dart';
part 'job_finder_controller_sheet_part.dart';
part 'job_finder_controller_lifecycle_part.dart';
part 'job_finder_controller_support_part.dart';

class JobFinderController extends GetxController {
  static JobFinderController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobFinderController(), permanent: permanent);
  }

  static JobFinderController? maybeFind() {
    final isRegistered = Get.isRegistered<JobFinderController>();
    if (!isRegistered) return null;
    return Get.find<JobFinderController>();
  }

  static const int _fullBootstrapLimit = ReadBudgetRegistry.jobHomeInitialLimit;
  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_job_listing_selection';
  static const String _allTurkeyRaw = 'Tüm Türkiye';

  final JobHomeSnapshotRepository _jobHomeSnapshotRepository =
      JobHomeSnapshotRepository.ensure();
  final JobRepository _jobRepository = JobRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final List<String> imgList = [
    AppAssets.practice1,
    AppAssets.practice2,
    AppAssets.practice3,
  ];

  // Tab management
  final innerTabIndex = 0.obs;
  final innerPageController = PageController();
  List<String> get innerTabTitles => [
        'pasaj.job_finder.tab.explore'.tr,
        'pasaj.job_finder.tab.create'.tr,
        'pasaj.job_finder.tab.applications'.tr,
        'pasaj.job_finder.tab.career_profile'.tr,
      ];

  RxList<JobModel> allJobs = <JobModel>[].obs;
  RxList<JobModel> list = <JobModel>[].obs;
  RxList<JobModel> aramaSonucu = <JobModel>[].obs;

  TextEditingController search = TextEditingController();
  var listingSelection = 1.obs;
  final RxBool listingSelectionReady = false.obs;
  var sehir = "".obs;
  final sehirler = <String>[].obs;
  var short = 0.obs;
  var filtre = false.obs;
  var isLoading = true.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  var kullaniciSehiri = "".obs;
  int _searchRequestId = 0;
  double? _userLat;
  double? _userLong;
  Position? _lastResolvedPosition;
  StreamSubscription<CachedResource<List<JobModel>>>? _homeSnapshotSub;
  Timer? _deferredLocationTimer;

  String get _allTurkeyLabel => 'pasaj.common.all_turkiye'.tr;

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
