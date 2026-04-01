part of 'test_repository_parts.dart';

class _TimedTests {
  const _TimedTests({required this.items, required this.cachedAt});

  final List<TestsModel> items;
  final DateTime cachedAt;
}

class TestRepository extends GetxService {
  TestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'test_repository_v1';
  final Map<String, _TimedTests> _memory = <String, _TimedTests>{};
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _handleTestRepositoryInit(this);
  }
}

TestRepository? maybeFindTestRepository() => _maybeFindTestRepository();

TestRepository ensureTestRepository() => _ensureTestRepository();

TestRepository? _maybeFindTestRepository() =>
    Get.isRegistered<TestRepository>() ? Get.find<TestRepository>() : null;

TestRepository _ensureTestRepository() =>
    _maybeFindTestRepository() ?? Get.put(TestRepository(), permanent: true);

void _handleTestRepositoryInit(TestRepository repository) {
  SharedPreferences.getInstance().then((prefs) => repository._prefs = prefs);
}

extension TestRepositoryFacadePart on TestRepository {}
