part of 'personalized_controller.dart';

class _PersonalizedControllerState {
  String? controllerTag;

  final RxList<IndividualScholarshipsModel> list =
      <IndividualScholarshipsModel>[].obs;
  final RxList<IndividualScholarshipsModel> vitrin =
      <IndividualScholarshipsModel>[].obs;

  final RxString ikametSehir = "".obs;
  final RxString nufusSehir = "".obs;
  final RxString ikametIlce = "".obs;
  final RxString nufusIlce = "".obs;
  final RxString locationSehir = "".obs;
  final RxString schoolCity = "".obs;
  final RxString universite = "".obs;
  final RxString ortaokul = "".obs;
  final RxString lise = "".obs;
  final RxString cinsiyet = "".obs;
  final RxBool hasSchoolInfo = false.obs;
  final RxString educationLevel = "".obs;

  final Map<int, String> docIdByTimestamp = <int, String>{};

  final RxBool showSearch = false.obs;
  final RxInt count = 0.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxBool isUserDataLoaded = false.obs;
  final RxBool usedFallback = false.obs;

  final ScrollController scrollController = ScrollController();
}

extension PersonalizedControllerFieldsPart on PersonalizedController {
  String? get controllerTag => _state.controllerTag;
  set controllerTag(String? value) => _state.controllerTag = value;

  RxList<IndividualScholarshipsModel> get list => _state.list;
  RxList<IndividualScholarshipsModel> get vitrin => _state.vitrin;
  RxString get ikametSehir => _state.ikametSehir;
  RxString get nufusSehir => _state.nufusSehir;
  RxString get ikametIlce => _state.ikametIlce;
  RxString get nufusIlce => _state.nufusIlce;
  RxString get locationSehir => _state.locationSehir;
  RxString get schoolCity => _state.schoolCity;
  RxString get universite => _state.universite;
  RxString get ortaokul => _state.ortaokul;
  RxString get lise => _state.lise;
  RxString get cinsiyet => _state.cinsiyet;
  RxBool get hasSchoolInfo => _state.hasSchoolInfo;
  RxString get educationLevel => _state.educationLevel;
  Map<int, String> get docIdByTimestamp => _state.docIdByTimestamp;
  RxBool get showSearch => _state.showSearch;
  RxInt get count => _state.count;
  RxInt get currentIndex => _state.currentIndex;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialLoading => _state.isInitialLoading;
  RxBool get isUserDataLoaded => _state.isUserDataLoaded;
  RxBool get usedFallback => _state.usedFallback;
  ScrollController get scrollController => _state.scrollController;
}
