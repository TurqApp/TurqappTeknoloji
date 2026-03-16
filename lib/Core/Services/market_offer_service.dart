import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Services/market_notification_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketOfferService {
  MarketOfferService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get _currentUid {
    final authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (authUid.isNotEmpty) {
      return authUid;
    }
    return CurrentUserService.instance.userId;
  }

  static Future<void> createOffer({
    required MarketItemModel item,
    required double offerPrice,
    String message = '',
  }) async {
    final buyerId = _currentUid;
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
    final todayOfferCount = await _countTodayOffers(
      buyerId: buyerId,
      startOfDay: startOfDay,
    );
    if (todayOfferCount >= 20) {
      throw Exception('daily_offer_limit_reached');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final offerId = now.toString();
    final itemRef = _firestore.collection('marketStore').doc(item.id);
    final offerRef = itemRef.collection('offers').doc(offerId);
    final sentRef = _firestore
        .collection('users')
        .doc(buyerId)
        .collection('marketOffersSent')
        .doc(offerId);
    final receivedRef = _firestore
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
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    };

    await _firestore.runTransaction((tx) async {
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

  static Future<int> _countTodayOffers({
    required String buyerId,
    required int startOfDay,
  }) async {
    const options = GetOptions(source: Source.serverAndCache);
    try {
      final todayOffers = await _firestore
          .collectionGroup('offers')
          .where('buyerId', isEqualTo: buyerId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .limit(20)
          .get(options);
      return todayOffers.docs.length;
    } on FirebaseException {
      try {
        final buyerOffers = await _firestore
            .collectionGroup('offers')
            .where('buyerId', isEqualTo: buyerId)
            .limit(100)
            .get(options);
        return buyerOffers.docs
            .where(
              (doc) =>
                  ((doc.data()['createdAt'] as num?)?.toInt() ?? 0) >=
                  startOfDay,
            )
            .length;
      } on FirebaseException {
        // Teklif göndermeyi index eksikliği yüzünden bloklamayalım.
        return 0;
      }
    }
  }

  static Future<List<MarketOfferModel>> fetchSentOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchSentOffers(uid);
  }

  static Future<List<MarketOfferModel>> fetchReceivedOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchReceivedOffers(uid);
  }

  static Future<void> respondToOffer({
    required MarketOfferModel offer,
    required String status,
  }) async {
    final sellerId = _currentUid;
    if (sellerId.isEmpty) {
      throw Exception('auth_required');
    }
    if (sellerId != offer.sellerId) {
      throw Exception('not_offer_owner');
    }
    if (status != 'accepted' && status != 'rejected') {
      throw Exception('invalid_offer_status');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final itemRef = _firestore.collection('marketStore').doc(offer.itemId);
    final offerRef = itemRef.collection('offers').doc(offer.id);
    final sentRef = _firestore
        .collection('users')
        .doc(offer.buyerId)
        .collection('marketOffersSent')
        .doc(offer.id);
    final receivedRef = _firestore
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

    await _firestore.runTransaction((tx) async {
      final offerSnap = await tx.get(offerRef);
      if (!offerSnap.exists) {
        throw Exception('offer_not_found');
      }
      final currentStatus =
          (offerSnap.data()?['status'] ?? 'pending').toString().trim();
      if (currentStatus != 'pending') {
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
          'status': status == 'accepted' ? 'reserved' : 'active',
          'acceptedOfferId': status == 'accepted' ? offer.id : '',
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      tx.set(
        sentRef,
        mirrorPayload,
        SetOptions(merge: true),
      );
      tx.set(
        receivedRef,
        mirrorPayload,
        SetOptions(merge: true),
      );
    });
    try {
      await MarketNotificationService.notifyOfferStatus(
        offer: offer,
        status: status,
      );
    } catch (_) {}

    if (status == 'accepted') {
      final pendingOffers = await itemRef
          .collection('offers')
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = _firestore.batch();
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

  static Future<List<MarketOfferModel>> _fetchOffers({
    required String field,
    required String uid,
  }) async {
    const options = GetOptions(source: Source.serverAndCache);
    try {
      final snap = await _firestore
          .collectionGroup('offers')
          .where(field, isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get(options);
      return snap.docs
          .map((doc) => MarketOfferModel.fromMap(doc.data(), doc.id))
          .toList(growable: false);
    } on FirebaseException {
      final snap = await _firestore
          .collectionGroup('offers')
          .where(field, isEqualTo: uid)
          .limit(50)
          .get(options);
      final items = snap.docs
          .map((doc) => MarketOfferModel.fromMap(doc.data(), doc.id))
          .toList(growable: false);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }
  }

  static Future<List<MarketOfferModel>> _fetchReceivedOffers(String uid) async {
    final merged = <String, MarketOfferModel>{};

    try {
      final userSnap = await _firestore
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
        final userSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('marketOffersReceived')
            .limit(100)
            .get(const GetOptions(source: Source.serverAndCache));
        for (final doc in userSnap.docs) {
          merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
        }
      } on FirebaseException {
        // Fallbackler aşağıda devam eder.
      }
    }

    try {
      final direct = await _fetchOffers(field: 'sellerId', uid: uid);
      for (final offer in direct) {
        merged[offer.id] = offer;
      }
    } on FirebaseException {
      // sellerId index/permission tarafı düşerse item bazlı fallback aşağıda çalışır.
    } catch (_) {}

    try {
      final ownedItemOffers = await _fetchReceivedOffersByOwnedItems(uid);
      for (final offer in ownedItemOffers) {
        merged[offer.id] = offer;
      }
    } on FirebaseException {
      // İki kaynak da düşerse eldeki veriyle devam et.
    } catch (_) {}

    final items = merged.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<List<MarketOfferModel>> _fetchSentOffers(String uid) async {
    final merged = <String, MarketOfferModel>{};

    try {
      final userSnap = await _firestore
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
        final userSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('marketOffersSent')
            .limit(100)
            .get(const GetOptions(source: Source.serverAndCache));
        for (final doc in userSnap.docs) {
          merged[doc.id] = MarketOfferModel.fromMap(doc.data(), doc.id);
        }
      } on FirebaseException {
        // Fallbackler aşağıda devam eder.
      }
    }

    try {
      final direct = await _fetchOffers(field: 'buyerId', uid: uid);
      for (final offer in direct) {
        merged[offer.id] = offer;
      }
    } on FirebaseException {
      // buyerId index/permission düşerse item bazlı fallback aşağıda çalışır.
    } catch (_) {}

    try {
      final scanned = await _scanAllOffersForUser(uid, matchBuyer: true);
      for (final offer in scanned) {
        merged[offer.id] = offer;
      }
    } on FirebaseException {
      // Elimizdeki veriyle devam et.
    } catch (_) {}

    final items = merged.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<List<MarketOfferModel>> _fetchReceivedOffersByOwnedItems(
    String uid,
  ) async {
    const options = GetOptions(source: Source.serverAndCache);
    final itemSnap = await _firestore
        .collection('marketStore')
        .where('userId', isEqualTo: uid)
        .limit(100)
        .get(options);

    final offers = <MarketOfferModel>[];
    for (final itemDoc in itemSnap.docs) {
      try {
        final offerSnap = await itemDoc.reference
            .collection('offers')
            .limit(100)
            .get(options);
        offers.addAll(
          offerSnap.docs.map(
            (doc) => MarketOfferModel.fromMap(doc.data(), doc.id),
          ),
        );
      } on FirebaseException {
        continue;
      }
    }

    offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return offers;
  }

  static Future<List<MarketOfferModel>> _scanAllOffersForUser(
    String uid, {
    required bool matchBuyer,
  }) async {
    const options = GetOptions(source: Source.serverAndCache);
    final itemSnap = await _firestore
        .collection('marketStore')
        .limit(200)
        .get(options);

    final offers = <MarketOfferModel>[];
    for (final itemDoc in itemSnap.docs) {
      try {
        final offerSnap = await itemDoc.reference
            .collection('offers')
            .limit(100)
            .get(options);
        for (final doc in offerSnap.docs) {
          final offer = MarketOfferModel.fromMap(doc.data(), doc.id);
          final matches = matchBuyer
              ? offer.buyerId.trim() == uid
              : offer.sellerId.trim() == uid;
          if (matches) {
            offers.add(offer);
          }
        }
      } on FirebaseException {
        continue;
      }
    }

    offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return offers;
  }
}
