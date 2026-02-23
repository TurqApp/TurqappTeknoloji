import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/question_content.dart';

class AntremanController extends GetxController {
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
  final RxMap<String, double> imageAspectRatios = <String, double>{}.obs;
  final RxString justAnswered = ''.obs; // New state to track answer status

  final String userID = FirebaseAuth.instance.currentUser!.uid;
  final int batchSize = 5;
  final RxInt expandedSubIndex = RxInt(-1);
  final RxList<QuestionBankModel> questions = RxList<QuestionBankModel>();
  final RxList<QuestionBankModel> savedQuestionsList =
      RxList<QuestionBankModel>();

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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      return doc.data()?['antPoint'] ?? 0;
    } catch (e) {
      log("AntPoint alınırken hata: $e");
      return 0;
    }
  }

  Future<void> selectSubject(
      String subject, String anaBaslik, String sinavTuru) async {
    selectedSubject.value = subject;
    selectedSinavTuru.value = sinavTuru;
    isSortingEnabled.value = true;
    loadingProgress.value = 0.0;
    questions.clear();
    await fetchAllQuestions(anaBaslik, sinavTuru, subject);
  }

  Future<void> fetchAllQuestions(
      String anaBaslik, String sinavTuru, String ders) async {
    try {
      loadingProgress.value = 0.0;
      questions.clear();
      DocumentSnapshot? lastDocument;
      bool hasMoreData = true;
      int totalFetched = 0;

      while (hasMoreData) {
        Query query = FirebaseFirestore.instance
            .collection('SoruBankasi')
            .where('anaBaslik', isEqualTo: anaBaslik)
            .where('sinavTuru', isEqualTo: sinavTuru)
            .where('ders', isEqualTo: ders)
            .orderBy('soruNo', descending: false)
            .limit(batchSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMoreData = false;
          break;
        }

        lastDocument = snapshot.docs.last;
        totalFetched += snapshot.docs.length;

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docID'] = doc.id;
          final question = QuestionBankModel.fromJson(data);
          questions.add(question);

          // Initialize basic states
          selectedAnswers[question.soru] = '';
          initialAnswers[question.soru] = '';
          answerStates[question.soru] = false;
          likedQuestions[question.soru] = question.begeniler.contains(userID);
          savedQuestions[question.soru] = question.soruCoz.contains(userID);
        }

        // Update progress
        loadingProgress.value =
            (totalFetched / (totalFetched + batchSize)) * 0.6;

        // Navigate early if initial batch is fetched
        if (totalFetched == batchSize && questions.isNotEmpty) {
          currentQuestionIndex.value = 0;
          addToviewers(questions[0]);
          Get.to(() => QuestionContent());
        }
      }

      // Fetch user answers for all questions in background
      if (questions.isNotEmpty) {
        final docIds = questions.map((q) => q.docID).toList();
        final cevapSnapshots = await Future.wait(
          docIds.map(
            (docID) => FirebaseFirestore.instance
                .collection('SoruBankasi')
                .doc(docID)
                .collection('Cevaplayanlar')
                .doc(userID)
                .get(),
          ),
        );

        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          final cevapSnapshot = cevapSnapshots[i];
          if (cevapSnapshot.exists) {
            final data = cevapSnapshot.data()!;
            final cevap = data['cevap'] as String?;
            if (cevap != null) {
              selectedAnswers[question.soru] = cevap;
              initialAnswers[question.soru] = cevap;
              answerStates[question.soru] = cevap == question.dogruCevap;
            }
          }
        }
      }

      // Sort questions
      sortQuestions();

      // Load aspect ratios for the first few questions in background
      await Future.wait(
        questions.take(5).map((question) async {
          if (!imageAspectRatios.containsKey(question.soru)) {
            final aspectRatio = await getImageAspectRatio(question.soru);
            imageAspectRatios[question.soru] = aspectRatio ?? 1.0;
          }
        }),
      );

      loadingProgress.value = 1.0;
    } catch (e) {
      log("Sorular çekilirken hata oluştu");
      AppSnackbar("Hata", "Sorular çekilirken hata oluştu");
      loadingProgress.value = 1.0;
    }
  }

  Future<void> fetchSavedQuestions() async {
    try {
      loadingProgress.value = 0.0;
      savedQuestionsList.clear(); // questions yerine savedQuestionsList
      DocumentSnapshot? lastDocument;
      bool hasMoreData = true;
      int totalFetched = 0;

      while (hasMoreData) {
        Query query = FirebaseFirestore.instance
            .collection('SoruBankasi')
            .where('soruCoz', arrayContains: userID)
            .limit(batchSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          hasMoreData = false;
          break;
        }

        lastDocument = snapshot.docs.last;
        totalFetched += snapshot.docs.length;

        List<QuestionBankModel> tempQuestions = [];
        List<String> validDocIDs = [];

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docID'] = doc.id;
          tempQuestions.add(QuestionBankModel.fromJson(data));
          if (doc.id.isNotEmpty) {
            validDocIDs.add(doc.id);
          }
          loadingProgress.value =
              (totalFetched / (totalFetched + batchSize)) * 0.4;
        }

        await Future.wait(
          tempQuestions.take(5).map((question) async {
            if (!imageAspectRatios.containsKey(question.soru)) {
              final aspectRatio = await getImageAspectRatio(question.soru);
              imageAspectRatios[question.soru] = aspectRatio ?? 1.0;
            }
          }),
        );
        loadingProgress.value =
            (totalFetched / (totalFetched + batchSize)) * 0.6;

        final cevapSnapshots = await Future.wait(
          validDocIDs.map(
            (docID) => FirebaseFirestore.instance
                .collection('SoruBankasi')
                .doc(docID)
                .collection('Cevaplayanlar')
                .doc(userID)
                .get(),
          ),
        );
        int cevapIndex = 0;

        for (var question in tempQuestions) {
          if (question.docID.isEmpty) {
            log("Geçersiz docID: ${question.soru}");
            continue;
          }

          final cevapSnapshot = cevapSnapshots[cevapIndex++];
          if (cevapSnapshot.exists) {
            final data = cevapSnapshot.data()!;
            final cevap = data['cevap'] as String?;
            if (cevap != null) {
              selectedAnswers[question.soru] = cevap;
              initialAnswers[question.soru] = cevap;
              answerStates[question.soru] = cevap == question.dogruCevap;
            } else {
              selectedAnswers[question.soru] = '';
              initialAnswers[question.soru] = '';
              answerStates[question.soru] = false;
            }
          } else {
            selectedAnswers[question.soru] = '';
            initialAnswers[question.soru] = '';
            answerStates[question.soru] = false;
          }

          likedQuestions[question.soru] = question.begeniler.contains(userID);
          savedQuestions[question.soru] = question.soruCoz.contains(userID);
          loadingProgress.value =
              (totalFetched / (totalFetched + batchSize)) * 0.8;
        }

        savedQuestionsList
            .addAll(tempQuestions); // questions yerine savedQuestionsList
        sortQuestions();
        loadingProgress.value =
            (totalFetched / (totalFetched + batchSize)) * 0.9;
      }

      loadingProgress.value = 1.0;
    } catch (e) {
      log("Kaydedilen sorular çekilirken hata oluştu");
      AppSnackbar("Hata", "Kaydedilen sorular yüklenirken hata oluştu");
      loadingProgress.value = 1.0;
    }
  }

  void sortQuestions() {
    if (questions.isNotEmpty) {
      List<QuestionBankModel> tempQuestions = List.from(questions);
      tempQuestions.sort((a, b) {
        bool aAnswered = selectedAnswers[a.soru]?.isNotEmpty ?? false;
        bool bAnswered = selectedAnswers[b.soru]?.isNotEmpty ?? false;
        if (aAnswered && !bAnswered) return 1;
        if (!aAnswered && bAnswered) return -1;
        return 0;
      });
      questions.assignAll(tempQuestions);
    }
    if (savedQuestionsList.isNotEmpty) {
      List<QuestionBankModel> tempSavedQuestions =
          List.from(savedQuestionsList);
      tempSavedQuestions.sort((a, b) {
        bool aAnswered = selectedAnswers[a.soru]?.isNotEmpty ?? false;
        bool bAnswered = selectedAnswers[b.soru]?.isNotEmpty ?? false;
        if (aAnswered && !bAnswered) return 1;
        if (!aAnswered && bAnswered) return -1;
        return 0;
      });
      savedQuestionsList.assignAll(tempSavedQuestions);
    }
  }

  Future<void> addToviewers(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    if (!question.goruntuleme.contains(userID)) {
      try {
        await FirebaseFirestore.instance
            .collection('SoruBankasi')
            .doc(question.docID)
            .update({
          'goruntuleme': FieldValue.arrayUnion([userID]),
        });
      } catch (e) {
        AppSnackbar("Hata", "Görüntüleme güncellenirken hata");
      }
    }
  }

  Future<void> addToSonraCoz(QuestionBankModel question) async {
    if (question.docID.isEmpty) return;
    final isSaved = savedQuestions[question.soru] ?? false;
    try {
      await FirebaseFirestore.instance
          .collection('SoruBankasi')
          .doc(question.docID)
          .update({
        'soruCoz': isSaved
            ? FieldValue.arrayRemove([userID])
            : FieldValue.arrayUnion([userID]),
      });
      savedQuestions[question.soru] = !isSaved;
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
    final isLiked = likedQuestions[question.soru] ?? false;
    try {
      await FirebaseFirestore.instance
          .collection('SoruBankasi')
          .doc(question.docID)
          .update({
        'begeniler': isLiked
            ? FieldValue.arrayRemove([userID])
            : FieldValue.arrayUnion([userID]),
      });

      if (isLiked) {
        question.begeniler.remove(userID);
      } else {
        question.begeniler.add(userID);
      }
      likedQuestions[question.soru] = !isLiked;
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
    if (!question.paylasanlar.contains(userID)) {
      try {
        await FirebaseFirestore.instance
            .collection('SoruBankasi')
            .doc(question.docID)
            .update({
          'paylasanlar': FieldValue.arrayUnion([userID]),
        });

        final response = await http.get(Uri.parse(question.soru));
        if (response.statusCode == 200) {
          final Uint8List imageBytes = response.bodyBytes;

          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/question_${question.docID}.png');
          await file.writeAsBytes(imageBytes);

          final shareText = '''
✨ TurqApp ile 'Çöz Geç' Jimnastiği! ✨
📚 Sınav Türü: ${question.sinavTuru}
📖 Ders: ${question.ders}
🔢 Soru Numarası: ${question.soruNo}

Bu zorlu soruyu çözmeye hazır mısın? 🚀 
TurqApp ile kendini test et, bilgini güçlendir! 💪

 iOS: https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr

🤖 Android: https://play.google.com/store/apps/details?id=com.turqapp.app

#TurqApp #Eğitim #ÇözGeç
''';

          // Share the image and text
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'image/png')],
              text: shareText,
              subject:
                  'TurqApp - ${question.sinavTuru} ${question.ders} Sorusu',
            ),
          );

          // Clean up the temporary file
          await file.delete();
        } else {
          AppSnackbar("Hata", "Soru görseli yüklenemedi");
        }
      } catch (e) {
        AppSnackbar("Hata", "Paylaşım eklenirken hata");
      }
    }
  }

  Future<void> submitAnswer(
    String selectedAnswer,
    QuestionBankModel question,
  ) async {
    if (question.docID.isEmpty) return;

    if (selectedAnswers[question.soru]!.isNotEmpty) {
      AppSnackbar("Bilgi", "Bu sorunun cevabını değiştiremezsiniz!");
      return;
    }

    bool isFirstAnswer = selectedAnswers[question.soru]!.isEmpty;
    selectedAnswers[question.soru] = selectedAnswer;
    if (isFirstAnswer) {
      initialAnswers[question.soru] = selectedAnswer;
    }
    bool isCorrect = selectedAnswer == question.dogruCevap;
    answerStates[question.soru] = isCorrect;
    justAnswered.value =
        isCorrect ? 'correct' : 'incorrect'; // Set answer status

    try {
      await FirebaseFirestore.instance
          .collection('SoruBankasi')
          .doc(question.docID)
          .collection('Cevaplayanlar')
          .doc(userID)
          .set({
        'cevap': selectedAnswer,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });

      final docRef = FirebaseFirestore.instance
          .collection('SoruBankasi')
          .doc(question.docID);
      if (isCorrect) {
        if (!question.dogruCevapVerenler.contains(userID)) {
          await docRef.update({
            'dogruCevapVerenler': FieldValue.arrayUnion([userID]),
            'yanlisCevapVerenler': FieldValue.arrayRemove([userID]),
          });
        }
      } else {
        if (!question.yanlisCevapVerenler.contains(userID)) {
          await docRef.update({
            'yanlisCevapVerenler': FieldValue.arrayUnion([userID]),
            'dogruCevapVerenler': FieldValue.arrayRemove([userID]),
          });
        }
      }

      if (isFirstAnswer) {
        int currentAntPoint = await getAntPoint();
        int newAntPoint =
            isCorrect ? currentAntPoint + 10 : currentAntPoint - 3;
        if (newAntPoint < 0) newAntPoint = 0;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .update({'antPoint': newAntPoint});
        // AppSnackbar(
        //   "Sonuç",
        //   isCorrect ? "Doğru cevap! +10 puan" : "Yanlış cevap! -3 puan",
        // );
      }

      nextQuestion();
    } catch (e) {
      AppSnackbar("Hata", "Cevap kaydedilirken hata");
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
    Set<String> anaBaslikSet = {};
    Set<String> dersSet = {};
    Set<String> sinavTuruSet = {};

    final querySnapshot =
        await FirebaseFirestore.instance.collection('SoruBankasi').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data();

      if (data['anaBaslik'] != null) {
        anaBaslikSet.add(data['anaBaslik']);
      }
      if (data['ders'] != null) {
        dersSet.add(data['ders']);
      }
      if (data['sinavTuru'] != null) {
        sinavTuruSet.add(data['sinavTuru']);
      }
    }

    log('Ana Başlıklar: ${anaBaslikSet.toList()}');
    log('Dersler: ${dersSet.toList()}');
    log('Sınav Türleri: ${sinavTuruSet.toList()}');
  }

  Future<void> fetchMoreQuestions() async {
    if (loadingProgress.value >= 1.0 || questions.isEmpty) return;

    try {
      DocumentSnapshot? lastDocument = questions.isNotEmpty
          ? (await FirebaseFirestore.instance
              .collection('SoruBankasi')
              .doc(questions.last.docID)
              .get())
          : null;

      Query query = FirebaseFirestore.instance
          .collection('SoruBankasi')
          .where('anaBaslik',
              isEqualTo: selectedSinavTuru.value.isNotEmpty
                  ? selectedSinavTuru.value
                  : selectedSubject.value)
          .where('sinavTuru', isEqualTo: selectedSinavTuru.value)
          .where('ders', isEqualTo: selectedSubject.value)
          .orderBy('soruNo', descending: false)
          .limit(batchSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        loadingProgress.value = 1.0;
        return;
      }

      int totalFetched = questions.length + snapshot.docs.length;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docID'] = doc.id;
        final question = QuestionBankModel.fromJson(data);
        questions.add(question);

        // Initialize basic states
        selectedAnswers[question.soru] = '';
        initialAnswers[question.soru] = '';
        answerStates[question.soru] = false;
        likedQuestions[question.soru] = question.begeniler.contains(userID);
        savedQuestions[question.soru] = question.soruCoz.contains(userID);
      }

      // Update progress
      loadingProgress.value = (totalFetched / (totalFetched + batchSize)) * 0.6;

      // Fetch user answers for the new batch
      final newDocs =
          questions.skip(questions.length - snapshot.docs.length).toList();
      final docIds = newDocs.map((q) => q.docID).toList();
      final cevapSnapshots = await Future.wait(
        docIds.map(
          (docID) => FirebaseFirestore.instance
              .collection('SoruBankasi')
              .doc(docID)
              .collection('Cevaplayanlar')
              .doc(userID)
              .get(),
        ),
      );

      for (int i = 0; i < newDocs.length; i++) {
        final question = newDocs[i];
        final cevapSnapshot = cevapSnapshots[i];
        if (cevapSnapshot.exists) {
          final data = cevapSnapshot.data()!;
          final cevap = data['cevap'] as String?;
          if (cevap != null) {
            selectedAnswers[question.soru] = cevap;
            initialAnswers[question.soru] = cevap;
            answerStates[question.soru] = cevap == question.dogruCevap;
          }
        }
      }
      sortQuestions();

      await Future.wait(
        newDocs.take(5).map((question) async {
          if (!imageAspectRatios.containsKey(question.soru)) {
            final aspectRatio = await getImageAspectRatio(question.soru);
            imageAspectRatios[question.soru] = aspectRatio ?? 1.0;
          }
        }),
      );

      loadingProgress.value = (totalFetched / (totalFetched + batchSize)) * 0.9;
    } catch (e) {
      log("Daha fazla soru çekilirken hata oluştu: $e");
      AppSnackbar("Hata", "Daha fazla soru çekilirken hata oluştu");
      loadingProgress.value = 1.0;
    }
  }
}
