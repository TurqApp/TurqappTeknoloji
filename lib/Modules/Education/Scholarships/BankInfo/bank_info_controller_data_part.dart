part of 'bank_info_controller.dart';

extension _BankInfoControllerDataX on BankInfoController {
  Future<void> loadData() async {
    try {
      final data = await _userRepository.getUserRaw(
            CurrentUserService.instance.effectiveUserId,
          ) ??
          const <String, dynamic>{};
      final bank = userString(data, key: 'bank', scope: 'finance');
      final iban = userString(data, key: 'iban', scope: 'finance');
      final kolayAdresFromDb = userString(
        data,
        key: 'kolayAdresSelection',
        scope: 'preferences',
        fallback: BankInfoController._email,
      );
      selectedBank.value =
          bank.isNotEmpty ? bank : BankInfoController._selectBank;
      this.iban.text = iban.startsWith('TR') ? iban.substring(2) : iban;
      kolayAdres.value = kolayAdresList.contains(kolayAdresFromDb)
          ? kolayAdresFromDb
          : BankInfoController._email;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'bank_info.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
