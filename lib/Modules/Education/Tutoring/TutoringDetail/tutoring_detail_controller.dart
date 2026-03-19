import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

class TutoringDetailController extends GetxController {
  var isLoading = true.obs;
  var tutoring = TutoringModel(
    docID: '',
    aciklama: '',
    baslik: '',
    brans: '',
    cinsiyet: '',
    dersYeri: [],
    end: 0,
    favorites: [],
    fiyat: 0,
    ilce: '',
    onayVerildi: false,
    sehir: '',
    telefon: false,
    timeStamp: 0,
    userID: '',
    whatsapp: false,
    imgs: null,
  ).obs;
  var users = <String, Map<String, dynamic>>{}.obs;
  var carouselCurrentIndex = 0.obs;

  // Application state
  final basvuruldu = false.obs;

  // Similar listings
  final similarList = <TutoringModel>[].obs;
  final similarUsers = <String, Map<String, dynamic>>{}.obs;

  // Reviews
  final reviews = <TutoringReviewModel>[].obs;
  final reviewUsers = <String, Map<String, dynamic>>{}.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    final tutoringData = Get.arguments as TutoringModel?;
    if (tutoringData != null) {
      fetchTutoringDetail(tutoringData.docID);
      fetchUserData(tutoringData.userID);
      checkBasvuru(tutoringData.docID);
      getSimilar(tutoringData.brans, tutoringData.docID);
      fetchReviews(tutoringData.docID);
      _incrementViewCount(tutoringData.docID, tutoringData.userID);
    }
  }

  Future<void> fetchUserData(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        users[userID] = summary.toMap();
      }
    } catch (_) {
    }
  }

  Future<void> fetchTutoringDetail(String docID) async {
    isLoading.value = true;
    try {
      final document = await _tutoringRepository.fetchById(
        docID,
        allowExpired: true,
      );
      if (document != null) {
        tutoring.value = document;
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // ── Application ──

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      basvuruldu.value = await _tutoringRepository.hasApplication(docID, uid);
    } catch (_) {
      basvuruldu.value = false;
    }
  }

  Future<void> toggleBasvuru(String docId) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar('common.error'.tr, 'tutoring.apply_login_required'.tr);
      return;
    }

    try {
      final t = tutoring.value;
      final ownerData = users[t.userID];
      final tutorName =
          (ownerData?['displayName'] ?? ownerData?['nickname'] ?? '')
              .toString()
              .trim();
      final tutorImage = (ownerData?['avatarUrl'] ?? '').toString();
      final currentUserSummary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
      );
      final applicantName = currentUserSummary?.displayName.trim() ?? '';
      final applicantLabel =
          applicantName.isNotEmpty ? applicantName : 'Bir kullanıcı';
      final applicantImage = currentUserSummary?.avatarUrl.trim() ?? '';

      final isApplied = await _tutoringRepository.toggleApplication(
        tutoringId: docId,
        ownerUid: tutoring.value.userID,
        userId: uid,
        tutoringTitle: t.baslik,
        tutorName: tutorName,
        tutorImage: tutorImage,
        applicantLabel: applicantLabel,
        applicantImage: applicantImage,
      );
      basvuruldu.value = isApplied;
      if (isApplied) {
        AppSnackbar('common.success'.tr, 'tutoring.application_sent'.tr);
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tutoring.application_failed'.tr);
    }
  }

  // ── View Count ──

  Future<void> _incrementViewCount(String docID, String ownerUID) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      if (uid == ownerUID) return;
      await _tutoringRepository.incrementViewCount(docID);
    } catch (_) {}
  }

  // ── Unpublish ──

  Future<void> unpublishTutoring() async {
    final docId = tutoring.value.docID;
    try {
      await _tutoringRepository.unpublish(docId);
    } catch (_) {
    }
  }

  // ── Similar ──

  Future<void> getSimilar(String brans, String currentDocID) async {
    try {
      final items = await _tutoringRepository.fetchSimilarByBranch(
        brans,
        currentDocID,
      );

      // Fetch users for similar items
      final userIds = items.map((t) => t.userID).toSet();
      final toFetch =
          userIds.where((id) => !similarUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final summaries = await _userSummaryResolver.resolveMany(batch);
          for (final entry in summaries.entries) {
            similarUsers[entry.key] = entry.value.toMap();
          }
        }
      }

      similarList.assignAll(items);
    } catch (_) {
    }
  }

  // ── Reviews ──

  Future<void> fetchReviews(String docID) async {
    try {
      final items = await _tutoringRepository.fetchReviews(docID);

      // Fetch users for reviews
      final userIds = items.map((r) => r.userID).toSet();
      final toFetch =
          userIds.where((id) => !reviewUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final summaries = await _userSummaryResolver.resolveMany(batch);
          for (final entry in summaries.entries) {
            reviewUsers[entry.key] = entry.value.toMap();
          }
        }
      }

      reviews.assignAll(items);
    } catch (_) {
    }
  }

  Future<void> submitReview(String docID, int rating, String comment) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _tutoringRepository.submitReview(
        tutoringId: docID,
        userId: uid,
        rating: rating,
        comment: comment,
      );
      await fetchReviews(docID);
    } catch (_) {
    }
  }

  Future<void> deleteReview(String docID, String reviewID) async {
    try {
      await _tutoringRepository.deleteReview(
        tutoringId: docID,
        reviewId: reviewID,
      );
      await fetchReviews(docID);
    } catch (_) {
    }
  }
}
