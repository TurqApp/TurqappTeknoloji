import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class SavedItemsController extends GetxController {
  final isLoading = false.obs;
  final likedScholarships = <Map<String, dynamic>>[].obs;
  final bookmarkedScholarships = <Map<String, dynamic>>[].obs;
  final selectedTabIndex = 0.obs;
  final pageController = PageController();

  Stream<List<Map<String, dynamic>>>? _likedStream;
  Stream<List<Map<String, dynamic>>>? _bookmarkedStream;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    bindStreams();
  }

  void bindStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    final userId = user.uid;
    print('User ID: $userId');

    _likedStream = _createScholarshipStream(userId, isLiked: true);
    _bookmarkedStream = _createScholarshipStream(userId, isBookmarked: true);

    likedScholarships.bindStream(_likedStream!);
    bookmarkedScholarships.bindStream(_bookmarkedStream!);
  }

  Stream<List<Map<String, dynamic>>> _createScholarshipStream(
    String userId, {
    bool isLiked = false,
    bool isBookmarked = false,
  }) async* {
    try {
      isLoading.value = true;

      final bireyselStream = FirebaseFirestore.instance
          .collection('BireyselBurslar')
          .where(
            isLiked ? 'begeniler' : 'kaydedenler',
            arrayContains: userId,
          )
          .snapshots();

      // Kurumsal burslar kaldırıldı

      bireyselStream.listen((snapshot) {
        print(
          'Bireysel snapshot: ${snapshot.docs.length} docs, time: ${DateTime.now()}',
        );
      });
      //

      yield* bireyselStream
          .asyncMap((snapshot) async {
        final startTime = DateTime.now();
        final scholarships = <Map<String, dynamic>>[];
        print('Processing snapshot, docs: ${snapshot.docs.length}');

        {
          print(
            'Processing Bireysel snapshot, docs: ${snapshot.docs.length}',
          );

          final userFutures = <Future<DocumentSnapshot>>[];
          final userIds = <String>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final userID = data['userID'] as String? ?? '';
            if (userID.isNotEmpty) {
              userIds.add(userID);
              userFutures.add(
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userID)
                    .get(),
              );
            }
          }

          final userDocs =
              userFutures.isNotEmpty ? await Future.wait(userFutures) : [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final begeniler = data['begeniler'] as List<dynamic>? ?? [];
            final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
            print(
              'Doc ID: ${doc.id}, begeniler: $begeniler, kaydedenler: $kaydedenler',
            );

            try {
                final userID = data['userID'] as String? ?? '';
                var userData = {
                  'pfImage': '',
                  'nickname': '',
                  'userID': userID,
                };

                if (userID.isNotEmpty) {
                  final index = userIds.indexOf(userID);
                  if (index != -1 && userDocs[index].exists) {
                    userData = {
                      'pfImage':
                          userDocs[index].data()?['pfImage'] as String? ?? '',
                      'nickname':
                          userDocs[index].data()?['nickname'] as String? ?? '',
                      'userID': userID,
                    };
                  }
                }

                scholarships.add({
                  'model': IndividualScholarshipsModel.fromJson(data),
                  'type': 'bireysel',
                  'userData': userData,
                  'docId': doc.id,
                  'likesCount': begeniler.length,
                  'bookmarksCount': kaydedenler.length,
                });
                print('Added bireysel scholarship: ${doc.id}');
            } catch (e) {
              print('Error processing doc ${doc.id}: $e');
              AppSnackbar('Hata', 'Burs verisi işlenemedi.');
            }
          }
        }

        print(
          'Total scholarships: ${scholarships.length}, processing time: ${DateTime.now().difference(startTime).inMilliseconds}ms',
        );
        // Fix: Set isLoading to false when no scholarships are found
        isLoading.value = scholarships.isNotEmpty ? false : false;
        return scholarships;
      }).handleError((e) {
        AppSnackbar('Hata', 'Veriler yüklenemedi.');
        print('Stream error: $e');
        isLoading.value = false;
      });
    } catch (e) {
      print('Stream setup error: $e');
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    final userId = user.uid;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('BireyselBurslar').doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final begeniler = List<String>.from(doc.data()?['begeniler'] ?? []);
      if (begeniler.contains(userId)) {
        begeniler.remove(userId);
      } else {
        begeniler.add(userId);
      }

      await docRef.update({'begeniler': begeniler});
      print('Updated begeniler for $docId: $begeniler');

      // Stream otomatik olarak güncellenir, manuel liste güncellemesi gerekmez
    } catch (e) {
      AppSnackbar('Hata', 'Beğeni işlemi başarısız.');
      print('toggleLike error: $e');
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      return;
    }
    final userId = user.uid;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('BireyselBurslar').doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final kaydedenler = List<String>.from(doc.data()?['kaydedenler'] ?? []);
      if (kaydedenler.contains(userId)) {
        kaydedenler.remove(userId);
      } else {
        kaydedenler.add(userId);
      }

      await docRef.update({'kaydedenler': kaydedenler});
      print('Updated kaydedenler for $docId: $kaydedenler');

      // Stream otomatik olarak güncellenir, manuel liste güncellemesi gerekmez
    } catch (e) {
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
      print('toggleBookmark error: $e');
    }
  }

  void onTabChanged(int index) {
    selectedTabIndex.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 120),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    likedScholarships.close();
    bookmarkedScholarships.close();
    super.onClose();
  }
}
