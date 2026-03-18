import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/admin_approval_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/verified_account_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/verified_account_data_list.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final VerifiedAccountRepository _verifiedAccountRepository =
      VerifiedAccountRepository.ensure();
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  late final Future<bool> _canAccessFuture;
  String _selectedBadge = '';
  bool _saving = false;
  _BadgeChangeResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canAccessTask('badges');
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
                                'Kullanıcı adı ile rozet yönet',
                                style: TextStyle(
                                  fontFamily: 'MontserratBold',
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Kullanıcı adını gir, rozeti seç ve kaydet. `Rozetsiz` seçimi mevcut rozeti kaldırır.',
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
                                  labelText: 'Kullanıcı adı',
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
                        const SizedBox(height: 14),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _verifiedAccountRepository.watchApplications(),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final docs = snap.data?.docs ?? const [];
                            return _ApplicationsSection(docs: docs);
                          },
                        ),
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
      AppSnackbar('Eksik Bilgi', 'Kullanıcı adı zorunludur.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        final user = await _userRepository.findUserByNickname(nickname);
        if (user == null) {
          AppSnackbar('Hata', 'Bu kullanıcı adı ile kullanıcı bulunamadı.');
          return;
        }
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'Rozet değişikliği onayı',
          summary:
              '@$nickname için ${_selectedBadge.isEmpty ? 'rozet kaldırma' : '$_selectedBadge rozeti verme'} talebi oluşturuldu.',
          targetUserId: (user['id'] ?? '').toString(),
          targetNickname: (user['nickname'] ?? '').toString(),
          payload: <String, dynamic>{
            'userId': (user['id'] ?? '').toString(),
            'rozet': _selectedBadge,
          },
        );
        AppSnackbar('Rozet', 'İşlem admin onay kuyruğuna gönderildi.');
        return;
      }

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
        return 'Bu kullanıcı adı ile kullanıcı bulunamadı.';
      case 'permission-denied':
        return 'Bu işlem için admin yetkisi gerekli.';
      case 'invalid-argument':
        return error.message ?? 'Girilen bilgi geçersiz.';
      case 'failed-precondition':
        return 'Bu kullanıcı adı için birden fazla kullanıcı bulundu.';
      default:
        return error.message ?? 'Rozet kaydedilemedi.';
    }
  }
}

