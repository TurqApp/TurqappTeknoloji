import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_controller.dart';
import 'package:turqappv2/Core/Services/integration_media_test_harness.dart';
import 'package:turqappv2/Core/Services/integration_permission_test_harness.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/Social/Comments/post_comment_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/StoryComments/story_comments_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Core/Services/video_state_manager.dart';

class IntegrationTestStateProbe {
  const IntegrationTestStateProbe._();

  static Map<String, String> _permissionStatuses = <String, String>{};
  static bool _permissionsRegistered = false;

  static void updatePermissionStatuses(
    Map<String, PermissionStatus> statuses,
  ) {
    _permissionsRegistered = true;
    _permissionStatuses = statuses.map(
      (key, value) => MapEntry(key, value.name),
    );
  }

  static void clearPermissionStatuses() {
    _permissionsRegistered = false;
    _permissionStatuses = <String, String>{};
  }

  static Map<String, dynamic> snapshot() {
    final routing = Get.routing;
    return <String, dynamic>{
      'feed': _feedSnapshot(),
      'explore': _exploreSnapshot(),
      'education': _educationSnapshot(),
      'chat': _chatSnapshot(),
      'chatConversation': _chatConversationSnapshot(),
      'comments': _commentsSnapshot(),
      'short': _shortSnapshot(),
      'profile': _profileSnapshot(),
      'socialProfile': _socialProfileSnapshot(),
      'notifications': _notificationsSnapshot(),
      'permissions': _permissionsSnapshot(),
      'storyComments': _storyCommentsSnapshot(),
      'auth': _authSnapshot(),
      'testHarnesses': _testHarnessSnapshot(),
      'snackbar': readLastSnackbarDebugState(),
      'navBar': _navBarSnapshot(),
      'videoPlayback': _videoPlaybackSnapshot(),
      'currentRoute': Get.currentRoute,
      'previousRoute': routing.previous,
      'isBack': routing.isBack,
      'isBottomSheet': routing.isBottomSheet,
      'isDialog': routing.isDialog,
    };
  }

