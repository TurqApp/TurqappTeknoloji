import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class MarketMyItemsView extends StatefulWidget {
  const MarketMyItemsView({super.key});

  @override
  State<MarketMyItemsView> createState() => _MarketMyItemsViewState();
}

class _MarketMyItemsViewState extends State<MarketMyItemsView> {
  final MarketRepository _repository = MarketRepository.ensure();
  final TypesenseMarketSearchService _typesense =
      TypesenseMarketSearchService.instance;
  final MarketShareService _shareService = const MarketShareService();
  late final String uid;
  late Future<List<MarketItemModel>> _itemsFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    uid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    _reload();
  }

  void _reload({bool force = false}) {
    _itemsFuture = _typesense.fetchByUserId(
      uid,
      preferCache: !force,
      forceRefresh: force,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: const Text(
          'İlanlarım',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible =
              (snapshot.data ?? const <MarketItemModel>[]).toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reload(force: true));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
              children: [
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'Bu durumda ilan bulunamadi.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  )
                else
                  ...visible.map(_buildItemCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(MarketItemModel item) {
    final busy = _busyIds.contains(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Get.to(() => MarketDetailView(item: item));
                    if (!mounted) return;
                    setState(() => _reload(force: true));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.locationText}  •  ${item.categoryLabel}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              busy
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : PullDownButton(
                      itemBuilder: (context) => [
                        PullDownMenuItem(
                          onTap: () => _onMenuAction(item, 'edit'),
                          title: 'Düzenle',
                          icon: CupertinoIcons.pencil,
                        ),
                        PullDownMenuItem(
                          onTap: () => _onMenuAction(item, 'share'),
                          title: 'Paylaş',
                          icon: CupertinoIcons.share,
                        ),
                        if (item.status != 'active')
                          PullDownMenuItem(
                            onTap: () => _onMenuAction(item, 'active'),
                            title: 'Aktif Yap',
                            icon: CupertinoIcons.check_mark_circled,
                          ),
                        if (item.status != 'sold')
                          PullDownMenuItem(
                            onTap: () => _onMenuAction(item, 'sold'),
                            title: 'Satıldı Yap',
                            icon: CupertinoIcons.check_mark,
                          ),
                      ],
                      buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                        onTap: showMenu,
                        child: Icon(
                          AppIcons.ellipsisVertical,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_formatMoney(item.price)} ${item.currency.toUpperCase() == 'TRY' ? 'TL' : item.currency}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
                ),
              ),
              if (_shouldShowStatusChip(item.status)) ...[
                const Spacer(),
                _statusChip(item.status),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenuAction(MarketItemModel item, String action) async {
    if (action == 'edit') {
      final result = await Get.to(() => MarketCreateView(initialItem: item));
      if (result != null && mounted) {
        setState(() => _reload(force: true));
      }
      return;
    }
    if (action == 'share') {
      await _shareService.shareItem(item);
      return;
    }

    setState(() {
      _busyIds.add(item.id);
    });
    try {
      await _repository.updateItemStatus(
        docId: item.id,
        userId: uid,
        status: action,
      );
      if (!mounted) return;
      setState(() {
        _busyIds.remove(item.id);
        _reload(force: true);
      });
      AppSnackbar('Tamam', _actionSuccessText(action));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyIds.remove(item.id);
      });
      AppSnackbar('Hata', 'İlan durumu güncellenemedi.');
    }
  }

  String _actionSuccessText(String action) {
    switch (action) {
      case 'sold':
        return 'İlan satıldı olarak işaretlendi.';
      default:
        return 'İlan aktif duruma alındı.';
    }
  }

  bool _shouldShowStatusChip(String status) {
    return status == 'active' || status == 'sold';
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'Satıldı';
      case 'reserved':
        return 'Rezerve';
      case 'draft':
        return 'Taslak';
      case 'archived':
        return 'Arşiv';
      default:
        return 'Aktif';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFB91C1C);
      case 'reserved':
        return const Color(0xFF1D4ED8);
      case 'draft':
        return const Color(0xFF6D28D9);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF267A2F);
    }
  }

  String _formatMoney(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
