part of 'market_detail_view.dart';

extension _MarketDetailViewUiPart on _MarketDetailViewState {
  Widget _performBuildGallery(List<String> images) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.18,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _imageFallback(),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.82,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (value) {
          _updateViewState(() {
            _currentPage = value;
          });
        },
        itemBuilder: (context, index) {
          final image = images[index];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          );
        },
      ),
    );
  }

  Widget _performBuildGalleryIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.black : Colors.black26,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  double _performNormalizeOfferPrice(double value) {
    if (value <= 0) return 0;
    if (value < 100) return value.roundToDouble();
    if (value < 1000) return ((value / 10).round() * 10).toDouble();
    return ((value / 50).round() * 50).toDouble();
  }

  String _performPlainOfferText(double value) {
    return value.toStringAsFixed(0);
  }

  String _performFormattedMoney(double value) {
    final text = value.toStringAsFixed(0);
    final chars = text.split('');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      final remaining = chars.length - i;
      buffer.write(chars[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _performCurrencyLabel(String currency) {
    return marketCurrencyLabel(currency);
  }

  Widget _performImageFallback() {
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

  Widget _performInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: Column(
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _performInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _performPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  Widget _performRelatedCard(MarketItemModel related) {
    return GestureDetector(
      onTap: () async {
        await Get.to(() => MarketDetailView(item: related));
        await _refreshItem(silent: true);
      },
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1,
                child: related.coverImageUrl.isNotEmpty
                    ? Image.network(
                        related.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      )
                    : _imageFallback(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              related.title,
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
              '${related.price.toStringAsFixed(0)} ${_currencyLabel(related.currency)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              related.locationText.isEmpty
                  ? 'pasaj.market.location_missing'.tr
                  : related.locationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _performSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x22000000)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  String _performStatusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'pasaj.market.status.sold'.tr;
      case 'draft':
        return 'pasaj.market.status.draft'.tr;
      case 'archived':
        return 'pasaj.market.status.archived'.tr;
      case 'reserved':
        return 'pasaj.market.status.reserved'.tr;
      default:
        return 'pasaj.market.status.active'.tr;
    }
  }

  InputDecoration _performInputDecoration(String hint) {
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
