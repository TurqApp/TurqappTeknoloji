import 'package:flutter/cupertino.dart';

class AdminTaskDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const AdminTaskDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const List<AdminTaskDefinition> adminTaskCatalog = <AdminTaskDefinition>[
  AdminTaskDefinition(
    id: 'moderation',
    title: 'Moderasyon',
    description: 'Flag, rapor ve içerik eşiklerini yönetir.',
    icon: CupertinoIcons.flag_fill,
  ),
  AdminTaskDefinition(
    id: 'reports',
    title: 'Raporlar',
    description: 'Kullanıcı ve içerik raporlarını inceler.',
    icon: CupertinoIcons.exclamationmark_bubble_fill,
  ),
  AdminTaskDefinition(
    id: 'badges',
    title: 'Rozet Yönetimi',
    description: 'Rozet başvurularını inceler ve rozet verir.',
    icon: CupertinoIcons.checkmark_seal_fill,
  ),
  AdminTaskDefinition(
    id: 'approvals',
    title: 'Onay / Başvurular',
    description: 'Rozet ve benzeri başvuru-onay kuyruklarını takip eder.',
    icon: CupertinoIcons.checkmark_alt_circle_fill,
  ),
  AdminTaskDefinition(
    id: 'user_bans',
    title: 'Ban Yönetimi',
    description: 'Kullanıcı banlarını uygular veya kaldırır.',
    icon: CupertinoIcons.hand_raised_fill,
  ),
  AdminTaskDefinition(
    id: 'admin_push',
    title: 'Admin Push',
    description: 'Toplu bildirim ve sistem duyurularını gönderir.',
    icon: CupertinoIcons.bell_fill,
  ),
  AdminTaskDefinition(
    id: 'ads_center',
    title: 'Reklam Merkezi',
    description: 'Reklam ve kampanya operasyonlarını yönetir.',
    icon: CupertinoIcons.speaker_2_fill,
  ),
  AdminTaskDefinition(
    id: 'story_music',
    title: 'Hikaye Müzikleri',
    description: 'Hikaye müziği kataloglarını yönetir.',
    icon: CupertinoIcons.music_note_list,
  ),
  AdminTaskDefinition(
    id: 'pasaj',
    title: 'Pasaj Operasyonu',
    description: 'Pasaj tarafındaki içerik ve akışları takip eder.',
    icon: CupertinoIcons.briefcase_fill,
  ),
  AdminTaskDefinition(
    id: 'support',
    title: 'Kullanıcı Destek',
    description: 'Kullanıcı taleplerini ve geri bildirimleri takip eder.',
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
