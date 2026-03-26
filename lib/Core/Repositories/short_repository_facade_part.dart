part of 'short_repository.dart';

ShortRepository? _maybeFindShortRepository() =>
    Get.isRegistered<ShortRepository>() ? Get.find<ShortRepository>() : null;

ShortRepository _ensureShortRepository() =>
    _maybeFindShortRepository() ?? Get.put(ShortRepository(), permanent: true);

Future<List<PostsModel>> _fetchRandomReadyShortPosts(
  ShortRepository repository, {
  int limit = 1000,
  int? nowMs,
}) async {
  final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final snap = await repository._firestore
      .collection('Posts')
      .where('hlsStatus', isEqualTo: 'ready')
      .limit(limit)
      .get();
  return snap.docs
      .map(PostsModel.fromFirestore)
      .where((p) => p.timeStamp <= ts)
      .toList(growable: false);
}

Future<PostsModel?> _fetchShortById(
  String docId, {
  bool preferCache = true,
}) async {
  final map = await PostRepository.ensure().fetchPostCardsByIds(
    <String>[docId],
    preferCache: preferCache,
  );
  return map[docId];
}

Future<Map<String, PostsModel>> _fetchShortByIds(
  List<String> postIds, {
  bool preferCache = true,
}) {
  return PostRepository.ensure().fetchPostCardsByIds(
    postIds,
    preferCache: preferCache,
  );
}
