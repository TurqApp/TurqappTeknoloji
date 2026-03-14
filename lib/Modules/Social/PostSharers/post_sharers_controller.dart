import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';

class PostSharersController extends GetxController {
  final String postID;

  PostSharersController({required this.postID});

  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;
  final UserRepository _userRepository = UserRepository.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    loadPostSharers();
  }

  Future<void> loadPostSharers() async {
    try {
      isLoading.value = true;

      final sharers = await _postRepository.fetchPostSharers(postID);
      final Set<String> userIDs = {};

      for (final sharer in sharers) {
        userIDs.add(sharer.userID);
      }

      postSharers.value = sharers;

      // Load user data for all sharers
      await loadUsersData(userIDs.toList());
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUsersData(List<String> userIDs) async {
    try {
      final Map<String, Map<String, dynamic>> userData = {};
      final rawUsers = await _userRepository.getUsersRaw(userIDs.toSet().toList());
      for (final userID in userIDs.toSet()) {
        final data = rawUsers[userID];
        if (data == null) {
          userData[userID] = {
            'nickname': 'Bilinmeyen Kullanıcı',
            'avatarUrl': '',
            'fullName': 'Bilinmeyen Kullanıcı',
            'firstName': '',
            'lastName': '',
          };
          continue;
        }
        final firstName = (data['firstName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        final fullName = ('$firstName $lastName').trim();

        userData[userID] = {
          'nickname':
              data['displayName'] ?? data['username'] ?? data['nickname'] ?? '',
          'avatarUrl': (data['avatarUrl'] ?? '').toString(),
          'fullName': fullName.isNotEmpty ? fullName : 'Bilinmeyen Kullanıcı',
          'firstName': firstName,
          'lastName': lastName,
        };
      }

      usersData.value = userData;
    } catch (_) {
    }
  }

  Future<void> refreshSharers() async {
    await loadPostSharers();
  }
}
