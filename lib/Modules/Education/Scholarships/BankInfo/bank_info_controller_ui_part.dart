part of 'bank_info_controller.dart';

extension _BankInfoControllerUiX on BankInfoController {
  String localizedFastType(String value) {
    switch (value) {
      case BankInfoController._selectBank:
        return 'bank_info.select_bank'.tr;
      case BankInfoController._email:
        return 'bank_info.fast_email'.tr;
      case BankInfoController._phone:
        return 'bank_info.fast_phone'.tr;
      case BankInfoController._ibanType:
        return 'bank_info.fast_iban'.tr;
      default:
        return value;
    }
  }

  void showBankBottomSheet(BuildContext context) {
    ListBottomSheet.show(
      context: context,
      items: banks,
      title: 'bank_info.select_bank'.tr,
      selectedItem: selectedBank.value == BankInfoController._selectBank
          ? null
          : selectedBank.value,
      onSelect: (item) {
        selectedBank.value = item;
      },
    );
  }

  void showKolayAdresBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      items: kolayAdresList.map(localizedFastType).toList(),
      title: 'bank_info.select_fast_type'.tr,
      selectedItem: localizedFastType(kolayAdres.value),
      onSelect: (item) {
        final selectedIndex =
            kolayAdresList.map(localizedFastType).toList().indexOf(item);
        kolayAdres.value =
            selectedIndex >= 0 ? kolayAdresList[selectedIndex] : item;
        iban.text = '';
      },
    );
  }
}
