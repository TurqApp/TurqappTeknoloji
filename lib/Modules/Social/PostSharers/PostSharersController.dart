import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/PostSharersModel.dart';

class PostSharersController extends GetxController {
  final String postID;

  PostSharersController({required this.postID});

  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadPostSharers();
  }

  Future<void> loadPostSharers() async {
    try {
      isLoading.value = true;

      // Get all post sharers from the subcollection
      final snapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postID)
          .collection('postSharers')
          .orderBy('timestamp', descending: true)
          .get();

      final List<PostSharersModel> sharers = [];
      final Set<String> userIDs = {};

      for (final doc in snapshot.docs) {
        final sharer = PostSharersModel.fromFirestore(doc);
        sharers.add(sharer);
        userIDs.add(sharer.userID);
      }

      postSharers.value = sharers;
      print(
          'PostSharers: Found ${sharers.length} sharers with userIDs: $userIDs');

      // Load user data for all sharers
      await loadUsersData(userIDs.toList());
    } catch (e) {
      print('Error loading post sharers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUsersData(List<String> userIDs) async {
    try {
      final Map<String, Map<String, dynamic>> userData = {};

      for (final userID in userIDs) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data() ?? {};
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            final fullName = ('$firstName $lastName').trim();

            userData[userID] = {
              'nickname': data['nickname'] ?? '',
              'pfImage': data['pfImage'] ?? '',
              'pfImageUrl':
                  data['pfImage'] ?? '', // For compatibility with the view
              'fullName':
                  fullName.isNotEmpty ? fullName : 'Bilinmeyen Kullanıcı',
              'firstName': firstName,
              'lastName': lastName,
            };
            print('PostSharers: Loaded data for $userID: ${userData[userID]}');
          } else {
            print('PostSharers: User document not found for $userID');
          }
        } catch (e) {
          print('Error loading user data for $userID: $e');
          // Add placeholder data for failed requests
          userData[userID] = {
            'nickname': 'Bilinmeyen Kullanıcı',
            'pfImage': '',
            'pfImageUrl': '',
            'fullName': 'Bilinmeyen Kullanıcı',
            'firstName': '',
            'lastName': '',
          };
        }
      }

      usersData.value = userData;
    } catch (e) {
      print('Error loading users data: $e');
    }
  }

  Future<void> refreshSharers() async {
    await loadPostSharers();
  }
}
