part of 'career_profile_controller.dart';

class _CareerProfileControllerState {
  final CvRepository cvRepository = ensureCvRepository();
  final RxBool cvVar = false.obs;
  final RxBool isFindingJob = false.obs;
  final RxBool isLoading = false.obs;
  final RxString fullName = ''.obs;
  final RxString about = ''.obs;
  final RxString meslek = ''.obs;
  final RxString photoUrl = ''.obs;
  final RxList<CVLanguegeModel> languages = <CVLanguegeModel>[].obs;
  final RxList<CVExperinceModel> experiences = <CVExperinceModel>[].obs;
  final RxList<CvSchoolModel> schools = <CvSchoolModel>[].obs;
  final RxList<String> skills = <String>[].obs;
}

extension CareerProfileControllerFieldsPart on CareerProfileController {
  CvRepository get _cvRepository => _state.cvRepository;
  RxBool get cvVar => _state.cvVar;
  RxBool get isFindingJob => _state.isFindingJob;
  RxBool get isLoading => _state.isLoading;
  RxString get fullName => _state.fullName;
  RxString get about => _state.about;
  RxString get meslek => _state.meslek;
  RxString get photoUrl => _state.photoUrl;
  RxList<CVLanguegeModel> get languages => _state.languages;
  RxList<CVExperinceModel> get experiences => _state.experiences;
  RxList<CvSchoolModel> get schools => _state.schools;
  RxList<String> get skills => _state.skills;
}
