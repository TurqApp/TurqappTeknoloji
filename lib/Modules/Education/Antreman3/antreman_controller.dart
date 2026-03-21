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
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/question_content.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_controller_actions_part.dart';

class AntremanController extends GetxController {
  static const String _mainCategoryPrefKeyPrefix = 'antreman_main_category';
  static const String _categoryCachePrefix = 'antreman_category_cache_';
  static const String _categoryCacheTimePrefix =
      'antreman_category_cache_time_';
  static const Duration _categoryCacheTtl = Duration(hours: 12);
  static const int _mainCategoryWarmupLimit = 10;
  final QuestionBankSnapshotRepository _questionBankSnapshotRepository =
      QuestionBankSnapshotRepository.ensure();
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  String get _activeUid {
    final uid = CurrentUserService.instance.userId.trim();
    return uid.isEmpty ? 'guest' : uid;
  }

  String get _mainCategoryPrefKey => '$_mainCategoryPrefKeyPrefix:$_activeUid';
  final Map<String, Map<String, List<String>>> subjects = {
    "LGS": {
      "LGS": [
        "Türkçe",
        "Matematik",
        "Fen Bilimleri",
        "İnkilap Tarihi",
        "Din Kültürü",
        "Yabancı Dil",
      ],
    },
    "YKS": {
      "TYT": ["Türkçe", "Temel Matematik", "Fen Bilimleri", "Sosyal Bilimler"],
      "AYT": [
        "Edebiyat - Sosyal Bilimler 1",
        "Matematik",
        "Sosyal Bilimler 2",
        "Fen Bilimleri",
      ],
      "YDT": ["İngilizce", "Almanca", "Arapça", "Fransızca", "Rusça"],
    },
    "KPSS": {
      "Orta Öğretim": ["Genel Kültür", "Genel Yetenek"],
      "Ön Lisans": ["Genel Kültür", "Genel Yetenek"],
      "Lisans": [
        "Genel Kültür",
        "Genel Yetenek",
        "Eğitim Bilimleri",
        "Çalışma Ekonomisi",
        "İstatistik",
        "Uluslararası İlişkiler",
        "Kamu Yönetimi",
        "Hukuk",
        "İktisat",
        "İşletme",
        "Maliye",
        "Muhasebe",
        "Almanca Öğretmenliği",
        "Beden Eğitimi",
        "Biyoloji Öğretmenliği",
        "Coğrafya Öğretmenliği",
        "Din Kültürü",
        "Edebiyat Öğretmenliği",
        "Fen Bilimleri Öğretmenliği",
        "Fizik Öğretmenliği",
        "Matematik Öğretmenliği",
        "İmam Hatip Öğretmenliği",
        "İngilizce Öğretmenliği",
        "Kimya Öğretmenliği",
        "Lise Matematik Öğretmenliği",
        "Okul Öncesi Öğretmenliği",
        "Rehberlik",
        "Sınıf Öğretmenliği",
        "Sosyal Bilgiler Öğretmenliği",
        "Tarih Öğretmenliği",
        "Türkçe Öğretmenliği",
        "Eğitim Bilimleri"
      ]
    },
    "YDS": {
      "İngilizce": ["Test Of English"],
      "Almanca": ["DeutschTest"],
      "Fransızca": ["Test De Français"],
      "Rusça": ["ТЕСТ НА ЗНАНИЕ РУССКОГО ЯЗЫКА"],
      "Arapça": ["Arapça"],
    },
    "ALES": {
      "ALES": [
        "Sözel",
        "Sayısal",
        "Sözel 1",
        "Sözel 2",
        "Sayısal 1",
        "Sayısal 2"
      ]
    },
    "DGS": {
      "DGS": ["Sayısal", "Sözel"]
    },
    "DUS": {
      "DUS": ["Temel Bilimler", "Klinik Bilimler"]
    },
    "TUS": {
      "TTBT": ["Temel Tıp Bilimleri"],
      "KTBT": ["Klinik Tıp Bilimleri"],
    }
  };

  final Map<String, IconData> icons = {
    "LGS": CupertinoIcons.lightbulb,
    "YKS": CupertinoIcons.book_fill,
    "TYT": CupertinoIcons.book_fill,
    "AYT": CupertinoIcons.doc_text,
    "YDT": CupertinoIcons.flag,
    "ALES": CupertinoIcons.graph_square_fill,
    "DGS": CupertinoIcons.archivebox,
    "YDS": CupertinoIcons.pen,
    "TUS": CupertinoIcons.pencil,
    "DUS": CupertinoIcons.doc_on_clipboard,
    "KPSS Ortaöğretim": CupertinoIcons.person_3_fill,
    "KPSS Ön Lisans": CupertinoIcons.list_bullet,
    "KPSS GY-GK": CupertinoIcons.info_circle_fill,
    "KPSS Eğitim Bilimleri": CupertinoIcons.book,
    "KPSS Alan Bilgisi": CupertinoIcons.briefcase_fill,
    "KPSS A Grubu 1": CupertinoIcons.lock_fill,
    "KPSS A Grubu 2": CupertinoIcons.wrench_fill,
  };
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

  final String userID = CurrentUserService.instance.userId;
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

  List<String> get mainCategories => const <String>[
        'LGS',
        'YKS',
        'KPSS',
        'YDS',
        'ALES',
        'DGS',
        'DUS',
        'TUS',
      ];

  List<String> get visibleMainCategories => mainCategory.value.isEmpty
      ? mainCategories
      : <String>[mainCategory.value];

  bool get hasActiveSearch => searchQuery.value.trim().length >= 2;

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

  Future<void> loadMainCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_mainCategoryPrefKey) ?? '';
      if (saved.isNotEmpty && subjects.containsKey(saved)) {
        mainCategory.value = saved;
      } else {
        mainCategory.value = '';
      }
    } catch (_) {
      mainCategory.value = '';
    } finally {
      mainCategoryLoaded.value = true;
    }
  }

  Future<void> setMainCategory(String category) async {
    if (!subjects.containsKey(category)) return;
    mainCategory.value = category;
    expandedIndex.value = -1;
    expandedSubIndex.value = -1;
    _mainCategoryPromptShown = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mainCategoryPrefKey, category);
    unawaited(_prefetchSelectedMainCategoryOnWifi(category));
  }

  Future<void> openMainCategoryPicker(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!mainCategoryLoaded.value) {
      await loadMainCategory();
    }
    if (!force && mainCategory.value.isNotEmpty) return;
    if (_mainCategoryPromptShown && !force) return;
    _mainCategoryPromptShown = true;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: !force,
      enableDrag: !force,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.72;
        return PopScope(
          canPop: !force,
          child: SafeArea(
            child: SizedBox(
              height: maxHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  MediaQuery.of(sheetContext).padding.bottom + 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'training.select_main_category_title'.tr,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!force)
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'training.select_main_category_body'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: mainCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final category = mainCategories[index];
                          final selected = category == mainCategory.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await setMainCategory(category);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: getRandomColor(index),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.black.withValues(alpha: 0.35)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? CupertinoIcons
                                            .check_mark_circled_solid
                                        : CupertinoIcons.chevron_right,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _mainCategoryPromptShown = false;
  }

  Color getRandomColor(int index) {
    List<Color> colors = [
      Colors.blue.shade900,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber.shade900,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.lime.shade700,
      Colors.amber,
      Colors.black54,
      Colors.orange.shade400,
      Colors.red.shade900,
    ];
    return colors[index % colors.length];
  }
}
