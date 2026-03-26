part of 'top_tags_repository.dart';

abstract class _TopTagsRepositoryBase extends GetxService {
  _TopTagsRepositoryBase({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  List<HashtagModel>? _memory;
  DateTime? _memoryAt;
  final List<PostsModel> _feedMemory = <PostsModel>[];
  DocumentSnapshot<Map<String, dynamic>>? _lastFeedDoc;
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
