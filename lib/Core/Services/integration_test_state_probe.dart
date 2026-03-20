import 'package:get/get.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/InAppNotifications/in_app_notifications_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';

class IntegrationTestStateProbe {
  const IntegrationTestStateProbe._();

  static Map<String, dynamic> snapshot() {
    return <String, dynamic>{
      'feed': _feedSnapshot(),
      'short': _shortSnapshot(),
      'profile': _profileSnapshot(),
      'socialProfile': _socialProfileSnapshot(),
      'notifications': _notificationsSnapshot(),
      'currentRoute': Get.currentRoute,
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
      'lastCenteredIndex': controller.lastCenteredIndex,
    };
  }

  static Map<String, dynamic> _shortSnapshot() {
    if (!Get.isRegistered<ShortController>()) {
      return const <String, dynamic>{'registered': false};
    }
    final controller = Get.find<ShortController>();
    final index = controller.lastIndex.value;
    final items = controller.shorts;
    return <String, dynamic>{
      'registered': true,
      'count': items.length,
      'activeIndex': index,
      'activeDocId':
          index >= 0 && index < items.length ? items[index].docID : '',
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
