import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/system_navigation_padding.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

class PasajListingApprovalsView extends StatefulWidget {
  const PasajListingApprovalsView({super.key});

  @override
  State<PasajListingApprovalsView> createState() =>
      _PasajListingApprovalsViewState();
}

class _PasajListingApprovalsViewState extends State<PasajListingApprovalsView> {
  late Future<List<_PendingPasajListing>> _future;
  late final Future<bool> _canAccessFuture;

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canManageSliders();
    _future = _load();
  }

  Future<List<_PendingPasajListing>> _load() async {
    final firestore = AppFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('marketStore')
          .where('status', isEqualTo: 'pending_review')
          .limit(80)
          .get(),
      firestore
          .collection('isBul')
          .where('onayVerildi', isEqualTo: false)
          .limit(80)
          .get(),
      firestore
          .collection('educators')
          .where('onayVerildi', isEqualTo: false)
          .limit(80)
          .get(),
    ]);

    final items = <_PendingPasajListing>[
      ...results[0].docs.map((doc) => _PendingPasajListing.market(doc)),
      ...results[1].docs.map((doc) => _PendingPasajListing.job(doc)),
      ...results[2].docs.map((doc) => _PendingPasajListing.tutoring(doc)),
    ]..removeWhere((item) => item.isEnded);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _review(_PendingPasajListing item, String action) async {
    try {
      await AppCloudFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('reviewPasajListing')
          .call({
        'listingType': item.type,
        'docId': item.docId,
        'action': action,
      });
      AppSnackbar(
        'Pasaj onayı',
        action == 'approve' ? 'İlan onaylandı.' : 'İlan reddedildi.',
      );
      _refresh();
    } catch (e) {
      AppSnackbar('common.error'.tr, 'İşlem tamamlanamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BackButtons(text: 'Pasaj İlan Onayları'),
            Expanded(
              child: FutureBuilder<bool>(
                future: _canAccessFuture,
                builder: (context, accessSnap) {
                  if (accessSnap.connectionState == ConnectionState.waiting) {
                    return const AppStateView.loading();
                  }
                  if (accessSnap.data != true) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'admin.no_access'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return FutureBuilder<List<_PendingPasajListing>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const AppStateView.loading();
                      }
                      final items = snap.data ?? const <_PendingPasajListing>[];
                      if (items.isEmpty) {
                        return const AppStateView.empty(
                          title: 'Bekleyen Pasaj ilanı yok.',
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            15,
                            8,
                            15,
                            androidNavigationAwareBottom(context, spacing: 24),
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PendingListingCard(
                                item: item,
                                onApprove: () => _review(item, 'approve'),
                                onReject: () => _review(item, 'reject'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPasajListing {
  const _PendingPasajListing({
    required this.type,
    required this.docId,
    required this.title,
    required this.subtitle,
    required this.owner,
    required this.rozet,
    required this.imageUrl,
    required this.description,
    required this.location,
    required this.price,
    required this.details,
    required this.createdAt,
    required this.isEnded,
  });

  factory _PendingPasajListing.market(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final seller = data['seller'] is Map
        ? Map<String, dynamic>.from(data['seller'] as Map)
        : const <String, dynamic>{};
    return _PendingPasajListing(
      type: 'market',
      docId: doc.id,
      title: (data['title'] ?? '').toString(),
      subtitle: 'Market',
      owner: (data['sellerNickname'] ?? data['userId'] ?? '').toString(),
      rozet: (data['sellerRozet'] ?? seller['rozet'] ?? '').toString(),
      imageUrl: _firstString(data['coverImageUrl'], data['imageUrls']),
      description: (data['description'] ?? '').toString(),
      location: _joinNonEmpty([
        (data['city'] ?? '').toString(),
        (data['district'] ?? '').toString(),
      ]),
      price: _formatPrice(data['price'], (data['currency'] ?? '').toString()),
      details: [
        _InfoLine('Kategori', _joinStringList(data['categoryPath'])),
        _InfoLine('Durum', (data['status'] ?? '').toString()),
      ],
      createdAt: _asInt(data['createdAt'] ?? data['updatedAt']),
      isEnded: (data['status'] ?? '').toString() == 'archived',
    );
  }

  factory _PendingPasajListing.job(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _PendingPasajListing(
      type: 'job',
      docId: doc.id,
      title: (data['ilanBasligi'] ?? data['meslek'] ?? '').toString(),
      subtitle: 'İş Bul',
      owner: (data['nickname'] ?? data['userID'] ?? '').toString(),
      rozet: (data['rozet'] ?? '').toString(),
      imageUrl: (data['logo'] ?? data['avatarUrl'] ?? '').toString(),
      description: (data['isTanimi'] ?? data['about'] ?? '').toString(),
      location: _joinNonEmpty([
        (data['city'] ?? '').toString(),
        (data['town'] ?? '').toString(),
      ]),
      price: _jobSalary(data),
      details: [
        _InfoLine('Firma', (data['brand'] ?? '').toString()),
        _InfoLine('Meslek', (data['meslek'] ?? '').toString()),
        _InfoLine('Çalışma', _joinStringList(data['calismaTuru'])),
      ],
      createdAt: _asInt(data['timeStamp']),
      isEnded: data['ended'] == true,
    );
  }

  factory _PendingPasajListing.tutoring(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _PendingPasajListing(
      type: 'tutoring',
      docId: doc.id,
      title: (data['baslik'] ?? data['brans'] ?? '').toString(),
      subtitle: 'Özel Ders',
      owner: (data['nickname'] ?? data['userID'] ?? '').toString(),
      rozet: (data['rozet'] ?? '').toString(),
      imageUrl: _firstString(data['avatarUrl'], data['imgs']),
      description: (data['aciklama'] ?? '').toString(),
      location: _joinNonEmpty([
        (data['sehir'] ?? '').toString(),
        (data['ilce'] ?? '').toString(),
      ]),
      price: _formatPrice(data['fiyat'], 'TRY'),
      details: [
        _InfoLine('Branş', (data['brans'] ?? '').toString()),
        _InfoLine('Ders yeri', _joinStringList(data['dersYeri'])),
        _InfoLine('Cinsiyet', (data['cinsiyet'] ?? '').toString()),
        _InfoLine('Uygunluk', _availabilitySummary(data['availability'])),
      ],
      createdAt: _asInt(data['timeStamp']),
      isEnded: data['ended'] == true,
    );
  }

  final String type;
  final String docId;
  final String title;
  final String subtitle;
  final String owner;
  final String rozet;
  final String imageUrl;
  final String description;
  final String location;
  final String price;
  final List<_InfoLine> details;
  final int createdAt;
  final bool isEnded;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  static String _firstString(dynamic primary, dynamic fallbackList) {
    final primaryValue = (primary ?? '').toString().trim();
    if (primaryValue.isNotEmpty) return primaryValue;
    if (fallbackList is List && fallbackList.isNotEmpty) {
      return (fallbackList.first ?? '').toString().trim();
    }
    return '';
  }

  static String _joinNonEmpty(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' / ');
  }

  static String _joinStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => (entry ?? '').toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', ');
    }
    return (value ?? '').toString().trim();
  }

  static String _formatPrice(dynamic value, String currency) {
    final amount =
        value is num ? value : num.tryParse((value ?? '').toString());
    if (amount == null || amount <= 0) return '';
    final rounded = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final remaining = rounded.length - i;
      buffer.write(rounded[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    final normalizedCurrency = currency.trim().toUpperCase();
    final suffix = normalizedCurrency == 'TRY' ? 'TL' : normalizedCurrency;
    return suffix.isEmpty ? buffer.toString() : '${buffer.toString()} $suffix';
  }

  static String _jobSalary(Map<String, dynamic> data) {
    final min = data['maas1'];
    final max = data['maas2'];
    final first = _formatPrice(min, 'TRY');
    final second = _formatPrice(max, 'TRY');
    if (first.isEmpty && second.isEmpty) return '';
    if (first.isEmpty) return second;
    if (second.isEmpty || second == first) return first;
    return '$first - $second';
  }

  static String _availabilitySummary(dynamic value) {
    if (value is! Map) return '';
    final parts = <String>[];
    value.forEach((day, slots) {
      final slotText = _joinStringList(slots);
      if (slotText.isNotEmpty) parts.add('${day.toString()}: $slotText');
    });
    return parts.join(' | ');
  }
}

class _InfoLine {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;
}

class _PendingListingCard extends StatelessWidget {
  const _PendingListingCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final _PendingPasajListing item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title.trim().isEmpty ? item.docId : item.title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                  ),
                ),
              ),
              _Chip(text: item.subtitle),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '@${item.owner.isEmpty ? '-' : item.owner} - rozet: ${item.rozet.isEmpty ? 'yok' : item.rozet}',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ListingPreviewImage(imageUrl: item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.price.isNotEmpty) _DetailText(item.price),
                    if (item.location.isNotEmpty) _DetailText(item.location),
                    ...item.details
                        .where((detail) => detail.value.trim().isNotEmpty)
                        .map(
                          (detail) => _DetailText(
                            '${detail.label}: ${detail.value}',
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 12,
                height: 1.35,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Onayla'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('Reddet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingPreviewImage extends StatelessWidget {
  const _ListingPreviewImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 78,
        height: 78,
        color: const Color(0xFFF3F4F6),
        child: imageUrl.trim().isEmpty
            ? const Icon(Icons.image_outlined, color: Colors.black38)
            : CacheFirstNetworkImage(
                imageUrl: imageUrl.trim(),
                cacheManager: TurqImageCacheManager.instance,
                fallback: const Icon(
                  Icons.image_outlined,
                  color: Colors.black38,
                ),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'MontserratMedium',
          fontSize: 12,
          height: 1.25,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 11,
        ),
      ),
    );
  }
}
