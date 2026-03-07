import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/post_sharers_model.dart';

class PostSharersController extends GetxController {
  final String postID;

  PostSharersController({required this.postID});

  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;
  static const int _whereInChunkSize = 10;

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

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
      for (final chunk
          in _chunkList(userIDs.toSet().toList(), _whereInChunkSize)) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          final foundIds = snap.docs.map((d) => d.id).toSet();

          for (final userDoc in snap.docs) {
            final data = userDoc.data();
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            final fullName = ('$firstName $lastName').trim();

            userData[userDoc.id] = {
              'nickname': data['displayName'] ??
                  data['username'] ??
                  data['nickname'] ??
                  '',
              'avatarUrl':   '',
              'fullName':
                  fullName.isNotEmpty ? fullName : 'Bilinmeyen Kullanıcı',
              'firstName': firstName,
              'lastName': lastName,
            };
          }

          for (final missingId in chunk.where((id) => !foundIds.contains(id))) {
            userData[missingId] = {
              'nickname': 'Bilinmeyen Kullanıcı',
              'avatarUrl': '',
              'fullName': 'Bilinmeyen Kullanıcı',
              'firstName': '',
              'lastName': '',
            };
          }
        } catch (e) {
          print('Error loading users data chunk: $e');
          for (final userID in chunk) {
            userData[userID] = {
              'nickname': 'Bilinmeyen Kullanıcı',
              'avatarUrl': '',
              'fullName': 'Bilinmeyen Kullanıcı',
              'firstName': '',
              'lastName': '',
            };
          }
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
