import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class MarketSavedView extends StatefulWidget {
  const MarketSavedView({super.key});

  @override
  State<MarketSavedView> createState() => _MarketSavedViewState();
}

class _MarketSavedViewState extends State<MarketSavedView> {
  final MarketRepository _repository = MarketRepository.ensure();
  late final String uid;
  late Future<List<MarketItemModel>> _savedFuture;
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
    _savedFuture = _repository.fetchSaved(
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
        title: Text(
          'pasaj.market.saved_items'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _savedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <MarketItemModel>[];
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reload(force: true));
            },
            child: items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: 140),
                      Center(
                        child: Text(
                          'pasaj.market.saved_empty'.tr,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildItemCard(items[index]),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(MarketItemModel item) {
    final busy = _busyIds.contains(item.id);
    return GestureDetector(
      onTap: () async {
        await Get.to(() => MarketDetailView(item: item));
        if (!mounted) return;
        setState(() => _reload(force: true));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 65,
                height: 65,
                color: const Color(0xFFF3F4F6),
                child: item.coverImageUrl.trim().isNotEmpty
                    ? Image.network(
                        item.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          AppIcons.save,
                          color: Colors.orange,
                        ),
                      )
                    : Icon(
                        AppIcons.save,
                        color: Colors.orange,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.locationText.isEmpty
                        ? 'pasaj.market.location_missing'.tr
                        : item.locationText,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatMoney(item.price)} ${item.currency.toUpperCase() == 'TRY' ? 'TL' : item.currency}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: busy ? null : () => _unsave(item),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                      : Icon(
                          AppIcons.saved,
                          color: Colors.orange,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unsave(MarketItemModel item) async {
    setState(() {
      _busyIds.add(item.id);
    });
    try {
      await MarketSavedStore.unsave(uid, item.id);
      if (!mounted) return;
      setState(() {
        _busyIds.remove(item.id);
        _reload(force: true);
      });
      AppSnackbar('common.success'.tr, 'pasaj.market.removed_saved'.tr);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busyIds.remove(item.id);
      });
      AppSnackbar('common.error'.tr, 'pasaj.market.unsave_failed'.tr);
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
