import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/market_review_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
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
part 'market_detail_view_shell_part.dart';
part 'market_detail_view_shell_content_part.dart';
part 'market_detail_view_content_part.dart';

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
  static final MarketRepository _repository = ensureMarketRepository();
  static final ReportRepository _reportRepository = ensureReportRepository();
  static final UserRepository _userRepository = UserRepository.ensure();
  static final TypesenseMarketSearchService _typesense =
      TypesenseMarketSearchService.instance;
  late final PageController _pageController;
  late MarketItemModel _item;
  int _currentPage = 0;
  bool _isRefreshing = false;
  bool _isLoadingReviews = false;
  bool _isSubmittingReport = false;
  bool _isUpdatingStatus = false;
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
    return _buildMarketDetailScaffold(context, galleryImages);
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

  Widget _dangerButton({
    required String label,
    required VoidCallback onTap,
  }) =>
      _performDangerButton(label: label, onTap: onTap);

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

  Future<void> _archiveItem() => _performArchiveItem();

  Future<void> _incrementViewCount() => _performIncrementViewCount();

  Future<void> _openEdit() => _performOpenEdit();
}
