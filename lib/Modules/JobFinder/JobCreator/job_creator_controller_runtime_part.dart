part of 'job_creator_controller.dart';

extension JobCreatorControllerRuntimeX on JobCreatorController {
  String localizedWorkTypes(List<String> values) =>
      _JobCreatorControllerSupportX(this).localizedWorkTypes(values);

  String localizedWorkDays(List<String> values) =>
      _JobCreatorControllerSupportX(this).localizedWorkDays(values);

  String localizedBenefits(List<String> values) =>
      _JobCreatorControllerSupportX(this).localizedBenefits(values);

  int parseMoneyInput(String value) =>
      _JobCreatorControllerSupportX(this).parseMoneyInput(value);

  void _handleOnInit() {
    final existingLoader = GlobalLoaderController.maybeFind(tag: loaderTag);
    if (existingLoader == null) {
      GlobalLoaderController.ensure(tag: loaderTag, permanent: false);
      _ownsLoader = true;
    }

    if (existingJob != null) {
      brand.text = existingJob!.brand;
      about.text = existingJob!.about;
      isTanimi.text = existingJob!.isTanimi;
      maas1.text =
          existingJob!.maas1 > 0 ? _formatMoneyInput(existingJob!.maas1) : '';
      maas2.text =
          existingJob!.maas2 > 0 ? _formatMoneyInput(existingJob!.maas2) : '';
      calismaSaatiBaslangic.text = existingJob!.calismaSaatiBaslangic;
      calismaSaatiBitis.text = existingJob!.calismaSaatiBitis;
      meslek.value = existingJob!.meslek;
      sehir.value = existingJob!.city;
      ilce.value = existingJob!.town;
      adres.value = existingJob!.adres;
      lat.value = existingJob!.lat;
      long.value = existingJob!.long;
      selectedCalismaTuruList.value =
          existingJob!.calismaTuru.cast<String>().toList();
      selectedCalismaGunleri.value =
          existingJob!.calismaGunleri.cast<String>().toList();
      selectedYanHaklar.value = existingJob!.yanHaklar.cast<String>().toList();
      ilanBasligi.text = existingJob!.ilanBasligi;
      basvuruSayisi.text = existingJob!.applicationCount.toString();
      pozisyonSayisi.text = existingJob!.pozisyonSayisi.toString();
    } else {
      selectedCalismaGunleri.assignAll(
        calismaGunleriList.take(5).toList(growable: false),
      );
    }

    loadSehirler();

    if (existingJob == null || (lat.value == 0 && long.value == 0)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(
          const Duration(milliseconds: 250),
          () =>
              autoFillLocationIfNeeded(allowPermissionPrompt: !Platform.isIOS),
        );
      });
    }
  }
}
