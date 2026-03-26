part of 'family_info_controller.dart';

class _FamilyInfoControllerState {
  final userRepository = UserRepository.ensure();
  final cityDirectoryService = ensureCityDirectoryService();
  final isLoading = true.obs;
  final familyInfo = ''.obs;
  final fatherName = TextEditingController().obs;
  final fatherSurname = TextEditingController().obs;
  final fatherSalary = TextEditingController().obs;
  final fatherPhoneNumber = TextEditingController().obs;
  final fatherLiving = _familyInfoSelectValue.obs;
  final fatherJob = _familyInfoSelectJob.obs;
  final motherName = TextEditingController().obs;
  final motherSurname = TextEditingController().obs;
  final motherSalary = TextEditingController().obs;
  final motherPhoneNumber = TextEditingController().obs;
  final motherLiving = _familyInfoSelectValue.obs;
  final motherJob = _familyInfoSelectJob.obs;
  final totalLiving = TextEditingController().obs;
  final evMulkiyeti = _familyInfoSelectHomeOwnership.obs;
  final city = ''.obs;
  final town = ''.obs;
  final scrollController = ScrollController();
  final evevMulkiyeti = <String>[
    _familyInfoOwnedHome,
    _familyInfoRelativeHome,
    _familyInfoLodgingHome,
    _familyInfoRentHome,
  ].obs;
  final living = <String>[
    _familyInfoYesValue,
    _familyInfoNoValue,
  ].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
}

extension FamilyInfoControllerFieldsPart on FamilyInfoController {
  UserRepository get _userRepository => _state.userRepository;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  RxBool get isLoading => _state.isLoading;
  RxString get familyInfo => _state.familyInfo;
  Rx<TextEditingController> get fatherName => _state.fatherName;
  Rx<TextEditingController> get fatherSurname => _state.fatherSurname;
  Rx<TextEditingController> get fatherSalary => _state.fatherSalary;
  Rx<TextEditingController> get fatherPhoneNumber => _state.fatherPhoneNumber;
  RxString get fatherLiving => _state.fatherLiving;
  RxString get fatherJob => _state.fatherJob;
  Rx<TextEditingController> get motherName => _state.motherName;
  Rx<TextEditingController> get motherSurname => _state.motherSurname;
  Rx<TextEditingController> get motherSalary => _state.motherSalary;
  Rx<TextEditingController> get motherPhoneNumber => _state.motherPhoneNumber;
  RxString get motherLiving => _state.motherLiving;
  RxString get motherJob => _state.motherJob;
  Rx<TextEditingController> get totalLiving => _state.totalLiving;
  RxString get evMulkiyeti => _state.evMulkiyeti;
  RxString get city => _state.city;
  RxString get town => _state.town;
  ScrollController get scrollController => _state.scrollController;
  RxList<String> get evevMulkiyeti => _state.evevMulkiyeti;
  RxList<String> get living => _state.living;
  RxList<String> get sehirler => _state.sehirler;
  RxList<CitiesModel> get sehirlerVeIlcelerData => _state.sehirlerVeIlcelerData;
}
