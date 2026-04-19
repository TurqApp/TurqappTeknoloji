part of 'current_user_service.dart';

class _TimedValue<T> {
  final T value;
  final DateTime fetchedAt;

  _TimedValue({
    required T value,
    required this.fetchedAt,
  }) : value = _cloneTimedValuePayload(value);
}

T _cloneTimedValuePayload<T>(T value) {
  final cloned = _cloneTimedValueDynamic(value);
  return cloned is T ? cloned : value;
}

dynamic _cloneTimedValueDynamic(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneTimedValueDynamic(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneTimedValueDynamic).toList(growable: false);
  }
  return value;
}

SharedPreferences? _prefs;
StreamSubscription<Map<String, dynamic>?>? _firestoreSubscription;
StreamSubscription<User?>? _authFeedWarmSubscription;
Timer? _exclusiveSessionHeartbeat;
const Duration _exclusiveSessionHeartbeatInterval = Duration(seconds: 10);
const Duration _feedTypesenseWarmThrottle = Duration(seconds: 12);

const String _cacheKeyPrefix = 'cached_current_user';
const String _cacheTimestampKeyPrefix = 'cached_current_user_timestamp';
const String _activeCacheUidKey = 'cached_current_user_active_uid';
const String _viewSelectionPrefKeyPrefix = 'preferred_feed_view_selection';
const String _emailPromptTimestampKeyPrefix = 'email_verify_prompt_last_shown';
Duration get _cacheExpiration =>
    MetadataCachePolicy.ttlFor(MetadataCacheBucket.currentUserSummary);

bool _isInitialized = false;
bool _isSyncing = false;
int? _lastKnownViewSelection;
final UserSubcollectionRepository _userSubcollectionRepository =
    ensureUserSubcollectionRepository();
const Duration _rootDocCacheTtl = Duration(minutes: 2);
const Duration _subdocCacheTtl = Duration(minutes: 10);
const Duration _listCacheTtl = Duration(minutes: 2);
final Map<String, _TimedValue<Map<String, dynamic>>> _rootDocCache = {};
final Map<String, _TimedValue<Map<String, dynamic>>> _subdocCache = {};
final Map<String, _TimedValue<Map<String, dynamic>>> _listCache = {};
final Map<String, DateTime> _silentLogAt = {};

Timer? _cacheSaveTimer;
String? _lastCacheSignature;
String? _lastReactiveSignature;
String? _lastRootSyncSignature;
String? _lastWarmedAvatarUrl;
bool _handlingPermanentBan = false;
bool _handlingSessionDisplacement = false;
String _lastFeedTypesenseWarmUid = '';
DateTime? _lastFeedTypesenseWarmAt;

final RxBool emailVerifiedRx = true.obs;
DateTime? _lastEmailPromptAt;
Duration _emailPromptCooldown = const Duration(days: 7);
