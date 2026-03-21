import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:uuid/uuid.dart';

class MarketFeedPostShareService {
  const MarketFeedPostShareService();

  Future<void> shareItem(MarketItemModel item) async {
    final currentUid = CurrentUserService.instance.userId;
    if (currentUid.isEmpty) {
      AppSnackbar('login.sign_in'.tr, 'education_feed.share_sign_in_required'.tr);
      return;
    }
    if (item.coverImageUrl.trim().isEmpty) {
      AppSnackbar('common.error'.tr, 'market_feed_share.cover_required'.tr);
      return;
    }

    await ShareActionGuard.run(() async {
      final loader = Get.isRegistered<GlobalLoaderController>()
          ? Get.find<GlobalLoaderController>()
          : Get.put(GlobalLoaderController());
      loader.isOn.value = true;

      try {
        final postId = const Uuid().v4();
        final now = DateTime.now().millisecondsSinceEpoch;
        final imageUrls = [item.coverImageUrl.trim()];
        final reshareMap = {
          'visibility': 0,
          'ctaLabel': 'education_feed.cta_listing'.tr,
          'ctaUrl': const MarketShareService().buildInternalUrl(item.id),
          'ctaType': 'market',
          'ctaDocId': item.id,
        };
        await FirebaseFirestore.instance.collection('Posts').doc(postId).set({
          'arsiv': false,
          'debugMode': false,
          'deletedPost': false,
          'deletedPostTime': 0,
          'flood': false,
          'floodCount': 1,
          'gizlendi': false,
          'img': imageUrls,
          'imgMap': [
            {
              'url': item.coverImageUrl.trim(),
              'aspectRatio': 1.0,
            }
          ],
          'isAd': false,
          'ad': false,
          'izBirakYayinTarihi': now,
          'stats': {
            'commentCount': 0,
            'likeCount': 0,
            'reportedCount': 0,
            'retryCount': 0,
            'savedCount': 0,
            'statsCount': 0,
          },
          'konum': '',
          'mainFlood': '',
          'metin': _caption(item),
          'reshareMap': reshareMap,
          'scheduledAt': 0,
          'sikayetEdildi': false,
          'stabilized': false,
          'tags': [],
          'thumbnail': item.coverImageUrl.trim(),
          'timeStamp': now,
          'userID': currentUid,
          'video': '',
          'hlsStatus': 'none',
          'hlsMasterUrl': '',
          'hlsUpdatedAt': 0,
          'yorum': true,
          'yorumMap': {
            'visibility': 0,
          },
          'originalUserID': '',
          'originalPostID': '',
          'sharedAsPost': false,
        });
        unawaited(
          TypesensePostService.instance.syncPostById(postId).catchError((_) {}),
        );

        final newPost = PostsModel(
          ad: false,
          arsiv: false,
          aspectRatio: 1.0,
          debugMode: false,
          deletedPost: false,
          deletedPostTime: 0,
          docID: postId,
          flood: false,
          floodCount: 1,
          gizlendi: false,
          img: imageUrls,
          isAd: false,
          izBirakYayinTarihi: now,
          konum: '',
          mainFlood: '',
          metin: _caption(item),
          originalPostID: '',
          originalUserID: '',
          paylasGizliligi: 0,
          reshareMap: reshareMap,
          scheduledAt: 0,
          sikayetEdildi: false,
          stabilized: false,
          stats: PostStats(),
          tags: const [],
          thumbnail: item.coverImageUrl.trim(),
          timeStamp: now,
          userID: currentUid,
          video: '',
          hlsStatus: 'none',
          hlsMasterUrl: '',
          hlsUpdatedAt: 0,
          yorum: true,
          yorumMap: const {'visibility': 0},
        );

        if (Get.isRegistered<AgendaController>()) {
          final agendaController = Get.find<AgendaController>();
          agendaController.addUploadedPostsAtTop([newPost]);
          if (agendaController.scrollController.hasClients) {
            await agendaController.scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
            );
          }
        }

        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().getLastPostAndAddToAllPosts();
        }

        AppSnackbar('common.success'.tr, 'market_feed_share.shared'.tr);
      } catch (_) {
        AppSnackbar('common.error'.tr, 'education_feed.share_failed'.tr);
      } finally {
        loader.isOn.value = false;
      }
    });
  }

  String _caption(MarketItemModel item) {
    return <String>[
      '"${item.title}"',
      '${item.price.toStringAsFixed(0)} ${marketCurrencyLabel(item.currency)}',
      if (item.locationText.trim().isNotEmpty) item.locationText.trim(),
    ].join('\n');
  }
}
