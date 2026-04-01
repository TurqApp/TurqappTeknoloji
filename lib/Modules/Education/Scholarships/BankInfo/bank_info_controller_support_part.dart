part of 'bank_info_controller.dart';

BankInfoController ensureBankInfoController({
  required String tag,
  bool permanent = false,
}) =>
    _ensureBankInfoController(tag: tag, permanent: permanent);

BankInfoController? maybeFindBankInfoController({required String tag}) =>
    _maybeFindBankInfoController(tag: tag);

BankInfoController _ensureBankInfoController({
  required String tag,
  bool permanent = false,
}) {
  final existing = _maybeFindBankInfoController(tag: tag);
  if (existing != null) return existing;
  return Get.put(BankInfoController(), tag: tag, permanent: permanent);
}

BankInfoController? _maybeFindBankInfoController({required String tag}) {
  final isRegistered = Get.isRegistered<BankInfoController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<BankInfoController>(tag: tag);
}

void _handleBankInfoControllerInit(BankInfoController controller) {
  BankInfoControllerFacadePart(controller).loadData();
}
