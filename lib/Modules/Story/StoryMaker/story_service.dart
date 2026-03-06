import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'story_model.dart';

class StoryService {
  /// Firestore’daki “stories” koleksiyonuna referans
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('stories');

  /// Oturum açmış kullanıcıya ait hikâyeleri çeker
  Future<List<StoryModel>> fetchStoriesByCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu yok');
    }

    // userId alanına göre sorgulayalım, en yeni en başta
    final query = await _col.orderBy('createdDate', descending: true).get();

    // Her dokümandan StoryModel örneği üret
    return query.docs.map((doc) => StoryModel.fromDoc(doc)).toList();
  }

  /// Belirli bir hikâyeyi ID’siyle çeker
  Future<StoryModel> fetchStoryById(String storyId) async {
    final doc = await _col.doc(storyId).get();
    if (!doc.exists) {
      throw Exception('Hikâye bulunamadı: $storyId');
    }
    return StoryModel.fromDoc(doc);
  }
}
