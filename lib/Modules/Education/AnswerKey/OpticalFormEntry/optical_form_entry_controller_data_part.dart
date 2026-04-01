part of 'optical_form_entry_controller_library.dart';

class _OpticalFormEntryControllerState {
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final OpticalFormRepository opticalFormRepository =
      ensureOpticalFormRepository();
  final TextEditingController search = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final RxString searchText = ''.obs;
  final Rx<OpticalFormModel?> model = Rx<OpticalFormModel?>(null);
  final RxString fullName = ''.obs;
  final RxString avatarUrl = ''.obs;
}

class OpticalFormEntryController extends GetxController {
  final _state = _OpticalFormEntryControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}

extension OpticalFormEntryControllerFieldsPart on OpticalFormEntryController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  OpticalFormRepository get _opticalFormRepository =>
      _state.opticalFormRepository;
  TextEditingController get search => _state.search;
  FocusNode get focusNode => _state.focusNode;
  RxString get searchText => _state.searchText;
  Rx<OpticalFormModel?> get model => _state.model;
  RxString get fullName => _state.fullName;
  RxString get avatarUrl => _state.avatarUrl;
}

OpticalFormEntryController ensureOpticalFormEntryController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindOpticalFormEntryController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    OpticalFormEntryController(),
    tag: tag,
    permanent: permanent,
  );
}

OpticalFormEntryController? maybeFindOpticalFormEntryController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<OpticalFormEntryController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<OpticalFormEntryController>(tag: tag);
}

extension OpticalFormEntryControllerDataPart on OpticalFormEntryController {
  void _handleControllerInit() {
    search.addListener(() {
      searchText.value = search.text;
    });
  }

  void _handleControllerClose() {
    search.dispose();
    focusNode.dispose();
  }

  Future<void> searchDocID() async {
    final opticalForm = await _opticalFormRepository.fetchById(search.text);
    if (opticalForm == null) return;

    final bitis = opticalForm.bitis;
    final baslangic = opticalForm.baslangic;
    final userID = opticalForm.userID;

    if (bitis.toInt() > DateTime.now().millisecondsSinceEpoch) {
      focusNode.unfocus();
      model.value = OpticalFormModel(
        docID: opticalForm.docID,
        name: opticalForm.name,
        cevaplar: opticalForm.cevaplar,
        max: opticalForm.max,
        userID: opticalForm.userID,
        baslangic: baslangic,
        bitis: bitis,
        kisitlama: opticalForm.kisitlama,
      );
      await getUserData(userID);
      return;
    }

    focusNode.unfocus();
    showAlertDialog(
      'answer_key.exam_expired_title'.tr,
      'answer_key.exam_expired_body'.tr,
    );
    model.value = null;
  }

  Future<void> getUserData(String userID) async {
    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    fullName.value = data?.displayName.trim() ?? '';
    avatarUrl.value = data?.avatarUrl ?? '';
  }
}
