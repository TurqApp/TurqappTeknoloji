import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketMyItemsView extends StatefulWidget {
  const MarketMyItemsView({super.key});

  @override
  State<MarketMyItemsView> createState() => _MarketMyItemsViewState();
}

class _MarketMyItemsViewState extends State<MarketMyItemsView> {
  final MarketRepository _repository = MarketRepository.ensure();
  final MarketShareService _shareService = const MarketShareService();
  late final String uid;
  late Future<List<MarketItemModel>> _itemsFuture;
  String _selectedStatus = 'all';
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
    _itemsFuture = _repository.fetchByOwner(
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

          final allItems = snapshot.data ?? const <MarketItemModel>[];
          final visible = _filterItems(allItems);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reload(force: true));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
              children: [
                _buildStatusTabs(allItems),
                const SizedBox(height: 14),
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

  List<MarketItemModel> _filterItems(List<MarketItemModel> items) {
    if (_selectedStatus == 'all') return items;
    return items.where((item) => item.status == _selectedStatus).toList();
  }

  Widget _buildStatusTabs(List<MarketItemModel> items) {
    final counts = <String, int>{
      'all': items.length,
      'active': items.where((item) => item.status == 'active').length,
      'reserved': items.where((item) => item.status == 'reserved').length,
      'sold': items.where((item) => item.status == 'sold').length,
      'draft': items.where((item) => item.status == 'draft').length,
      'archived': items.where((item) => item.status == 'archived').length,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statusTab('Tüm', 'all', counts['all'] ?? 0),
          _statusTab('Aktif', 'active', counts['active'] ?? 0),
          _statusTab('Rezerve', 'reserved', counts['reserved'] ?? 0),
          _statusTab('Satildi', 'sold', counts['sold'] ?? 0),
          _statusTab('Taslak', 'draft', counts['draft'] ?? 0),
          _statusTab('Arsiv', 'archived', counts['archived'] ?? 0),
        ],
      ),
    );
  }

  Widget _statusTab(String label, String value, int count) {
    final selected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.withAlpha(35),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 12,
            fontFamily: 'MontserratBold',
          ),
        ),
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
              PopupMenuButton<String>(
                onSelected: busy ? null : (value) => _onMenuAction(item, value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Düzenle'),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Text('Paylaş'),
                  ),
                  if (item.status != 'active')
                    const PopupMenuItem(
                      value: 'active',
                      child: Text('Aktif Yap'),
                    ),
                  if (item.status != 'sold')
                    const PopupMenuItem(
                      value: 'sold',
                      child: Text('Satıldı Yap'),
                    ),
                  if (item.status != 'reserved')
                    const PopupMenuItem(
                      value: 'reserved',
                      child: Text('Rezerve Yap'),
                    ),
                  if (item.status != 'archived')
                    const PopupMenuItem(
                      value: 'archived',
                      child: Text('Arşivle'),
                    ),
                ],
                child: busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: Colors.black54,
                        size: 20,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${item.price.toStringAsFixed(0)} ${item.currency}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const Spacer(),
              _statusChip(item.status),
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
      case 'reserved':
        return 'İlan rezerve olarak işaretlendi.';
      case 'archived':
        return 'İlan arşive alındı.';
      default:
        return 'İlan aktif duruma alındı.';
    }
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
        return const Color(0xFF946200);
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
}
