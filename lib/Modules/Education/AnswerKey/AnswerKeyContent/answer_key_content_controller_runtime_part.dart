part of 'answer_key_content_controller.dart';

String _resolveAnswerKeyContentCurrentUid() =>
    CurrentUserService.instance.effectiveUserId;

Future<Set<String>> _loadAnswerKeyContentSavedIds(String userId) {
  final cached = AnswerKeyContentController._savedIdsByUser[userId];
  if (cached != null) {
    return Future<Set<String>>.value(cached);
  }
  final existingLoader = AnswerKeyContentController._savedIdsLoaders[userId];
  if (existingLoader != null) {
    return existingLoader;
  }

  final loader = () async {
    final entries = await ensureUserSubcollectionRepository().getEntries(
      userId,
      subcollection: 'books',
      orderByField: 'createdAt',
      descending: true,
      preferCache: true,
      forceRefresh: false,
    );
    final ids = entries.map((entry) => entry.id).toSet();
    AnswerKeyContentController._savedIdsByUser[userId] = ids;
    return ids;
  }();

  AnswerKeyContentController._savedIdsLoaders[userId] = loader;
  return loader.whenComplete(() {
    AnswerKeyContentController._savedIdsLoaders.remove(userId);
  });
}

Future<void> _warmAnswerKeyContentSavedIdsForCurrentUser() async {
  final userId = _resolveAnswerKeyContentCurrentUid();
  if (userId.isEmpty) return;
  await _loadAnswerKeyContentSavedIds(userId);
}
