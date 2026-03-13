import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class MyScholarshipController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  var isLoading = true.obs;
  final myScholarships = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyScholarships();
  }

  Future<void> fetchMyScholarships() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final rawScholarships = await _scholarshipRepository.fetchMyScholarshipsRaw(
        user.uid,
        limit: 50,
      );

      final scholarships = <Map<String, dynamic>>[];

      final userIds = <String>{};
      for (final data in rawScholarships) {
        final userID = data['userID'] as String? ?? '';
        if (userID.isNotEmpty) userIds.add(userID);
      }

      final userDataMap = <String, Map<String, dynamic>>{};
      final fetchedUsers = userIds.isEmpty
          ? <String, Map<String, dynamic>>{}
          : await _userRepository.getUsersRaw(userIds.toList());
      for (final entry in fetchedUsers.entries) {
          final user = entry.value;
          final profileImage = (user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  '')
              .toString();
          final profileName = (user['displayName'] ??
                  user['username'] ??
                  user['nickname'] ??
                  '')
              .toString();
          userDataMap[entry.key] = {
            'avatarUrl': profileImage,
            'nickname': profileName,
            'displayName': profileName,
            'userID': entry.key,
          };
      }

      for (final data in rawScholarships) {
        try {
          final userID = data['userID'] as String? ?? '';
          final userData = userDataMap[userID] ??
              {'avatarUrl': '', 'nickname': '', 'userID': userID};

          scholarships.add({
            'model': IndividualScholarshipsModel.fromJson(data),
            'type': 'bireysel',
            'userData': userData,
            'docId': (data['docId'] ?? '').toString(),
          });
        } catch (e) {
          AppSnackbar('Hata', 'Burs verisi işlenemedi.');
        }
      }

      myScholarships.value = scholarships;
    } catch (e) {
      AppSnackbar('Hata', 'Veriler yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }
}
