part of 'scholarship_applications_content_controller.dart';

class _ScholarshipApplicationsContentControllerDataPart {
  final ScholarshipApplicationsContentController _controller;

  const _ScholarshipApplicationsContentControllerDataPart(this._controller);

  void handleOnInit() {
    loadInitialData();
    _controller.isDetailsLoading.value = true;
    Future.wait([getData(), ogrenciBilgileriniKontrolEt()]).then((_) {
      _controller.isDetailsLoading.value = false;
    }).catchError((_) {
      _controller.isDetailsLoading.value = false;
      AppSnackbar('common.error'.tr, 'scholarship.applicant_load_failed'.tr);
    });
  }

  Future<void> loadInitialData() async {
    try {
      _controller.isLoading.value = true;
      final data = await _controller._userSummaryResolver.resolve(
        _controller.userID,
        preferCache: true,
      );
      if (data != null) {
        _controller.nickname.value = data.nickname;
        _controller.avatarUrl.value = data.avatarUrl;
        _controller.fullName.value = data.displayName;
      }
    } catch (_) {
    } finally {
      _controller.isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _loadUserRaw({bool forceRefresh = false}) {
    if (!forceRefresh && _controller._userRawFuture != null) {
      return _controller._userRawFuture!;
    }
    final future = _controller._userRepository.getUserRaw(
      _controller.userID,
      preferCache: !forceRefresh,
      forceServer: forceRefresh,
    );
    _controller._userRawFuture = future;
    return future;
  }

  Future<void> getData() async {
    try {
      final data = await _loadUserRaw();
      if (data == null) return;

      _controller.phoneNumber.value = userString(data, key: 'phoneNumber');
      _controller.email.value = userString(data, key: 'email');
      _controller.universite.value =
          userString(data, key: 'universite', scope: 'education');
      _controller.lise.value =
          userString(data, key: 'lise', scope: 'education');
      _controller.ortaOkul.value =
          userString(data, key: 'ortaOkul', scope: 'education');
      _controller.educationLevel.value =
          userString(data, key: 'educationLevel', scope: 'education');
      _controller.bolum.value =
          userString(data, key: 'bolum', scope: 'education');
      _controller.ulke.value = userString(data, key: 'ulke', scope: 'profile');
      _controller.nufusSehir.value =
          userString(data, key: 'nufusSehir', scope: 'profile');
      _controller.nufusIlce.value =
          userString(data, key: 'nufusIlce', scope: 'profile');
      _controller.fakulte.value =
          userString(data, key: 'fakulte', scope: 'education');
    } catch (_) {}
  }

  Future<void> ogrenciBilgileriniKontrolEt() async {
    try {
      final data = await _loadUserRaw();
      if (data == null) return;

      _controller.dogumTarigi.value =
          userString(data, key: 'dogumTarihi', scope: 'profile');
      _controller.medeniHal.value =
          userString(data, key: 'medeniHal', scope: 'profile');
      _controller.cinsiyet.value =
          userString(data, key: 'cinsiyet', scope: 'profile');
      _controller.engelliRaporu.value =
          userString(data, key: 'engelliRaporu', scope: 'family');
      _controller.calismaDurumu.value =
          userString(data, key: 'calismaDurumu', scope: 'profile');

      _controller.babaAdi.value =
          userString(data, key: 'fatherName', scope: 'family');
      _controller.babaSoyadi.value =
          userString(data, key: 'fatherSurname', scope: 'family');
      _controller.babaHayata.value =
          userString(data, key: 'fatherLiving', scope: 'family');
      _controller.babaPhone.value =
          userString(data, key: 'fatherPhone', scope: 'family');
      _controller.babaJob.value =
          userString(data, key: 'fatherJob', scope: 'family');
      _controller.babaSalary.value =
          userString(data, key: 'fatherSalary', scope: 'family');

      _controller.anneAdi.value =
          userString(data, key: 'motherName', scope: 'family');
      _controller.anneSoyadi.value =
          userString(data, key: 'motherSurname', scope: 'family');
      _controller.anneHayata.value =
          userString(data, key: 'motherLiving', scope: 'family');
      _controller.annePhone.value =
          userString(data, key: 'motherPhone', scope: 'family');
      _controller.anneJob.value =
          userString(data, key: 'motherJob', scope: 'family');
      _controller.anneSalary.value =
          userString(data, key: 'motherSalary', scope: 'family');

      _controller.evMulkiyeti.value =
          userString(data, key: 'evMulkiyeti', scope: 'family');
      _controller.ikametSehir.value =
          userString(data, key: 'ikametSehir', scope: 'profile');
      _controller.ikametIlce.value =
          userString(data, key: 'ikametIlce', scope: 'profile');
    } catch (_) {}
  }

  Future<void> toggleDetails() async {
    _controller.showDetails.value = !_controller.showDetails.value;
    if (!_controller.showDetails.value) return;

    _controller.isDetailsLoading.value = true;
    await Future.wait([getData(), ogrenciBilgileriniKontrolEt()]);
    _controller.isDetailsLoading.value = false;
  }
}
