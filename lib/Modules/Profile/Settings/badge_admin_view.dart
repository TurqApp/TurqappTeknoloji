import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';

class BadgeAdminView extends StatefulWidget {
  const BadgeAdminView({super.key});

  @override
  State<BadgeAdminView> createState() => _BadgeAdminViewState();
}

class _BadgeAdminViewState extends State<BadgeAdminView> {
  static const List<String> _badgeOptions = <String>[
    '',
    'Gri',
    'Turkuaz',
    'Sarı',
    'Mavi',
    'Siyah',
    'Kırmızı',
  ];

  final TextEditingController _nicknameController = TextEditingController();
  late final Future<bool> _canAccessFuture;
  String _selectedBadge = '';
  bool _saving = false;
  _BadgeChangeResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Rozet Yönetimi"),
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nickname ile rozet ata',
                                style: TextStyle(
                                  fontFamily: 'MontserratBold',
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nickname gir, rozeti seç ve kaydet. `Rozetsiz` seçimi mevcut rozeti kaldırır.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'MontserratMedium',
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nicknameController,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(
                                  fontFamily: 'MontserratMedium',
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Nickname',
                                  hintText: '@kullaniciadi',
                                  labelStyle: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                  ),
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedBadge,
                                items: _badgeOptions
                                    .map(
                                      (badge) => DropdownMenuItem<String>(
                                        value: badge,
                                        child: _BadgeMenuRow(
                                          badge: badge,
                                          label: badge.isEmpty
                                              ? 'Rozetsiz'
                                              : badge,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedBadge = value ?? '';
                                        });
                                      },
                                decoration: InputDecoration(
                                  labelText: 'Rozet',
                                  labelStyle: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              if (_selectedDescription != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _selectedDescription!,
                                  style: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                    fontSize: 12,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _saveBadge,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _saving ? 'Kaydediliyor' : 'Rozeti Kaydet',
                                    style: const TextStyle(
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_lastResult != null) ...[
                          const SizedBox(height: 14),
                          _ResultCard(result: _lastResult!),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _selectedDescription {
    if (_selectedBadge.isEmpty) {
      return 'Seçilen kullanıcının mevcut rozeti kaldırılır.';
    }
    for (final item in verifiedAccountData) {
      if (item.title == _selectedBadge) {
        return item.desc;
      }
    }
    return null;
  }

  Future<void> _saveBadge() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final nickname = _normalizeNickname(_nicknameController.text);
    if (nickname.isEmpty) {
      AppSnackbar('Eksik Bilgi', 'Nickname zorunludur.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByNickname');
      final response = await callable.call<Map<String, dynamic>>({
        'nickname': nickname,
        'rozet': _selectedBadge,
      });

      final result = _BadgeChangeResult.fromMap(
        Map<String, dynamic>.from(response.data),
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
      });
      AppSnackbar(
        'Rozet',
        result.badge.isEmpty
            ? '@${result.nickname} için rozet kaldırıldı.'
            : '@${result.nickname} için ${result.badge} rozeti kaydedildi.',
      );
    } on FirebaseFunctionsException catch (e) {
      AppSnackbar('Hata', _errorMessage(e));
    } catch (e) {
      AppSnackbar('Hata', 'Rozet kaydedilemedi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
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
        return 'Bu nickname ile kullanıcı bulunamadı.';
      case 'permission-denied':
        return 'Bu işlem için admin yetkisi gerekli.';
      case 'invalid-argument':
        return error.message ?? 'Girilen bilgi geçersiz.';
      case 'failed-precondition':
        return 'Bu nickname için birden fazla kullanıcı bulundu.';
      default:
        return error.message ?? 'Rozet kaydedilemedi.';
    }
  }
}

class _BadgeMenuRow extends StatelessWidget {
  const _BadgeMenuRow({
    required this.badge,
    required this.label,
  });

  final String badge;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = badge.isEmpty ? Colors.transparent : mapRozetToColor(badge);
    return Row(
      children: [
        Icon(
          badge.isEmpty ? Icons.remove_circle_outline : Icons.verified,
          color: badge.isEmpty ? Colors.black54 : color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _BadgeChangeResult result;

  @override
  Widget build(BuildContext context) {
    final appliedBadge = result.badge.isEmpty ? 'Rozetsiz' : result.badge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son işlem',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${result.nickname}',
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UID: ${result.userId}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BadgeMenuRow(
                badge: result.badge,
                label: appliedBadge,
              ),
              const Spacer(),
              Text(
                result.updatedAtLabel,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeChangeResult {
  const _BadgeChangeResult({
    required this.userId,
    required this.nickname,
    required this.badge,
    required this.updatedAtMs,
  });

  final String userId;
  final String nickname;
  final String badge;
  final int updatedAtMs;

  factory _BadgeChangeResult.fromMap(Map<String, dynamic> data) {
    int updatedAt = 0;
    final rawUpdatedAt = data['updatedAt'];
    if (rawUpdatedAt is int) {
      updatedAt = rawUpdatedAt;
    } else if (rawUpdatedAt is num) {
      updatedAt = rawUpdatedAt.toInt();
    }
    return _BadgeChangeResult(
      userId: (data['userId'] ?? '').toString(),
      nickname: (data['nickname'] ?? '').toString(),
      badge: (data['rozet'] ?? '').toString(),
      updatedAtMs: updatedAt,
    );
  }

  String get updatedAtLabel {
    if (updatedAtMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
    final twoDigitMonth = dt.month.toString().padLeft(2, '0');
    final twoDigitDay = dt.day.toString().padLeft(2, '0');
    final twoDigitHour = dt.hour.toString().padLeft(2, '0');
    final twoDigitMinute = dt.minute.toString().padLeft(2, '0');
    return '$twoDigitDay.$twoDigitMonth.${dt.year} $twoDigitHour:$twoDigitMinute';
  }
}
