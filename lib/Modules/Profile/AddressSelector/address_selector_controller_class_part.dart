part of 'address_selector_controller.dart';

class AddressSelectorController extends _AddressSelectorControllerBase {
  static AddressSelectorController ensure({bool permanent = false}) =>
      _ensureAddressSelectorController(permanent: permanent);

  static AddressSelectorController? maybeFind() =>
      _maybeFindAddressSelectorController();

  Future<void> setData() => _setAddressSelectorData(this);
}
