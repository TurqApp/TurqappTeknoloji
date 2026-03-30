import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/short_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/AppPolicy/surface_policy_override_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SurfacePolicySettingsView extends StatefulWidget {
  const SurfacePolicySettingsView({super.key});

  @override
  State<SurfacePolicySettingsView> createState() =>
      _SurfacePolicySettingsViewState();
}

class _SurfacePolicySettingsViewState extends State<SurfacePolicySettingsView> {
  late final SurfacePolicyOverrideService _overrideService;
  late final List<_PolicySection> _sections;
  late final Map<String, TextEditingController> _controllers;
  bool _isReady = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _overrideService = ensureSurfacePolicyOverrideService();
    _sections = _buildSections();
    _controllers = {
      for (final field in _allFields)
        field.key: TextEditingController(
          text: field.defaultValue.toString(),
        ),
    };
    _loadOverrides();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<_PolicyField> get _allFields =>
      _sections.expand((section) => section.fields).toList(growable: false);

  Future<void> _loadOverrides() async {
    await _overrideService.ensureReady();
    final overrides = _overrideService.snapshot();
    for (final field in _allFields) {
      _controllers[field.key]?.text =
          (overrides[field.key] ?? field.defaultValue).toString();
    }
    if (!mounted) return;
    setState(() => _isReady = true);
  }

  Future<void> _save() async {
    await _persistOverrides();
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _overrideService.clearAll();
      for (final field in _allFields) {
        _controllers[field.key]?.text = field.defaultValue.toString();
      }
      AppSnackbar(
        'Varsayılanlara dönüldü',
        'Bu cihazdaki yerel akış ve önbellek ayarları sıfırlandı.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _reloadNow() async {
    final saved = await _persistOverrides(showSuccessMessage: false);
    if (!saved) return;

    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isNotEmpty) {
      await Future.wait(<Future<void>>[
        ensureFeedSnapshotRepository().clearUserSnapshots(userId: userId),
        ensureShortSnapshotRepository().clearUserSnapshots(userId: userId),
      ]);
    }

    final agendaController = maybeFindAgendaController();
    final shortController = maybeFindShortController();
    final recommendedController = maybeFindRecommendedUserListController();

    await Future.wait(<Future<void>>[
      if (agendaController != null) agendaController.refreshAgenda(),
      if (shortController != null) shortController.refreshShorts(),
      if (recommendedController != null) recommendedController.refreshUsers(),
    ]);

    AppSnackbar(
      'Ayarlar uygulandı',
      'Aktif yüzeyler yeniden yüklendi. Başlangıç ayarları ise bir sonraki açılışta etkili olur.',
    );
  }

