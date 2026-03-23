part of 'sinav_hazirla_controller.dart';

extension SinavHazirlaControllerFormPart on SinavHazirlaController {
  void _initializeFormState() {
    if (sinavModel != null) {
      sinavTuru.value = sinavModel!.sinavTuru;
      sinavIsmi.value.text = sinavModel!.sinavAdi;
      aciklama.value.text = sinavModel!.sinavAciklama;
      kpssSecilenLisans.value =
          _normalizeKpssLisans(sinavModel!.kpssSecilenLisans);
      yanlisDogruyuGotururMu.value = true;
      currentDersler.assignAll(sinavModel!.dersler);
      docID.value = sinavModel!.docID;
      public.value = sinavModel!.public;
      sure.value = sinavModel!.bitisDk.toInt();
      soruSayisiTextFields.assignAll(
        sinavModel!.soruSayilari
            .map((soru) => TextEditingController(text: soru))
            .toList(),
      );
      return;
    }

    currentDersler.assignAll(tytDersler);
    soruSayisiTextFields.assignAll(
      List.generate(
        tytDersler.length,
        (index) => TextEditingController(text: ''),
      ),
    );
  }

  void _disposeFormControllers() {
    sinavIsmi.value.dispose();
    aciklama.value.dispose();
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
  }

  void updateSinavTuru(String newTuru) {
    sinavTuru.value = newTuru;
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }

    if (newTuru == _sinavTuruLgs) {
      currentDersler.assignAll(lgsDersler);
    } else if (newTuru == _sinavTuruTyt) {
      currentDersler.assignAll(tytDersler);
    } else if (newTuru == _sinavTuruAyt) {
      currentDersler.assignAll(aytDersler);
    } else if (newTuru == _sinavTuruKpss) {
      kpssSecilenLisans.value = _kpssLisansOrtaogretim;
      currentDersler.assignAll(kpssDerslerOrtaVeOnLisans);
    } else if (newTuru == _sinavTuruAles || newTuru == _sinavTuruDgs) {
      currentDersler.assignAll(alesVeDgsDersler);
    } else {
      currentDersler.assignAll(ydsDersler);
    }

    soruSayisiTextFields.assignAll(
      List.generate(currentDersler.length, (index) => TextEditingController()),
    );
  }

  void updateKpssLisans(String newLisans) {
    kpssSecilenLisans.value = _normalizeKpssLisans(newLisans);
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }

    final normalizedLisans = _normalizeKpssLisans(newLisans);
    if (normalizedLisans == _kpssLisansOrtaogretim ||
        normalizedLisans == _kpssLisansLisans ||
        normalizedLisans == _kpssLisansOnLisans) {
      currentDersler.assignAll(kpssDerslerOrtaVeOnLisans);
    } else if (normalizedLisans == _kpssLisansEgitimBirimleri) {
      currentDersler.assignAll(kpssDerslerEgitimbirimleri);
    } else if (normalizedLisans == _kpssLisansAGrubu1) {
      currentDersler.assignAll(kpssDerslerAgrubu1);
    } else if (normalizedLisans == _kpssLisansAGrubu2) {
      currentDersler.assignAll(kpssDerslerAgrubu2);
    }

    soruSayisiTextFields.assignAll(
      List.generate(
        currentDersler.length,
        (index) => TextEditingController(text: "1"),
      ),
    );
  }

  Future<void> resetForm() async {
    sinavIsmi.value.clear();
    aciklama.value.clear();
    cover.value = null;
    startDate.value = DateTime.now();
    selectedTime.value = const TimeOfDay(hour: 15, minute: 00);
    sinavTuru.value = 'TYT';
    currentDersler.assignAll(tytDersler);
    for (var controller in soruSayisiTextFields) {
      controller.dispose();
    }
    soruSayisiTextFields.assignAll(
      List.generate(
        tytDersler.length,
        (index) => TextEditingController(text: ''),
      ),
    );
    public.value = true;
    sure.value = 140;
    docID.value = DateTime.now().millisecondsSinceEpoch.toString();
  }
}
