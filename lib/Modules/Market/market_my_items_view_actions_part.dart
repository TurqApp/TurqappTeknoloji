part of 'market_my_items_view.dart';

extension MarketMyItemsViewActionsPart on _MarketMyItemsViewState {
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
                    _updateViewState(() => _reload(force: true));
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
                          title: 'common.edit'.tr,
                          icon: CupertinoIcons.pencil,
                        ),
                        PullDownMenuItem(
                          onTap: () => _onMenuAction(item, 'share'),
                          title: 'common.share'.tr,
                          icon: CupertinoIcons.share,
                        ),
                        if (item.status != 'active')
                          PullDownMenuItem(
                            onTap: () => _onMenuAction(item, 'active'),
                            title: 'pasaj.market.status.active'.tr,
                            icon: CupertinoIcons.check_mark_circled,
                          ),
                        if (item.status != 'sold')
                          PullDownMenuItem(
                            onTap: () => _onMenuAction(item, 'sold'),
                            title: 'pasaj.market.status.sold'.tr,
                            icon: CupertinoIcons.check_mark,
                          ),
                      ],
                      buttonBuilder: (context, showMenu) =>
                          AppHeaderActionButton(
                        onTap: showMenu,
                        size: 36,
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
                '${_formatMoney(item.price)} ${marketCurrencyLabel(item.currency)}',
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
        _updateViewState(() => _reload(force: true));
      }
      return;
    }
    if (action == 'share') {
      await _shareService.shareItem(item);
      return;
    }

    _updateViewState(() {
      _busyIds.add(item.id);
    });
    try {
      await _repository.updateItemStatus(
        docId: item.id,
        userId: uid,
        status: action,
      );
      if (!mounted) return;
      _updateViewState(() {
        _busyIds.remove(item.id);
        _reload(force: true);
      });
      AppSnackbar('common.success'.tr, _actionSuccessText(action));
    } catch (_) {
      if (!mounted) return;
      _updateViewState(() {
        _busyIds.remove(item.id);
      });
      AppSnackbar(
        'common.error'.tr,
        'pasaj.market.status_update_failed'.tr,
      );
    }
  }

  String _actionSuccessText(String action) {
    switch (action) {
      case 'sold':
        return 'pasaj.market.marked_sold'.tr;
      default:
        return 'pasaj.market.marked_active'.tr;
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
        return 'pasaj.market.status.sold'.tr;
      case 'reserved':
        return 'pasaj.market.status.reserved'.tr;
      case 'draft':
        return 'pasaj.market.status.draft'.tr;
      case 'archived':
        return 'pasaj.market.status.archived'.tr;
      default:
        return 'pasaj.market.status.active'.tr;
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
