import 'package:flutter/cupertino.dart';

class AdminTaskDefinition {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  const AdminTaskDefinition({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });
}

const List<AdminTaskDefinition> adminTaskCatalog = <AdminTaskDefinition>[
  AdminTaskDefinition(
    id: 'moderation',
    titleKey: 'admin.task.moderation.title',
    descriptionKey: 'admin.task.moderation.desc',
    icon: CupertinoIcons.flag_fill,
  ),
  AdminTaskDefinition(
    id: 'reports',
    titleKey: 'admin.task.reports.title',
    descriptionKey: 'admin.task.reports.desc',
    icon: CupertinoIcons.exclamationmark_bubble_fill,
  ),
  AdminTaskDefinition(
    id: 'badges',
    titleKey: 'admin.task.badges.title',
    descriptionKey: 'admin.task.badges.desc',
    icon: CupertinoIcons.checkmark_seal_fill,
  ),
  AdminTaskDefinition(
    id: 'approvals',
    titleKey: 'admin.task.approvals.title',
    descriptionKey: 'admin.task.approvals.desc',
    icon: CupertinoIcons.checkmark_alt_circle_fill,
  ),
  AdminTaskDefinition(
    id: 'user_bans',
    titleKey: 'admin.task.user_bans.title',
    descriptionKey: 'admin.task.user_bans.desc',
    icon: CupertinoIcons.hand_raised_fill,
  ),
  AdminTaskDefinition(
    id: 'admin_push',
    titleKey: 'admin.task.admin_push.title',
    descriptionKey: 'admin.task.admin_push.desc',
    icon: CupertinoIcons.bell_fill,
  ),
  AdminTaskDefinition(
    id: 'ads_center',
    titleKey: 'admin.task.ads_center.title',
    descriptionKey: 'admin.task.ads_center.desc',
    icon: CupertinoIcons.speaker_2_fill,
  ),
  AdminTaskDefinition(
    id: 'story_music',
    titleKey: 'admin.task.story_music.title',
    descriptionKey: 'admin.task.story_music.desc',
    icon: CupertinoIcons.music_note_list,
  ),
  AdminTaskDefinition(
    id: 'pasaj',
    titleKey: 'admin.task.pasaj.title',
    descriptionKey: 'admin.task.pasaj.desc',
    icon: CupertinoIcons.briefcase_fill,
  ),
  AdminTaskDefinition(
    id: 'support',
    titleKey: 'admin.task.support.title',
    descriptionKey: 'admin.task.support.desc',
    icon: CupertinoIcons.chat_bubble_2_fill,
  ),
];

Map<String, AdminTaskDefinition> get adminTaskCatalogById =>
    <String, AdminTaskDefinition>{
      for (final task in adminTaskCatalog) task.id: task,
    };

List<String> normalizeAdminTaskIds(Iterable<dynamic> raw) {
  final known = adminTaskCatalogById;
  final out = <String>[];
  for (final value in raw) {
    final id = value.toString().trim();
    if (id.isNotEmpty && known.containsKey(id) && !out.contains(id)) {
      out.add(id);
    }
  }
  return out;
}
