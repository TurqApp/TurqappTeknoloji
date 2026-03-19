import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:get/get.dart';

class ScholarshipApplicationsContentController extends GetxController {
  final String userID;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  ScholarshipApplicationsContentController({required this.userID});

  // Observable variables
  var fullName = "".obs;
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var showDetails = false.obs;
  var isLoading = false.obs;
  var isDetailsLoading = false.obs;

  // Student basic info
  var ad = "".obs;
  var soyad = "".obs;
  var email = "".obs;
  var phoneNumber = "".obs;
  var ulke = "".obs;
  var nufusSehir = "".obs;
  var nufusIlce = "".obs;
  var fakulte = "".obs;

  // University info
  var universite = "".obs;
  var bolum = "".obs;
  var lise = "".obs;
  var ortaOkul = "".obs;
  var educationLevel = "".obs;

  // Personal info
  var dogumTarigi = "".obs;
  var medeniHal = "".obs;
  var cinsiyet = "".obs;
  var engelliRaporu = "".obs;
  var calismaDurumu = "".obs;

  // Father info
  var babaAdi = "".obs;
  var babaSoyadi = "".obs;
  var babaHayata = "".obs;
  var babaPhone = "".obs;
  var babaJob = "".obs;
  var babaSalary = "".obs;

  // Mother info
  var anneAdi = "".obs;
  var anneSoyadi = "".obs;
  var anneHayata = "".obs;
  var annePhone = "".obs;
  var anneJob = "".obs;
  var anneSalary = "".obs;

  // Housing info
  var evMulkiyeti = "".obs;
  var ikametSehir = "".obs;
  var ikametIlce = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    // Tüm verileri yüklemek için getData ve ogrenciBilgileriniKontrolEt'i çağır
    isDetailsLoading.value = true;
    Future.wait([getData(), ogrenciBilgileriniKontrolEt()]).then((_) {
      isDetailsLoading.value = false;
    }).catchError((_) {
      isDetailsLoading.value = false;
      AppSnackbar('common.error'.tr, 'scholarship.applicant_load_failed'.tr);
    });
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      final data = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (data != null) {
        nickname.value = data.nickname;
        avatarUrl.value = data.avatarUrl;
        fullName.value = data.displayName;
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getData() async {
    try {
      final data = await _userRepository.getUserRaw(userID);
      if (data != null) {
        // ad.value = doc.get("firstName") ?? "";
        // soyad.value = doc.get("lastName") ?? "";
        phoneNumber.value = userString(data, key: "phoneNumber");
        email.value = userString(data, key: "email");
        universite.value =
            userString(data, key: "universite", scope: "education");
        lise.value = userString(data, key: "lise", scope: "education");
        ortaOkul.value = userString(data, key: "ortaOkul", scope: "education");
        educationLevel.value =
            userString(data, key: "educationLevel", scope: "education");
        bolum.value = userString(data, key: "bolum", scope: "education");
        ulke.value = userString(data, key: "ulke", scope: "profile");
        nufusSehir.value =
            userString(data, key: "nufusSehir", scope: "profile");
        nufusIlce.value = userString(data, key: "nufusIlce", scope: "profile");
        fakulte.value = userString(data, key: "fakulte", scope: "education");
      }
    } catch (_) {
    }
  }

  Future<void> ogrenciBilgileriniKontrolEt() async {
    try {
      final data = await _userRepository.getUserRaw(userID);
      if (data != null) {
        dogumTarigi.value =
            userString(data, key: "dogumTarihi", scope: "profile");
        medeniHal.value = userString(data, key: "medeniHal", scope: "profile");
        cinsiyet.value = userString(data, key: "cinsiyet", scope: "profile");
        engelliRaporu.value =
            userString(data, key: "engelliRaporu", scope: "family");
        calismaDurumu.value =
            userString(data, key: "calismaDurumu", scope: "profile");

        babaAdi.value = userString(data, key: "fatherName", scope: "family");
        babaSoyadi.value =
            userString(data, key: "fatherSurname", scope: "family");
        babaHayata.value =
            userString(data, key: "fatherLiving", scope: "family");
        babaPhone.value = userString(data, key: "fatherPhone", scope: "family");
        babaJob.value = userString(data, key: "fatherJob", scope: "family");
        babaSalary.value =
            userString(data, key: "fatherSalary", scope: "family");

        anneAdi.value = userString(data, key: "motherName", scope: "family");
        anneSoyadi.value =
            userString(data, key: "motherSurname", scope: "family");
        anneHayata.value =
            userString(data, key: "motherLiving", scope: "family");
        annePhone.value = userString(data, key: "motherPhone", scope: "family");
        anneJob.value = userString(data, key: "motherJob", scope: "family");
        anneSalary.value =
            userString(data, key: "motherSalary", scope: "family");

        evMulkiyeti.value =
            userString(data, key: "evMulkiyeti", scope: "family");
        ikametSehir.value =
            userString(data, key: "ikametSehir", scope: "profile");
        ikametIlce.value =
            userString(data, key: "ikametIlce", scope: "profile");
      }
    } catch (_) {
    }
  }

  Future<void> toggleDetails() async {
    showDetails.value = !showDetails.value;
    if (showDetails.value) {
      isDetailsLoading.value = true;
      await Future.wait([getData(), ogrenciBilgileriniKontrolEt()]);
      isDetailsLoading.value = false;
    }
  }
}
