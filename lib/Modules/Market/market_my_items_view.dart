import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketMyItemsView extends StatelessWidget {
  MarketMyItemsView({super.key});

  final MarketRepository _repository = MarketRepository.ensure();

  @override
  Widget build(BuildContext context) {
    final uid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
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
          'Ilanlarim',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _repository.fetchByOwner(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <MarketItemModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Henuz bir ilanin yok.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildItemCard(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(MarketItemModel item) {
    return GestureDetector(
      onTap: () => Get.to(() => MarketDetailView(item: item)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14000000)),
        ),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${item.price.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const Spacer(),
                _statusChip(item.status == 'sold' ? 'Satildi' : 'Aktif'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF267A2F),
          fontSize: 11,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