  Future<bool> _persistOverrides({
    bool showSuccessMessage = true,
  }) async {
    FocusScope.of(context).unfocus();
    if (_isSaving) return false;
    final values = <String, int>{};
    for (final field in _allFields) {
      final raw = _controllers[field.key]?.text.trim() ?? '';
      final parsed = int.tryParse(raw);
      if (parsed == null || parsed < 1) {
        AppSnackbar(
          'Geçersiz değer',
          '${field.title} için 1 veya daha büyük bir sayı gir.',
        );
        return false;
      }
      values[field.key] = parsed;
    }
    setState(() => _isSaving = true);
    try {
      await _overrideService.replaceAll(values);
      if (showSuccessMessage) {
        AppSnackbar(
          'Ayarlar kaydedildi',
          'Bu ayarlar bu cihazda saklandı. Bazı değişiklikler ilgili ekran yeniden açıldığında etkili olur.',
        );
      }
      return true;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<_PolicySection> _buildSections() {
    return <_PolicySection>[
      _PolicySection(
        title: 'Akış',
        description:
            'İlk yükleme ve görünür liste boyutlarını burada ayarlayabilirsin.',
        fields: <_PolicyField>[
          _PolicyField(
            key: SurfacePolicyOverrideKeys.feedHomeInitialLimit,
            title: 'Feed ilk yükleme limiti',
            defaultValue: ReadBudgetRegistry.feedHomeInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.shortHomeInitialLimit,
            title: 'Kısa akış ilk yükleme limiti',
            defaultValue: ReadBudgetRegistry.shortHomeInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.recommendedUsersInitialLimit,
            title: 'Önerilen kullanıcı limiti',
            defaultValue: ReadBudgetRegistry.recommendedUsersInitialLimit,
          ),
        ],
      ),
      _PolicySection(
        title: 'Kişisel Listeler',
        description:
            'Sahip olduğun, çözdüğün ve kaydettiğin içerik yüzeyleri için başlangıç boyutları.',
        fields: <_PolicyField>[
          _PolicyField(
            key: SurfacePolicyOverrideKeys.marketOwnerInitialLimit,
            title: 'Benim ilanlarım limiti',
            defaultValue: ReadBudgetRegistry.marketOwnerInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.jobOwnerInitialLimit,
            title: 'Benim iş ilanlarım limiti',
            defaultValue: ReadBudgetRegistry.jobOwnerInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.testAnsweredInitialLimit,
            title: 'Çözdüğüm testler limiti',
            defaultValue: ReadBudgetRegistry.testAnsweredInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.testFavoritesInitialLimit,
            title: 'Kaydettiğim testler limiti',
            defaultValue: ReadBudgetRegistry.testFavoritesInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.practiceExamAnsweredInitialLimit,
            title: 'Çözdüğüm denemeler limiti',
            defaultValue: ReadBudgetRegistry.practiceExamAnsweredInitialLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.opticalFormAnsweredInitialLimit,
            title: 'Optik sonuçlarım limiti',
            defaultValue: ReadBudgetRegistry.opticalFormAnsweredInitialLimit,
          ),
        ],
      ),
      _PolicySection(
        title: 'Başlangıç',
        description:
            'Splash ve ilk sıcak açılışta kaç belge ve kaç liste ısıtılacağını belirler.',
        fields: <_PolicyField>[
          _PolicyField(
            key: SurfacePolicyOverrideKeys.startupFeedPrefetchDocLimit,
            title: 'Feed başlangıç ön getirme belge limiti',
            defaultValue: ReadBudgetRegistry.startupFeedPrefetchDocLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.startupShortPrefetchDocLimit,
            title: 'Kısa akış başlangıç ön getirme belge limiti',
            defaultValue: ReadBudgetRegistry.startupShortPrefetchDocLimit,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.startupListingWarmLimitOnWiFi,
            title: 'Başlangıç liste ısıtma limiti (Wi‑Fi)',
            defaultValue: ReadBudgetRegistry.startupListingWarmLimit(
              onWiFi: true,
            ),
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.startupListingWarmLimitOnCellular,
            title: 'Başlangıç liste ısıtma limiti (Hücresel)',
            defaultValue: ReadBudgetRegistry.startupListingWarmLimit(
              onWiFi: false,
            ),
          ),
        ],
      ),
      _PolicySection(
        title: 'Oynatma',
        description:
            'Mobil veri tarafındaki video ısıtma ve segment davranışlarını ayarlar.',
        fields: <_PolicyField>[
          _PolicyField(
            key: SurfacePolicyOverrideKeys.mobileWarmWindow,
            title: 'Mobil ısıtma penceresi',
            defaultValue: ReadBudgetRegistry.mobileWarmWindow,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.mobileNextWindow,
            title: 'Mobil sonraki pencere',
            defaultValue: ReadBudgetRegistry.mobileNextWindow,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.minGlobalCachedVideos,
            title: 'Minimum global önbellekli video',
            defaultValue: ReadBudgetRegistry.minGlobalCachedVideos,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.mobileInitialSegments,
            title: 'Mobil ilk segment sayısı',
            defaultValue: ReadBudgetRegistry.mobileInitialSegments,
          ),
          _PolicyField(
            key: SurfacePolicyOverrideKeys.mobileAheadSegments,
            title: 'Mobil ileri segment sayısı',
            defaultValue: ReadBudgetRegistry.mobileAheadSegments,
          ),
        ],
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
            BackButtons(text: 'Akış ve Önbellek Ayarları'),
            Expanded(
              child: !_isReady
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 14),
                        ..._sections.map(_buildSectionCard),
                        const SizedBox(height: 20),
                        _buildActions(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu menü yalnızca bu cihazdaki yerel ayarları değiştirir.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kaydettiğin sayılar merkezi policy omurgasının üstüne yerel override olarak yazılır. Bazı değişiklikler ilgili ekran yeniden açıldığında, bazıları ise bir sonraki başlangıçta etkili olur.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_PolicySection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 16),
            ...section.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PolicyNumberField(
                  title: field.title,
                  defaultValue: field.defaultValue,
                  controller: _controllers[field.key]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _reset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Varsayılanlara Dön',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _reloadNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F1F1),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Şimdi Yeniden Yükle',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyNumberField extends StatelessWidget {
  const _PolicyNumberField({
    required this.title,
    required this.defaultValue,
    required this.controller,
  });

  final String title;
  final int defaultValue;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: defaultValue.toString(),
            helperText: 'Varsayılan: $defaultValue',
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _PolicySection {
  const _PolicySection({
    required this.title,
    required this.description,
    required this.fields,
  });

  final String title;
  final String description;
  final List<_PolicyField> fields;
}

class _PolicyField {
  const _PolicyField({
    required this.key,
    required this.title,
    required this.defaultValue,
  });

  final String key;
  final String title;
  final int defaultValue;
}
