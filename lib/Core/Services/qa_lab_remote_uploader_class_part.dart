part of 'qa_lab_remote_uploader.dart';

class QALabRemoteUploader extends GetxService {
  QALabRemoteUploader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  static QALabRemoteUploader ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QALabRemoteUploader(), permanent: true);
  }

  static QALabRemoteUploader? maybeFind() {
    if (!Get.isRegistered<QALabRemoteUploader>()) {
      return null;
    }
    return Get.find<QALabRemoteUploader>();
  }

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  final RxString lastSyncState = 'idle'.obs;
  final RxString lastSyncError = ''.obs;
  final RxString lastSyncReason = ''.obs;
  final Rxn<DateTime> lastSyncedAt = Rxn<DateTime>();
  final Rxn<DateTime> lastGateCheckedAt = Rxn<DateTime>();
  final RxBool remoteCollectionEnabled = false.obs;
  final RxInt uploadCount = 0.obs;
  final RxInt uploadedOccurrenceCount = 0.obs;

  Timer? _debounceTimer;
  StreamSubscription<Map<String, dynamic>>? _qaConfigSubscription;
  bool _syncInFlight = false;
  Map<String, dynamic>? _pendingSessionDocument;
  String _pendingReason = '';
  final Map<String, Map<String, dynamic>> _pendingOccurrences =
      <String, Map<String, dynamic>>{};
  final Set<String> _uploadedOccurrenceIds = <String>{};
  String _activeSessionId = '';
  DateTime? _lastGateRefreshAt;
  DateTime? _permissionDeniedUntil;
  String _permissionDeniedSessionId = '';

  @override
  void onClose() {
    QALabRemoteUploaderRuntimePart(this).onClose();
    super.onClose();
  }
}
