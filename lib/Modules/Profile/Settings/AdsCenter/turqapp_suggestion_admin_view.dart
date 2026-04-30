import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/turqapp_suggestion_config_service.dart';
import 'package:turqappv2/Core/Slider/slider_admin_view.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';

class TurqAppSuggestionAdminView extends StatefulWidget {
  const TurqAppSuggestionAdminView({super.key});

  @override
  State<TurqAppSuggestionAdminView> createState() =>
      _TurqAppSuggestionAdminViewState();
}

class _TurqAppSuggestionAdminViewState
    extends State<TurqAppSuggestionAdminView> {
  final TurqAppSuggestionConfigService _service =
      TurqAppSuggestionConfigService.instance;
  final Map<String, TextEditingController> _headlineControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _bodyControllers =
      <String, TextEditingController>{};
  final Set<String> _dirtyPlacements = <String>{};
  final Set<String> _savingPlacements = <String>{};
  final Set<String> _removingPlacements = <String>{};
  final Map<String, ManagedAdInventoryItem> _inventoryById =
      <String, ManagedAdInventoryItem>{};

  bool _loading = true;
  String? _errorText;
  ManagedAdInventoryOverview? _inventoryOverview;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    for (final controller in _headlineControllers.values) {
      controller.dispose();
    }
    for (final controller in _bodyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final configs = await _service.loadAll(forceRefresh: forceRefresh);
      for (final placement in TurqAppSuggestionPlacements.entries) {
        final config = configs[placement.id] ??
            TurqAppSuggestionConfig.defaultsFor(placement);
        _ensureControllers(config);
      }
      final overview = await _service.getManagedInventoryOverview(
          forceRefresh: forceRefresh);
      _inventoryOverview = overview;
      _inventoryById
        ..clear()
        ..addEntries(
          overview.items.map(
            (item) => MapEntry<String, ManagedAdInventoryItem>(
              item.placement.id,
              item,
            ),
          ),
        );
      _errorText = null;
    } catch (error) {
      _errorText = '$error';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _ensureControllers(TurqAppSuggestionConfig config) {
    final id = config.placementId;
    final headlineController = _headlineControllers.putIfAbsent(id, () {
      final controller = TextEditingController(text: config.headline);
      controller.addListener(() {
        _dirtyPlacements.add(id);
      });
      return controller;
    });
    final bodyController = _bodyControllers.putIfAbsent(id, () {
      final controller = TextEditingController(text: config.body);
      controller.addListener(() {
        _dirtyPlacements.add(id);
      });
      return controller;
    });

    if (!_dirtyPlacements.contains(id) &&
        headlineController.text != config.headline) {
      headlineController.text = config.headline;
    }
    if (!_dirtyPlacements.contains(id) && bodyController.text != config.body) {
      bodyController.text = config.body;
    }
  }

  Future<void> _refreshManagedInventory() async {
    final overview =
        await _service.getManagedInventoryOverview(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _inventoryOverview = overview;
      _inventoryById
        ..clear()
        ..addEntries(
          overview.items.map(
            (item) => MapEntry<String, ManagedAdInventoryItem>(
              item.placement.id,
              item,
            ),
          ),
        );
    });
  }

  Future<void> _savePlacement(TurqAppSuggestionPlacement placement) async {
    final headline = _headlineControllers[placement.id]?.text.trim() ?? '';
    final body = _bodyControllers[placement.id]?.text.trim() ?? '';
    final config = TurqAppSuggestionConfig(
      placementId: placement.id,
      title: placement.title,
      sliderId: placement.sliderId,
      headline: headline.isEmpty
          ? TurqAppSuggestionConfig.headlineForPlacement(placement)
          : headline,
      body: body.isEmpty
          ? TurqAppSuggestionConfig.bodyForPlacement(placement)
          : body,
    );

    setState(() {
      _savingPlacements.add(placement.id);
    });
    try {
      await _service.saveConfig(config);
      _dirtyPlacements.remove(placement.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${placement.title} ayarları kaydedildi'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${placement.title} kaydı başarısız: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPlacements.remove(placement.id);
        });
      }
    }
  }

  Future<void> _openSliderAdmin(ManagedAdPlacement placement) async {
    await Get.to(
      () => SliderAdminView(
        sliderId: placement.sliderId,
        title: placement.title,
      ),
    );
    await _refreshManagedInventory();
  }

  Future<void> _confirmRemoveSlider(ManagedAdPlacement placement) async {
    if (_removingPlacements.contains(placement.id)) {
      return;
    }
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('${placement.title} sliderını kaldır'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Yüklenen görseller kaldırılacak. Slot, tekrar random TurqApp Önerisi yapısına döner.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kaldır'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await _removeSlider(placement);
  }

  Future<void> _removeSlider(ManagedAdPlacement placement) async {
    setState(() {
      _removingPlacements.add(placement.id);
    });
    try {
      await _service.removeManagedSlider(placement);
      await _refreshManagedInventory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${placement.title} sliderı kaldırıldı'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${placement.title} kaldırılamadı: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _removingPlacements.remove(placement.id);
        });
      }
    }
  }

  Widget _buildStatusChip(ManagedAdInventoryItem item) {
    final sliderLoaded = item.hasManagedAd;
    final backgroundColor =
        sliderLoaded ? const Color(0xFFE7F7ED) : const Color(0xFFF5F5F5);
    final textColor =
        sliderLoaded ? const Color(0xFF177245) : const Color(0xFF525252);
    final text = sliderLoaded
        ? 'Yönetilen reklam aktif'
        : item.placement.supportsFallbackText
            ? 'Slider boşsa TurqApp Önerisi çalışır'
            : 'Slider boşsa mevcut ekran yapısı çalışır';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }

  Widget _buildManagedOverviewCard(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
        ],
      ),
    );
  }

  ManagedAdInventoryItem _inventoryForPlacement(
    TurqAppSuggestionPlacement placement,
  ) {
    return _inventoryById[placement.id] ??
        ManagedAdInventoryItem(
          placement: ManagedAdPlacements.byId(placement.id)!,
          sliderSummary: const SliderRuntimeSummary(
            totalItems: 0,
            activeItems: 0,
            scheduledItems: 0,
            expiredItems: 0,
            viewCount: 0,
            uniqueViewCount: 0,
          ),
          config: TurqAppSuggestionConfig.defaultsFor(placement),
        );
  }

  Widget _buildPlacementCard(TurqAppSuggestionPlacement placement) {
    final headlineController = _headlineControllers[placement.id]!;
    final bodyController = _bodyControllers[placement.id]!;
    final saving = _savingPlacements.contains(placement.id);
    final inventoryItem = _inventoryForPlacement(placement);
    final removing = _removingPlacements.contains(placement.id);
    final hasSliderItems = inventoryItem.sliderSummary.totalItems > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
                      placement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      placement.surfaceSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(inventoryItem),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: headlineController,
            decoration: const InputDecoration(
              labelText: 'Başlık metni',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Açıklama metni',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSliderAdmin(inventoryItem.placement),
                  icon: const Icon(CupertinoIcons.photo_on_rectangle),
                  label: Text(
                    hasSliderItems ? 'Slider Yönet' : 'Slider Yükle',
                  ),
                ),
              ),
              if (hasSliderItems) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: removing
                        ? null
                        : () => _confirmRemoveSlider(inventoryItem.placement),
                    icon: removing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(CupertinoIcons.trash),
                    label: const Text('Kaldır'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : () => _savePlacement(placement),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(CupertinoIcons.check_mark),
              label: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagedInventoryCard(ManagedAdInventoryItem item) {
    final placement = item.placement;
    final summary = item.sliderSummary;
    final kindText = placement.kind == ManagedAdPlacementKind.suggestionSlot
        ? 'Ana başlık alanı'
        : 'Üst slider alanı';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
                      placement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      placement.surfaceSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kindText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(item),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slider kimliği: ${placement.sliderId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aktif ${summary.activeItems} · Planlı ${summary.scheduledItems} · Süresi biten ${summary.expiredItems}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Görüntülenme ${summary.viewCount} · Kişi ${summary.uniqueViewCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    if (placement.supportsFallbackText &&
                        item.config != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Fallback başlık: ${item.config!.headline}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontFamily: 'MontserratMedium',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openSliderAdmin(placement),
                icon: const Icon(CupertinoIcons.photo_on_rectangle),
                label: Text(
                  item.hasManagedAd ? 'Slider Yönet' : 'Slider Yükle',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final overview = _inventoryOverview;
    if (_loading) {
      return const AppStateView.loading();
    }
    if (_errorText != null && _errorText!.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 32, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => unawaited(_bootstrap(forceRefresh: true)),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _bootstrap(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Yönetilen reklam alanları',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ana başlık slotları ve ekran üstü slider alanları tek merkezden yönetilir.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 18),
          if (overview != null) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildManagedOverviewCard(
                  'Toplam alan',
                  '${overview.totalPlacements}',
                ),
                _buildManagedOverviewCard(
                  'Aktif alan',
                  '${overview.activePlacementCount}',
                ),
                _buildManagedOverviewCard(
                  'Fallback alan',
                  '${overview.fallbackPlacementCount}',
                ),
                _buildManagedOverviewCard(
                  'Görüntülenme',
                  '${overview.viewCount}',
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          for (final placement in ManagedAdPlacements.entries)
            if (_inventoryById[placement.id] != null)
              _buildManagedInventoryCard(_inventoryById[placement.id]!),
          const SizedBox(height: 10),
          const Text(
            'TurqApp Önerisi',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sadece ana başlık slotlarında, slider boş kaldığında gösterilecek başlık ve açıklama metinlerini aşağıdan değiştirirsiniz.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 18),
          for (final placement in TurqAppSuggestionPlacements.entries)
            _buildPlacementCard(placement),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildBody();
}
