import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_view.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'tests_grid_controller_data_part.dart';
part 'tests_grid_controller_actions_part.dart';

class TestsGridController extends GetxController {
  static TestsGridController ensure(
    TestsModel model, {
    Function? onUpdate,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestsGridController(model, onUpdate),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestsGridController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestsGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestsGridController>(tag: tag);
  }

  final TestsModel model;
  final Function? onUpdate;

  final fullName = ''.obs;
  final avatarUrl = ''.obs;
  final nickname = ''.obs;
  final secim = ''.obs;
  final totalYanit = 0.obs;
  final isFavorite = false.obs;
  final appStore = ''.obs;
  final googlePlay = ''.obs;
  final TestRepository _testRepository = TestRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  TestsGridController(this.model, this.onUpdate) {
    _initialize();
  }

  void _initialize() {
    checkIfFavorite();
    getUygulamaLinks();
    getUserData();
    getTotalYanit();
  }
}