  static Map<String, dynamic> _navBarSnapshot() {
    final controller = NavBarController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      'selectedIndex': controller.selectedIndex.value,
      'showBar': controller.showBar.value,
    };
  }

  static Map<String, dynamic> _feedSnapshot() {
    final controller = maybeFindAgendaController();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final centeredIndex = controller.centeredIndex.value;
    final items = controller.agendaList;
    final centeredItem = centeredIndex >= 0 && centeredIndex < items.length
        ? items[centeredIndex]
        : null;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'centeredIndex': centeredIndex,
      'centeredDocId': centeredItem?.docID ?? '',
      'centeredHasPlayableVideo': centeredItem?.hasPlayableVideo == true,
      'centeredHasRenderableVideoCard':
          centeredItem?.hasRenderableVideoCard == true,
      'docIds':
          items.take(24).map((item) => item.docID).toList(growable: false),
      'lastCenteredIndex': controller.lastCenteredIndex,
      'playbackSuspended': controller.playbackSuspended.value,
      'pauseAll': controller.pauseAll.value,
      'canClaimPlaybackNow': controller.canClaimPlaybackNow,
      'feedViewMode': controller.feedViewMode.value.name,
    };
  }

  static Map<String, dynamic> _videoPlaybackSnapshot() {
    final manager = VideoStateManager.maybeFind();
    if (manager == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      ...manager.debugSnapshot(),
    };
  }

  static Map<String, dynamic> _shortSnapshot() {
    final controller = ShortController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final index = controller.lastIndex.value;
    final items = controller.shorts;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'activeIndex': index,
      'activeDocId':
          index >= 0 && index < items.length ? items[index].docID : '',
      'docIds':
          items.take(24).map((item) => item.docID).toList(growable: false),
    };
  }

  static Map<String, dynamic> _exploreSnapshot() {
    final controller = ExploreController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      'selection': controller.selection.value,
      'searchMode': controller.isSearchMode.value,
      'trendingCount': controller.trendingTags.length,
      'exploreCount': controller.explorePosts.length,
      'floodCount': controller.exploreFloods.length,
      'floodVisibleIndex': controller.floodsVisibleIndex.value,
      'exploreDocIds': controller.explorePosts
          .take(24)
          .map((item) => item.docID)
          .toList(growable: false),
      'floodDocIds': controller.exploreFloods
          .take(24)
          .map((item) => item.docID)
          .toList(growable: false),
    };
  }

  static Map<String, dynamic> _educationSnapshot() {
    final controller = maybeFindEducationController();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      'selectedTab': controller.selectedTab.value,
      'visibleTabIndexes': controller.visibleTabIndexes.toList(growable: false),
      'visibleTabIds': controller.visibleTabIndexes
          .map((index) => controller.titles[index])
          .toList(growable: false),
      'searchMode': controller.isSearchMode.value,
    };
  }

  static Map<String, dynamic> _chatSnapshot() {
    final controller = ChatListingController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      'selectedTab': controller.selectedTab.value,
      'count': controller.list.length,
      'filteredCount': controller.filteredList.length,
      'chatIds': controller.filteredList.take(24).map((e) => e.chatID).toList(),
      'userIds': controller.filteredList.take(24).map((e) => e.userID).toList(),
    };
  }

  static Map<String, dynamic> _chatConversationSnapshot() {
    final controller = maybeFindChatController();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final latest =
        controller.messages.isNotEmpty ? controller.messages.first : null;
    return <String, dynamic>{
      'registered': true,
      'chatId': controller.chatID,
      'userId': controller.userID,
      'count': controller.messages.length,
      'draftText': controller.textEditingController.text,
      'selectedGifUrl': controller.selectedGifUrl.value,
      'lastSentMessageId': controller.lastSentMessageId.value,
      'lastSentText': controller.lastSentText.value,
      'lastSentType': controller.lastSentType.value,
      'lastSentMediaCount': controller.lastSentMediaCount.value,
      'lastSentPrimaryMediaUrl': controller.lastSentPrimaryMediaUrl.value,
      'lastSentVideoUrl': controller.lastSentVideoUrl.value,
      'lastSentAudioUrl': controller.lastSentAudioUrl.value,
      'latestMessageId': latest?.rawDocID ?? '',
      'latestMessageText': latest?.metin ?? '',
      'latestMessageType': _resolveChatMessageType(latest),
      'latestMessageMediaCount': latest?.imgs.length ?? 0,
      'latestMessageVideoUrl': latest?.video ?? '',
      'latestMessageAudioUrl': latest?.sesliMesaj ?? '',
      'selectedImageCount': controller.images.length,
      'hasPendingVideo': controller.pendingVideo.value != null,
      'selection': controller.selection.value,
      'isRecording': controller.isRecording.value,
      'lastMediaAction': controller.lastMediaAction.value,
      'lastMediaFailureCode': controller.lastMediaFailureCode.value,
      'lastMediaFailureDetail': controller.lastMediaFailureDetail.value,
    };
  }

  static String _resolveChatMessageType(MessageModel? model) {
    if (model == null) return '';
    if (model.video.trim().isNotEmpty) return 'video';
    if (model.sesliMesaj.trim().isNotEmpty) return 'audio';
    if (model.imgs.isNotEmpty) return 'media';
    if (model.postID.trim().isNotEmpty) return 'post';
    if (model.kisiAdSoyad.trim().isNotEmpty) return 'contact';
    if (model.lat != 0 || model.long != 0) return 'location';
    return 'text';
  }

  static Map<String, dynamic> _commentsSnapshot() {
    final controller = maybeFindPostCommentController();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final currentUid = CurrentUserService.instance.effectiveUserId;
    return <String, dynamic>{
      'registered': true,
      'count': controller.list.length,
      'docIds': controller.list
          .take(24)
          .map((item) => item.docID)
          .toList(growable: false),
      'likedByMeDocIds': currentUid.isEmpty
          ? const <String>[]
          : controller.list
              .where((item) => item.likes.contains(currentUid))
              .take(24)
              .map((item) => item.docID)
              .toList(growable: false),
      'replyingToCommentId': controller.replyingToCommentId.value,
      'replyingToNickname': controller.replyingToNickname.value,
      'selectedGifUrl': controller.selectedGifUrl.value,
      'lastSuccessfulCommentId': controller.lastSuccessfulCommentId.value,
      'lastSuccessfulSendText': controller.lastSuccessfulSendText.value,
      'lastSuccessfulSendWasReply': controller.lastSuccessfulSendWasReply.value,
      'lastDeletedCommentId': controller.lastDeletedCommentId.value,
      'lastDeletedCommentText': controller.lastDeletedCommentText.value,
    };
  }

  static Map<String, dynamic> _profileSnapshot() {
    final controller = ProfileController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final index = controller.centeredIndex.value;
    final items = controller.mergedPosts;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'centeredIndex': index,
      'centeredDocId': index >= 0 && index < items.length
          ? (items[index]['docID'] ?? '').toString()
          : '',
      'docIds': items
          .take(24)
          .map((item) => (item['docID'] ?? '').toString())
          .toList(growable: false),
      'lastCenteredIndex': controller.lastCenteredIndex,
    };
  }

  static Map<String, dynamic> _socialProfileSnapshot() {
    final controller = SocialProfileController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final index = controller.centeredIndex.value;
    final items = controller.allPosts;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'centeredIndex': index,
      'centeredDocId':
          index >= 0 && index < items.length ? items[index].docID : '',
      'docIds':
          items.take(24).map((item) => item.docID).toList(growable: false),
      'lastCenteredIndex': controller.lastCenteredIndex,
    };
  }

  static Map<String, dynamic> _notificationsSnapshot() {
    final controller = InAppNotificationsController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final notifyReader = maybeFindNotifyReaderController();
    return <String, dynamic>{
      'registered': true,
      'count': controller.list.length,
      'selection': controller.selection.value,
      'unreadTotal': controller.unreadTotal.value,
      'docIds': controller.list
          .take(24)
          .map((item) => item.docID)
          .toList(growable: false),
      'types': controller.list
          .take(24)
          .map((item) => item.type)
          .toList(growable: false),
      'postTypes': controller.list
          .take(24)
          .map((item) => item.postType)
          .toList(growable: false),
      'postIds': controller.list
          .take(24)
          .map((item) => item.postID)
          .toList(growable: false),
      'userIds': controller.list
          .take(24)
          .map((item) => item.userID)
          .toList(growable: false),
      'lastOpenedNotificationId':
          notifyReader?.lastOpenedNotificationId.value ?? '',
      'lastOpenedNotificationType':
          notifyReader?.lastOpenedNotificationType.value ?? '',
      'lastOpenedRouteKind': notifyReader?.lastOpenedRouteKind.value ?? '',
      'lastOpenedTargetId': notifyReader?.lastOpenedTargetId.value ?? '',
    };
  }

  static Map<String, dynamic> _permissionsSnapshot() {
    return <String, dynamic>{
      'registered': _permissionsRegistered,
      'statuses': Map<String, String>.from(_permissionStatuses),
    };
  }

  static Map<String, dynamic> _storyCommentsSnapshot() {
    final controller = maybeFindStoryCommentsController();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    return <String, dynamic>{
      'registered': true,
      'storyId': controller.storyID,
      'count': controller.list.length,
      'selectedGifUrl': controller.selectedGifUrl.value,
      'lastSuccessfulCommentText': controller.lastSuccessfulCommentText.value,
      'lastSuccessfulCommentGif': controller.lastSuccessfulCommentGif.value,
    };
  }

  static Map<String, dynamic> _authSnapshot() {
    final currentUserService = CurrentUserService.instance;
    final accountCenter = maybeFindAccountCenterService();
    final activeUid = accountCenter?.activeUid.value.trim() ?? '';
    final lastUsedUid = accountCenter?.lastUsedUid.value.trim() ?? '';
    String currentUid;
    try {
      currentUid = currentUserService.effectiveUserId.trim();
    } catch (_) {
      currentUid = '';
    }
    final activeAccount =
        activeUid.isEmpty ? null : accountCenter?.accountByUid(activeUid);
    var isFirebaseSignedIn = false;
    try {
      isFirebaseSignedIn = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      isFirebaseSignedIn = false;
    }
    return <String, dynamic>{
      'registered': true,
      'currentUid': currentUid,
      'isFirebaseSignedIn': isFirebaseSignedIn,
      'currentUserLoaded': currentUserService.currentUser != null,
      'viewSelection': currentUserService.effectiveViewSelection,
      'accountCenterRegistered': accountCenter != null,
      'accountCount': accountCenter?.accounts.length ?? 0,
      'activeUid': activeUid,
      'lastUsedUid': lastUsedUid,
      'activeSessionValid': activeAccount?.isSessionValid ?? false,
      'activeRequiresReauth': activeAccount?.requiresReauth ?? false,
    };
  }

  static Map<String, dynamic> _testHarnessSnapshot() {
    return <String, dynamic>{
      'permissionHarness': IntegrationPermissionTestHarness.snapshot(),
      'mediaHarness': IntegrationMediaTestHarness.snapshot(),
    };
  }
}
