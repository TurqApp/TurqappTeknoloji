import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';

class MarketDetailView extends StatelessWidget {
  const MarketDetailView({
    super.key,
    required this.item,
  });

  final MarketItemModel item;
  static const MarketContactService _contactService = MarketContactService();

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
          'Ilan Detayi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
        children: [
          AspectRatio(
            aspectRatio: 1.18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: item.coverImageUrl.isNotEmpty
                  ? Image.network(
                      item.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${item.price.toStringAsFixed(0)} ${item.currency}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.locationText}  •  ${item.categoryLabel}',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  label: 'Mesaj Gonder',
                  onTap: () => _contactService.openChat(item),
                ),
              ),
              if (item.canShowPhone) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _secondaryButton(
                    label: 'Telefonu Goster',
                    onTap: () => _contactService.showPhoneSheet(context, item),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: 'Teklif Ver',
                  onTap: () => _showOfferSheet(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondaryButton(
                  label: 'Ilani Paylas',
                  onTap: () => const MarketShareService().shareItem(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _secondaryButton(
            label: 'Anasayfada Paylas',
            onTap: () => const MarketFeedPostShareService().shareItem(item),
          ),
          const SizedBox(height: 18),
          const Text(
            'Aciklama',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description.isEmpty
                ? 'Ilan aciklamasi bu adimda baglanacak.'
                : item.description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.45,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF6F7FB),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Satici',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.sellerName.isEmpty ? 'Turq Kullanici' : item.sellerName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOfferSheet(BuildContext context) async {
    final priceController = TextEditingController(
      text: item.price > 0 ? item.price.toStringAsFixed(0) : '',
    );
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            15,
            18,
            15,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teklif Ver',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Teklif Fiyati'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 5,
                decoration: _inputDecoration('Not (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final offerPrice = double.tryParse(
                      priceController.text.trim().replaceAll(',', '.'),
                    );
                    if (offerPrice == null || offerPrice <= 0) {
                      AppSnackbar('Eksik Bilgi', 'Gecerli bir teklif gir.');
                      return;
                    }
                    try {
                      await MarketOfferService.createOffer(
                        item: item,
                        offerPrice: offerPrice,
                        message: noteController.text.trim(),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                      AppSnackbar('Tamam', 'Teklif gonderildi.');
                    } catch (e) {
                      final message =
                          e.toString().contains('own_item_offer_not_allowed')
                              ? 'Kendi ilanina teklif veremezsin.'
                              : 'Teklif gonderilemedi.';
                      AppSnackbar('Hata', message);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Teklifi Gonder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: Colors.black45,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x22000000)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.black45,
        fontSize: 13,
        fontFamily: 'MontserratMedium',
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }
}
