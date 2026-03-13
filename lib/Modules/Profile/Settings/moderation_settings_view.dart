import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/moderation_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/moderation_config_service.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Models/moderation_config_model.dart';

class ModerationSettingsView extends StatefulWidget {
  const ModerationSettingsView({super.key});

  @override
  State<ModerationSettingsView> createState() => _ModerationSettingsViewState();
}

class _ModerationSettingsViewState extends State<ModerationSettingsView> {
  final ModerationConfigService _configService =
      const ModerationConfigService();
  late final Future<bool> _canAccessFuture;
  bool _provisioning = false;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Moderasyon"),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (accessSnap.data != true) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bu alan sadece admin erişimine açıktır.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return StreamBuilder<ModerationConfigModel>(
                    stream: _configService.watch(),
                    builder: (context, configSnap) {
                      final config =
                          configSnap.data ?? ModerationConfigModel.defaults;
                      return _ModerationThresholdList(
                        config: config,
                        provisioning: _provisioning,
                        onEnsureConfig: _ensureConfig,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ensureConfig() async {
    if (_provisioning) return;
    setState(() => _provisioning = true);
    try {
      final config = await _configService.ensureWithCallable();
      AppSnackbar(
        'Moderasyon',
        'Config güncellendi. Eşik: ${config.blackBadgeFlagThreshold}',
      );
    } catch (e) {
      AppSnackbar('Hata', 'Config güncellenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _provisioning = false);
      }
    }
  }
}

class _ModerationThresholdList extends StatelessWidget {
  const _ModerationThresholdList({
    required this.config,
    required this.provisioning,
    required this.onEnsureConfig,
  });

  final ModerationConfigModel config;
  final bool provisioning;
  final Future<void> Function() onEnsureConfig;
  static final ModerationRepository _moderationRepository =
      ModerationRepository.ensure();

  @override
  Widget build(BuildContext context) {
    final threshold = config.blackBadgeFlagThreshold.clamp(1, 1000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildConfigCard(config),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(CupertinoIcons.flag_fill, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Text(
                'Eşik Değeri Aşan Postlar (≥ $threshold)',
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ModerationFlaggedPost>>(
              stream: _moderationRepository.watchFlaggedPosts(
                threshold: threshold,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(
                    child: Text(
                      'Moderasyon listesi alınamadı.',
                      style: TextStyle(fontFamily: 'MontserratMedium'),
                    ),
                  );
                }
                final docs = snap.data ?? const <ModerationFlaggedPost>[];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Eşiği aşan post bulunmuyor.',
                      style: TextStyle(fontFamily: 'MontserratMedium'),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = docs[index];
                    final data = item.data;
                    final moderation = _asMap(data['moderation']);
                    final flagCount = _asInt(moderation['flagCount']);
                    final status =
                        (moderation['status'] ?? 'active').toString();
                    final userId =
                        (data['userID'] ?? data['userId'] ?? '').toString();
                    final text = (data['metin'] ?? '').toString();
                    final lastFlagAt = _toDateTime(moderation['lastFlagAt']);
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      title: Text(
                        text.isEmpty ? 'Metin yok' : text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'post: ${item.id}\nuser: $userId\nstatus: $status • flag: $flagCount'
                          '${lastFlagAt == null ? '' : ' • son: ${_formatDate(lastFlagAt)}'}',
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      trailing: status == 'shadow_hidden'
                          ? const Icon(CupertinoIcons.eye_slash_fill,
                              color: Colors.orange, size: 18)
                          : const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: Colors.red,
                              size: 18),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(ModerationConfigModel config) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'adminConfig/moderation',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'enabled: ${config.enabled}\n'
            'blackBadgeFlagThreshold: ${config.blackBadgeFlagThreshold}\n'
            'allowSingleFlagPerUser: ${config.allowSingleFlagPerUser}\n'
            'enableShadowHide: ${config.enableShadowHide}\n'
            'notifyOwnerOnAdminRemove: ${config.notifyOwnerOnAdminRemove}\n'
            'notifyFlaggersOnAdminRemove: ${config.notifyFlaggersOnAdminRemove}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: provisioning ? null : onEnsureConfig,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black.withValues(alpha: 0.25)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: provisioning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.gear, size: 15),
              label: Text(
                provisioning ? 'Kuruluyor...' : 'Config Kur/Yenile',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  static int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static String _formatDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
