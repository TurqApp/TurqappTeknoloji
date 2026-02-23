import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class MyScholarshipController extends GetxController {
  var isLoading = true.obs;
  final myScholarships = <Map<String, dynamic>>[].obs;

  Stream<List<Map<String, dynamic>>>? _myScholarshipsStream;

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
      isLoading.value = false;
      return;
    }
    final userId = user.uid;
    print('User ID: $userId');

    _myScholarshipsStream = _createScholarshipStream(userId);
    myScholarships.bindStream(_myScholarshipsStream!);
  }

  Stream<List<Map<String, dynamic>>> _createScholarshipStream(
    String userId,
  ) async* {
    try {
      isLoading.value = true;

      final bireyselStream = FirebaseFirestore.instance
          .collection('BireyselBurslar')
          .where('userID', isEqualTo: userId)
          .snapshots();

      // Kurumsal burslar kaldırıldı, sadece bireysel burslar takip ediliyor

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
        isLoading.value = false;
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

  @override
  void onClose() {
    myScholarships.close();
    super.onClose();
  }
}
