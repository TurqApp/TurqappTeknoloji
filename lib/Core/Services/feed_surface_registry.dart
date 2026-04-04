class FeedSurfaceRegistry {
  FeedSurfaceRegistry._();

  static List<String> _videoDocIds = const <String>[];

  static void recordVideoDocIds(Iterable<String> docIds) {
    final seen = <String>{};
    _videoDocIds = docIds
        .map((docId) => docId.trim())
        .where((docId) => docId.isNotEmpty && seen.add(docId))
        .toList(growable: false);
  }

  static List<String> currentVideoDocIds() =>
      List<String>.from(_videoDocIds, growable: false);
}
