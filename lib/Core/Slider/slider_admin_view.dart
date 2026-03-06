import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class SliderAdminView extends StatefulWidget {
  const SliderAdminView({
    super.key,
    required this.sliderId,
    required this.title,
  });

  final String sliderId;
  final String title;

  @override
  State<SliderAdminView> createState() => _SliderAdminViewState();
}

class _SliderAdminViewState extends State<SliderAdminView> {
  bool _isBusy = false;

  DocumentReference<Map<String, dynamic>> get _sliderMeta =>
      FirebaseFirestore.instance.collection('sliders').doc(widget.sliderId);

  CollectionReference<Map<String, dynamic>> get _sliderItems =>
      _sliderMeta.collection('items');

  List<String> get _defaults => SliderCatalog.defaultImagesFor(widget.sliderId);

  Future<void> _ensureSliderMeta() {
    return _sliderMeta.set({
      'title': widget.title,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> _addSlide() async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    setState(() => _isBusy = true);
    try {
      await _ensureSliderMeta();
      final existing = await _sliderItems.orderBy('order').get();
      final nextOrder = existing.docs.isEmpty
          ? _defaults.length
          : ((existing.docs.last.data()['order'] as num?)?.toInt() ??
                  (_defaults.length - 1)) +
              1;
      final itemId = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'slider/${widget.sliderId}/$itemId';
      final imageUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: storagePath,
      );

      await _sliderItems.doc(itemId).set({
        'imageUrl': imageUrl,
        'storagePath': '$storagePath.webp',
        'order': nextOrder,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      });
      AppSnackbar('Tamam', 'Slider görseli eklendi');
    } catch (e) {
      AppSnackbar('Hata', 'Slider görseli eklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _replaceSlide({
    required int index,
    QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    setState(() => _isBusy = true);
    try {
      final itemId =
          remoteDoc?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final oldStoragePath = remoteDoc == null
          ? ''
          : (remoteDoc.data()['storagePath'] ?? '').toString();
      final storagePath = 'slider/${widget.sliderId}/$itemId';
      final imageUrl = await WebpUploadService.uploadFileAsWebp(
        storage: FirebaseStorage.instance,
        file: file,
        storagePathWithoutExt: storagePath,
      );

      await _ensureSliderMeta();
      await _sliderMeta.set({
        'hiddenDefaults': FieldValue.arrayRemove([index]),
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      await _sliderItems.doc(itemId).set({
        'imageUrl': imageUrl,
        'storagePath': '$storagePath.webp',
        'order': index,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      if (oldStoragePath.isNotEmpty && oldStoragePath != '$storagePath.webp') {
        await FirebaseStorage.instance.ref().child(oldStoragePath).delete();
      }
      AppSnackbar('Tamam', 'Slider görseli güncellendi');
    } catch (e) {
      AppSnackbar('Hata', 'Slider görseli güncellenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _hideOrDeleteSlide({
    required int index,
    required bool hasDefault,
    QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) async {
    setState(() => _isBusy = true);
    try {
      if (remoteDoc != null) {
        final storagePath = (remoteDoc.data()['storagePath'] ?? '').toString();
        await remoteDoc.reference.delete();
        if (storagePath.isNotEmpty) {
          await FirebaseStorage.instance.ref().child(storagePath).delete();
        }
      }

      if (hasDefault) {
        await _ensureSliderMeta();
        await _sliderMeta.set({
          'hiddenDefaults': FieldValue.arrayUnion([index]),
          'updatedDate': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      await _normalizeExtraOrder();
      AppSnackbar('Tamam', hasDefault ? 'Görsel kaldırıldı' : 'Görsel silindi');
    } catch (e) {
      AppSnackbar('Hata', 'Slider görseli kaldırılamadı: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _restoreDefault(int index) async {
    setState(() => _isBusy = true);
    try {
      await _ensureSliderMeta();
      await _sliderMeta.set({
        'hiddenDefaults': FieldValue.arrayRemove([index]),
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppSnackbar('Tamam', 'Varsayılan görsel geri açıldı');
    } catch (e) {
      AppSnackbar('Hata', 'Varsayılan görsel açılamadı: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _moveRemoteSlide({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required int order,
    required int direction,
  }) async {
    final currentIndex = docs.indexWhere(
      (doc) => ((doc.data()['order'] as num?)?.toInt() ?? -1) == order,
    );
    if (currentIndex == -1) return;

    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= docs.length) return;

    setState(() => _isBusy = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentDoc = docs[currentIndex];
      final targetDoc = docs[targetIndex];
      final currentOrder =
          (currentDoc.data()['order'] as num?)?.toInt() ?? currentIndex;
      final targetOrder =
          (targetDoc.data()['order'] as num?)?.toInt() ?? targetIndex;

      batch.update(currentDoc.reference, {
        'order': targetOrder,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      });
      batch.update(targetDoc.reference, {
        'order': currentOrder,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      });
      await batch.commit();
    } catch (e) {
      AppSnackbar('Hata', 'Sıralama güncellenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _normalizeExtraOrder() async {
    final snapshot = await _sliderItems.orderBy('order').get();
    final extras = snapshot.docs
        .where(
          (doc) =>
              ((doc.data()['order'] as num?)?.toInt() ?? 0) >= _defaults.length,
        )
        .toList();
    if (extras.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < extras.length; i++) {
      batch.update(extras[i].reference, {'order': _defaults.length + i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(text: '${widget.title} Slider'),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _sliderMeta.snapshots(),
                    builder: (context, metaSnapshot) {
                      final hiddenDefaults =
                          ((metaSnapshot.data?.data()?['hiddenDefaults']
                                      as List<dynamic>?) ??
                                  const <dynamic>[])
                              .map((e) => e is num ? e.toInt() : -1)
                              .where((e) => e >= 0)
                              .toSet();

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _sliderItems.orderBy('order').snapshots(),
                        builder: (context, itemSnapshot) {
                          if (itemSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !itemSnapshot.hasData) {
                            return const Center(
                              child: CupertinoActivityIndicator(),
                            );
                          }

                          final remoteDocs =
                              itemSnapshot.data?.docs ?? const [];
                          final remoteByOrder = <int,
                              QueryDocumentSnapshot<Map<String, dynamic>>>{};
                          for (final doc in remoteDocs) {
                            remoteByOrder[
                                (doc.data()['order'] as num?)?.toInt() ??
                                    0] = doc;
                          }

                          final maxOrder = remoteDocs.isEmpty
                              ? _defaults.length
                              : remoteDocs
                                      .map((doc) =>
                                          (doc.data()['order'] as num?)
                                              ?.toInt() ??
                                          0)
                                      .reduce((a, b) => a > b ? a : b) +
                                  1;
                          final itemCount = maxOrder > _defaults.length
                              ? maxOrder
                              : _defaults.length;

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 120),
                            itemCount: itemCount,
                            separatorBuilder: (_, __) => 12.ph,
                            itemBuilder: (context, index) {
                              final hasDefault = index < _defaults.length;
                              final remoteDoc = remoteByOrder[index];
                              final remoteUrl = remoteDoc == null
                                  ? ''
                                  : (remoteDoc.data()['imageUrl'] ?? '')
                                      .toString();
                              final isHidden =
                                  hasDefault && hiddenDefaults.contains(index);
                              final previewSource = remoteUrl.isNotEmpty
                                  ? remoteUrl
                                  : (hasDefault ? _defaults[index] : '');

                              return Opacity(
                                opacity:
                                    isHidden && remoteDoc == null ? 0.55 : 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 8,
                                          child: previewSource
                                                  .startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: previewSource,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) =>
                                                      const ColoredBox(
                                                    color: Color(0xFFF1F1F1),
                                                    child: Icon(
                                                        CupertinoIcons.photo),
                                                  ),
                                                )
                                              : previewSource.isNotEmpty
                                                  ? Image.asset(
                                                      previewSource,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const ColoredBox(
                                                      color: Color(0xFFF1F1F1),
                                                      child: Icon(
                                                        CupertinoIcons.photo,
                                                      ),
                                                    ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isHidden
                                                    ? Colors.black45
                                                    : Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'MontserratBold',
                                                ),
                                              ),
                                            ),
                                            12.pw,
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Slider görseli ${index + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'MontserratBold',
                                                    ),
                                                  ),
                                                  Text(
                                                    remoteDoc != null
                                                        ? 'Canlı görsel'
                                                        : hasDefault
                                                            ? isHidden
                                                                ? 'Gizli varsayılan'
                                                                : 'Varsayılan görsel'
                                                            : 'Ek görsel',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 12,
                                                      fontFamily:
                                                          'MontserratMedium',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (remoteDoc != null)
                                              IconButton(
                                                onPressed: _isBusy
                                                    ? null
                                                    : () => _moveRemoteSlide(
                                                          docs: remoteDocs,
                                                          order: index,
                                                          direction: -1,
                                                        ),
                                                icon: const Icon(
                                                  CupertinoIcons.arrow_up,
                                                ),
                                              ),
                                            if (remoteDoc != null)
                                              IconButton(
                                                onPressed: _isBusy
                                                    ? null
                                                    : () => _moveRemoteSlide(
                                                          docs: remoteDocs,
                                                          order: index,
                                                          direction: 1,
                                                        ),
                                                icon: const Icon(
                                                  CupertinoIcons.arrow_down,
                                                ),
                                              ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == 'replace') {
                                                  await _replaceSlide(
                                                    index: index,
                                                    remoteDoc: remoteDoc,
                                                  );
                                                } else if (value == 'delete') {
                                                  await _hideOrDeleteSlide(
                                                    index: index,
                                                    hasDefault: hasDefault,
                                                    remoteDoc: remoteDoc,
                                                  );
                                                } else if (value == 'restore') {
                                                  await _restoreDefault(index);
                                                }
                                              },
                                              itemBuilder: (context) {
                                                final items =
                                                    <PopupMenuEntry<String>>[
                                                  const PopupMenuItem(
                                                    value: 'replace',
                                                    child: Text(
                                                        'Görseli Değiştir'),
                                                  ),
                                                ];
                                                if (isHidden &&
                                                    hasDefault &&
                                                    remoteDoc == null) {
                                                  items.add(
                                                    const PopupMenuItem(
                                                      value: 'restore',
                                                      child: Text('Yeniden Aç'),
                                                    ),
                                                  );
                                                } else {
                                                  items.add(
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                        hasDefault
                                                            ? 'Kaldır'
                                                            : 'Sil',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return items;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 24,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.black,
                onPressed: _isBusy ? null : _addSlide,
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(CupertinoIcons.add, color: Colors.white),
                label: const Text(
                  'Görsel Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
