part of 'recommended_users_repository.dart';

class RecommendedUsersRepository extends GetxService {
  static const String _prefsKeyPrefix = 'recommended_users_repository_v1';
  static const Duration _ttl = Duration(minutes: 10);

  List<RecommendedUserModel> _memory = const <RecommendedUserModel>[];
  DateTime? _cachedAt;
  SharedPreferences? _prefs;
  bool _initialized = false;
  StreamSubscription<User?>? _authSub;

  static RecommendedUsersRepository? maybeFind() {
    final isRegistered = Get.isRegistered<RecommendedUsersRepository>();
    if (!isRegistered) return null;
    return Get.find<RecommendedUsersRepository>();
  }

  static RecommendedUsersRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(RecommendedUsersRepository(), permanent: true);
  }

  String get _prefsKey => userScopedKey(_prefsKeyPrefix);

  Future<List<RecommendedUserModel>> fetchCandidates({
    int limit = 500,
    bool preferCache = true,
  }) =>
      _fetchCandidatesImpl(
        limit: limit,
        preferCache: preferCache,
      );

  bool get _isFresh =>
      _cachedAt != null && DateTime.now().difference(_cachedAt!) <= _ttl;

  @override
  void onClose() {
    _handleClose();
    super.onClose();
  }
}
