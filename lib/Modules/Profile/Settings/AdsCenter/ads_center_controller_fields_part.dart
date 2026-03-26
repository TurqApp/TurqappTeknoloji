part of 'ads_center_controller.dart';

class _AdsCenterControllerState {
  _AdsCenterControllerState({
    AdsRepositoryService? repository,
    AdsDeliveryService? deliveryService,
    AdsTargetingService? targetingService,
    AdsAnalyticsService? analyticsService,
  })  : repository = repository ?? const AdsRepositoryService(),
        deliveryService = deliveryService ?? AdsDeliveryService(),
        targetingService = targetingService ?? const AdsTargetingService(),
        analyticsService = analyticsService ?? const AdsAnalyticsService();

  final AdsRepositoryService repository;
  final AdsDeliveryService deliveryService;
  final AdsTargetingService targetingService;
  final AdsAnalyticsService analyticsService;
  final RxBool canAccess = false.obs;
  final RxBool loading = false.obs;
  final RxnString errorText = RxnString();

  final RxMap<String, dynamic> dashboard = <String, dynamic>{}.obs;
  final RxList<AdCampaign> campaigns = <AdCampaign>[].obs;
  final RxList<AdCreative> creatives = <AdCreative>[].obs;
  final RxList<AdAdvertiser> advertisers = <AdAdvertiser>[].obs;
  final RxList<AdStatsSnapshot> dailyStats = <AdStatsSnapshot>[].obs;
  final RxList<Map<String, dynamic>> deliveryLogs =
      <Map<String, dynamic>>[].obs;

  final Rx<AdDeliveryResult> previewResult = AdDeliveryResult.empty.obs;
  final RxBool previewLoading = false.obs;
  final Rxn<AdCampaignStatus> filterStatus = Rxn<AdCampaignStatus>();
  final Rxn<AdPlacementType> filterPlacement = Rxn<AdPlacementType>();
  final RxBool filterIncludeTest = true.obs;

  StreamSubscription<List<AdCampaign>>? campaignSub;
  StreamSubscription<List<AdCreative>>? creativeSub;
  StreamSubscription<List<AdAdvertiser>>? advertiserSub;
  StreamSubscription<List<AdStatsSnapshot>>? statsSub;
  StreamSubscription<List<Map<String, dynamic>>>? logSub;
}

extension AdsCenterControllerFieldsPart on AdsCenterController {
  AdsRepositoryService get repository => _state.repository;
  AdsDeliveryService get deliveryService => _state.deliveryService;
  AdsTargetingService get targetingService => _state.targetingService;
  AdsAnalyticsService get analyticsService => _state.analyticsService;
  RxBool get canAccess => _state.canAccess;
  RxBool get loading => _state.loading;
  RxnString get errorText => _state.errorText;
  RxMap<String, dynamic> get dashboard => _state.dashboard;
  RxList<AdCampaign> get campaigns => _state.campaigns;
  RxList<AdCreative> get creatives => _state.creatives;
  RxList<AdAdvertiser> get advertisers => _state.advertisers;
  RxList<AdStatsSnapshot> get dailyStats => _state.dailyStats;
  RxList<Map<String, dynamic>> get deliveryLogs => _state.deliveryLogs;
  Rx<AdDeliveryResult> get previewResult => _state.previewResult;
  RxBool get previewLoading => _state.previewLoading;
  Rxn<AdCampaignStatus> get filterStatus => _state.filterStatus;
  Rxn<AdPlacementType> get filterPlacement => _state.filterPlacement;
  RxBool get filterIncludeTest => _state.filterIncludeTest;

  StreamSubscription<List<AdCampaign>>? get _campaignSub => _state.campaignSub;
  set _campaignSub(StreamSubscription<List<AdCampaign>>? value) =>
      _state.campaignSub = value;

  StreamSubscription<List<AdCreative>>? get _creativeSub => _state.creativeSub;
  set _creativeSub(StreamSubscription<List<AdCreative>>? value) =>
      _state.creativeSub = value;

  StreamSubscription<List<AdAdvertiser>>? get _advertiserSub =>
      _state.advertiserSub;
  set _advertiserSub(StreamSubscription<List<AdAdvertiser>>? value) =>
      _state.advertiserSub = value;

  StreamSubscription<List<AdStatsSnapshot>>? get _statsSub => _state.statsSub;
  set _statsSub(StreamSubscription<List<AdStatsSnapshot>>? value) =>
      _state.statsSub = value;

  StreamSubscription<List<Map<String, dynamic>>>? get _logSub => _state.logSub;
  set _logSub(StreamSubscription<List<Map<String, dynamic>>>? value) =>
      _state.logSub = value;
}
