part of 'personel_info_controller.dart';

class _PersonelInfoControllerState {
  final UserRepository userRepository = UserRepository.ensure();
  final CityDirectoryService cityDirectoryService =
      ensureCityDirectoryService();
  final tc = ''.obs;
  final medeniHal = _single.obs;
  final county = _turkey.obs;
  final cinsiyet = _selectValue.obs;
  final engelliRaporu = _none.obs;
  final calismaDurumu = _notWorking.obs;
  final city = ''.obs;
  final town = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final originalTC = ''.obs;
  final originalMedeniHal = _single.obs;
  final originalCounty = _turkey.obs;
  final originalCinsiyet = _selectValue.obs;
  final originalEngelliRaporu = _none.obs;
  final originalCalismaDurumu = _notWorking.obs;
  final originalCity = ''.obs;
  final originalTown = ''.obs;
  final originalSelectedDate = Rxn<DateTime>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final sehirler = <String>[].obs;
  final medeniHalList = [_single, _married, _divorced];
  final cinsiyetList = [_male, _female];
  final engelliRaporuList = [_hasReport, _none];
  final calismaDurumuList = [_working, _notWorking];
  final countryList = _countryList;
  late final List<FieldConfig> fieldConfigs;
  final animationControllers = <String, AnimationController>{};
  final animationTurns = <String, RxDouble>{};
}

extension PersonelInfoControllerFieldsPart on PersonelInfoController {
  UserRepository get _userRepository => _state.userRepository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  RxString get tc => _state.tc;
  RxString get medeniHal => _state.medeniHal;
  RxString get county => _state.county;
  RxString get cinsiyet => _state.cinsiyet;
  RxString get engelliRaporu => _state.engelliRaporu;
  RxString get calismaDurumu => _state.calismaDurumu;
  RxString get city => _state.city;
  RxString get town => _state.town;
  Rxn<DateTime> get selectedDate => _state.selectedDate;
  RxString get originalTC => _state.originalTC;
  RxString get originalMedeniHal => _state.originalMedeniHal;
  RxString get originalCounty => _state.originalCounty;
  RxString get originalCinsiyet => _state.originalCinsiyet;
  RxString get originalEngelliRaporu => _state.originalEngelliRaporu;
  RxString get originalCalismaDurumu => _state.originalCalismaDurumu;
  RxString get originalCity => _state.originalCity;
  RxString get originalTown => _state.originalTown;
  Rxn<DateTime> get originalSelectedDate => _state.originalSelectedDate;
  RxBool get isLoading => _state.isLoading;
  RxBool get isSaving => _state.isSaving;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
  RxList<String> get sehirler => _state.sehirler;
  List<String> get medeniHalList => _state.medeniHalList;
  List<String> get cinsiyetList => _state.cinsiyetList;
  List<String> get engelliRaporuList => _state.engelliRaporuList;
  List<String> get calismaDurumuList => _state.calismaDurumuList;
  List<String> get countryList => _state.countryList;
  List<FieldConfig> get fieldConfigs => _state.fieldConfigs;
  set fieldConfigs(List<FieldConfig> value) => _state.fieldConfigs = value;
  Map<String, AnimationController> get _animationControllers =>
      _state.animationControllers;
  Map<String, RxDouble> get _animationTurns => _state.animationTurns;
}
