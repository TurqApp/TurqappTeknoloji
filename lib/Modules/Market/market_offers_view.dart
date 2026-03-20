import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketOffersView extends StatefulWidget {
  const MarketOffersView({super.key});

  @override
  State<MarketOffersView> createState() => _MarketOffersViewState();
}

class _MarketOffersViewState extends State<MarketOffersView> {
  final MarketRepository _repository = MarketRepository.ensure();
  late final String uid;
  late Future<List<MarketOfferModel>> sentFuture;
  late Future<List<MarketOfferModel>> receivedFuture;
  final Set<String> _processingIds = <String>{};

  @override
  void initState() {
    super.initState();
    uid = (FirebaseAuth.instance.currentUser?.uid ?? '').isNotEmpty
        ? (FirebaseAuth.instance.currentUser?.uid ?? '')
        : CurrentUserService.instance.userId;
    _reload();
  }

  void _reload() {
    sentFuture = MarketOfferService.fetchSentOffers(uid);
    receivedFuture = MarketOfferService.fetchReceivedOffers(uid);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            'pasaj.market.offers_title'.tr,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'MontserratBold',
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'pasaj.market.sent_tab'.tr),
              Tab(text: 'pasaj.market.received_tab'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOfferFuture(
              future: sentFuture,
              subtitle: 'pasaj.market.sent_offer'.tr,
              showActions: false,
            ),
            _buildOfferFuture(
              future: receivedFuture,
              subtitle: 'pasaj.market.received_offer'.tr,
              showActions: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferFuture({
    required Future<List<MarketOfferModel>> future,
    required String subtitle,
    required bool showActions,
  }) {
    return FutureBuilder<List<MarketOfferModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final offers = snapshot.data ?? const <MarketOfferModel>[];
        if (offers.isEmpty) {
          return Center(
            child: Text(
              'pasaj.market.offer_empty'.trParams({
                'subtitle': subtitle.toLowerCase(),
              }),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final processing = _processingIds.contains(offer.id);
              return GestureDetector(
                onTap: () => _openOfferItem(offer),
                child: Container(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFF3F4F6),
                              child: offer.coverImageUrl.trim().isNotEmpty
                                  ? Image.network(
                                      offer.coverImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.black45,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.black45,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.itemTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                                if (offer.locationText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    offer.locationText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (offer.message.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          offer.message.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_formatMoney(offer.offerPrice)} ${offer.currency.toUpperCase() == 'TRY' ? 'TL' : offer.currency}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _statusChip(_statusLabel(offer.status)),
                        ],
                      ),
                      if (showActions &&
                          normalizeMarketOfferStatus(offer.status) ==
                              kMarketOfferStatusPending) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: processing
                                      ? null
                                      : () => _respondToOffer(
                                            offer: offer,
                                            status: kMarketOfferStatusRejected,
                                          ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.withAlpha(120),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: processing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'pasaj.job_finder.reject'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontFamily: 'MontserratBold',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: processing
                                      ? null
                                      : () => _respondToOffer(
                                            offer: offer,
                                            status: kMarketOfferStatusAccepted,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'pasaj.job_finder.accept'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _respondToOffer({
    required MarketOfferModel offer,
    required String status,
  }) async {
    setState(() {
      _processingIds.add(offer.id);
    });
    try {
      await MarketOfferService.respondToOffer(offer: offer, status: status);
      if (!mounted) return;
      setState(() {
        _processingIds.remove(offer.id);
        _reload();
      });
      AppSnackbar(
        'common.info'.tr,
        status == kMarketOfferStatusAccepted
            ? 'pasaj.market.offer_accepted'.tr
            : 'pasaj.market.offer_rejected'.tr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingIds.remove(offer.id);
      });
      final text = e.toString().contains('offer_already_processed')
          ? 'pasaj.market.offer_already_processed'.tr
          : 'pasaj.market.offer_update_failed'.tr;
      AppSnackbar('common.error'.tr, text);
    }
  }

  String _statusLabel(String status) {
    switch (normalizeMarketOfferStatus(status)) {
      case kMarketOfferStatusAccepted:
        return 'pasaj.market.status.accepted'.tr;
      case kMarketOfferStatusRejected:
        return 'pasaj.market.status.rejected'.tr;
      case kMarketOfferStatusCancelled:
        return 'pasaj.market.status.cancelled'.tr;
      default:
        return 'pasaj.market.status.pending'.tr;
    }
  }

  Widget _statusChip(String status) {
    final normalizedStatus = normalizeMarketOfferStatus(status);
    final bool accepted = normalizedStatus == kMarketOfferStatusAccepted;
    final bool rejected = normalizedStatus == kMarketOfferStatusRejected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accepted
            ? const Color(0xFFEEF7EE)
            : rejected
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: accepted
              ? const Color(0xFF267A2F)
              : rejected
                  ? const Color(0xFFB42318)
                  : const Color(0xFF946200),
          fontSize: 11,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Future<void> _openOfferItem(MarketOfferModel offer) async {
    final item = await _repository.fetchById(
      offer.itemId,
      forceRefresh: true,
    );
    if (item == null) {
      AppSnackbar('common.error'.tr, 'pasaj.market.listing_unavailable'.tr);
      return;
    }
    await Get.to(() => MarketDetailView(item: item));
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
