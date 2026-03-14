import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/connectivity_helper.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/question_content.dart';

class AntremanController extends GetxController {
  static const String _mainCategoryPrefKey = 'antreman_main_category';
  static const String _categoryCachePrefix = 'antreman_category_cache_';
  static const String _categoryCacheTimePrefix =
      'antreman_category_cache_time_';
  static const Duration _categoryCacheTtl = Duration(hours: 12);
  static const int _mainCategoryWarmupLimit = 10;
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
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

  final String userID = FirebaseAuth.instance.currentUser!.uid;
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
                        const Expanded(
                          child: Text(
                            'Ana Kategori Seç',
                            style: TextStyle(
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
                    const Text(
                      'Soru Bankası bu kategori ile açılır. İstediğin zaman menüden değiştirebilirsin.',
                      style: TextStyle(
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

  Future<int> getAntPoint() async {
    try {
      final monthlyScore = await _antremanRepository.getMonthlyScore(userID);
      if (monthlyScore != null) {
        return monthlyScore;
      }

      final userData = await _userRepository.getUserRaw(
        userID,
        preferCache: true,
      );
      return ((userData?['antPoint'] ?? 100) as num).toInt();
    } catch (e) {
      log("AntPoint alınırken hata: $e");
      return 100;
    }
  }

  Future<void> selectSubject(
      String subject, String anaBaslik, String sinavTuru) async {
    if (isSubjectSelecting.value) return;
    isSubjectSelecting.value = true;
    selectedSubject.value = subject;
    selectedSinavTuru.value = sinavTuru;
    isSortingEnabled.value = true;
    loadingProgress.value = 0.0;
    questions.clear();
    try {
      await fetchAllQuestions(anaBaslik, sinavTuru, subject);
    } finally {
      isSubjectSelecting.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      _searchToken++;
      isSearchLoading.value = false;
      searchResults.clear();
      return;
    }

    final token = ++_searchToken;
    isSearchLoading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, token);
    });
  }

  Future<void> _searchFromTypesense(String query, int token) async {
    final normalized = query.trim();
    try {
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.workout,
        query: normalized,
        limit: 40,
      );
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }

      final results = await _fetchQuestionModelsByIds(docIds);
      if (token != _searchToken || searchQuery.value.trim() != normalized) {
        return;
      }
      searchResults.assignAll(results.where((item) => item.active));
    } catch (e) {
      log('Workout typesense search error: $e');
      if (token == _searchToken) {
        searchResults.clear();
      }
    } finally {
      if (token == _searchToken) {
        isSearchLoading.value = false;
      }
    }
  }

  Future<void> openSearchResult(QuestionBankModel question) async {
    final categoryKey = question.categoryKey.isNotEmpty
        ? question.categoryKey
        : _buildCategoryKey(
            question.anaBaslik, question.sinavTuru, question.ders);
    _activeCategoryKey.value = categoryKey;
    selectedSubject.value = question.ders;
    selectedSinavTuru.value = question.sinavTuru;
    loadingProgress.value = 1.0;
    questions.assignAll(<QuestionBankModel>[question]);
    _categoryPool
      ..clear()
      ..add(question);
    _loadedQuestionIds
      ..clear()
      ..add(question.docID);
    currentQuestionIndex.value = 0;
    await _hydrateAnswerAndSavedState(<QuestionBankModel>[question]);
    await _prefetchAspectRatios(<QuestionBankModel>[question]);
    await addToviewers(question);
    Get.to(
      () => QuestionContent(),
      transition: Transition.noTransition,
      preventDuplicates: true,
    );
  }

