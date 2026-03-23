part of 'market_offer_service.dart';

Future<void> _createOfferImpl({
  required MarketItemModel item,
  required double offerPrice,
  required String message,
}) async {
  final buyerId = MarketOfferService._currentUid;
  if (buyerId.isEmpty) {
    throw Exception('auth_required');
  }
  if (buyerId == item.userId) {
    throw Exception('own_item_offer_not_allowed');
  }

  final nowDate = DateTime.now();
  final startOfDay = DateTime(
    nowDate.year,
    nowDate.month,
    nowDate.day,
  ).millisecondsSinceEpoch;
  final todayOfferCount = await _countTodayOffersImpl(
    buyerId: buyerId,
    startOfDay: startOfDay,
  );
  if (todayOfferCount >= 20) {
    throw Exception('daily_offer_limit_reached');
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final offerId = now.toString();
  final itemRef = MarketOfferService._firestore.collection('marketStore').doc(
        item.id,
      );
  final offerRef = itemRef.collection('offers').doc(offerId);
  final sentRef = MarketOfferService._firestore
      .collection('users')
      .doc(buyerId)
      .collection('marketOffersSent')
      .doc(offerId);
  final receivedRef = MarketOfferService._firestore
      .collection('users')
      .doc(item.userId)
      .collection('marketOffersReceived')
      .doc(offerId);
  final offerPayload = <String, dynamic>{
    'id': offerId,
    'itemId': item.id,
    'itemTitle': item.title,
    'coverImageUrl': item.coverImageUrl,
    'locationText': item.locationText,
    'buyerId': buyerId,
    'sellerId': item.userId,
    'offerPrice': offerPrice,
    'currency': item.currency,
    'message': message.trim(),
    'status': kMarketOfferStatusPending,
    'createdAt': now,
    'updatedAt': now,
  };

  await MarketOfferService._firestore.runTransaction((tx) async {
    tx.set(offerRef, offerPayload);
    tx.set(sentRef, offerPayload);
    tx.set(receivedRef, offerPayload);
    tx.set(
      itemRef,
      {
        'offerCount': FieldValue.increment(1),
        'lastOfferAt': now,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
  });
  try {
    await MarketNotificationService.notifyOfferCreated(
      item: item,
      offerPrice: offerPrice,
    );
  } catch (_) {}
}

Future<void> _respondToOfferImpl({
  required MarketOfferModel offer,
  required String status,
}) async {
  final sellerId = MarketOfferService._currentUid;
  if (sellerId.isEmpty) {
    throw Exception('auth_required');
  }
  if (sellerId != offer.sellerId) {
    throw Exception('not_offer_owner');
  }
  if (status != kMarketOfferStatusAccepted &&
      status != kMarketOfferStatusRejected) {
    throw Exception('invalid_offer_status');
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final itemRef =
      MarketOfferService._firestore.collection('marketStore').doc(offer.itemId);
  final offerRef = itemRef.collection('offers').doc(offer.id);
  final sentRef = MarketOfferService._firestore
      .collection('users')
      .doc(offer.buyerId)
      .collection('marketOffersSent')
      .doc(offer.id);
  final receivedRef = MarketOfferService._firestore
      .collection('users')
      .doc(offer.sellerId)
      .collection('marketOffersReceived')
      .doc(offer.id);
  final mirrorPayload = <String, dynamic>{
    'id': offer.id,
    'itemId': offer.itemId,
    'itemTitle': offer.itemTitle,
    'coverImageUrl': offer.coverImageUrl,
    'locationText': offer.locationText,
    'buyerId': offer.buyerId,
    'sellerId': offer.sellerId,
    'offerPrice': offer.offerPrice,
    'currency': offer.currency,
    'message': offer.message,
    'status': status,
    'createdAt': offer.createdAt,
    'updatedAt': now,
    'respondedAt': now,
  };

  await MarketOfferService._firestore.runTransaction((tx) async {
    final offerSnap = await tx.get(offerRef);
    if (!offerSnap.exists) {
      throw Exception('offer_not_found');
    }
    final currentStatus =
        (offerSnap.data()?['status'] ?? kMarketOfferStatusPending)
            .toString()
            .trim();
    if (currentStatus != kMarketOfferStatusPending) {
      throw Exception('offer_already_processed');
    }

    tx.set(
      offerRef,
      {
        'status': status,
        'updatedAt': now,
        'respondedAt': now,
      },
      SetOptions(merge: true),
    );

    tx.set(
      itemRef,
      {
        'status': status == kMarketOfferStatusAccepted ? 'reserved' : 'active',
        'acceptedOfferId': status == kMarketOfferStatusAccepted ? offer.id : '',
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    tx.set(sentRef, mirrorPayload, SetOptions(merge: true));
    tx.set(receivedRef, mirrorPayload, SetOptions(merge: true));
  });
  try {
    await MarketNotificationService.notifyOfferStatus(
      offer: offer,
      status: status,
    );
  } catch (_) {}

  if (status == kMarketOfferStatusAccepted) {
    final pendingOffers = await itemRef
        .collection('offers')
        .where('status', isEqualTo: kMarketOfferStatusPending)
        .get();
    final batch = MarketOfferService._firestore.batch();
    for (final doc in pendingOffers.docs) {
      if (doc.id == offer.id) continue;
      batch.set(
        doc.reference,
        {
          'status': 'rejected',
          'updatedAt': now,
          'respondedAt': now,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
