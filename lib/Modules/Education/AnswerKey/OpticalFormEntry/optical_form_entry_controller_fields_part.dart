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
