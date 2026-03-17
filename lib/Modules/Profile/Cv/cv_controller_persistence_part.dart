part of 'cv_controller.dart';

extension CvControllerPersistencePart on CvController {
  Future<void> referansEkle() async {
    TextEditingController adsoyad = TextEditingController();
    TextEditingController telefon = TextEditingController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Yeni Referans Ekle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (adsoyad.text.trim().isEmpty) {
                      AppSnackbar("Eksik Alan", "Ad soyad boş bırakılamaz");
                      return;
                    }
                    String raw = telefon.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String formatted = _formatPhoneNumber(raw);
                    referanslar.add(CVReferenceHumans(
                        nameSurname: adsoyad.text.trim(), phone: formatted));
                    Get.back();
                  },
                  child: Text("Ekle",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(adsoyad, "Ad Soyad"),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: telefon,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: "Telefon (ör, 05xx..)",
                  hintStyle: TextStyle(
                      color: Colors.grey, fontFamily: "MontserratMedium"),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void referansDuzenle(int index) {
    final model = referanslar[index];
    TextEditingController adsoyad =
        TextEditingController(text: model.nameSurname);
    TextEditingController telefon = TextEditingController(
        text: model.phone.replaceAll(RegExp(r'[^0-9]'), ''));

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Referans Düzenle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (adsoyad.text.trim().isEmpty) {
                      AppSnackbar("Eksik Alan", "Ad soyad boş bırakılamaz");
                      return;
                    }
                    String raw = telefon.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String formatted = _formatPhoneNumber(raw);
                    referanslar[index] = CVReferenceHumans(
                        nameSurname: adsoyad.text.trim(), phone: formatted);
                    referanslar.refresh();
                    Get.back();
                  },
                  child: Text("Kaydet",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(adsoyad, "Ad Soyad"),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: telefon,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: "Telefon (ör, 05xx..)",
                  hintStyle: TextStyle(
                      color: Colors.grey, fontFamily: "MontserratMedium"),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Skills ──

  Future<void> beceriEkle() async {
    TextEditingController beceri = TextEditingController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Yeni Beceri Ekle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    final text = beceri.text.trim();
                    if (text.isEmpty) {
                      AppSnackbar("Eksik Alan", "Beceri adı boş bırakılamaz");
                      return;
                    }
                    if (skills.contains(text)) {
                      AppSnackbar("Uyarı", "Bu beceri zaten eklenmiş");
                      return;
                    }
                    skills.add(text);
                    Get.back();
                  },
                  child: Text("Ekle",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(beceri, "Beceri (ör. Flutter, Photoshop)"),
            SizedBox(height: 15),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium",
                                    color: Colors.blueAccent)),
                          ))
                      .toList(),
                )),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Helpers ──

  String _formatPhoneNumber(String raw) {
    if (raw.length == 11 && raw.startsWith("0")) {
      return "0 (${raw.substring(1, 4)}) ${raw.substring(4, 7)} ${raw.substring(7)}";
    } else if (raw.startsWith("90") && raw.length >= 12) {
      final cleaned = raw.substring(2);
      return "0 (${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)} ${cleaned.substring(6)}";
    }
    return raw;
  }

  Widget _textFieldBox(TextEditingController ctrl, String hint) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey, fontFamily: "MontserratMedium"),
          border: InputBorder.none,
        ),
        style: TextStyle(
            color: Colors.black, fontSize: 15, fontFamily: "MontserratMedium"),
      ),
    );
  }

  // ── Data Operations ──

  Future<void> setData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar("Hata", "Oturum açık değil.");
      return;
    }
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final payload = {
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "mail": mail.text.trim(),
        "phone": phoneNumber.text.trim(),
        "about": onYazi.text.trim(),
        "photoUrl": photoUrl.value.trim(),
        "okullar": okullar.map((e) => e.toMap()).toList(),
        "diller": diler.map((e) => e.toMap()).toList(),
        "deneyim": isDeneyimleri.map((e) => e.toMap()).toList(),
        "referans": referanslar.map((e) => e.toMap()).toList(),
        "skills": skills.toList(),
        "findingJob": false,
      };
      await FirebaseFirestore.instance.collection("CV").doc(uid).set(payload);
      await _cvRepository.setCv(uid, payload);
      Get.back();
      AppSnackbar("CV Oluşturuldu!",
          "Şimdi iş başvurusu yaparken daha hızlı bir şekilde başvurabilirsin");
    } catch (e) {
      AppSnackbar("Hata", "CV kaydedilemedi. Tekrar deneyin.");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> loadDataFromFirestore({bool forceRefresh = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = await _cvRepository.getCv(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (data != null) {
        _applyCvData(data);
      }
      ensureDefaultPhoto();
    } catch (_) {}
  }

  Future<void> loadFromModel(CvModel model) async {
    firstName.text = model.firstName;
    lastName.text = model.lastName;
    mail.text = model.mail;
    phoneNumber.text = model.phone;
    onYazi.text = model.about;
    ensureDefaultPhoto();

    okullar.value = model.schools;
    diler.value = model.languages;
    isDeneyimleri.value = model.experiences;
    referanslar.value = model.references;
    skills.value = model.skills.toList();
  }

  void okulSil(int index) {
    okullar.removeAt(index);
  }
}
