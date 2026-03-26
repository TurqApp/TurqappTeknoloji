part of 'become_verified_account_controller.dart';

class _BecomeVerifiedAccountControllerState {
  final verifiedAccountRepository = ensureVerifiedAccountRepository();
  final aciklamaText = ''.obs;
  final canSubmitApplication = false.obs;
  final isSubmitting = false.obs;
  final hasAcceptedConsent = false.obs;
  final existingApplicationStatus = ''.obs;
  final selected = Rx<VerifiedAccountModel?>(null);
  final selectedColor = '2196F3'.obs;
  final selectedInt = 0.obs;
  final bodySelection = 0.obs;
  final instagram = TextEditingController();
  final twitter = TextEditingController();
  final linkedin = TextEditingController();
  final tiktok = TextEditingController();
  final youtube = TextEditingController();
  final website = TextEditingController();
  final nickname = TextEditingController();
  final aciklama = TextEditingController();
  final eDevletBarcodeNo = TextEditingController();
  final show = false.obs;
}

extension BecomeVerifiedAccountControllerFieldsPart
    on BecomeVerifiedAccountController {
  VerifiedAccountRepository get _verifiedAccountRepository =>
      _state.verifiedAccountRepository;
  RxString get aciklamaText => _state.aciklamaText;
  RxBool get canSubmitApplication => _state.canSubmitApplication;
  RxBool get isSubmitting => _state.isSubmitting;
  RxBool get hasAcceptedConsent => _state.hasAcceptedConsent;
  RxString get existingApplicationStatus => _state.existingApplicationStatus;
  Rx<VerifiedAccountModel?> get selected => _state.selected;
  RxString get selectedColor => _state.selectedColor;
  RxInt get selectedInt => _state.selectedInt;
  RxInt get bodySelection => _state.bodySelection;
  TextEditingController get instagram => _state.instagram;
  TextEditingController get twitter => _state.twitter;
  TextEditingController get linkedin => _state.linkedin;
  TextEditingController get tiktok => _state.tiktok;
  TextEditingController get youtube => _state.youtube;
  TextEditingController get website => _state.website;
  TextEditingController get nickname => _state.nickname;
  TextEditingController get aciklama => _state.aciklama;
  TextEditingController get eDevletBarcodeNo => _state.eDevletBarcodeNo;
  RxBool get show => _state.show;
}
