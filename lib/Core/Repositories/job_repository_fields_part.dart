part of 'job_repository.dart';

class _JobRepositoryState {
  _JobRepositoryState({required this.firestore});

  final FirebaseFirestore firestore;
  final Map<String, _TimedJobs> memory = <String, _TimedJobs>{};
  final Map<String, _TimedBool> boolMemory = <String, _TimedBool>{};
  SharedPreferences? prefs;
}

extension JobRepositoryFieldsPart on JobRepository {
  FirebaseFirestore get _firestore => _state.firestore;
  Map<String, _TimedJobs> get _memory => _state.memory;
  Map<String, _TimedBool> get _boolMemory => _state.boolMemory;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
