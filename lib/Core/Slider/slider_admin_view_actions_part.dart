part of 'slider_admin_view.dart';

extension _SliderAdminViewActionsPart on _SliderAdminViewState {
  Future<void> _addSlide() async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    _updateViewState(() => _isBusy = true);
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
        file: file,
        storagePathWithoutExt: storagePath,
      );

      await _sliderItems.doc(itemId).set({
        'imageUrl': imageUrl,
        'storagePath': '$storagePath.webp',
        'order': nextOrder,
        'viewCount': 0,
        'uniqueViewCount': 0,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      });
      AppSnackbar('common.ok'.tr, 'slider_admin.added'.tr);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'slider_admin.add_failed'.trParams({'error': '$e'}),
      );
    } finally {
      _updateViewState(() => _isBusy = false);
    }
  }

  Future<void> _replaceSlide({
    required int index,
    QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) async {
    final file = await AppImagePickerService.pickSingleImage(context);
    if (file == null) return;

    _updateViewState(() => _isBusy = true);
    try {
      final itemId =
          remoteDoc?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final oldStoragePath = remoteDoc == null
          ? ''
          : (remoteDoc.data()['storagePath'] ?? '').toString();
      final storagePath = 'slider/${widget.sliderId}/$itemId';
      final imageUrl = await WebpUploadService.uploadFileAsWebp(
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
        'viewCount': (remoteDoc?.data()['viewCount'] as num?)?.toInt() ?? 0,
        'uniqueViewCount':
            (remoteDoc?.data()['uniqueViewCount'] as num?)?.toInt() ?? 0,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      if (oldStoragePath.isNotEmpty && oldStoragePath != '$storagePath.webp') {
        await AppFirebaseStorage.instance.ref().child(oldStoragePath).delete();
      }
      AppSnackbar('common.ok'.tr, 'slider_admin.updated'.tr);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'slider_admin.update_failed'.trParams({'error': '$e'}),
      );
    } finally {
      _updateViewState(() => _isBusy = false);
    }
  }

  Future<void> _hideOrDeleteSlide({
    required int index,
    required bool hasDefault,
    QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) async {
    _updateViewState(() => _isBusy = true);
    try {
      if (remoteDoc != null) {
        final storagePath = (remoteDoc.data()['storagePath'] ?? '').toString();
        await remoteDoc.reference.delete();
        if (storagePath.isNotEmpty) {
          await AppFirebaseStorage.instance.ref().child(storagePath).delete();
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
      AppSnackbar(
        'common.ok'.tr,
        hasDefault ? 'slider_admin.hidden'.tr : 'slider_admin.deleted'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'slider_admin.remove_failed'.trParams({'error': '$e'}),
      );
    } finally {
      _updateViewState(() => _isBusy = false);
    }
  }

  Future<void> _restoreDefault(int index) async {
    _updateViewState(() => _isBusy = true);
    try {
      await _ensureSliderMeta();
      await _sliderMeta.set({
        'hiddenDefaults': FieldValue.arrayRemove([index]),
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppSnackbar('common.ok'.tr, 'slider_admin.restored'.tr);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'slider_admin.restore_failed'.trParams({'error': '$e'}),
      );
    } finally {
      _updateViewState(() => _isBusy = false);
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

    _updateViewState(() => _isBusy = true);
    try {
      final batch = AppFirestore.instance.batch();
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
      AppSnackbar(
        'common.error'.tr,
        'slider_admin.sort_failed'.trParams({'error': '$e'}),
      );
    } finally {
      _updateViewState(() => _isBusy = false);
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

    final batch = AppFirestore.instance.batch();
    for (var i = 0; i < extras.length; i++) {
      batch.update(extras[i].reference, {'order': _defaults.length + i});
    }
    await batch.commit();
  }

  Future<void> _setSlideBoundary({
    required QueryDocumentSnapshot<Map<String, dynamic>> remoteDoc,
    required bool isStart,
  }) async {
    final currentValue =
        ((remoteDoc.data()[isStart ? 'startDate' : 'endDate'] as num?)
                        ?.toInt() ??
                    0) >
                0
            ? DateTime.fromMillisecondsSinceEpoch(
                (remoteDoc.data()[isStart ? 'startDate' : 'endDate'] as num)
                    .toInt(),
              )
            : DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue),
    );
    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    _updateViewState(() => _isBusy = true);
    try {
      await remoteDoc.reference.set({
        isStart ? 'startDate' : 'endDate': dateTime.millisecondsSinceEpoch,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppSnackbar(
        'common.ok'.tr,
        isStart ? 'Başlangıç zamanı güncellendi' : 'Bitiş zamanı güncellendi',
      );
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'Zaman güncellenemedi: $e',
      );
    } finally {
      _updateViewState(() => _isBusy = false);
    }
  }

  Future<void> _clearSlideWindow(
    QueryDocumentSnapshot<Map<String, dynamic>> remoteDoc,
  ) async {
    _updateViewState(() => _isBusy = true);
    try {
      await remoteDoc.reference.set({
        'startDate': FieldValue.delete(),
        'endDate': FieldValue.delete(),
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      AppSnackbar('common.ok'.tr, 'Süre alanı temizlendi');
    } catch (e) {
      AppSnackbar('common.error'.tr, 'Süre temizlenemedi: $e');
    } finally {
      _updateViewState(() => _isBusy = false);
    }
  }
}
