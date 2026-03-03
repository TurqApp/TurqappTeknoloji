import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/notification_preferences_service.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  Map<String, dynamic> _prefs = NotificationPreferencesService.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs =
        await NotificationPreferencesService.getCurrentUserPreferences();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    _writePath(next, path, value);
    setState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }

  void _writePath(Map<String, dynamic> source, String path, dynamic value) {
    final segments = path.split('.');
    Map<String, dynamic> current = source;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final next = current[key];
      if (next is Map<String, dynamic>) {
        current = next;
      } else if (next is Map) {
        current = Map<String, dynamic>.from(next);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
  }

  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackButtons(text: 'Bildirimler'),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _deviceNoticeCard(),
                        const SizedBox(height: 18),
                        const _SectionLabel('Anlık Bildirimler'),
                        _SwitchTile(
                          title: 'Tümünü durdur',
                          subtitle:
                              'Bildirimleri geçici olarak tamamen sessize al.',
                          value: _boolValue('pauseAll'),
                          onChanged: (value) => _setValue('pauseAll', value),
                        ),
                        _SwitchTile(
                          title: 'Uyku modu',
                          subtitle:
                              'Rahatsız edilmek istemediğinde bildirimleri sakinleştir.',
                          value: _boolValue('sleepMode'),
                          onChanged: (value) => _setValue('sleepMode', value),
                        ),
                        _SwitchTile(
                          title: 'Sadece mesajlar',
                          subtitle:
                              'Açıkken yalnızca mesaj bildirimleri görünür.',
                          value: _boolValue('messagesOnly'),
                          onChanged: (value) =>
                              _setValue('messagesOnly', value),
                        ),
                        const SizedBox(height: 14),
                        const _SectionLabel('Kategoriler'),
                        _NavTile(
                          title: 'Gönderiler ve yorumlar',
                          subtitle:
                              'Gönderi etkileşimleri, yorumlar ve duyurular.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'Gönderiler ve yorumlar',
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'posts.comments',
                                    title: 'Yorumlar',
                                    subtitle: 'Gönderine yapılan yorumlar.',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'posts.postActivity',
                                    title: 'Gönderi etkileşimleri',
                                    subtitle:
                                        'Beğeniler, paylaşımlar ve gönderi pushları.',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'Takipler',
                          subtitle: 'Yeni takipçiler ve takip hareketleri.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'Takipler',
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'followers.follows',
                                    title: 'Takip bildirimleri',
                                    subtitle:
                                        'Seni takip eden kullanıcılar ve takip hareketleri.',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'Mesajlar',
                          subtitle: 'Sohbet ve direkt mesaj bildirimleri.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'Mesajlar',
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'messages.directMessages',
                                    title: 'Mesajlar',
                                    subtitle:
                                        'Birebir sohbetler ve gelen yeni mesajlar.',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                        _NavTile(
                          title: 'İlanlar ve başvurular',
                          subtitle:
                              'İş ve özel ders ilanlarına gelen başvurular.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _NotificationCategoryView(
                                title: 'İlanlar ve başvurular',
                                items: const [
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.jobApplications',
                                    title: 'İş ilanı başvuruları',
                                    subtitle:
                                        'İş ilanına yapılan yeni başvurular.',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.tutoringApplications',
                                    title: 'Özel ders başvuruları',
                                    subtitle:
                                        'Özel ders ilanına yapılan başvurular.',
                                  ),
                                  _NotificationPreferenceItem(
                                    path: 'opportunities.applicationStatus',
                                    title: 'Başvuru durumu',
                                    subtitle:
                                        'Özel ders başvuru sonucu ve durum güncellemeleri.',
                                  ),
                                ],
                                initialPrefs: _prefs,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.bell,
              size: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kilit ekranında bildirimleri görmek için cihaz ayarlarından bildirim iznini açık tut.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.25,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: openAppSettings,
                  child: const Text(
                    'Cihaz ayarlarına git',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCategoryView extends StatefulWidget {
  final String title;
  final List<_NotificationPreferenceItem> items;
  final Map<String, dynamic> initialPrefs;

  const _NotificationCategoryView({
    required this.title,
    required this.items,
    required this.initialPrefs,
  });

  @override
  State<_NotificationCategoryView> createState() =>
      _NotificationCategoryViewState();
}

class _NotificationCategoryViewState extends State<_NotificationCategoryView> {
  late Map<String, dynamic> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = NotificationPreferencesService.mergeWithDefaults(
      widget.initialPrefs,
    );
  }

  bool _boolValue(String path) {
    dynamic current = _prefs;
    for (final segment in path.split('.')) {
      if (current is! Map) return false;
      current = current[segment];
    }
    return current == true;
  }

  Future<void> _setValue(String path, bool value) async {
    final next = NotificationPreferencesService.mergeWithDefaults(_prefs);
    final segments = path.split('.');
    Map<String, dynamic> current = next;
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i];
      final nested = current[key];
      if (nested is Map<String, dynamic>) {
        current = nested;
      } else if (nested is Map) {
        current = Map<String, dynamic>.from(nested);
      } else {
        final created = <String, dynamic>{};
        current[key] = created;
        current = created;
      }
    }
    current[segments.last] = value;
    setState(() {
      _prefs = next;
    });
    await NotificationPreferencesService.setValue(path, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0x12000000)),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _SwitchTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    value: _boolValue(item.path),
                    onChanged: (value) => _setValue(item.path, value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreferenceItem {
  final String path;
  final String title;
  final String subtitle;

  const _NotificationPreferenceItem({
    required this.path,
    required this.title,
    required this.subtitle,
  });
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    height: 1.25,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                      height: 1.25,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