class _ApplicationsSection extends StatelessWidget {
  const _ApplicationsSection({
    required this.docs,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rozet Başvuruları',
            style: TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Başvurular ayarlardan gelir. Sosyal medya ve TurqApp profil linkleri aşağıda açılır.',
            style: TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Henüz başvuru yok.',
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            )
          else
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ApplicationCard(data: doc.data()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  final AdminApprovalRepository _approvalRepository =
      AdminApprovalRepository.ensure();
  bool _approving = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final selected = (data['selected'] ?? '').toString().trim();
    final currentNickname = (data['currentNickname'] ?? '').toString().trim();
    final requestedNickname = (data['talepNickname'] ?? '').toString().trim();
    final userId = (data['userID'] ?? '').toString().trim();
    final timeStamp = (data['timeStamp'] as num?)?.toInt() ?? 0;
    final status = (data['status'] ?? 'pending').toString().trim();
    final links = <_ApplicationLink>[
      _ApplicationLink(
        label: 'Instagram',
        url: _pickSocialUrl(
          data['instagramUrl'],
          data['instagram'],
          prefix: 'https://instagram.com/',
        ),
      ),
      _ApplicationLink(
        label: 'X',
        url: _pickSocialUrl(
          data['twitterUrl'],
          data['twitter'],
          prefix: 'https://x.com/',
        ),
      ),
      _ApplicationLink(
        label: 'TikTok',
        url: _pickSocialUrl(
          data['tiktokUrl'],
          data['tiktok'],
          prefix: 'https://tiktok.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'YouTube',
        url: _pickSocialUrl(
          data['youtubeUrl'],
          data['youtube'],
          prefix: 'https://youtube.com/@',
        ),
      ),
      _ApplicationLink(
        label: 'LinkedIn',
        url: _pickSocialUrl(
          data['linkedinUrl'],
          data['linkedin'],
          prefix: 'https://linkedin.com/in/',
        ),
      ),
      _ApplicationLink(
        label: 'Website',
        url: _pickWebsiteUrl(data['websiteUrl'], data['website']),
      ),
    ].where((item) => item.url.isNotEmpty).toList(growable: false);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requestedNickname.isEmpty ? '@-' : requestedNickname,
                      style: const TextStyle(
                        fontFamily: 'MontserratBold',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: userId.isEmpty
                          ? null
                          : () => Get.to(() => SocialProfile(userID: userId)),
                      child: Text(
                        'TurqApp: ${currentNickname.isEmpty ? '@-' : currentNickname}',
                        style: TextStyle(
                          fontFamily: 'MontserratMedium',
                          fontSize: 12,
                          color: userId.isEmpty ? Colors.black54 : Colors.blue,
                          decoration: userId.isEmpty
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: $userId',
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selected.isEmpty ? 'Rozet seçilmedi' : selected,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Durum: $status',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          if (timeStamp > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timeStamp),
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links
                  .map((item) => _LinkChip(link: item))
                  .toList(growable: false),
            ),
          ],
          if (status != 'approved' && selected.isNotEmpty && userId.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _approving ? null : () => _approve(userId, selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _approving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: const Text(
                  'Onayla ve Rozet Ver',
                  style: TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(String userId, String rozet) async {
    setState(() {
      _approving = true;
    });
    try {
      final isPrimaryAdmin = await AdminAccessService.isPrimaryAdmin();
      if (!isPrimaryAdmin) {
        await _approvalRepository.createApproval(
          type: 'badge_change',
          title: 'Rozet başvurusu onayı',
          summary:
              '@${(widget.data['talepNickname'] ?? '').toString().trim()} için $rozet rozeti onaya gönderildi.',
          targetUserId: userId,
          targetNickname:
              (widget.data['currentNickname'] ?? '').toString().trim(),
          payload: <String, dynamic>{
            'userId': userId,
            'rozet': rozet,
          },
        );
        AppSnackbar('Rozet', 'Başvuru admin onay kuyruğuna gönderildi.');
        return;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('setUserBadgeByUserId');
      await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'rozet': rozet,
      });
      AppSnackbar('Rozet', 'Rozet verildi ve başvuru onaylandı.');
    } on FirebaseFunctionsException catch (e) {
      final message = e.message ?? 'Başvuru onaylanamadı.';
      AppSnackbar('Hata', message);
    } catch (e) {
      AppSnackbar('Hata', 'Başvuru onaylanamadı: $e');
    } finally {
      if (mounted) {
        setState(() {
          _approving = false;
        });
      }
    }
  }

  String _formatTimestamp(int value) {
    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${dt.year} $hh:$min';
  }

  String _pickSocialUrl(Object? urlValue, Object? rawValue,
      {required String prefix}) {
    final url = (urlValue ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final raw = (rawValue ?? '')
        .toString()
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) return '';
    return '$prefix$raw';
  }

  String _pickWebsiteUrl(Object? urlValue, Object? rawValue) {
    final url = (urlValue ?? '').toString().trim();
    if (url.isNotEmpty) return url;
    final raw = (rawValue ?? '').toString().trim();
    if (raw.isEmpty || raw == 'https://' || raw == 'http://') return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'https://$raw';
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.link,
  });

  final _ApplicationLink link;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          link.label,
          style: const TextStyle(
            fontFamily: 'MontserratBold',
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ApplicationLink {
  _ApplicationLink({
    required this.label,
    Object? url,
  }) : url = (url ?? '').toString().trim();

  final String label;
  final String url;
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
