import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';

part 'scholarship_providers_controller_runtime_part.dart';

class ScholarshipProvidersController extends GetxController {
  static ScholarshipProvidersController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ScholarshipProvidersController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ScholarshipProvidersController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<ScholarshipProvidersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ScholarshipProvidersController>(tag: tag);
  }

  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final isLoading = true.obs;
  final providers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }

  Future<void> fetchProviders({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _fetchProvidersImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
