part of 'address_selector_controller.dart';

class _AddressSelectorControllerState {
  final TextEditingController addressController = TextEditingController();
  final RxInt currentLength = 0.obs;
  final UserRepository userRepository = UserRepository.ensure();
}

extension AddressSelectorControllerFieldsPart on AddressSelectorController {
  TextEditingController get addressController => _state.addressController;
  RxInt get currentLength => _state.currentLength;
  UserRepository get _userRepository => _state.userRepository;
}
