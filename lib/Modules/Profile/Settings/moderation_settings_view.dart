import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Repositories/moderation_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
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
          const _UserBanSection(),
          const SizedBox(height: 12),
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

class _UserBanSection extends StatefulWidget {
  const _UserBanSection();

  @override
  State<_UserBanSection> createState() => _UserBanSectionState();
}

class _UserBanSectionState extends State<_UserBanSection> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  bool _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('bannedUser')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kullanıcı Ban Yönetimi',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '1. ihlal: 1 ay, 2. ihlal: 3 ay, 3. ihlal: kalıcı yasak. Geçici cezada kullanıcı sadece gezebilir, beğeni bırakabilir ve yeniden paylaşım yapabilir.',
            style: TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nicknameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Kullanıcı adı',
              prefixIcon: const Icon(CupertinoIcons.at),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Ban nedeni',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: Icon(CupertinoIcons.exclamationmark_bubble),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _applyByNickname('advance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(CupertinoIcons.hammer_fill, size: 16),
                  label: const Text(
                    'Sonraki Cezayı Uygula',
                    style: TextStyle(fontFamily: 'MontserratBold'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _applyByNickname('clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.refresh_thick, size: 16),
                  label: const Text(
                    'Banı Kaldır',
                    style: TextStyle(fontFamily: 'MontserratBold'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Aktif Banlar',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return const Text(
                  'Ban listesi alınamadı.',
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                );
              }

              final docs = (snap.data?.docs ?? const [])
                  .where((doc) => (doc.data()['status'] ?? '') != 'cleared')
                  .toList(growable: false);
              if (docs.isEmpty) {
                return const Text(
                  'Aktif banlı kullanıcı yok.',
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    children: docs
                        .map((doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildBannedUserCard(doc),
                            ))
                        .toList(growable: false),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBannedUserCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final nickname = ((data['nickname'] ?? '').toString().trim()).isEmpty
        ? doc.id
        : (data['nickname'] ?? '').toString().trim();
    final reason = (data['reason'] ?? '').toString().trim();
    final strikeCount = _asInt(data['strikeCount']);
    final level = _asInt(data['banLevel']);
    final untilMs = _asInt(data['restrictedUntil']);
    final permanent = (data['permanent'] ?? false) == true;
    final status = (data['status'] ?? 'active').toString();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expired = !permanent && untilMs > 0 && untilMs <= nowMs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '@$nickname',
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              _BanChip(
                text: permanent
                    ? 'Kalıcı'
                    : expired
                        ? 'Süresi Doldu'
                        : 'Seviye $level',
                color: permanent
                    ? Colors.red
                    : expired
                        ? Colors.orange
                        : Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Strike: $strikeCount • Durum: $status',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          if (untilMs > 0 && !permanent)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Bitiş: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(untilMs))}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                reason,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _applyByUserId(doc.id, 'advance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Bir Sonraki Ceza',
                    style: TextStyle(fontFamily: 'MontserratBold'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _applyByUserId(doc.id, 'clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Banı Kaldır',
                    style: TextStyle(fontFamily: 'MontserratBold'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyByNickname(String action) async {
    final nickname = _normalizeNickname(_nicknameController.text);
    if (nickname.isEmpty) {
      AppSnackbar('Eksik Bilgi', 'Kullanıcı adı zorunludur.');
      return;
    }
    await _callBanAction(
      callableName: 'setUserBanByNickname',
      payload: <String, dynamic>{
        'nickname': nickname,
        'action': action,
        'reason': _reasonController.text.trim(),
      },
    );
  }

  Future<void> _applyByUserId(String userId, String action) async {
    await _callBanAction(
      callableName: 'setUserBanByUserId',
      payload: <String, dynamic>{
        'userId': userId,
        'action': action,
        'reason': _reasonController.text.trim(),
      },
    );
  }

  Future<void> _callBanAction({
    required String callableName,
    required Map<String, dynamic> payload,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        String targetUserId = (payload['userId'] ?? '').toString().trim();
        String targetNickname = '';
        if (targetUserId.isEmpty) {
          final nickname = (payload['nickname'] ?? '').toString().trim();
          final user = await _userRepository.findUserByNickname(nickname);
          if (user == null) {
            AppSnackbar('Hata', 'Bu kullanıcı adı ile kullanıcı bulunamadı.');
            return;
          }
          targetUserId = (user['id'] ?? '').toString().trim();
          targetNickname = (user['nickname'] ?? '').toString().trim();
        } else {
          final user = await _userRepository.getUserRaw(targetUserId);
          targetNickname = (user?['nickname'] ?? '').toString().trim();
        }
        final action = (payload['action'] ?? '').toString().trim();
        final reason = (payload['reason'] ?? '').toString().trim();
        await _approvalRepository.createApproval(
          type: 'user_ban',
          title: action == 'clear' ? 'Ban kaldırma onayı' : 'Ban işlemi onayı',
          summary: action == 'clear'
              ? '@$targetNickname için ban kaldırma talebi oluşturuldu.'
              : '@$targetNickname için sonraki ceza talebi oluşturuldu.',
          targetUserId: targetUserId,
          targetNickname: targetNickname,
          payload: <String, dynamic>{
            'userId': targetUserId,
            'action': action,
            'reason': reason,
          },
        );
        AppSnackbar('Moderasyon', 'İşlem admin onay kuyruğuna gönderildi.');
        if (callableName == 'setUserBanByNickname') {
          _nicknameController.clear();
        }
        _reasonController.clear();
        return;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable(callableName);
      final response = await callable.call<Map<String, dynamic>>(payload);
      final data = Map<String, dynamic>.from(response.data);
      final nickname = (data['nickname'] ?? '').toString().trim();
      final permanent = (data['permanent'] ?? false) == true;
      final level = _asInt(data['banLevel']);
      final cleared = (data['status'] ?? '') == 'cleared';
      if (!mounted) return;
      AppSnackbar(
        'Moderasyon',
        cleared
            ? '@$nickname için ban kaldırıldı.'
            : permanent
                ? '@$nickname için kalıcı yasak uygulandı.'
                : '@$nickname için seviye $level ceza uygulandı.',
      );
      if (callableName == 'setUserBanByNickname') {
        _nicknameController.clear();
      }
      if (cleared || permanent || level > 0) {
        _reasonController.clear();
      }
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar('Hata', _errorMessage(e));
    } catch (e) {
      AppSnackbar('Hata', 'Ban işlemi tamamlanamadı: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _normalizeNickname(String raw) {
    return raw
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  String _errorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'not-found':
        return 'Bu kullanıcı adı ile kullanıcı bulunamadı.';
      case 'permission-denied':
        return 'Bu işlem için admin yetkisi gerekli.';
      case 'invalid-argument':
        return error.message ?? 'Girilen bilgi geçersiz.';
      case 'failed-precondition':
        return 'Bu kullanıcı adı için birden fazla kullanıcı bulundu.';
      default:
        return error.message ?? 'Ban işlemi tamamlanamadı.';
    }
  }

  static int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static String _formatDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _BanChip extends StatelessWidget {
  const _BanChip({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
