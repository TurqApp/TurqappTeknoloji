part of 'badge_admin_view.dart';

extension _BadgeAdminViewContentPart on _BadgeAdminViewState {
  Widget _buildBadgeAdminContent(BuildContext context, ThemeData theme) {
    return Column(
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
              Text(
                'admin.badges.manage_by_username'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'admin.badges.manage_help'.tr,
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
                  labelText: 'admin.tasks.username'.tr,
                  hintText: 'admin.tasks.username_hint'.tr,
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
                items: _BadgeAdminViewState._badgeOptions
                    .map(
                      (badge) => DropdownMenuItem<String>(
                        value: badge,
                        child: _BadgeMenuRow(
                          badge: badge,
                          label: badge.isEmpty
                              ? 'admin.badges.no_badge'.tr
                              : _localizedBadgeTitle(badge),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) {
                        _updateBadgeAdminState(() {
                          _selectedBadge = value ?? '';
                        });
                      },
                decoration: InputDecoration(
                  labelText: 'admin.badges.badge_label'.tr,
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
                    _saving
                        ? 'admin.tasks.saving'.tr
                        : 'admin.badges.save_badge'.tr,
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
              return const AppStateView.loading(
                padding: EdgeInsets.symmetric(vertical: 24),
              );
            }
            final docs = snap.data?.docs ?? const [];
            return _ApplicationsSection(docs: docs);
          },
        ),
      ],
    );
  }

  String? get _selectedDescription {
    if (_selectedBadge.isEmpty) {
      return 'admin.badges.remove_selected_desc'.tr;
    }
    return _localizedBadgeDesc(_selectedBadge);
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
    final appliedBadge =
        result.badge.isEmpty ? 'admin.badges.no_badge'.tr : result.badge;
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
          Text(
            'admin.badges.last_action'.tr,
            style: const TextStyle(
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
