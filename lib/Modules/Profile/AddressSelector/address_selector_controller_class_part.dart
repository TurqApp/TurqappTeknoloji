part of 'address_selector_controller.dart';

class AddressSelectorController extends GetxController {
  static AddressSelectorController ensure({bool permanent = false}) =>
      _ensureAddressSelectorController(permanent: permanent);

  static AddressSelectorController? maybeFind() =>
      _maybeFindAddressSelectorController();

  final TextEditingController addressController = TextEditingController();
  final currentLength = 0.obs;
  final UserRepository _userRepository = UserRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _handleAddressSelectorControllerInit(this);
  }

  @override
  void onClose() {
    _handleAddressSelectorControllerClose(this);
    super.onClose();
  }

  Future<void> setData() => _setAddressSelectorData(this);
}
