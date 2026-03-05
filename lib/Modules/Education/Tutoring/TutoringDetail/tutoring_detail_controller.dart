import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';

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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (userDoc.exists) {
        final raw = userDoc.data() as Map<String, dynamic>? ?? {};
        final profileImage = (raw['avatarUrl'] ??
                raw['pfImage'] ??
                raw['photoURL'] ??
                raw['profileImageUrl'] ??
                '')
            .toString();
        final profileName =
            (raw['displayName'] ?? raw['username'] ?? raw['nickname'] ?? '')
                .toString();
        users[userID] = {
          ...raw,
          'avatarUrl': profileImage,
          'pfImage': profileImage,
          'displayName': profileName,
          'nickname': profileName,
        };
      }
    } catch (e) {
      log("Error fetching user data: $e");
    }
  }

  Future<void> fetchTutoringDetail(String docID) async {
    isLoading.value = true;
    try {
      final document = await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .get();
      if (document.exists) {
        tutoring.value = TutoringModel.fromJson(
            document.data() as Map<String, dynamic>, docID);
      } else {
        log("Tutoring document does not exist");
      }
    } catch (e) {
      log("Error fetching tutoring detail: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ── Application ──

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .collection('Applications')
          .doc(uid)
          .get();
      basvuruldu.value = snap.exists;
    } catch (e) {
      log("checkBasvuru error: $e");
      basvuruldu.value = false;
    }
  }

  Future<void> toggleBasvuru(String docId) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar('Hata', 'Başvuru için tekrar giriş yapın.');
      return;
    }

    final educatorAppRef = FirebaseFirestore.instance
        .collection('educators')
        .doc(docId)
        .collection('Applications')
        .doc(uid);
    final userAppRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('myTutoringApplications')
        .doc(docId);
    final ownerNotificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(tutoring.value.userID)
        .collection('notifications')
        .doc();
    final educatorDocRef =
        FirebaseFirestore.instance.collection('educators').doc(docId);

    try {
      final snap = await educatorAppRef.get();
      final batch = FirebaseFirestore.instance.batch();

      if (snap.exists) {
        // Cancel application
        batch.delete(educatorAppRef);
        batch.delete(userAppRef);
        batch.update(
            educatorDocRef, {'applicationCount': FieldValue.increment(-1)});
        await batch.commit();

        // Prevent negative count
        final docSnap = await educatorDocRef.get();
        if (docSnap.exists) {
          final count = (docSnap.data()?['applicationCount'] ?? 0) as num;
          if (count < 0) {
            await educatorDocRef.update({'applicationCount': 0});
          }
        }

        basvuruldu.value = false;
      } else {
        // Apply
        final now = DateTime.now().millisecondsSinceEpoch;
        final t = tutoring.value;
        final ownerData = users[t.userID];
        final tutorName =
            '${ownerData?['firstName'] ?? ''} ${ownerData?['lastName'] ?? ''}'
                .trim();
        final tutorImage = (ownerData?['avatarUrl'] ??
                ownerData?['pfImage'] ??
                ownerData?['photoURL'] ??
                '')
            .toString();
        final currentUserDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final currentUserData = currentUserDoc.data() ?? const {};
        final applicantName = [
          (currentUserData['firstName'] ?? '').toString().trim(),
          (currentUserData['lastName'] ?? '').toString().trim(),
        ].where((e) => e.isNotEmpty).join(' ').trim();
        final applicantLabel = applicantName.isNotEmpty
            ? applicantName
            : (currentUserData['displayName'] ??
                    currentUserData['username'] ??
                    currentUserData['nickname'] ??
                    'Bir kullanıcı')
                .toString();
        final applicantImage = (currentUserData['avatarUrl'] ??
                currentUserData['pfImage'] ??
                currentUserData['photoURL'] ??
                currentUserData['profileImageUrl'] ??
                '')
            .toString();

        batch.set(educatorAppRef, {
          'timeStamp': now,
          'status': 'pending',
          'statusUpdatedAt': now,
          'note': '',
          'tutoringTitle': t.baslik,
          'tutorName': tutorName,
          'tutorImage': tutorImage,
        });

        batch.set(userAppRef, {
          'timeStamp': now,
          'tutoringTitle': t.baslik,
          'tutorName': tutorName,
          'tutorImage': tutorImage,
          'status': 'pending',
          'userID': uid,
        });

        batch.update(educatorDocRef, {
          'applicationCount': FieldValue.increment(1),
        });
        batch.set(ownerNotificationRef, {
          'type': 'tutoring_application',
          'fromUserID': uid,
          'postID': docId,
          'timeStamp': now,
          'read': false,
          'title': applicantLabel,
          'body': '${t.baslik} ilanina basvuru yapti',
          'thumbnail': applicantImage,
        });

        await batch.commit();
        basvuruldu.value = true;
        AppSnackbar('Başarılı', 'Başvurun gönderildi.');
      }
    } catch (e) {
      log("toggleBasvuru error: $e");
      AppSnackbar('Hata', 'Başvuru sırasında bir sorun oluştu.');
    }
  }

  // ── View Count ──

  Future<void> _incrementViewCount(String docID, String ownerUID) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      if (uid == ownerUID) return;
      await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .update({'viewCount': FieldValue.increment(1)});
    } catch (_) {}
  }

  // ── Unpublish ──

  Future<void> unpublishTutoring() async {
    final docId = tutoring.value.docID;
    final ref = FirebaseFirestore.instance.collection('educators').doc(docId);
    try {
      await ref.update({
        'ended': true,
        'endedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log("unpublishTutoring error: $e");
    }
  }

  // ── Similar ──

  Future<void> getSimilar(String brans, String currentDocID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('educators')
          .where('brans', isEqualTo: brans)
          .limit(11)
          .get();

      final items = snapshot.docs
          .map((d) => TutoringModel.fromJson(d.data(), d.id))
          .where((t) => t.docID != currentDocID && t.ended != true)
          .take(10)
          .toList();

      // Fetch users for similar items
      final userIds = items.map((t) => t.userID).toSet();
      final toFetch =
          userIds.where((id) => !similarUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (var doc in snap.docs) {
            similarUsers[doc.id] = doc.data();
          }
        }
      }

      similarList.assignAll(items);
    } catch (e) {
      log("getSimilar error: $e");
    }
  }

  // ── Reviews ──

  Future<void> fetchReviews(String docID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .collection('Reviews')
          .orderBy('timeStamp', descending: true)
          .limit(50)
          .get();

      final items = snapshot.docs
          .map((d) => TutoringReviewModel.fromMap(d.data(), d.id))
          .toList();

      // Fetch users for reviews
      final userIds = items.map((r) => r.userID).toSet();
      final toFetch =
          userIds.where((id) => !reviewUsers.containsKey(id)).toList();
      if (toFetch.isNotEmpty) {
        for (var i = 0; i < toFetch.length; i += 30) {
          final batch = toFetch.skip(i).take(30).toList();
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (var doc in snap.docs) {
            reviewUsers[doc.id] = doc.data();
          }
        }
      }

      reviews.assignAll(items);
    } catch (e) {
      log("fetchReviews error: $e");
    }
  }

  Future<void> submitReview(String docID, int rating, String comment) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .collection('Reviews')
          .doc(uid)
          .set({
        'userID': uid,
        'tutoringDocID': docID,
        'rating': rating,
        'comment': comment,
        'timeStamp': now,
      });

      // Recalculate average rating
      await _recalculateAverageRating(docID);
      await fetchReviews(docID);
    } catch (e) {
      log("submitReview error: $e");
    }
  }

  Future<void> deleteReview(String docID, String reviewID) async {
    try {
      await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .collection('Reviews')
          .doc(reviewID)
          .delete();

      await _recalculateAverageRating(docID);
      await fetchReviews(docID);
    } catch (e) {
      log("deleteReview error: $e");
    }
  }

  Future<void> _recalculateAverageRating(String docID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .collection('Reviews')
          .get();

      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('educators')
            .doc(docID)
            .update({'averageRating': null, 'reviewCount': 0});
        return;
      }

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] as num? ?? 0).toDouble();
      }
      final avg = total / snapshot.docs.length;

      await FirebaseFirestore.instance
          .collection('educators')
          .doc(docID)
          .update({
        'averageRating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': snapshot.docs.length,
      });
    } catch (e) {
      log("_recalculateAverageRating error: $e");
    }
  }
}
