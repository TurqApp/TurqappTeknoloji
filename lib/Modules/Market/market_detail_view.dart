import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_feed_post_share_service.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';

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
  static final MarketRepository _repository = MarketRepository.ensure();
  static final TypesenseMarketSearchService _typesense =
      TypesenseMarketSearchService.instance;
  late final PageController _pageController;
  late MarketItemModel _item;
  int _currentPage = 0;
  bool _isRefreshing = false;
  bool _isUpdatingStatus = false;
  bool _isSaved = false;
  bool _isSaveLoading = false;

  MarketItemModel get item => _item;
  bool get _isOwner {
    final uid = CurrentUserService.instance.userId.trim();
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
    _loadSavedState();
    _refreshItem(silent: true);
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
            IconButton(
              onPressed: _isSaveLoading ? null : _toggleSaved,
              icon: _isSaveLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                      color: Colors.black,
                      size: 22,
                    ),
            ),
          IconButton(
            onPressed: _isRefreshing ? null : _refreshItem,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    CupertinoIcons.refresh,
                    color: Colors.black,
                    size: 20,
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
                        'Bu ilan sana ait. Buradan düzenleyebilir, durumunu güncelleyebilir veya paylaşabilirsin.',
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
              _buildOwnerStatusActions(),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _primaryButton(
                    label: _isOwner ? 'İlanı Düzenle' : 'Mesaj Gönder',
                    onTap: _isOwner
                        ? _openEdit
                        : () => _contactService.openChat(item),
                  ),
                ),
                if (_isOwner || item.canShowPhone) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _secondaryButton(
                      label: _isOwner ? 'İlanı Paylaş' : 'Telefonu Göster',
                      onTap: _isOwner
                          ? () => const MarketShareService().shareItem(item)
                          : () => _contactService.showPhoneSheet(context, item),
                    ),
                  ),
                ],
              ],
            ),
            if (!_isOwner) ...[
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
                      label: 'İlanı Paylaş',
                      onTap: () => const MarketShareService().shareItem(item),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _secondaryButton(
              label: 'Anasayfada Paylaş',
              onTap: () => const MarketFeedPostShareService().shareItem(item),
            ),
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
                _infoRow('Goruntulenme', item.viewCount.toString()),
                _infoRow('Kaydeden', item.favoriteCount.toString()),
                _infoRow('Teklif', item.offerCount.toString()),
              ],
            ),
            if (item.attributes.isNotEmpty) ...[
              const SizedBox(height: 14),
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
                  ? 'Bu ilan icin aciklama eklenmemis.'
                  : item.description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.45,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 18),
            _infoCard(
              title: 'Satıcı',
              children: [
                GestureDetector(
                  onTap: item.userId.trim().isEmpty
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
                            Text(
                              item.sellerName.isEmpty
                                  ? 'Turq Kullanıcı'
                                  : item.sellerName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
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
                      const Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.black38,
                        size: 18,
                      ),
                    ],
                  ),
                ),
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
                      'Bu kategori icin baska ilan bulunamadi.',
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
          ],
        ),
      ),
    );
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
                decoration: _inputDecoration('Teklif Fiyatı'),
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
                      AppSnackbar('Eksik Bilgi', 'Geçerli bir teklif gir.');
                      return;
                    }
                    try {
                      await MarketOfferService.createOffer(
                        item: item,
                        offerPrice: offerPrice,
                        message: noteController.text.trim(),
                      );
                      if (mounted) {
                        setState(() {
                          _item = item.copyWith(
                            offerCount: item.offerCount + 1,
                          );
                        });
                      }
                      if (context.mounted) Navigator.of(context).pop();
                      AppSnackbar('Tamam', 'Teklif gönderildi.');
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
                    'Teklifi Gönder',
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
            width: 86,
            child: Text(
              label,
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
              '${related.price.toStringAsFixed(0)} ${related.currency}',
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

  Widget _buildOwnerStatusActions() {
    final actions = <Map<String, String>>[
      {'key': 'draft', 'label': 'Taslak'},
      {'key': 'active', 'label': 'Aktif'},
      {'key': 'reserved', 'label': 'Rezerve'},
      {'key': 'sold', 'label': 'Satildi'},
      {'key': 'archived', 'label': 'Arsiv'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlan Durumu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratBold',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((action) {
            final statusKey = action['key']!;
            final selected = item.status == statusKey;
            final color = _statusColor(statusKey);
            return GestureDetector(
              onTap: _isUpdatingStatus || selected
                  ? null
                  : () => _updateStatus(statusKey),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? color.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: 0.35)
                        : const Color(0x22000000),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isUpdatingStatus && selected) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      action['label']!,
                      style: TextStyle(
                        color: selected ? color : Colors.black87,
                        fontSize: 12,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
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

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFF946200);
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
      final latest = await _typesense.fetchByDocId(item.id);
      if (latest != null && mounted) {
        setState(() {
          _item = latest;
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

  Future<void> _loadSavedState() async {
    final uid = CurrentUserService.instance.userId.trim();
    if (uid.isEmpty || _isOwner) return;
    try {
      final saved = await MarketSavedStore.isSaved(uid, item.id);
      if (!mounted) return;
      setState(() {
        _isSaved = saved;
      });
    } catch (_) {}
  }

  Future<void> _openEdit() async {
    final result = await Get.to(() => MarketCreateView(initialItem: item));
    if (result == null) return;
    await _refreshItem();
  }

  Future<void> _toggleSaved() async {
    final uid = CurrentUserService.instance.userId.trim();
    if (uid.isEmpty) {
      AppSnackbar('Giris Gerekli', 'Kaydetmek icin giris yapmalisin.');
      return;
    }
    if (_isSaveLoading) return;

    final previousSaved = _isSaved;
    final previousCount = item.favoriteCount;
    final nextSaved = !_isSaved;
    final nextCount =
        nextSaved ? previousCount + 1 : (previousCount - 1).clamp(0, 1 << 30);
    setState(() {
      _isSaveLoading = true;
      _isSaved = nextSaved;
      _item = item.copyWith(favoriteCount: nextCount);
    });

    try {
      if (nextSaved) {
        await MarketSavedStore.save(uid, item.id);
      } else {
        await MarketSavedStore.unsave(uid, item.id);
      }
      AppSnackbar(
        'Tamam',
        nextSaved ? 'Ilan kaydedildi.' : 'Kayit kaldirildi.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaved = previousSaved;
        _item = item.copyWith(favoriteCount: previousCount);
      });
      AppSnackbar('Hata', 'Kaydetme islemi tamamlanamadi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaveLoading = false;
        });
      } else {
        _isSaveLoading = false;
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
    });
    try {
      await _repository.updateItemStatus(
        docId: item.id,
        userId: item.userId,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _item = item.copyWith(status: status);
      });
      AppSnackbar('Tamam', 'Ilan durumu guncellendi.');
      await _refreshItem(silent: true);
    } catch (_) {
      AppSnackbar('Hata', 'Ilan durumu guncellenemedi.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      } else {
        _isUpdatingStatus = false;
      }
    }
  }
}
