part of 'top_tags_repository_parts.dart';

const int _topTagsDefaultTrendWindowHours = 24;
const int _topTagsDefaultTrendThreshold = 1;
const Duration _topTagsTtl = Duration(hours: 1);
const String _topTagsPrefsKey = 'top_tags_repository_v1';

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

class TopTagsRepository extends _TopTagsRepositoryBase {
  TopTagsRepository({super.firestore});
}
