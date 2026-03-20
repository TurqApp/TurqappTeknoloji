import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketNotificationService {
  MarketNotificationService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ??
      CurrentUserService.instance.userId;

  static String get _senderLabel {
    final fullName = CurrentUserService.instance.fullName.trim();
    if (fullName.isNotEmpty) return fullName;
    final nickname = CurrentUserService.instance.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final authDisplayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (authDisplayName.isNotEmpty) return authDisplayName;
    return 'app.name'.tr;
  }

  static Future<void> notifyOfferCreated({
    required MarketItemModel item,
    required double offerPrice,
  }) async {
    await _writeNotification(
      targetUserId: item.userId,
      type: 'market_offer',
      docId: item.id,
      title: _senderLabel,
      body: 'market_notifications.offer_created'.tr,
      desc: 'market_notifications.offer_amount'
          .trParams({'amount': _formatPrice(offerPrice, item.currency)}),
      thumbnail: item.coverImageUrl,
      imageUrl: item.coverImageUrl,
    );
  }

  static Future<void> notifyOfferStatus({
    required MarketOfferModel offer,
    required String status,
  }) async {
    final body = status == 'accepted'
        ? 'market_notifications.offer_accepted'.tr
        : 'market_notifications.offer_rejected'.tr;
    await _writeNotification(
      targetUserId: offer.buyerId,
      type: 'market_offer_status',
      docId: offer.itemId,
      title: _senderLabel,
      body: body,
      desc: offer.itemTitle.trim().isEmpty ? body : offer.itemTitle,
      thumbnail: offer.coverImageUrl,
      imageUrl: offer.coverImageUrl,
    );
  }

  static Future<void> notifyMarketMessage({
    required String targetUserId,
    required String chatId,
    required String sellerId,
    required String itemId,
    required String itemTitle,
    required String coverImageUrl,
  }) async {
    final body = targetUserId == sellerId
        ? 'market_notifications.message_for_your_listing'.tr
        : 'market_notifications.new_listing_message'.tr;
    await _writeNotification(
      targetUserId: targetUserId,
      type: 'chat',
      docId: chatId,
      title: _senderLabel,
      body: body,
      desc: itemTitle.trim().isEmpty ? body : itemTitle,
      thumbnail: coverImageUrl,
      imageUrl: coverImageUrl,
      postType: 'market_chat',
      extra: <String, dynamic>{
        'marketItemId': itemId,
        'marketSellerId': sellerId,
      },
    );
  }

  static Future<void> _writeNotification({
    required String targetUserId,
    required String type,
    required String docId,
    required String title,
    required String body,
    String desc = '',
    String thumbnail = '',
    String imageUrl = '',
    String postType = 'market',
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final fromUid = _currentUid.trim();
    final targetUid = targetUserId.trim();
    if (fromUid.isEmpty || targetUid.isEmpty || fromUid == targetUid) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add({
      'type': type,
      'fromUserID': fromUid,
      'userID': targetUid,
      'postID': docId,
      'postType': postType,
      'thumbnail': thumbnail,
      'imageUrl': imageUrl,
      'timeStamp': now,
      'read': false,
      'isRead': false,
      'title': title,
      'body': body,
      'desc': desc.isEmpty ? body : desc,
      ...extra,
    });
  }

  static String _formatPrice(double value, String currency) {
    final amount = value.round().toString();
    final chars = amount.split('').reversed.toList(growable: false);
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    final formatted = buffer.toString().split('').reversed.join();
    return '$formatted ${currency == 'TRY' ? 'TL' : currency}';
  }
}
