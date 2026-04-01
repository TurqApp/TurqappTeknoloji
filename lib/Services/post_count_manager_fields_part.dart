part of 'post_count_manager.dart';

class _PostCountManagerState {
  final Map<String, RxInt> likeCounts = <String, RxInt>{};
  final Map<String, RxInt> commentCounts = <String, RxInt>{};
  final Map<String, RxInt> savedCounts = <String, RxInt>{};
  final Map<String, RxInt> retryCounts = <String, RxInt>{};
  final Map<String, RxInt> statsCounts = <String, RxInt>{};
}

extension _PostCountManagerFieldsPart on PostCountManager {
  Map<String, RxInt> get _likeCounts => _state.likeCounts;
  Map<String, RxInt> get _commentCounts => _state.commentCounts;
  Map<String, RxInt> get _savedCounts => _state.savedCounts;
  Map<String, RxInt> get _retryCounts => _state.retryCounts;
  Map<String, RxInt> get _statsCounts => _state.statsCounts;
}
