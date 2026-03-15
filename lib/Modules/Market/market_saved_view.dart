import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketSavedView extends StatelessWidget {
  MarketSavedView({super.key});

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
          'Kaydettiklerim',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: FutureBuilder<List<MarketItemModel>>(
        future: _repository.fetchSaved(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <MarketItemModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Kaydedilmis ilan bulunamadi.',
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
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => Get.to(() => MarketDetailView(item: item)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF3F4F6),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.bookmark_outline),
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
                              item.locationText,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.price.toStringAsFixed(0)} TL',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