  Future<void> fetchAllQuestions(
      String anaBaslik, String sinavTuru, String ders) async {
    try {
      loadingProgress.value = 0.0;
      questions.clear();
      _loadedQuestionIds.clear();
      final categoryKey = _buildCategoryKey(anaBaslik, sinavTuru, ders);
      _activeCategoryKey.value = categoryKey;

      final cachedDocs = await _loadCachedCategoryPool(categoryKey);
      if (cachedDocs.isNotEmpty) {
        _categoryPool
          ..clear()
          ..addAll(cachedDocs);

        await _appendQuestionsFromProgress(categoryKey, batchSize);
        if (questions.isNotEmpty) {
          currentQuestionIndex.value = 0;
          await addToviewers(questions[0]);
          await _prefetchAspectRatios(questions.take(5).toList());
          Get.to(
            () => QuestionContent(),
            transition: Transition.noTransition,
            preventDuplicates: true,
          );
        }
      }

      final docs = await _fetchCategoryPoolDocs(
        anaBaslik,
        sinavTuru,
        ders,
        limit: 120,
      );
      _categoryPool
        ..clear()
        ..addAll(docs);
      await _saveCachedCategoryPool(categoryKey, docs);

      if (_categoryPool.isEmpty) {
        loadingProgress.value = 1.0;
        AppSnackbar("Bilgi", "Bu kategoride soru bulunamadı");
        return;
      }

      if (questions.isEmpty) {
        await _appendQuestionsFromProgress(categoryKey, batchSize);
      }
      if (questions.isNotEmpty && Get.currentRoute != '/QuestionContent') {
        currentQuestionIndex.value = 0;
        await addToviewers(questions[0]);
        await _prefetchAspectRatios(questions.take(5).toList());
        Get.to(
          () => QuestionContent(),
          transition: Transition.noTransition,
          preventDuplicates: true,
        );
      }
      // Kalan soruları arka planda doldur, ilk açılışı bloklama.
      _fillCategoryPoolInBackground(anaBaslik, sinavTuru, ders);
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Sorular çekilirken hata oluştu: $e");
      // İlk yükleme sırasında geçici indeks/ağ dalgalanmalarında kullanıcıya
      // yanıltıcı hata göstermeyelim; ekranda soru yoksa üstteki bilgi mesajı
      // zaten gösteriliyor.
      loadingProgress.value = 1.0;
    }
  }

  Future<void> fetchSavedQuestions() async {
    try {
      loadingProgress.value = 0.0;
      savedQuestionsList.clear();
      final savedIds = await _antremanRepository.fetchSavedQuestionIds(
        userID,
      );
      if (savedIds.isEmpty) {
        loadingProgress.value = 1.0;
        return;
      }

      final models = await _fetchQuestionModelsByIds(savedIds);
      savedQuestionsList.assignAll(models);
      await _hydrateAnswerAndSavedState(models);
      await _prefetchAspectRatios(models.take(5).toList());
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Kaydedilen sorular çekilirken hata oluştu");
      AppSnackbar("Hata", "Kaydedilen sorular yüklenirken hata oluştu");
      loadingProgress.value = 1.0;
    }
  }

  void sortQuestions() {
    // Progress-based ordering is preserved intentionally.
  }

  Future<void> addToviewers(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    try {
      await _antremanRepository.recordQuestionView(
        userId: userID,
        questionId: question.docID,
      );
    } catch (e) {
      AppSnackbar("Hata", "Görüntüleme güncellenirken hata");
    }
  }

  Future<void> addToSonraCoz(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;
    final isSaved = savedQuestions[key] ?? false;
    try {
      await _antremanRepository.toggleSavedQuestion(
        userId: userID,
        questionId: question.docID,
        currentlySaved: isSaved,
      );
      savedQuestions[key] = !isSaved;
      AppSnackbar(
        "Başarılı",
        isSaved
            ? "Soru 'Sonra Çöz' listesinden kaldırıldı!"
            : "Soru 'Sonra Çöz' listesine eklendi!",
      );
    } catch (e) {
      AppSnackbar(
        "Hata",
        isSaved
            ? "Sonra Çöz kaldırma sırasında hata oluştu."
            : "Sonra Çöz güncellenirken hata oluştu.",
      );
    }
  }

  Future<void> addTolikes(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;
    final isLiked = likedQuestions[key] ?? false;
    try {
      await _antremanRepository.toggleLikedQuestion(
        userId: userID,
        questionId: question.docID,
        currentlyLiked: isLiked,
      );

      if (isLiked) {
        question.begeniler.remove(userID);
      } else {
        question.begeniler.add(userID);
      }
      likedQuestions[key] = !isLiked;
      AppSnackbar(
        "Başarılı",
        isLiked ? "Beğeni kaldırıldı!" : "Soru beğenildi!",
      );
    } catch (e) {
      AppSnackbar(
        "Hata",
        isLiked
            ? "Beğeni kaldırma sırasında hata oluştu."
            : "Beğeni eklenirken hata oluştu.",
      );
    }
  }

