part of 'dormitory_info_controller.dart';

class _DormitoryInfoControllerState {
  _DormitoryInfoControllerState({
    required String selectCityValue,
    required String selectDistrictValue,
    required String selectAdminTypeValue,
    required List<String> adminTypes,
  })  : sehir = selectCityValue.obs,
        ilce = selectDistrictValue.obs,
        sub = selectAdminTypeValue.obs,
        subList = adminTypes.obs;

  final UserRepository userRepository = UserRepository.ensure();
  final CityDirectoryService cityDirectoryService =
      ensureCityDirectoryService();
  final EducationReferenceDataService referenceDataService =
      ensureEducationReferenceDataService();
  final RxBool isLoading = true.obs;
  final RxString sehir;
  final RxString ilce;
  final RxString yurt = "".obs;
  final RxString sub;
  final RxBool listedeYok = false.obs;
  final TextEditingController yurtInput = TextEditingController();
  final TextEditingController yurtSelectionController = TextEditingController();
  final RxString yurtInputText = "".obs;
  final RxList<String> subList;
  final RxList<String> sehirler = <String>[].obs;
  final RxList<CitiesModel> sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final RxList<DormitoryModel> yurtList = <DormitoryModel>[].obs;
}

extension DormitoryInfoControllerFieldsPart on DormitoryInfoController {
  UserRepository get _userRepository => _state.userRepository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  EducationReferenceDataService get _referenceDataService =>
      _state.referenceDataService;
  RxBool get isLoading => _state.isLoading;
  RxString get sehir => _state.sehir;
  RxString get ilce => _state.ilce;
  RxString get yurt => _state.yurt;
  RxString get sub => _state.sub;
  RxBool get listedeYok => _state.listedeYok;
  TextEditingController get yurtInput => _state.yurtInput;
  TextEditingController get yurtSelectionController =>
      _state.yurtSelectionController;
  RxString get yurtInputText => _state.yurtInputText;
  RxList<String> get subList => _state.subList;
  RxList<String> get sehirler => _state.sehirler;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
  RxList<DormitoryModel> get yurtList => _state.yurtList;
}
