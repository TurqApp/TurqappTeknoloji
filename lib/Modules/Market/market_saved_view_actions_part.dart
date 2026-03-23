part of 'market_saved_view.dart';

extension MarketSavedViewActionsPart on _MarketSavedViewState {
  Widget _buildItemCard(MarketItemModel item) {
    final busy = _busyIds.contains(item.id);
    return GestureDetector(
      onTap: () async {
        await Get.to(() => MarketDetailView(item: item));
        if (!mounted) return;
        _updateViewState(() => _reload(force: true));
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
                    '${_formatMoney(item.price)} ${marketCurrencyLabel(item.currency)}',
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
    _updateViewState(() {
      _busyIds.add(item.id);
    });
    try {
      await MarketSavedStore.unsave(uid, item.id);
      if (!mounted) return;
      _updateViewState(() {
        _busyIds.remove(item.id);
        _reload(force: true);
      });
      AppSnackbar('common.success'.tr, 'pasaj.market.removed_saved'.tr);
    } catch (_) {
      if (!mounted) return;
      _updateViewState(() {
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
