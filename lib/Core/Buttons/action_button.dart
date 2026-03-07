import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class ActionButton extends StatefulWidget {
  final BuildContext context;
  final List<PullDownMenuItem> menuItems;

  const ActionButton({
    super.key,
    required this.context,
    required this.menuItems,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  late final Future<Map<String, bool>> _permissionsFuture;
  bool _rozetErrorShown = false;
  static const Duration _rozetCacheTtl = Duration(minutes: 5);
  static const Duration _rozetStaleRetention = Duration(minutes: 20);
  static final Map<String, _RozetCacheEntry> _rozetCacheByUid =
      <String, _RozetCacheEntry>{};

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _loadPermissions();
  }

  Future<String> _loadRozet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '';
    }
    _pruneStaleRozetCache();
    final cached = _rozetCacheByUid[user.uid];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _rozetCacheTtl) {
      return cached.rozet;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _rozetCacheByUid[user.uid] =
            _RozetCacheEntry(rozet: '', cachedAt: DateTime.now());
        return '';
      }

      final rozet = (doc.data()?["rozet"] as String? ?? "").trim();
      _rozetCacheByUid[user.uid] =
          _RozetCacheEntry(rozet: rozet, cachedAt: DateTime.now());
      return rozet;
    } catch (e) {
      if (!_rozetErrorShown) {
        _rozetErrorShown = true;
        AppSnackbar("Hata!", "Rozet kontrolü başarısız oldu.");
      }
      debugPrint("Rozet kontrol hatası: $e");
      return '';
    }
  }

  void _pruneStaleRozetCache() {
    final now = DateTime.now();
    _rozetCacheByUid.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > _rozetStaleRetention,
    );
  }

  Future<bool> _canManageSliders() async {
    return AdminAccessService.canManageSliders();
  }

  Future<Map<String, bool>> _loadPermissions() async {
    final rozet = await _loadRozet();
    final canManageSliders = await _canManageSliders();
    return {
      'canCreateScholarship': ["Kirmizi", "Sari", "Turkuaz"].contains(rozet),
      'canCreateExam': ["Turkuaz", "Sari"].contains(rozet),
      'canManageSliders': canManageSliders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = false.obs;
    return Transform.translate(
      offset: const Offset(0, -60),
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        child: Obx(
          () => Opacity(
            opacity: isPressed.value ? 0.5 : 1.0,
            child: SizedBox(
              width: 60,
              height: 60,
              child: FutureBuilder<Map<String, bool>>(
                future: _permissionsFuture,
                builder: (context, snapshot) {
                  final canCreateScholarship =
                      snapshot.data?['canCreateScholarship'] ?? false;
                  final canCreateExam =
                      snapshot.data?['canCreateExam'] ?? false;
                  final canManageSliders =
                      snapshot.data?['canManageSliders'] ?? false;
                  return PullDownButton(
                    itemBuilder: (context) => widget.menuItems
                        .map((item) {
                          if ((item.title == 'Burs Oluştur' ||
                                  item.title == 'İlanlarım') &&
                              !canCreateScholarship) {
                            return null;
                          }
                          if (item.title == 'Deneme Oluştur' &&
                              !canCreateExam) {
                            return null;
                          }
                          if (item.title == 'Slider Yönetimi' &&
                              !canManageSliders) {
                            return null;
                          }
                          return item;
                        })
                        .whereType<PullDownMenuItem>()
                        .toList(),
                    buttonBuilder: (context, showMenu) => ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 16,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: Icon(
                              Icons.grid_view_outlined,
                              color: Colors.black,
                              size: Theme.of(context).iconTheme.size ?? 25,
                            ),
                            onPressed: showMenu,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RozetCacheEntry {
  final String rozet;
  final DateTime cachedAt;

  const _RozetCacheEntry({
    required this.rozet,
    required this.cachedAt,
  });
}
