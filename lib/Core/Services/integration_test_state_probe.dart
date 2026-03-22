import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';

class IntegrationTestStateProbe {
  const IntegrationTestStateProbe._();

  static Map<String, dynamic> snapshot() {
    final routing = Get.routing;
    return <String, dynamic>{
      'feed': _feedSnapshot(),
      'explore': _exploreSnapshot(),
      'education': _educationSnapshot(),
      'chat': _chatSnapshot(),
      'short': _shortSnapshot(),
      'profile': _profileSnapshot(),
      'socialProfile': _socialProfileSnapshot(),
      'notifications': _notificationsSnapshot(),
      'navBar': _navBarSnapshot(),
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
    final controller = AgendaController.maybeFind();
    if (controller == null) {
      return const <String, dynamic>{'registered': false};
    }
    final centeredIndex = controller.centeredIndex.value;
    final items = controller.agendaList;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'centeredIndex': centeredIndex,
      'centeredDocId': centeredIndex >= 0 && centeredIndex < items.length
          ? items[centeredIndex].docID
          : '',
      'docIds':
          items.take(24).map((item) => item.docID).toList(growable: false),
      'lastCenteredIndex': controller.lastCenteredIndex,
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
    final controller = EducationController.maybeFind();
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
    return <String, dynamic>{
      'registered': true,
      'count': controller.list.length,
      'selection': controller.selection.value,
      'unreadTotal': controller.unreadTotal.value,
    };
  }
}
