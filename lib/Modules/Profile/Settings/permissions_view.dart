import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';

class _PermissionItem {
  final String title;
  final Permission permission;
  final String accessText;
  final String helpText;
  final String helpSheetTitle;
  final String helpSheetBody;
  final String? helpSheetBody2;
  final String? helpSheetLinkText;

  const _PermissionItem({
    required this.title,
    required this.permission,
    required this.accessText,
    required this.helpText,
    required this.helpSheetTitle,
    required this.helpSheetBody,
    this.helpSheetBody2,
    this.helpSheetLinkText,
  });
}

class PermissionsView extends StatefulWidget {
  const PermissionsView({super.key});

  @override
  State<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  static const String _quotaKey = 'offline_cache_quota_gb';
  static const List<int> _quotaOptions = [2, 3, 4, 5];
  static const List<_PermissionItem> _items = [
    _PermissionItem(
      title: 'Kamera',
      permission: Permission.camera,
      accessText: 'kamerasına',
      helpText: 'Cihazınızın kamerasını nasıl kullanırız?',
      helpSheetTitle: 'Cihazının kamerasını nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, fotoğraf çekmek, video kaydetmek ve görsel/işitsel efektleri önizlemek gibi özellikleri kullanman için kamera erişimini kullanır.',
      helpSheetBody2:
          'Kameranı nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
      helpSheetLinkText: 'Gizlilik Merkezi',
    ),
    _PermissionItem(
      title: 'Kişiler',
      permission: Permission.contacts,
      accessText: 'kişilerine',
      helpText: 'Cihazınızın kişilerini nasıl kullanırız?',
      helpSheetTitle: 'Cihazının kişilerini nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, tanıdığın kişilerle daha kolay bağlantı kurmana yardımcı olmak ve kişi önerilerini iyileştirmek için bu bilgileri kullanır.',
      helpSheetLinkText: 'Daha fazla bilgi al',
    ),
    _PermissionItem(
      title: 'Konum Servisleri',
      permission: Permission.locationWhenInUse,
      accessText: 'konumuna',
      helpText: 'Cihazınızın konumunu nasıl kullanırız?',
      helpSheetTitle: 'Cihazının konumunu nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, yakınındaki yerleri keşfetmek, gönderi/hikayelerde konum etiketlemek ve güvenlik özelliklerini iyileştirmek için konum bilgisini kullanır.',
      helpSheetBody2:
          'Konum bilgilerini nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
      helpSheetLinkText: 'Gizlilik Merkezi',
    ),
    _PermissionItem(
      title: 'Mikrofon',
      permission: Permission.microphone,
      accessText: 'mikrofonuna',
      helpText: 'Cihazınızın mikrofonunu nasıl kullanırız?',
      helpSheetTitle: 'Cihazının mikrofonunu nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, video kaydında ses almak ve efektleri önizlemek gibi özellikler için mikrofon erişimini kullanır.',
      helpSheetBody2:
          'Mikrofonu nasıl kullandığımız hakkında daha fazla bilgiyi Gizlilik Merkezi\'nden alabilirsin.',
      helpSheetLinkText: 'Gizlilik Merkezi',
    ),
    _PermissionItem(
      title: 'Bildirimler',
      permission: Permission.notification,
      accessText: 'anlık bildirim göndermesine',
      helpText: 'Cihazınızın bildirimlerini nasıl kullanırız?',
      helpSheetTitle: 'Cihazının bildirimlerini nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, hesabında yeni hareketler olduğunda anlık bildirim göndermek için bildirim iznini kullanır.',
      helpSheetBody2:
          'Bildirimleri nasıl kullandığımız hakkında daha fazla bilgiyi Şeffaflık Merkezi\'nden alabilirsin.',
      helpSheetLinkText: 'Şeffaflık Merkezi',
    ),
    _PermissionItem(
      title: 'Fotoğraflar',
      permission: Permission.photos,
      accessText: 'fotoğraf ve videolarına erişmesine',
      helpText: 'Cihazınızın fotoğraflarını nasıl kullanırız?',
      helpSheetTitle: 'Cihazının fotoğraflarını nasıl kullanırız?',
      helpSheetBody:
          'TurqApp, galerinden fotoğraf/video seçip paylaşabilmen ve düzenleme araçlarını kullanabilmen için fotoğraf erişimini kullanır.',
    ),
  ];

  final Map<String, PermissionStatus> _statuses = {};
  bool _loading = true;
  int _selectedQuota = 3;

  @override
  void initState() {
    super.initState();
    _loadQuota();
    _refreshStatuses();
  }

