import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

class ScholarshipProvidersController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final isLoading = true.obs;
  final providers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    try {
      isLoading.value = true;

      // Sadece son 200 burstan unique provider'ları çek
      final scholarships = await _scholarshipRepository.fetchLatestRaw(limit: 200);

      final seenUserIDs = <String>{};
      for (final bursDoc in scholarships) {
        final userID = bursDoc['userID'] as String?;
        if (userID != null && userID.isNotEmpty) {
          seenUserIDs.add(userID);
        }
      }

      if (seenUserIDs.isEmpty) {
        providers.clear();
        return;
      }

      // Batch user fetch (max 30 per whereIn)
      final providerList = <Map<String, dynamic>>[];
      final userIdsList = seenUserIDs.toList();
      for (var i = 0; i < userIdsList.length; i += 30) {
        final end =
            (i + 30) > userIdsList.length ? userIdsList.length : (i + 30);
        final batchIds = userIdsList.sublist(i, end);
        final users = await _userRepository.getUsers(batchIds);
        for (final entry in users.entries) {
          final userDocId = entry.key;
          final user = entry.value.toMap();
          final profileImage = (user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  user['avatarUrl'] ??
                  '')
              .toString();
          final profileName = (user['displayName'] ??
                  user['username'] ??
                  user['nickname'] ??
                  'Bilinmeyen')
              .toString();
          providerList.add({
            'userID': userDocId,
            'avatarUrl': profileImage,
            'nickname': profileName,
            'displayName': profileName,
            'rozet': user['rozet'] as String? ?? '',
          });
        }
      }

      providers.assignAll(providerList);
    } catch (e) {
      AppSnackbar('Hata', 'Burs verenler yüklenemedi.');
    } finally {
      isLoading.value = false;
    }
  }
}
