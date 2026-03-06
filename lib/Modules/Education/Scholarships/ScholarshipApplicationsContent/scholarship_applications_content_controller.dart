import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
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
        final data = doc.data() as Map<String, dynamic>? ?? {};
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
        ulke.value = userString(data, key: "ulke");
        nufusSehir.value = userString(data, key: "nufusSehir");
        nufusIlce.value = userString(data, key: "nufusIlce");
        fakulte.value = userString(data, key: "fakulte", scope: "education");
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
        final data = doc.data() as Map<String, dynamic>? ?? {};
        dogumTarigi.value = userString(data, key: "dogumTarihi");
        medeniHal.value = userString(data, key: "medeniHal");
        cinsiyet.value = userString(data, key: "cinsiyet");
        engelliRaporu.value =
            userString(data, key: "engelliRaporu", scope: "family");
        calismaDurumu.value = userString(data, key: "calismaDurumu");

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
        ikametSehir.value = userString(data, key: "ikametSehir");
        ikametIlce.value = userString(data, key: "ikametIlce");
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
