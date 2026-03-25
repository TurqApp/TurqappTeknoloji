part of 'cv_controller.dart';

class _CvControllerState {
  final selection = 0.obs;
  final firstName = TextEditingController(text: '');
  final lastName = TextEditingController(text: '');
  final linkedin = TextEditingController(text: '');
  final mail = TextEditingController(text: '');
  final phoneNumber = TextEditingController(text: '');
  final onYazi = TextEditingController(text: '');
  final okullar = <CvSchoolModel>[].obs;
  final diler = <CVLanguegeModel>[].obs;
  final isDeneyimleri = <CVExperinceModel>[].obs;
  final referanslar = <CVReferenceHumans>[].obs;
  final skills = <String>[].obs;
  final isSaving = false.obs;
  final isUploadingPhoto = false.obs;
  final photoUrl = ''.obs;
}

extension CvControllerFieldsPart on CvController {
  RxInt get selection => _state.selection;
  TextEditingController get firstName => _state.firstName;
  TextEditingController get lastName => _state.lastName;
  TextEditingController get linkedin => _state.linkedin;
  TextEditingController get mail => _state.mail;
  TextEditingController get phoneNumber => _state.phoneNumber;
  TextEditingController get onYazi => _state.onYazi;
  RxList<CvSchoolModel> get okullar => _state.okullar;
  RxList<CVLanguegeModel> get diler => _state.diler;
  RxList<CVExperinceModel> get isDeneyimleri => _state.isDeneyimleri;
  RxList<CVReferenceHumans> get referanslar => _state.referanslar;
  RxList<String> get skills => _state.skills;
  RxBool get isSaving => _state.isSaving;
  RxBool get isUploadingPhoto => _state.isUploadingPhoto;
  RxString get photoUrl => _state.photoUrl;
}
