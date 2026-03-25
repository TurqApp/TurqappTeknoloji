import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:get/get.dart';

part 'scholarship_applications_content_controller_data_part.dart';

class ScholarshipApplicationsContentController extends GetxController {
  static ScholarshipApplicationsContentController ensure({
    required String tag,
    required String userID,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ScholarshipApplicationsContentController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static ScholarshipApplicationsContentController? maybeFind({
    required String tag,
  }) {
    final isRegistered =
        Get.isRegistered<ScholarshipApplicationsContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ScholarshipApplicationsContentController>(tag: tag);
  }

  final String userID;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  Future<Map<String, dynamic>?>? _userRawFuture;

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
    _ScholarshipApplicationsContentControllerDataPart(this).handleOnInit();
  }
}
