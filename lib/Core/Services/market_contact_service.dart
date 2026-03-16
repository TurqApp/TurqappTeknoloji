import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketContactService {
  const MarketContactService();

  Future<void> openChat(MarketItemModel item) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      AppSnackbar('Giriş Gerekli', 'Mesaj göndermek için giriş yapmalısın.');
      return;
    }
    if (currentUid == item.userId) {
      AppSnackbar('Bilgi', 'Kendi ilanın için mesaj gönderemezsin.');
      return;
    }

    final chatListingController = Get.isRegistered<ChatListingController>()
        ? Get.find<ChatListingController>()
        : Get.put(ChatListingController());
    final sohbet = chatListingController.list
        .firstWhereOrNull((val) => val.userID == item.userId);

    if (sohbet != null) {
      await Get.to(
        () => ChatView(
          chatID: sohbet.chatID,
          userID: item.userId,
          isNewChat: false,
          openKeyboard: true,
        ),
      );
      return;
    }

    final chatId = buildConversationId(currentUid, item.userId);
    await Get.to(
      () => ChatView(
        chatID: chatId,
        userID: item.userId,
        isNewChat: true,
        openKeyboard: true,
      ),
    );
    unawaited(chatListingController.getList());
  }

  Future<void> showPhoneSheet(
    BuildContext context,
    MarketItemModel item,
  ) async {
    final phone = await _resolvePhone(item);
    if (phone.isEmpty) {
      AppSnackbar('Bilgi Yok', 'Satıcının telefon bilgisi bulunamadı.');
      return;
    }

    final displayPhone = _formatDisplayPhone(phone);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Text(
                  'Telefon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    displayPhone,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final dialUri = Uri.parse('tel:${_dialValue(phone)}');
                      final opened = await launchUrl(dialUri);
                      if (!opened) {
                        AppSnackbar('Hata', 'Telefon uygulaması açılamadı.');
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ara',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _resolvePhone(MarketItemModel item) async {
    final direct = item.sellerPhoneNumber.trim();
    if (direct.isNotEmpty) return direct;
    if (item.userId.trim().isEmpty) return '';
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(item.userId)
          .get(const GetOptions(source: Source.serverAndCache));
      final data = snapshot.data() ?? const <String, dynamic>{};
      return (data['phoneNumber'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  String _dialValue(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 11) {
      return '+9$digits';
    }
    if (digits.length == 10 && digits.startsWith('5')) {
      return '+90$digits';
    }
    return rawPhone.trim();
  }

  String _formatDisplayPhone(String rawPhone) {
    final digits = _dialValue(rawPhone).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('90') && digits.length == 12) {
      return '+${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return rawPhone.trim();
  }
}
