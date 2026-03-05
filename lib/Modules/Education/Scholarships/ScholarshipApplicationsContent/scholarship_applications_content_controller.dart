import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';

class ScholarshipApplicationsContentController extends GetxController {
  final String userID;

  ScholarshipApplicationsContentController({required this.userID});

  // Observable variables
  var fullName = "".obs;
  var nickname = "".obs;
  var pfImage = "".obs;
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
    }).catchError((e) {
      print("Error loading detailed data: $e");
      isDetailsLoading.value = false;
      AppSnackbar('Hata', 'Veriler yüklenirken bir hata oluştu');
    });
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        nickname.value =
            (data["displayName"] ?? data["username"] ?? data["nickname"] ?? "")
                .toString();
        pfImage.value = (data["avatarUrl"] ??
                data["pfImage"] ??
                data["photoURL"] ??
                data["profileImageUrl"] ??
                "")
            .toString();
        fullName.value =
            "${(data["firstName"] ?? "").toString()} ${(data["lastName"] ?? "").toString()}"
                .trim();
      }
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();

      if (doc.exists) {
        // ad.value = doc.get("firstName") ?? "";
        // soyad.value = doc.get("lastName") ?? "";
        phoneNumber.value = doc.get("phoneNumber") ?? "";
        email.value = doc.get("email") ?? "";
        universite.value = doc.get("universite") ?? "";
        lise.value = doc.get("lise") ?? "";
        ortaOkul.value = doc.get("ortaOkul") ?? "";
        educationLevel.value = doc.get("educationLevel") ?? "";
        bolum.value = doc.get("bolum") ?? "";
        ulke.value = doc.get("ulke") ?? "";
        nufusSehir.value = doc.get("nufusSehir") ?? "";
        nufusIlce.value = doc.get("nufusIlce") ?? "";
        fakulte.value = doc.get("fakulte") ?? "";
      }
    } catch (e) {
      print("Error getting data: $e");
    }
  }

  Future<void> ogrenciBilgileriniKontrolEt() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get();

      if (doc.exists) {
        dogumTarigi.value = doc.get("dogumTarihi") ?? "";
        medeniHal.value = doc.get("medeniHal") ?? "";
        cinsiyet.value = doc.get("cinsiyet") ?? "";
        engelliRaporu.value = doc.get("engelliRaporu") ?? "";
        calismaDurumu.value = doc.get("calismaDurumu") ?? "";

        babaAdi.value = doc.get("fatherName") ?? "";
        babaSoyadi.value = doc.get("fatherSurname") ?? "";
        babaHayata.value = doc.get("fatherLiving") ?? "";
        babaPhone.value = doc.get("fatherPhone") ?? "";
        babaJob.value = doc.get("fatherJob") ?? "";
        babaSalary.value = doc.get("fatherSalary") ?? "";

        anneAdi.value = doc.get("motherName") ?? "";
        anneSoyadi.value = doc.get("motherSurname") ?? "";
        anneHayata.value = doc.get("motherLiving") ?? "";
        annePhone.value = doc.get("motherPhone") ?? "";
        anneJob.value = doc.get("motherJob") ?? "";
        anneSalary.value = doc.get("motherSalary") ?? "";

        evMulkiyeti.value = doc.get("evMulkiyeti") ?? "";
        ikametSehir.value = doc.get("ikametSehir") ?? "";
        ikametIlce.value = doc.get("ikametIlce") ?? "";
      }
    } catch (e) {
      print("Error checking student info: $e");
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
