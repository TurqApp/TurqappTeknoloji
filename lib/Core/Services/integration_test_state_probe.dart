import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
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
    if (!Get.isRegistered<NavBarController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<NavBarController>();
    return <String, dynamic>{
      'registered': true,
      'selectedIndex': controller.selectedIndex.value,
      'showBar': controller.showBar.value,
    };
  }

  static Map<String, dynamic> _feedSnapshot() {
    if (!Get.isRegistered<AgendaController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<AgendaController>();
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

  static Map<String, dynamic> _profileSnapshot() {
    if (!Get.isRegistered<ProfileController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<ProfileController>();
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
    if (!Get.isRegistered<SocialProfileController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<SocialProfileController>();
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
    if (!Get.isRegistered<InAppNotificationsController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<InAppNotificationsController>();
    return <String, dynamic>{
      'registered': true,
      'count': controller.list.length,
      'selection': controller.selection.value,
      'unreadTotal': controller.unreadTotal.value,
    };
  }
}
