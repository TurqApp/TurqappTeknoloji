import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketOfferService {
  MarketOfferService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get _currentUid {
    if (CurrentUserService.instance.userId.isNotEmpty) {
      return CurrentUserService.instance.userId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
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
    final todayOffers = await _firestore
        .collectionGroup('offers')
        .where('buyerId', isEqualTo: buyerId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .limit(20)
        .get(const GetOptions(source: Source.serverAndCache));
    if (todayOffers.docs.length >= 20) {
      throw Exception('daily_offer_limit_reached');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final offerId = now.toString();
    final itemRef = _firestore.collection('marketStore').doc(item.id);
    final offerRef = itemRef.collection('offers').doc(offerId);

    await _firestore.runTransaction((tx) async {
      tx.set(offerRef, {
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
      });
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
  }

  static Future<List<MarketOfferModel>> fetchSentOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchOffers(field: 'buyerId', uid: uid);
  }

  static Future<List<MarketOfferModel>> fetchReceivedOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchOffers(field: 'sellerId', uid: uid);
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
    });

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
}
