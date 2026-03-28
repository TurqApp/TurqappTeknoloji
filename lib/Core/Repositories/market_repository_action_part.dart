part of 'market_repository_library.dart';

extension MarketRepositoryActionPart on MarketRepository {
  Future<void> saveItem({
    required String docId,
    required Map<String, dynamic> payload,
    required String userId,
  }) async {
    await _itemsRef.doc(docId).set(payload, SetOptions(merge: true));
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> updateItemStatus({
    required String docId,
    required String userId,
    required String status,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _itemsRef.doc(docId).set({
      'status': status,
      'updatedAt': now,
      if (status == 'sold') 'soldAt': now,
      if (status == 'active') 'publishedAt': now,
    }, SetOptions(merge: true));
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> invalidateItemCaches({
    required String userId,
    required String docId,
  }) async {
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> incrementViewCount({
    required String docId,
    required String userId,
  }) async {
    if (docId.isEmpty || userId.isEmpty) return;
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('recordMarketViewBatch')
          .call({
            'items': [
              {'itemId': docId, 'count': 1},
            ],
          });
    } on FirebaseFunctionsException {
      return;
    } catch (_) {
      return;
    }
  }
}
