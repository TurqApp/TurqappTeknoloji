part of 'answer_key_content_controller.dart';

final Map<String, Set<String>> _answerKeyContentSavedIdsByUser =
    <String, Set<String>>{};
final Map<String, Future<Set<String>>> _answerKeyContentSavedIdsLoaders =
    <String, Future<Set<String>>>{};

String _resolveAnswerKeyContentCurrentUid() =>
    CurrentUserService.instance.effectiveUserId;

Future<Set<String>> _loadAnswerKeyContentSavedIds(String userId) {
  final cached = _answerKeyContentSavedIdsByUser[userId];
  if (cached != null) {
    return Future<Set<String>>.value(cached);
  }
  final existingLoader = _answerKeyContentSavedIdsLoaders[userId];
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
    _answerKeyContentSavedIdsByUser[userId] = ids;
    return ids;
  }();

  _answerKeyContentSavedIdsLoaders[userId] = loader;
  return loader.whenComplete(() {
    _answerKeyContentSavedIdsLoaders.remove(userId);
  });
}

Future<void> _warmAnswerKeyContentSavedIdsForCurrentUser() async {
  final userId = _resolveAnswerKeyContentCurrentUid();
  if (userId.isEmpty) return;
  await _loadAnswerKeyContentSavedIds(userId);
}
