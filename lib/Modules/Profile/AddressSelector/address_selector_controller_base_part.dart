part of 'address_selector_controller.dart';

class _AddressSelectorControllerState {
  final TextEditingController addressController = TextEditingController();
  final RxInt currentLength = 0.obs;
  final UserRepository userRepository = UserRepository.ensure();
}

abstract class _AddressSelectorControllerBase extends GetxController {
  final _state = _AddressSelectorControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleAddressSelectorControllerInit(this as AddressSelectorController);
  }

  @override
  void onClose() {
    _handleAddressSelectorControllerClose(this as AddressSelectorController);
    super.onClose();
  }
}

extension AddressSelectorControllerFieldsPart on AddressSelectorController {
  TextEditingController get addressController => _state.addressController;
  RxInt get currentLength => _state.currentLength;
  UserRepository get _userRepository => _state.userRepository;
}
