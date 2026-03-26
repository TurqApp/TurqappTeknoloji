part of 'scholarship_repository.dart';

class _ScholarshipRepositoryState {
  final Map<String, _TimedScholarship> memory = <String, _TimedScholarship>{};
  final Map<String, _TimedScholarshipList> queryMemory =
      <String, _TimedScholarshipList>{};
  final Map<String, _TimedScholarshipApply> applyMemory =
      <String, _TimedScholarshipApply>{};
  SharedPreferences? prefs;
}

extension _ScholarshipRepositoryFieldsPart on ScholarshipRepository {
  Map<String, _TimedScholarship> get _memory => _state.memory;
  Map<String, _TimedScholarshipList> get _queryMemory => _state.queryMemory;
  Map<String, _TimedScholarshipApply> get _applyMemory => _state.applyMemory;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
}
