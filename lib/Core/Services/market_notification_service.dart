import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketNotificationService {
  MarketNotificationService._();

  static dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _cloneMap(Map source) {
    return source.map(
      (key, value) => MapEntry(key.toString(), _cloneValue(value)),
    );
  }

  static String get _currentUid => CurrentUserService.instance.effectiveUserId;

  static String get _senderLabel {
    final fullName = CurrentUserService.instance.fullName.trim();
    if (fullName.isNotEmpty) return fullName;
    final nickname = CurrentUserService.instance.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
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

  static Future<bool> notifyConversationMessageIfNeeded({
    required String targetUserId,
    required String chatId,
    required Map<String, dynamic>? conversationData,
  }) async {
    final marketContext = _cloneMap(
      conversationData?['marketContext'] as Map? ?? const <String, dynamic>{},
    );
    final itemId = (marketContext['itemId'] ?? '').toString().trim();
    if (itemId.isEmpty) return false;
    await notifyMarketMessage(
      targetUserId: targetUserId,
      chatId: chatId,
      sellerId: (marketContext['sellerId'] ?? '').toString(),
      itemId: itemId,
      itemTitle: (marketContext['title'] ?? '').toString(),
      coverImageUrl: (marketContext['coverImageUrl'] ?? '').toString(),
    );
    return true;
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
    await NotificationsRepository.ensure().createInboxItem(targetUid, {
      'type': type,
      'fromUserID': fromUid,
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
