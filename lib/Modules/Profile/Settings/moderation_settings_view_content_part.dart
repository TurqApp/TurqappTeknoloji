part of 'moderation_settings_view.dart';

extension _ModerationSettingsViewContentPart on _ModerationSettingsViewState {
  Widget _buildModerationSettingsScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.moderation.title'.tr),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (accessSnap.data != true) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'admin.no_access'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
    _updateModerationSettingsState(() => _provisioning = true);
    try {
      final config = await _configService.ensureWithCallable();
      AppSnackbar(
        'admin.moderation.title'.tr,
        'admin.moderation.config_updated'.trParams(<String, String>{
          'threshold': '${config.blackBadgeFlagThreshold}',
        }),
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.moderation.config_failed'.tr}: $e',
      );
    } finally {
      _updateModerationSettingsState(() => _provisioning = false);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: bottomInset + 24),
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
                'admin.moderation.threshold_posts'.trParams(
                  <String, String>{'threshold': '$threshold'},
                ),
                style: const TextStyle(
                  fontFamily: 'MontserratBold',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<ModerationFlaggedPost>>(
            stream: _moderationRepository.watchFlaggedPosts(
              threshold: threshold,
            ),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'admin.moderation.list_failed'.tr,
                      style: const TextStyle(fontFamily: 'MontserratMedium'),
                    ),
                  ),
                );
              }
              final docs = snap.data ?? const <ModerationFlaggedPost>[];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'admin.moderation.no_threshold_posts'.tr,
                      style: const TextStyle(fontFamily: 'MontserratMedium'),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = docs[index];
                  final data = item.data;
                  final moderation = _asMap(data['moderation']);
                  final flagCount = _asInt(moderation['flagCount']);
                  final status = (moderation['status'] ?? 'active').toString();
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
                      text.isEmpty ? 'admin.moderation.no_text'.tr : text,
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
                        ? const Icon(
                            CupertinoIcons.eye_slash_fill,
                            color: Colors.orange,
                            size: 18,
                          )
                        : const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.red,
                            size: 18,
                          ),
                  );
                },
              );
            },
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
                provisioning
                    ? 'admin.moderation.provisioning'.tr
                    : 'admin.moderation.ensure_config'.tr,
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
