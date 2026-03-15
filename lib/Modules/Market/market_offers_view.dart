import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketOffersView extends StatelessWidget {
  MarketOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
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
          title: const Text(
            'Tekliflerim',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'MontserratBold',
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Verdigim'),
              Tab(text: 'Aldigim'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOfferFuture(
              future: MarketOfferService.fetchSentOffers(uid),
              subtitle: 'Verdigim teklif',
            ),
            _buildOfferFuture(
              future: MarketOfferService.fetchReceivedOffers(uid),
              subtitle: 'Aldigim teklif',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferFuture({
    required Future<List<MarketOfferModel>> future,
    required String subtitle,
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
              '$subtitle bulunamadi.',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(15),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.itemTitle,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${offer.offerPrice.toStringAsFixed(0)} ${offer.currency}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                      const Spacer(),
                      _statusChip(_statusLabel(offer.status)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'cancelled':
        return 'Iptal Edildi';
      default:
        return 'Bekliyor';
    }
  }

  Widget _statusChip(String status) {
    final bool accepted = status == 'Kabul Edildi';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFEEF7EE) : const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: accepted ? const Color(0xFF267A2F) : const Color(0xFF946200),
          fontSize: 11,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
