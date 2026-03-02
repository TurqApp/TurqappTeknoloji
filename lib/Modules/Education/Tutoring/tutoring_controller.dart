import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class TutoringController extends GetxController {
  final FocusNode focusNode = FocusNode();
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  var tutoringList = <TutoringModel>[].obs;
  var users = <String, Map<String, dynamic>>{}.obs;
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollOffset = 0.0.obs;
  StreamSubscription<QuerySnapshot>? _tutoringSubscription;
  DocumentSnapshot? _lastDocument;

  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    listenToTutoringData();
  }

  @override
  void onClose() {
    _tutoringSubscription?.cancel();
    focusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }

  /// Batch fetch user data for a set of userIDs (max 30 per whereIn)
  Future<void> _batchFetchUsers(Set<String> userIds) async {
    // Filter out already-fetched users
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      for (var i = 0; i < toFetch.length; i += 30) {
        final batch = toFetch.skip(i).take(30).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (var doc in snap.docs) {
          users[doc.id] = doc.data();
        }
      }
    } catch (e) {
      log("Error batch fetching users: $e");
    }
  }

  void listenToTutoringData() {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    _tutoringSubscription?.cancel();
    _tutoringSubscription = FirebaseFirestore.instance
        .collection('educators')
        .orderBy('timeStamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((QuerySnapshot querySnapshot) async {
      try {
        List<TutoringModel> tempList = querySnapshot.docs
            .map(
              (doc) => TutoringModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .where((t) => t.ended != true)
            .toList();

        log("Fetched ${tempList.length} tutoring items");

        if (querySnapshot.docs.isNotEmpty) {
          _lastDocument = querySnapshot.docs.last;
        }
        if (querySnapshot.docs.length < _pageSize) {
          hasMore.value = false;
        }

        // Batch fetch all users at once
        final userIds = tempList.map((t) => t.userID).toSet();
        await _batchFetchUsers(userIds);

        tutoringList.value = _applyPersonalization(tempList);
      } catch (e) {
        log("Error processing tutoring stream: $e");
        tutoringList.value = [];
      } finally {
        isLoading.value = false;
      }
    }, onError: (e) {
      log("Error listening to tutoring data: $e");
      isLoading.value = false;
    });
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('educators')
          .orderBy('timeStamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      final newItems = querySnapshot.docs
          .map(
            (doc) => TutoringModel.fromJson(
              doc.data(),
              doc.id,
            ),
          )
          .where((t) => t.ended != true)
          .toList();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }
      if (querySnapshot.docs.length < _pageSize) {
        hasMore.value = false;
      }

      // Batch fetch users for new items
      final userIds = newItems.map((t) => t.userID).toSet();
      await _batchFetchUsers(userIds);

      tutoringList.addAll(newItems);
    } catch (e) {
      log("Error loading more tutoring data: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Kişiselleştirilmiş sıralama puanı.
  /// Doğrulanmış (+3), kullanıcı şehrinde (+2), yüksek puan (+0-2).
  double _personalizedScore(TutoringModel t) {
    double score = 0;
    if (t.verified == true) score += 3;
    if (t.averageRating != null) {
      score += (t.averageRating!.toDouble() / 5.0) * 2.0;
    }
    // Kullanıcı şehri ile eşleşme
    try {
      final userCity = CurrentUserService.instance.currentUser?.city;
      if (userCity != null && userCity.isNotEmpty && t.sehir == userCity) {
        score += 2;
      }
    } catch (_) {}
    return score;
  }

  /// Listeyi kişiselleştir (doğrulanmış + aynı şehir + yüksek puan öne çık).
  List<TutoringModel> _applyPersonalization(List<TutoringModel> list) {
    final sorted = List<TutoringModel>.from(list);
    sorted.sort((a, b) {
      final scoreA = _personalizedScore(a);
      final scoreB = _personalizedScore(b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return 0; // Eşit puanda orijinal sırayı koru
    });
    return sorted;
  }

  Future<void> toggleFavorite(
    String docId,
    String userId,
    bool isFavorite,
  ) async {
    final tutoringIndex = tutoringList.indexWhere((t) => t.docID == docId);
    if (tutoringIndex == -1) return;

    // Optimistic local update
    final currentTutoring = tutoringList[tutoringIndex];
    final oldFavorites = List<String>.from(currentTutoring.favorites);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('educators').doc(docId);

      if (isFavorite) {
        await docRef.update({
          'favorites': FieldValue.arrayRemove([userId])
        });
      } else {
        await docRef.update({
          'favorites': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      // Rollback on error
      tutoringList[tutoringIndex] = currentTutoring.copyWith(
        favorites: oldFavorites,
      );
      tutoringList.refresh();
      log("Error toggling favorite: $e");
    }
  }
}

extension TutoringModelExtension on TutoringModel {
  TutoringModel copyWith({
    String? docID,
    String? aciklama,
    String? baslik,
    String? brans,
    String? cinsiyet,
    List<String>? dersYeri,
    num? end,
    List<String>? favorites,
    num? fiyat,
    List<String>? imgs,
    String? ilce,
    bool? onayVerildi,
    String? sehir,
    bool? telefon,
    num? timeStamp,
    String? userID,
    bool? whatsapp,
    bool? ended,
    num? endedAt,
    num? viewCount,
    num? applicationCount,
    num? averageRating,
    num? reviewCount,
    Map<String, List<String>>? availability,
    double? lat,
    double? long,
    bool? verified,
    List<String>? verificationDocs,
  }) {
    return TutoringModel(
      docID: docID ?? this.docID,
      aciklama: aciklama ?? this.aciklama,
      baslik: baslik ?? this.baslik,
      brans: brans ?? this.brans,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      dersYeri: dersYeri ?? this.dersYeri,
      end: end ?? this.end,
      favorites: favorites ?? this.favorites,
      fiyat: fiyat ?? this.fiyat,
      imgs: imgs ?? this.imgs,
      ilce: ilce ?? this.ilce,
      onayVerildi: onayVerildi ?? this.onayVerildi,
      sehir: sehir ?? this.sehir,
      telefon: telefon ?? this.telefon,
      timeStamp: timeStamp ?? this.timeStamp,
      userID: userID ?? this.userID,
      whatsapp: whatsapp ?? this.whatsapp,
      ended: ended ?? this.ended,
      endedAt: endedAt ?? this.endedAt,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      availability: availability ?? this.availability,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      verified: verified ?? this.verified,
      verificationDocs: verificationDocs ?? this.verificationDocs,
    );
  }
}
