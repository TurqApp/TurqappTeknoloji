part of 'market_detail_view.dart';

extension MarketDetailViewContentPart on _MarketDetailViewState {
  Widget _buildMarketDetailContent(
    BuildContext context,
    List<String> galleryImages,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
      children: [
        _buildGallery(galleryImages),
        if (galleryImages.length > 1) ...[
          const SizedBox(height: 10),
          _buildGalleryIndicator(galleryImages.length),
        ],
        const SizedBox(height: 14),
        Text(
          '${_formattedMoney(item.price)} ${_currencyLabel(item.currency)}',
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
        Text(
          'common.description'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.description.isEmpty
              ? 'pasaj.market.no_description'.tr
              : item.description,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.45,
            fontFamily: 'MontserratMedium',
          ),
        ),
        const SizedBox(height: 18),
        if (item.attributes.isNotEmpty) ...[
          const SizedBox(height: 18),
          _infoCard(
            title: 'common.features'.tr,
            children: item.attributes.entries
                .map(
                  (entry) => _infoRow(
                    entry.key,
                    entry.value.toString().trim().isEmpty
                        ? '-'
                        : entry.value.toString(),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 18),
        _infoCard(
          title: 'pasaj.market.listing_info'.tr,
          children: [
            _infoRow('common.category'.tr, item.categoryPath.join(' > ')),
            _infoRow('common.status'.tr, _statusLabel(item.status)),
            _infoRow(
              'common.contact'.tr,
              item.canShowPhone
                  ? 'pasaj.market.phone_and_message'.tr
                  : 'pasaj.market.message_only'.tr,
            ),
            _infoRow('common.views'.tr, item.viewCount.toString()),
            _infoRow(
              'pasaj.market.saved_count'.tr,
              item.favoriteCount.toString(),
            ),
            _infoRow(
              'pasaj.market.offer_count'.tr,
              item.offerCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSellerSection(),
        const SizedBox(height: 18),
        if (_isOwner) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Colors.black54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'pasaj.market.owner_hint'.tr,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildActionRow(context),
        const SizedBox(height: 18),
        Text(
          'pasaj.market.related_listings'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 10),
        _buildRelatedSection(),
        const SizedBox(height: 12),
        const AdmobKare(
          key: ValueKey('market-detail-ad-end'),
          suggestionPlacementId: 'market',
        ),
      ],
    );
  }

  Widget _buildSellerSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isOwner || item.userId.trim().isEmpty
                ? null
                : () => Get.to(() => SocialProfile(userID: item.userId)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE5E7EB),
                  backgroundImage: item.sellerPhotoUrl.trim().isNotEmpty
                      ? NetworkImage(item.sellerPhotoUrl)
                      : null,
                  child: item.sellerPhotoUrl.trim().isEmpty
                      ? const Icon(
                          CupertinoIcons.person_fill,
                          color: Colors.black54,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.sellerName.isEmpty
                                  ? 'pasaj.market.default_seller'.tr
                                  : item.sellerName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                          if (item.sellerRozet.trim().isNotEmpty)
                            RozetContent(
                              size: 14,
                              userID: item.userId,
                              rozetValue: item.sellerRozet,
                              leftSpacing: 1,
                            ),
                        ],
                      ),
                      if (item.sellerUsername.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@${item.sellerUsername}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isOwner)
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.black38,
                    size: 18,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          _buildReviewsSection(),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    if (_isOwner) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  label: 'common.edit'.tr,
                  onTap: _openEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondaryButton(
                  label: 'pasaj.market.messages'.tr,
                  onTap: () => Get.to(() => ChatListing()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _secondaryButton(
                  label: 'pasaj.market.offers'.tr,
                  onTap: () => Get.to(() => const MarketOffersView()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: item.status == 'archived'
                    ? const SizedBox.shrink()
                    : _dangerButton(
                        label: 'common.remove'.tr,
                        onTap: () {
                          noYesAlert(
                            title: 'pasaj.job_finder.unpublish_title'.tr,
                            message: 'pasaj.job_finder.unpublish_body'.tr,
                            yesText: 'common.remove'.tr,
                            cancelText: 'common.cancel'.tr,
                            onYesPressed: _archiveItem,
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _primaryButton(
            label: 'common.message'.tr,
            onTap: () => _MarketDetailViewState._contactService.openChat(item),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _secondaryButton(
            label: 'pasaj.market.offer_count'.tr,
            onTap: () => _showOfferSheet(context),
          ),
        ),
        if (item.canShowPhone) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _secondaryButton(
              label: 'common.phone'.tr,
              onTap: () => _MarketDetailViewState._contactService
                  .showPhoneSheet(context, item),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRelatedSection() {
    return FutureBuilder<List<MarketItemModel>>(
      future: _MarketDetailViewState._typesense.searchItems(
        query: '*',
        limit: 30,
        categoryKey: item.categoryKey,
        preferCache: true,
      ),
      builder: (context, snapshot) {
        final related = (snapshot.data ?? const <MarketItemModel>[])
            .where((candidate) => candidate.id != item.id)
            .where(
              (candidate) =>
                  candidate.categoryKey == item.categoryKey ||
                  (candidate.categoryPath.isNotEmpty &&
                      item.categoryPath.isNotEmpty &&
                      candidate.categoryPath.first == item.categoryPath.first),
            )
            .take(8)
            .toList(growable: false);

        if (snapshot.connectionState == ConnectionState.waiting &&
            related.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (related.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF6F7FB),
            ),
            child: Text(
              'pasaj.market.no_related'.tr,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
          );
        }

        return SizedBox(
          height: 242,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _relatedCard(related[index]),
          ),
        );
      },
    );
  }
}
