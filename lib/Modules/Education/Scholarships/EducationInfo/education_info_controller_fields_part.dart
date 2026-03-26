part of 'education_info_controller.dart';

class _EducationInfoControllerState {
  final UserRepository userRepository = UserRepository.ensure();
  final CurrentUserService currentUserService = CurrentUserService.instance;
  final CityDirectoryService cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService referenceDataService =
      EducationReferenceDataService.ensure();
  final RxString selectedEducationLevel = ''.obs;
  final RxString content = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxString selectedCountry = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxString selectedSchool = ''.obs;
  final RxString selectedHighSchool = ''.obs;
  final RxString selectedUniversity = ''.obs;
  final RxString selectedFaculty = ''.obs;
  final RxString selectedDepartment = ''.obs;
  final RxString selectedClassLevel = ''.obs;
  final RxList<String> countries = <String>[].obs;
  final RxList<String> cities = <String>[].obs;
  final RxList<CitiesModel> cityDistrictData = <CitiesModel>[].obs;
  final RxList<MiddleSchoolModel> middleSchools = <MiddleSchoolModel>[].obs;
  final RxList<HighSchoolModel> highSchools = <HighSchoolModel>[].obs;
  final RxList<HigherEducationModel> higherEducations =
      <HigherEducationModel>[].obs;
  final RxBool hasMiddleSchoolData = false.obs;
  final RxBool hasHighSchoolData = false.obs;
  final RxBool hasHigherEducationData = false.obs;
  final Map<String, AnimationController> animationControllers = {};
  final Map<String, RxDouble> animationTurns = {};
}

extension EducationInfoControllerFieldsPart on EducationInfoController {
  UserRepository get _userRepository => _state.userRepository;
  CurrentUserService get _currentUserService => _state.currentUserService;
  CityDirectoryService get _cityDirectoryService => _state.cityDirectoryService;
  EducationReferenceDataService get _referenceDataService =>
      _state.referenceDataService;
  RxString get selectedEducationLevel => _state.selectedEducationLevel;
  RxString get content => _state.content;
  RxBool get isLoading => _state.isLoading;
  RxBool get isInitialLoading => _state.isInitialLoading;
  RxString get selectedCountry => _state.selectedCountry;
  RxString get selectedCity => _state.selectedCity;
  RxString get selectedDistrict => _state.selectedDistrict;
  RxString get selectedSchool => _state.selectedSchool;
  RxString get selectedHighSchool => _state.selectedHighSchool;
  RxString get selectedUniversity => _state.selectedUniversity;
  RxString get selectedFaculty => _state.selectedFaculty;
  RxString get selectedDepartment => _state.selectedDepartment;
  RxString get selectedClassLevel => _state.selectedClassLevel;
  RxList<String> get countries => _state.countries;
  RxList<String> get cities => _state.cities;
  RxList<CitiesModel> get cityDistrictData => _state.cityDistrictData;
  RxList<MiddleSchoolModel> get middleSchools => _state.middleSchools;
  RxList<HighSchoolModel> get highSchools => _state.highSchools;
  RxList<HigherEducationModel> get higherEducations => _state.higherEducations;
  RxBool get hasMiddleSchoolData => _state.hasMiddleSchoolData;
  RxBool get hasHighSchoolData => _state.hasHighSchoolData;
  RxBool get hasHigherEducationData => _state.hasHigherEducationData;
  Map<String, AnimationController> get _animationControllers =>
      _state.animationControllers;
  Map<String, RxDouble> get _animationTurns => _state.animationTurns;
}
