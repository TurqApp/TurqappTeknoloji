import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Repositories/question_bank_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/question_content.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_controller_actions_part.dart';
part 'antreman_controller_category_part.dart';
part 'antreman_controller_models_part.dart';
part 'antreman_controller_question_actions_part.dart';
part 'antreman_controller_support_part.dart';

class AntremanController extends GetxController {
  static AntremanController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AntremanController(), permanent: permanent);
  }

  static AntremanController? maybeFind() {
    final isRegistered = Get.isRegistered<AntremanController>();
    if (!isRegistered) return null;
    return Get.find<AntremanController>();
  }

  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final Map<String, Map<String, List<String>>> subjects = _antremanSubjects;

  final Map<String, IconData> icons = _antremanIcons;
  var expandedIndex = RxInt(-1);
  final RxString selectedSubject = ''.obs;
  final RxString selectedSinavTuru = ''.obs;
  final RxInt currentQuestionIndex = 0.obs;
  final RxMap<String, String> selectedAnswers = <String, String>{}.obs;
  final RxMap<String, String> initialAnswers = <String, String>{}.obs;
  final RxMap<String, bool> answerStates = <String, bool>{}.obs;
  final RxMap<String, bool> likedQuestions = <String, bool>{}.obs;
  final RxMap<String, bool> savedQuestions = <String, bool>{}.obs;
  final RxBool isSortingEnabled = true.obs;
  final RxDouble loadingProgress = 0.0.obs;
  final RxBool isSubjectSelecting = false.obs;
  final RxMap<String, double> imageAspectRatios = <String, double>{}.obs;
  final RxString justAnswered = ''.obs; // New state to track answer status
  final RxString searchQuery = ''.obs;
  final RxList<QuestionBankModel> searchResults = <QuestionBankModel>[].obs;
  final RxBool isSearchLoading = false.obs;

  final String userID = CurrentUserService.instance.effectiveUserId;
  final int batchSize = 5;
  final RxInt expandedSubIndex = RxInt(-1);
  final RxString mainCategory = ''.obs;
  final RxBool mainCategoryLoaded = false.obs;
  final RxList<QuestionBankModel> questions = RxList<QuestionBankModel>();
  final RxList<QuestionBankModel> savedQuestionsList =
      RxList<QuestionBankModel>();
  final List<QuestionBankModel> _categoryPool = <QuestionBankModel>[];
  final Set<String> _loadedQuestionIds = <String>{};
  final RxString _activeCategoryKey = ''.obs;
  bool _mainCategoryPromptShown = false;
  Timer? _searchDebounce;
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    loadMainCategory();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
