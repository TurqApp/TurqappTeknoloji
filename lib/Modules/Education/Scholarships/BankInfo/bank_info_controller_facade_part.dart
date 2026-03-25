part of 'bank_info_controller.dart';

extension BankInfoControllerFacadePart on BankInfoController {
  String get defaultBankSelection => BankInfoController._selectBank;
  String get defaultFastTypeEmail => BankInfoController._email;
  bool get isIbanSelected => kolayAdres.value == BankInfoController._ibanType;
  bool get isPhoneSelected => kolayAdres.value == BankInfoController._phone;
  bool get isEmailSelected => kolayAdres.value == BankInfoController._email;

  String localizedFastType(String value) =>
      _BankInfoControllerUiX(this).localizedFastType(value);

  Future<void> loadData() => _BankInfoControllerDataX(this).loadData();

  void showBankBottomSheet(BuildContext context) =>
      _BankInfoControllerUiX(this).showBankBottomSheet(context);

  void showKolayAdresBottomSheet(BuildContext context) =>
      _BankInfoControllerUiX(this).showKolayAdresBottomSheet(context);

  Future<void> pasteFromClipboard() =>
      _BankInfoControllerActionsX(this).pasteFromClipboard();

  void saveData() => _BankInfoControllerActionsX(this).saveData();
}
