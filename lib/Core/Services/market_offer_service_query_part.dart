part of 'market_offer_service.dart';

Future<int> _countTodayOffersImpl({
  required String buyerId,
  required int startOfDay,
}) async {
  const options = GetOptions(source: Source.serverAndCache);
  try {
    final todayOffers = await MarketOfferService._firestore
        .collectionGroup('offers')
        .where('buyerId', isEqualTo: buyerId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .limit(20)
        .get(options);
    return todayOffers.docs.length;
  } on FirebaseException {
    try {
      final buyerOffers = await MarketOfferService._firestore
          .collectionGroup('offers')
          .where('buyerId', isEqualTo: buyerId)
          .limit(100)
          .get(options);
      return buyerOffers.docs
          .where(
            (doc) =>
                ((doc.data()['createdAt'] as num?)?.toInt() ?? 0) >= startOfDay,
          )
          .length;
    } on FirebaseException {
      // Teklif göndermeyi index eksikliği yüzünden bloklamayalım.
      return 0;
    }
  }
}

Future<List<MarketOfferModel>> _fetchReceivedOffersImpl(String uid) async {
  final merged = <String, MarketOfferModel>{};

  try {
    final userSnap = await MarketOfferService._firestore
        .collection('users')
        .doc(uid)
        .collection('marketOffersReceived')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get(const GetOptions(source: Source.serverAndCache));
    for (final doc in userSnap.docs) {
      merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
    }
  } on FirebaseException {
    try {
      final userSnap = await MarketOfferService._firestore
          .collection('users')
          .doc(uid)
          .collection('marketOffersReceived')
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in userSnap.docs) {
        merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
      }
    } on FirebaseException {
      // Mirror subcollection yoksa veya okunamıyorsa sessizce boş dön.
    }
  }

  final items = merged.values.toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
}

Future<List<MarketOfferModel>> _fetchSentOffersImpl(String uid) async {
  final merged = <String, MarketOfferModel>{};

  try {
    final userSnap = await MarketOfferService._firestore
        .collection('users')
        .doc(uid)
        .collection('marketOffersSent')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get(const GetOptions(source: Source.serverAndCache));
    for (final doc in userSnap.docs) {
      merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
    }
  } on FirebaseException {
    try {
      final userSnap = await MarketOfferService._firestore
          .collection('users')
          .doc(uid)
          .collection('marketOffersSent')
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in userSnap.docs) {
        merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
      }
    } on FirebaseException {
      // Mirror subcollection yoksa veya okunamıyorsa sessizce boş dön.
    }
  }

  final items = merged.values.toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
}
