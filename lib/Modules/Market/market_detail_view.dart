import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/market_review_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/education_share_icon_button.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_review_model.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Core/rozet_content.dart';

part 'market_detail_view_actions_part.dart';
part 'market_detail_view_reviews_part.dart';
part 'market_detail_view_ui_part.dart';

class MarketDetailView extends StatefulWidget {
  const MarketDetailView({
    super.key,
    required this.item,
  });

  final MarketItemModel item;

  @override
  State<MarketDetailView> createState() => _MarketDetailViewState();
}

class _MarketDetailViewState extends State<MarketDetailView> {
  static const MarketContactService _contactService = MarketContactService();
  static const MarketReviewService _reviewService = MarketReviewService();
  static final MarketRepository _repository = MarketRepository.ensure();
  static final ReportRepository _reportRepository = ReportRepository.ensure();
  static final UserRepository _userRepository = UserRepository.ensure();
  static final TypesenseMarketSearchService _typesense =
      TypesenseMarketSearchService.instance;
  late final PageController _pageController;
  late MarketItemModel _item;
  int _currentPage = 0;
  bool _isRefreshing = false;
  bool _isLoadingReviews = false;
  bool _isSubmittingReport = false;
  List<MarketReviewModel> _reviews = const <MarketReviewModel>[];
  Map<String, Map<String, dynamic>> _reviewUsers =
      const <String, Map<String, dynamic>>{};

  MarketItemModel get item => _item;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;
  bool get _isOwner {
    final uid = _currentUserId.trim();
    return uid.isNotEmpty && uid == item.userId;
  }

  List<String> get _galleryImages {
    final images = <String>[];
    final cover = item.coverImageUrl.trim();
    if (cover.isNotEmpty) images.add(cover);
    for (final image in item.imageUrls) {
      final clean = image.trim();
      if (clean.isEmpty || images.contains(clean)) continue;
      images.add(clean);
    }
    return images;
  }

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _pageController = PageController();
    _incrementViewCount();
    _refreshItem(silent: true);
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateViewState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.market.detail_title'.tr),
        actions: [
          if (!_isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: EducationShareIconButton(
                onTap: () => const MarketShareService().shareItem(item),
                size: 36,
                iconSize: 20,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: EducationFeedShareIconButton(
              onTap: () => const MarketFeedPostShareService().shareItem(item),
              size: 36,
              iconSize: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PullDownButton(
              itemBuilder: (context) => [
                if (!_isOwner)
                  PullDownMenuItem(
                    onTap: _showReportSheet,
                    title: 'pasaj.market.report_listing'.tr,
                    icon: CupertinoIcons.exclamationmark_circle,
                  ),
              ],
              buttonBuilder: (context, showMenu) => AppHeaderActionButton(
                onTap: showMenu,
                child: Icon(
                  AppIcons.ellipsisVertical,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshItem,
        child: ListView(
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
              style: TextStyle(
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
                _infoRow('pasaj.market.saved_count'.tr,
                    item.favoriteCount.toString()),
                _infoRow(
                    'pasaj.market.offer_count'.tr, item.offerCount.toString()),
              ],
            ),
            const SizedBox(height: 18),
            Container(
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
                        : () =>
                            Get.to(() => SocialProfile(userID: item.userId)),
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
            ),
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
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Colors.black54,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'pasaj.market.owner_hint'.tr,
                        style: TextStyle(
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
            if (_isOwner)
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _secondaryButton(
                      label: 'pasaj.market.offers'.tr,
                      onTap: () => Get.to(() => const MarketOffersView()),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _primaryButton(
                      label: 'common.message'.tr,
                      onTap: () => _contactService.openChat(item),
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
                        onTap: () =>
                            _contactService.showPhoneSheet(context, item),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 18),
            Text(
              'pasaj.market.related_listings'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<MarketItemModel>>(
              future: _typesense.searchItems(
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
                              candidate.categoryPath.first ==
                                  item.categoryPath.first),
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
                      style: TextStyle(
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
                    itemBuilder: (context, index) =>
                        _relatedCard(related[index]),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const AdmobKare(
              key: ValueKey('market-detail-ad-end'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportSheet() => _performShowReportSheet();

  Future<void> _submitReport(ReportModel selection) =>
      _performSubmitReport(selection);

  Widget _buildGallery(List<String> images) => _performBuildGallery(images);

  Widget _buildGalleryIndicator(int count) =>
      _performBuildGalleryIndicator(count);

  Future<void> _showOfferSheet(BuildContext context) =>
      _performShowOfferSheet(context);

  Widget _buildReviewsSection() => _performBuildReviewsSection();

  Widget _buildReviewCard(MarketReviewModel review) =>
      _performBuildReviewCard(review);

  Future<void> _loadReviews() => _performLoadReviews();

  Future<void> _showReviewSheet({MarketReviewModel? existingReview}) =>
      _performShowReviewSheet(existingReview: existingReview);

  Future<void> _deleteReview(String reviewId) => _performDeleteReview(reviewId);

  double _normalizeOfferPrice(double value) =>
      _performNormalizeOfferPrice(value);

  String _plainOfferText(double value) => _performPlainOfferText(value);

  String _formattedMoney(double value) => _performFormattedMoney(value);

  String _currencyLabel(String currency) => _performCurrencyLabel(currency);

  Widget _imageFallback() => _performImageFallback();

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) =>
      _performInfoCard(title: title, children: children);

  Widget _infoRow(String label, String value) => _performInfoRow(label, value);

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
  }) =>
      _performPrimaryButton(label: label, onTap: onTap);

  Widget _relatedCard(MarketItemModel related) => _performRelatedCard(related);

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) =>
      _performSecondaryButton(label: label, onTap: onTap);

  String _statusLabel(String status) => _performStatusLabel(status);

  InputDecoration _inputDecoration(String hint) =>
      _performInputDecoration(hint);

  Future<void> _refreshItem({bool silent = false}) =>
      _performRefreshItem(silent: silent);

  MarketItemModel _preserveProtectedFields(
    MarketItemModel remote,
    MarketItemModel local,
  ) =>
      _performPreserveProtectedFields(remote, local);

  Future<void> _incrementViewCount() => _performIncrementViewCount();

  Future<void> _openEdit() => _performOpenEdit();
}
