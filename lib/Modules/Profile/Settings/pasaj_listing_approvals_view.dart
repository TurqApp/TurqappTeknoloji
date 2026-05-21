import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Utils/system_navigation_padding.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
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
  final int createdAt;
  final bool isEnded;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
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