  Future<void> _loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_quotaKey) ?? 3;
    if (!mounted) return;
    setState(() => _selectedQuota = saved.clamp(2, 5));
  }

  Future<void> _setQuota(int gb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quotaKey, gb);
    try {
      if (Get.isRegistered<SegmentCacheManager>()) {
        await Get.find<SegmentCacheManager>().setUserLimitGB(gb);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _selectedQuota = gb);
  }

  Future<void> _refreshStatuses() async {
    setState(() => _loading = true);
    final next = <String, PermissionStatus>{};
    for (final item in _items) {
      next[item.title] = await item.permission.status;
    }
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  String _statusLabel(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return 'İzin verildi';
    return 'İzin verilmedi';
  }

  Widget _buildQuotaButton(int gb) {
    final selected = _selectedQuota == gb;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _setQuota(gb),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.black : Colors.black26,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$gb GB',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'Cihaz İzinleri'),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshStatuses,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          const Text(
                            'Tercihlerin',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._items.map((item) {
                            final status = _statuses[item.title] ??
                                PermissionStatus.denied;
                            return InkWell(
                              onTap: () => Get.to(
                                  () => _PermissionDetailView(item: item)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontFamily: 'MontserratMedium',
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _statusLabel(status),
                                      style: const TextStyle(
                                        color: Colors.black38,
                                        fontSize: 15,
                                        fontFamily: 'MontserratMedium',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.black38,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'Çevrimdışı İzleme Alanı',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (int i = 0;
                                  i < _quotaOptions.length;
                                  i++) ...[
                                Expanded(
                                  child: _buildQuotaButton(_quotaOptions[i]),
                                ),
                                if (i != _quotaOptions.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Seçtiğiniz GB kadar içerik cihazınıza indirilir ve internet bağlantısı olmadan izlenebilir. Alan doldukça eski videolar otomatik olarak silinir.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'Montserrat',
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDetailView extends StatefulWidget {
  final _PermissionItem item;
  const _PermissionDetailView({required this.item});

  @override
  State<_PermissionDetailView> createState() => _PermissionDetailViewState();
}

class _PermissionDetailViewState extends State<_PermissionDetailView> {
  PermissionStatus _status = PermissionStatus.denied;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final s = await widget.item.permission.status;
    if (!mounted) return;
    setState(() => _status = s);
  }

  bool get _enabled => _status.isGranted || _status.isLimited;

  bool get _usesDeviceSettingStyle =>
      widget.item.title == 'Kamera' ||
      widget.item.title == 'Mikrofon' ||
      widget.item.title == 'Bildirimler';

  Future<void> _onActionPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final canDirectRequest =
          _status.isDenied || _status.isLimited || _status.isProvisional;
      if (!_usesDeviceSettingStyle && canDirectRequest && !_enabled) {
        await widget.item.permission.request();
        await _loadStatus();
      } else {
        final shouldOpen = await _confirmOpenSettings();
        if (shouldOpen) {
          await openAppSettings();
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmOpenSettings() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Cihaz ayarlarını güncelle'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Cihaz ayarlarını aç, "${widget.item.title}" seçeneğine dokun ve bu izne nasıl erişim vermek istediğini seç.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(true),
              isDefaultAction: true,
              child: const Text('Cihaz ayarlarını aç'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Şimdi değil'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  String get _buttonText {
    if (_usesDeviceSettingStyle) return 'Cihaz ayarlarını güncelle';
    final canDirectRequest =
        _status.isDenied || _status.isLimited || _status.isProvisional;
    if (!_enabled && canDirectRequest) return 'İzinleri aç';
    if (widget.item.title == 'Konum Servisleri' && !_enabled) {
      return "Konum Servisleri'ni Aç";
    }
    return 'Cihaz ayarlarını güncelle';
  }

  List<Widget> _buildPreferenceBlock() {
    return [
      const Text(
        'Tercihlerini belirle',
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        "TurqApp'ın ${widget.item.accessText} izin vermek için ${widget.item.title} izinlerini aç.",
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
    ];
  }

  List<Widget> _buildDeviceSettingBlocks() {
    final currentStateTitle = _enabled ? 'İzin verildi' : 'İzin verilmedi';
    final otherStateTitle = _enabled ? 'İzin verilmedi' : 'İzin verildi';
    final currentStateDesc = _enabled
        ? "TurqApp'ın bu cihazın ${widget.item.accessText} izin veriliyor."
        : "TurqApp'ın bu cihazın ${widget.item.accessText} izin verilmiyor.";
    final otherStateDesc = _enabled
        ? "TurqApp'ın bu cihazın ${widget.item.accessText} izin verilmiyor."
        : "TurqApp'ın bu cihazın ${widget.item.accessText} izin veriliyor.";

    return [
      const Text(
        'Cihaz ayarın:',
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        currentStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        currentStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 26),
      const Text(
        'Diğer seçenek',
        style: TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        otherStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        otherStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'İzinlerini güncellemek için cihaz ayarlarına git.',
        style: TextStyle(
          color: Colors.black26,
          fontSize: 13,
          fontFamily: 'MontserratMedium',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.item.title),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(_usesDeviceSettingStyle
                        ? _buildDeviceSettingBlocks()
                        : _buildPreferenceBlock()),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _showHelpSheet,
                      child: Text(
                        widget.item.helpText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.black,
                            ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.black38,
                        ),
                        child: Text(
                          _busy ? 'Kontrol ediliyor...' : _buttonText,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    widget.item.helpSheetTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontFamily: 'MontserratBold',
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.item.helpSheetBody,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                    height: 1.25,
                  ),
                ),
                if (widget.item.helpSheetBody2 != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.item.helpSheetBody2!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                      height: 1.25,
                    ),
                  ),
                ],
                if (widget.item.helpSheetLinkText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.helpSheetLinkText!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
