import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Core/rozet_content.dart';

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
  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
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

  @override
  Widget build(BuildContext context) {
    final galleryImages = _galleryImages;
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
          'İlan Detayı',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
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
                    title: 'İlanı Bildir',
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
            const Text(
              'Açıklama',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description.isEmpty
                  ? 'Bu ilan için açıklama eklenmemiş.'
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
                title: 'Özellikler',
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
              title: 'İlan Bilgileri',
              children: [
                _infoRow('Kategori', item.categoryPath.join(' > ')),
                _infoRow('Durum', _statusLabel(item.status)),
                _infoRow(
                  'İletişim',
                  item.canShowPhone ? 'Telefon + Mesaj' : 'Sadece Mesaj',
                ),
                _infoRow('Görüntülenme', item.viewCount.toString()),
                _infoRow('Kaydeden', item.favoriteCount.toString()),
                _infoRow('Teklif', item.offerCount.toString()),
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
                                          ? 'Turq Kullanıcı'
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
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Colors.black54,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu ilan sana ait. Buradan duzenleyebilir veya paylasabilirsin.',
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
                      label: 'Düzenle',
                      onTap: _openEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _secondaryButton(
                      label: 'Mesajlar',
                      onTap: () => Get.to(() => ChatListing()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _secondaryButton(
                      label: 'Teklifler',
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
                      label: 'Mesaj',
                      onTap: () => _contactService.openChat(item),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _secondaryButton(
                      label: 'Teklif Ver',
                      onTap: () => _showOfferSheet(context),
                    ),
                  ),
                  if (item.canShowPhone) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _secondaryButton(
                        label: 'Ara',
                        onTap: () =>
                            _contactService.showPhoneSheet(context, item),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 18),
            const Text(
              'Benzer İlanlar',
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
                    child: const Text(
                      'Bu kategori için başka ilan bulunamadı.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 224,
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

  Future<void> _showReportSheet() async {
    if (_isSubmittingReport) return;
    final selections = await _reportRepository.fetchSelections();
    final selected = await showCupertinoModalPopup<ReportModel>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('İlanı Bildir'),
        message: const Text('Lütfen bir neden seç.'),
        actions: selections
            .map(
              (selection) => CupertinoActionSheetAction(
                onPressed: () => Navigator.of(sheetContext).pop(selection),
                child: Text(selection.title),
              ),
            )
            .toList(growable: false),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          isDefaultAction: true,
          child: const Text('Vazgeç'),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _submitReport(selected);
  }

  Future<void> _submitReport(ReportModel selection) async {
    if (_isSubmittingReport) return;
    setState(() {
      _isSubmittingReport = true;
    });
    try {
      await _reportRepository.submitReport(
        targetUserId: item.userId,
        postId: item.id,
        commentId: '',
        selection: selection,
        targetType: 'market',
      );
      if (!mounted) return;
      AppSnackbar(
        'Talebiniz Bize Ulaştı!',
        'İlan inceleme altına alındı. Teşekkür ederiz.',
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar('Hata', 'İlan bildirimi gönderilemedi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReport = false;
        });
      }
    }
  }

  Widget _buildGallery(List<String> images) {
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
          if (!mounted) return;
          setState(() {
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

  Widget _buildGalleryIndicator(int count) {
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

  Future<void> _showOfferSheet(BuildContext context) async {
    final double basePrice = item.price <= 0 ? 0.0 : item.price;
    final suggestionRates = <double>[0.90, 0.80, 0.70];
    final List<double> suggestions = suggestionRates
        .map((rate) => _normalizeOfferPrice(basePrice * rate))
        .where((value) => value > 0)
        .toSet()
        .toList()
      ..sort();
    double? selectedOffer =
        suggestions.length > 1 ? suggestions[1] : suggestions.firstOrNull;
    bool customMode = false;
    final customController = TextEditingController(
      text: selectedOffer == null ? '' : _plainOfferText(selectedOffer),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submitOffer() async {
              final rawText = customController.text.trim().replaceAll('.', '');
              final offerPrice = customMode
                  ? double.tryParse(rawText.replaceAll(',', '.'))
                  : selectedOffer;
              if (offerPrice == null || offerPrice <= 0) {
                AppSnackbar('Eksik Bilgi', 'Geçerli bir teklif seç.');
                return;
              }
              try {
                await MarketOfferService.createOffer(
                  item: item,
                  offerPrice: offerPrice,
                  message: '',
                );
                if (mounted) {
                  setState(() {
                    _item = item.copyWith(
                      offerCount: item.offerCount + 1,
                    );
                  });
                }
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                AppSnackbar('Tamam', 'Teklif gönderildi.');
              } catch (e) {
                final message =
                    e.toString().contains('own_item_offer_not_allowed')
                        ? 'Kendi ilanına teklif veremezsin.'
                        : e.toString().contains('daily_offer_limit_reached')
                        ? 'Bir günde en fazla 20 teklif yapabilirsin.'
                        : 'Teklif gönderilemedi.';
                AppSnackbar('Hata', message);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Teklif Ver',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontFamily: 'MontserratMedium',
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formattedMoney(selectedOffer ?? basePrice)} ${_currencyLabel(item.currency)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: suggestions.map((offer) {
                      final selected = !customMode && selectedOffer == offer;
                      final discount = basePrice > 0
                          ? ((1 - (offer / basePrice)) * 100).round()
                          : 0;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: offer == suggestions.last ? 0 : 10,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                customMode = false;
                                selectedOffer = offer;
                                customController.text = _plainOfferText(offer);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.black
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.black
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_formattedMoney(offer)} ${_currencyLabel(item.currency)}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 17,
                                      fontFamily: 'MontserratBold',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '%$discount indirim',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black45,
                                      fontSize: 11,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  if (customMode) ...[
                    TextField(
                      controller: customController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('Teklifini Kendin Belirle'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: submitOffer,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Teklif Ver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        customMode = true;
                        if (selectedOffer != null &&
                            customController.text.trim().isEmpty) {
                          customController.text =
                              _plainOfferText(selectedOffer!);
                        }
                      });
                    },
                    child: const Text(
                      'Teklifini Kendin Belirle',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    final canReview = !_isOwner;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final existingReview = _reviews
        .where((review) => review.userId == currentUserId)
        .cast<MarketReviewModel?>()
        .firstOrNull;
    final totalReviews = _reviews.length;
    final ratingCounts = <int, int>{
      for (var star = 1; star <= 5; star++) star: 0,
    };
    for (final review in _reviews) {
      final rating = review.rating.clamp(1, 5);
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Değerlendirmeler',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ),
            if (canReview)
              GestureDetector(
                onTap: () => _showReviewSheet(existingReview: existingReview),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    existingReview == null ? 'Değerlendir' : 'Düzenle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingReviews)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CupertinoActivityIndicator(),
          )
        else if (_reviews.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.star_border_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Henüz değerlendirme yok.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = ratingCounts[star] ?? 0;
                final percent = totalReviews == 0 ? 0.0 : count / totalReviews;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$star',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '%${(percent * 100).round()}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          ..._reviews.map(_buildReviewCard),
        ],
      ],
    );
  }

  Widget _buildReviewCard(MarketReviewModel review) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final user = _reviewUsers[review.userId] ?? const <String, dynamic>{};
    final name = (user['nickname'] ??
            user['username'] ??
            user['displayName'] ??
            user['fullName'] ??
            '')
        .toString()
        .trim();
    final avatarUrl = (user['avatarUrl'] ?? '').toString().trim();
    final rozet = (user['rozet'] ?? '').toString().trim();
    final isOwn = currentUserId == review.userId;
    final shouldHide = name.isEmpty && avatarUrl.isEmpty && review.comment.isEmpty;
    if (shouldHide) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      name.isEmpty ? 'Kullanici' : name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    if (rozet.isNotEmpty)
                      RozetContent(
                        size: 12,
                        userID: review.userId,
                        rozetValue: rozet,
                        leftSpacing: 1,
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
              if (isOwn) ...[
                GestureDetector(
                  onTap: () => _showReviewSheet(existingReview: review),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _deleteReview(review.reviewId),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final reviews = await _reviewService.fetchReviews(item.id);
      final userIds = reviews.map((e) => e.userId).toSet().toList(growable: false);
      final summaries = userIds.isEmpty
          ? const <String, dynamic>{}
          : await _userRepository.getUsers(userIds);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _reviewUsers = {
          for (final entry in summaries.entries) entry.key: entry.value.toMap(),
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = const <MarketReviewModel>[];
        _reviewUsers = const <String, Map<String, dynamic>>{};
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _showReviewSheet({MarketReviewModel? existingReview}) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      AppSnackbar('Bilgi', 'Değerlendirme yapmak için giriş yapmalısın.');
      return;
    }
    final selectedRating = ValueNotifier<int>(existingReview?.rating ?? 5);
    final commentController = TextEditingController();
    commentController.text = existingReview?.comment ?? '';
    final isSubmitting = ValueNotifier<bool>(false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: isSubmitting,
            builder: (context, submitting, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Değerlendir',
                    style: TextStyle(
                      fontFamily: 'MontserratBold',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: selectedRating,
                      builder: (context, rating, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => selectedRating.value = index + 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  size: 28,
                                  color: index < rating
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: _inputDecoration('Yorumunuzu yazın'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (selectedRating.value == 0) {
                                AppSnackbar('Hata', 'Lütfen bir puan seçin.');
                                return;
                              }
                              isSubmitting.value = true;
                              try {
                                await _reviewService.submitReview(
                                  itemId: item.id,
                                  ownerId: item.userId,
                                  rating: selectedRating.value,
                                  comment: commentController.text.trim(),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                                await _loadReviews();
                                AppSnackbar(
                                  'Başarılı',
                                  existingReview == null
                                      ? 'Değerlendirmeniz kaydedildi.'
                                      : 'Değerlendirmeniz güncellendi.',
                                );
                              } catch (e) {
                                final message = e.toString().contains(
                                      'own_item_review_not_allowed',
                                    )
                                    ? 'Kendi ilanını değerlendiremezsin.'
                                    : 'Değerlendirme gönderilemedi.';
                                AppSnackbar('Hata', message);
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                          ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontFamily: 'MontserratBold',
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await _reviewService.deleteReview(itemId: item.id, reviewId: reviewId);
      await _loadReviews();
      AppSnackbar('Başarılı', 'Değerlendirmeniz kaldırıldı.');
    } catch (_) {
      AppSnackbar('Hata', 'Değerlendirme kaldırılamadı.');
    }
  }

  double _normalizeOfferPrice(double value) {
    if (value <= 0) return 0;
    if (value < 100) return value.roundToDouble();
    if (value < 1000) return ((value / 10).round() * 10).toDouble();
    return ((value / 50).round() * 50).toDouble();
  }

  String _plainOfferText(double value) {
    return value.toStringAsFixed(0);
  }

  String _formattedMoney(double value) {
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

  String _currencyLabel(String currency) {
    return currency.toUpperCase() == 'TRY' ? 'TL' : currency;
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

  Widget _infoCard({
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

  Widget _infoRow(String label, String value) {
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

  Widget _primaryButton({
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

  Widget _relatedCard(MarketItemModel related) {
    return GestureDetector(
      onTap: () async {
        await Get.to(() => MarketDetailView(item: related));
        await _refreshItem(silent: true);
      },
      child: SizedBox(
        width: 164,
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
                  ? 'Konum belirtilmedi'
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

  Widget _secondaryButton({
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

  String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'Satildi';
      case 'draft':
        return 'Taslak';
      case 'archived':
        return 'Arsiv';
      case 'reserved':
        return 'Rezerve';
      default:
        return 'Aktif';
    }
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

  Future<void> _refreshItem({bool silent = false}) async {
    if (_isRefreshing) return;
    if (!silent && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      _isRefreshing = true;
    }
    try {
      final latest = await _repository.fetchById(
        item.id,
        preferCache: false,
        forceRefresh: true,
      );
      if (latest != null && mounted) {
        final preserved = _preserveProtectedFields(
          latest,
          _item,
        );
        setState(() {
          _item = preserved;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      } else {
        _isRefreshing = false;
      }
    }
  }

  MarketItemModel _preserveProtectedFields(
    MarketItemModel remote,
    MarketItemModel local,
  ) {
    final shouldKeepPhone =
        !remote.canShowPhone &&
        local.canShowPhone &&
        local.sellerPhoneNumber.trim().isNotEmpty;

    if (!shouldKeepPhone) return remote;

    return remote.copyWith(
      showPhone: true,
      contactPreference: 'phone',
      sellerPhoneNumber: local.sellerPhoneNumber,
    );
  }

  Future<void> _incrementViewCount() async {
    final currentUid = CurrentUserService.instance.userId.trim();
    if (currentUid.isNotEmpty && currentUid == item.userId) return;
    try {
      await _repository.incrementViewCount(
        docId: item.id,
        userId: item.userId,
      );
      if (!mounted) return;
      setState(() {
        _item = item.copyWith(viewCount: item.viewCount + 1);
      });
    } catch (_) {}
  }

  Future<void> _openEdit() async {
    final result = await Get.to(() => MarketCreateView(initialItem: item));
    if (result == null) return;
    await _refreshItem();
  }

}
