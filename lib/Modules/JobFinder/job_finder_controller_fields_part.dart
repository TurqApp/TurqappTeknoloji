part of 'job_finder_controller.dart';

class _JobFinderControllerState {
  final jobHomeSnapshotRepository = ensureJobHomeSnapshotRepository();
  final jobRepository = ensureJobRepository();
  final cityDirectoryService = ensureCityDirectoryService();
  final imgList = <String>[
    AppAssets.practice1,
    AppAssets.practice2,
    AppAssets.practice3,
  ];
  final innerTabIndex = 0.obs;
  final innerPageController = PageController();
  final allJobs = <JobModel>[].obs;
  final list = <JobModel>[].obs;
  final aramaSonucu = <JobModel>[].obs;
  final search = TextEditingController();
  final listingSelection = 1.obs;
  final listingSelectionReady = false.obs;
  final sehir = ''.obs;
  final sehirler = <String>[].obs;
  final short = 0.obs;
  final filtre = false.obs;
  final isLoading = true.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final kullaniciSehiri = ''.obs;
  int searchRequestId = 0;
  double? userLat;
  double? userLong;
  Position? lastResolvedPosition;
  StreamSubscription<CachedResource<List<JobModel>>>? homeSnapshotSub;
  Timer? deferredLocationTimer;
  Future<void>? startupPrepareFuture;
  bool primarySurfacePrimedOnce = false;
  bool startupShardHydrated = false;
  int? startupShardAgeMs;
}

extension JobFinderControllerFieldsPart on JobFinderController {
  JobHomeSnapshotRepository get _jobHomeSnapshotRepository =>
      _state.jobHomeSnapshotRepository;
  JobRepository get _jobRepository => _state.jobRepository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  List<String> get imgList => _state.imgList;
  RxInt get innerTabIndex => _state.innerTabIndex;
  PageController get innerPageController => _state.innerPageController;
  RxList<JobModel> get allJobs => _state.allJobs;
  RxList<JobModel> get list => _state.list;
  RxList<JobModel> get aramaSonucu => _state.aramaSonucu;
  TextEditingController get search => _state.search;
  RxInt get listingSelection => _state.listingSelection;
  RxBool get listingSelectionReady => _state.listingSelectionReady;
  RxString get sehir => _state.sehir;
  RxList<String> get sehirler => _state.sehirler;
  RxInt get short => _state.short;
  RxBool get filtre => _state.filtre;
  RxBool get isLoading => _state.isLoading;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
  RxString get kullaniciSehiri => _state.kullaniciSehiri;
  int get _searchRequestId => _state.searchRequestId;
  set _searchRequestId(int value) => _state.searchRequestId = value;
  double? get _userLat => _state.userLat;
  set _userLat(double? value) => _state.userLat = value;
  double? get _userLong => _state.userLong;
  set _userLong(double? value) => _state.userLong = value;
  Position? get _lastResolvedPosition => _state.lastResolvedPosition;
  set _lastResolvedPosition(Position? value) =>
      _state.lastResolvedPosition = value;
  StreamSubscription<CachedResource<List<JobModel>>>? get _homeSnapshotSub =>
      _state.homeSnapshotSub;
  set _homeSnapshotSub(
          StreamSubscription<CachedResource<List<JobModel>>>? value) =>
      _state.homeSnapshotSub = value;
  Timer? get _deferredLocationTimer => _state.deferredLocationTimer;
  set _deferredLocationTimer(Timer? value) =>
      _state.deferredLocationTimer = value;
  Future<void>? get _startupPrepareFuture => _state.startupPrepareFuture;
  set _startupPrepareFuture(Future<void>? value) =>
      _state.startupPrepareFuture = value;
  bool get _primarySurfacePrimedOnce => _state.primarySurfacePrimedOnce;
  set _primarySurfacePrimedOnce(bool value) =>
      _state.primarySurfacePrimedOnce = value;
  bool get _startupShardHydrated => _state.startupShardHydrated;
  set _startupShardHydrated(bool value) => _state.startupShardHydrated = value;
  int? get _startupShardAgeMs => _state.startupShardAgeMs;
  set _startupShardAgeMs(int? value) => _state.startupShardAgeMs = value;
}