  Future<void> addToPaylasanlar(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    try {
      await ShareActionGuard.run(() async {
        final shareId = 'question:${question.docID}';
        final shortTail = question.docID.length >= 8
            ? question.docID.substring(0, 8)
            : question.docID;
        final fallbackId = 'question-$shortTail';
        final fallbackUrl = 'https://turqapp.com/e/$fallbackId';
        String shortUrl = '';
        try {
          shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title:
                '${question.sinavTuru} - ${question.ders} Soru ${question.soruNo}',
            desc: question.anaBaslik.isNotEmpty
                ? question.anaBaslik
                : 'TurqApp Soru Bankası sorusu',
            imageUrl: question.soru.isNotEmpty ? question.soru : null,
          );
        } catch (_) {
          shortUrl = fallbackUrl;
        }

        // Kısa link servisi boş/root dönerse de paylaşılabilir bir eğitim linki üret.
        if (shortUrl.trim().isEmpty ||
            shortUrl.trim() == 'https://turqapp.com') {
          shortUrl = fallbackUrl;
        }

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: 'TurqApp - ${question.sinavTuru} ${question.ders} Sorusu',
          subject: 'TurqApp - ${question.sinavTuru} ${question.ders} Sorusu',
        );

        // İstatistik için en iyi gayretle yaz; başarısız olursa paylaşımı bozma.
        unawaited(
          _antremanRepository
              .recordSharedQuestion(
                userId: userID,
                questionId: question.docID,
              )
              .catchError((_) {}),
        );
      });
    } catch (_) {
      AppSnackbar("Hata", "Paylaşım başlatılamadı");
    }
  }

  Future<void> submitAnswer(
    String selectedAnswer,
    QuestionBankModel question,
  ) async {
    if (question.docID.isEmpty) return;
    final key = question.docID;

    if ((selectedAnswers[key] ?? '').isNotEmpty) {
      AppSnackbar("Bilgi", "Bu sorunun cevabını değiştiremezsiniz!");
      return;
    }

    selectedAnswers[key] = selectedAnswer;
    initialAnswers[key] = selectedAnswer;
    bool isCorrect = selectedAnswer == question.dogruCevap;
    answerStates[key] = isCorrect;
    justAnswered.value =
        isCorrect ? 'correct' : 'incorrect'; // Set answer status

    try {
      final Map<String, dynamic> userData = await _userRepository.getUserRaw(
            userID,
            preferCache: true,
          ) ??
          const <String, dynamic>{};
      await _antremanRepository.submitAnswer(
        userId: userID,
        question: question,
        selectedAnswer: selectedAnswer,
        categoryKey: question.categoryKey.isNotEmpty
            ? question.categoryKey
            : _activeCategoryKey.value,
        userData: userData,
      );
      nextQuestion();
    } catch (e) {
      log('submitAnswer error for ${question.docID}: $e');
      if (e.toString().contains('already_answered')) {
        AppSnackbar("Bilgi", "Bu sorunun cevabı daha önce kaydedilmiş.");
      } else {
        AppSnackbar("Hata", "Cevap kaydedilirken hata");
      }
    }
  }

  Future<double?> getImageAspectRatio(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Image image = await decodeImageFromList(bytes);
        return image.width / image.height;
      } else {
        debugPrint('Image load failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching image aspect ratio: $e');
      return null;
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      addToviewers(questions[currentQuestionIndex.value]);
      final nextQuestion = questions[currentQuestionIndex.value];
      if (!imageAspectRatios.containsKey(nextQuestion.soru)) {
        getImageAspectRatio(nextQuestion.soru).then((aspectRatio) {
          imageAspectRatios[nextQuestion.soru] = aspectRatio ?? 1.0;
        });
      }
    } else {
      AppSnackbar("Bilgi", "Bu kategoride başka soru kalmadı!");
    }
  }

  void settings(BuildContext context) {
    AppSnackbar("Bilgi", "Ayarlar ekranı açılıyor!");
  }

  void onScreenReEnter() {
    if (questions.isNotEmpty) {
      sortQuestions();
    }
  }

  Future<void> fetchUniqueFields() async {
    final payload = await _antremanRepository.fetchUniqueFields(
      preferCache: true,
      forceRefresh: false,
    );
    log('Ana Başlıklar: ${payload['anaBaslik'] ?? const <String>[]}');
    log('Dersler: ${payload['ders'] ?? const <String>[]}');
    log('Sınav Türleri: ${payload['sinavTuru'] ?? const <String>[]}');
  }

  Future<void> fetchMoreQuestions() async {
    if (_activeCategoryKey.value.isEmpty || _categoryPool.isEmpty) return;

    try {
      await _appendQuestionsFromProgress(_activeCategoryKey.value, batchSize);
      loadingProgress.value = 1.0;
    } catch (e) {
      log("Daha fazla soru çekilirken hata oluştu: $e");
      AppSnackbar("Hata", "Daha fazla soru çekilirken hata oluştu");
      loadingProgress.value = 1.0;
    }
  }

  String _buildCategoryKey(String anaBaslik, String sinavTuru, String ders) {
    return '$anaBaslik|$sinavTuru|$ders';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  int _coprimeStep(int n, math.Random random) {
    if (n <= 1) return 1;
    int step = random.nextInt(n - 1) + 1;
    int guard = 0;
    while (_gcd(step, n) != 1 && guard < n * 2) {
      step = random.nextInt(n - 1) + 1;
      guard++;
    }
    return step;
  }

  Map<String, dynamic> _newProgressState(int n, {int cycle = 0}) {
    final random = math.Random();
    return {
      'cursor': 0,
      'n': n,
      'a': _coprimeStep(n, random),
      'b': n > 0 ? random.nextInt(n) : 0,
      'cycle': cycle,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<List<QuestionBankModel>> _fetchCategoryPoolDocs(
      String anaBaslik, String sinavTuru, String ders,
      {int? limit}) async {
    return _antremanRepository.fetchCategoryQuestions(
      anaBaslik,
      sinavTuru,
      ders,
      limit: limit,
    );
  }

  Future<void> _fillCategoryPoolInBackground(
      String anaBaslik, String sinavTuru, String ders) async {
    try {
      final all = await _fetchCategoryPoolDocs(anaBaslik, sinavTuru, ders);
      await _saveCachedCategoryPool(
        _buildCategoryKey(anaBaslik, sinavTuru, ders),
        all,
      );
      if (_activeCategoryKey.value !=
          _buildCategoryKey(anaBaslik, sinavTuru, ders)) {
        return;
      }
      final existingIds = _categoryPool.map((e) => e.docID).toSet();
      for (final q in all) {
        if (!existingIds.contains(q.docID)) {
          _categoryPool.add(q);
          existingIds.add(q.docID);
        }
      }
    } catch (e) {
      log('Background pool fill error: $e');
    }
  }

  Future<void> _appendQuestionsFromProgress(
      String categoryKey, int count) async {
    if (_categoryPool.isEmpty || count <= 0) return;

    final progressData = await _antremanRepository.getProgress(
      userID,
      categoryKey,
    );
    final n = _categoryPool.length;
    Map<String, dynamic> progress;
    if (progressData == null) {
      progress = _newProgressState(n);
      await _antremanRepository.setProgress(userID, categoryKey, progress,
          merge: false);
    } else {
      progress = Map<String, dynamic>.from(progressData);
      final int prevN = (progress['n'] as num?)?.toInt() ?? 0;
      if (prevN != n || n == 0) {
        progress = _newProgressState(n,
            cycle: (progress['cycle'] as num?)?.toInt() ?? 0);
        await _antremanRepository.setProgress(userID, categoryKey, progress);
      }
    }

    int cursor = (progress['cursor'] as num?)?.toInt() ?? 0;
    int a = (progress['a'] as num?)?.toInt() ?? 1;
    int b = (progress['b'] as num?)?.toInt() ?? 0;
    int cycle = (progress['cycle'] as num?)?.toInt() ?? 0;

    final appended = <QuestionBankModel>[];
    int guard = 0;
    while (appended.length < count && guard < n * 3) {
      if (n == 0) break;
      if (cursor >= n) {
        cycle += 1;
        final reset = _newProgressState(n, cycle: cycle);
        cursor = 0;
        a = reset['a'] as int;
        b = reset['b'] as int;
      }
      final idx = (a * cursor + b) % n;
      final q = _categoryPool[idx];
      if (!_loadedQuestionIds.contains(q.docID)) {
        appended.add(q);
        _loadedQuestionIds.add(q.docID);
      }
      cursor += 1;
      guard += 1;
    }

    if (appended.isEmpty) return;

    await _antremanRepository.setProgress(userID, categoryKey, {
      'cursor': cursor,
      'n': n,
      'a': a,
      'b': b,
      'cycle': cycle,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    });

    questions.addAll(appended);
    await _hydrateAnswerAndSavedState(appended);
    await _prefetchAspectRatios(appended.take(5).toList());
  }

  Future<void> _hydrateAnswerAndSavedState(
      List<QuestionBankModel> models) async {
    if (models.isEmpty) return;
    final ids = models.map((e) => e.docID).toList();
    final answersById = await _fetchUserAnswers(ids);
    final savedSet = await _fetchSavedIds(ids);

    for (final q in models) {
      final key = q.docID;
      final answer = answersById[key];
      selectedAnswers[key] = answer ?? '';
      initialAnswers[key] = answer ?? '';
      answerStates[key] = answer != null && answer == q.dogruCevap;
      likedQuestions[key] = q.begeniler.contains(userID);
      savedQuestions[key] = savedSet.contains(key);
    }
  }

  Future<Map<String, String>> _fetchUserAnswers(List<String> docIds) async {
    return _antremanRepository.fetchUserAnswers(userID, docIds);
  }

  Future<Set<String>> _fetchSavedIds(List<String> docIds) async {
    return _antremanRepository.fetchSavedIds(userID, docIds);
  }

  Future<List<QuestionBankModel>> _fetchQuestionModelsByIds(
      List<String> ids) async {
    return _antremanRepository.fetchQuestionModelsByIds(ids);
  }

  Future<void> _prefetchAspectRatios(List<QuestionBankModel> models) async {
    await Future.wait(
      models.map((question) async {
        if (!imageAspectRatios.containsKey(question.soru)) {
          final aspectRatio = await getImageAspectRatio(question.soru);
          imageAspectRatios[question.soru] = aspectRatio ?? 1.0;
        }
      }),
    );
  }

  String _cacheKeyForCategory(String categoryKey) {
    return '$_categoryCachePrefix$categoryKey';
  }

  String _cacheTimeKeyForCategory(String categoryKey) {
    return '$_categoryCacheTimePrefix$categoryKey';
  }

  Future<List<QuestionBankModel>> _loadCachedCategoryPool(
      String categoryKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimeKeyForCategory(categoryKey));
      final payload = prefs.getString(_cacheKeyForCategory(categoryKey));
      if (cacheTime == null || payload == null || payload.isEmpty) {
        return <QuestionBankModel>[];
      }

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTime),
      );
      if (age > _categoryCacheTtl) {
        return <QuestionBankModel>[];
      }

      final decoded = jsonDecode(payload);
      if (decoded is! List) return <QuestionBankModel>[];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(QuestionBankModel.fromJson)
          .toList();
    } catch (e) {
      log('Kategori cache okunamadi: $e');
      return <QuestionBankModel>[];
    }
  }

  Future<void> _saveCachedCategoryPool(
    String categoryKey,
    List<QuestionBankModel> docs,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(
        docs.map((question) => question.toJson()).toList(),
      );
      await prefs.setString(_cacheKeyForCategory(categoryKey), payload);
      await prefs.setInt(
        _cacheTimeKeyForCategory(categoryKey),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      log('Kategori cache yazilamadi: $e');
    }
  }

  Future<void> _prefetchSelectedMainCategoryOnWifi(String category) async {
    try {
      final onWifi = await ConnectivityHelper.isWifi();
      if (!onWifi) return;

      final categorySubjects = subjects[category];
      if (categorySubjects == null) return;

      for (final entry in categorySubjects.entries) {
        final sinavTuru = entry.key;
        for (final ders in entry.value) {
          final categoryKey = _buildCategoryKey(category, sinavTuru, ders);
          final cached = await _loadCachedCategoryPool(categoryKey);
          if (cached.length >= _mainCategoryWarmupLimit) continue;

          final docs = await _fetchCategoryPoolDocs(
            category,
            sinavTuru,
            ders,
            limit: _mainCategoryWarmupLimit,
          );
          if (docs.isNotEmpty) {
            await _saveCachedCategoryPool(categoryKey, docs);
            await _prefetchAspectRatios(docs.take(3).toList());
          }
        }
      }
    } catch (e) {
      log('Secilen ana baslik warm cache hatasi: $e');
    }
  }
}
