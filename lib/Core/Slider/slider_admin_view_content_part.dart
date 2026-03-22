part of 'slider_admin_view.dart';

extension _SliderAdminViewContentPart on _SliderAdminViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BackButtons(
                  text: 'slider_admin.title'.trParams({'title': widget.title}),
                ),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _sliderMeta.snapshots(),
                    builder: (context, metaSnapshot) {
                      final hiddenDefaults = _hiddenDefaultsFrom(metaSnapshot);

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
                          return _buildSliderList(
                            hiddenDefaults: hiddenDefaults,
                            remoteDocs: remoteDocs,
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

  Set<int> _hiddenDefaultsFrom(
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> metaSnapshot,
  ) {
    return ((metaSnapshot.data?.data()?['hiddenDefaults'] as List<dynamic>?) ??
            const <dynamic>[])
        .map((e) => e is num ? e.toInt() : -1)
        .where((e) => e >= 0)
        .toSet();
  }

  Widget _buildSliderList({
    required Set<int> hiddenDefaults,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> remoteDocs,
  }) {
    final remoteByOrder = <int, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in remoteDocs) {
      remoteByOrder[(doc.data()['order'] as num?)?.toInt() ?? 0] = doc;
    }

    final maxOrder = remoteDocs.isEmpty
        ? _defaults.length
        : remoteDocs
                .map((doc) => (doc.data()['order'] as num?)?.toInt() ?? 0)
                .reduce((a, b) => a > b ? a : b) +
            1;
    final itemCount = maxOrder > _defaults.length ? maxOrder : _defaults.length;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 120),
      itemCount: itemCount,
      separatorBuilder: (_, __) => 12.ph,
      itemBuilder: (context, index) {
        final hasDefault = index < _defaults.length;
        final remoteDoc = remoteByOrder[index];
        final remoteUrl = remoteDoc == null
            ? ''
            : (remoteDoc.data()['imageUrl'] ?? '').toString();
        final isHidden = hasDefault && hiddenDefaults.contains(index);
        final previewSource = remoteUrl.isNotEmpty
            ? remoteUrl
            : (hasDefault ? _defaults[index] : '');

        return _buildSliderCard(
          index: index,
          hasDefault: hasDefault,
          isHidden: isHidden,
          previewSource: previewSource,
          remoteDoc: remoteDoc,
          remoteDocs: remoteDocs,
        );
      },
    );
  }

  Widget _buildSliderCard({
    required int index,
    required bool hasDefault,
    required bool isHidden,
    required String previewSource,
    required QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> remoteDocs,
  }) {
    return Opacity(
      opacity: isHidden && remoteDoc == null ? 0.55 : 1,
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: _buildPreview(previewSource),
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
                      color: isHidden ? Colors.black45 : Colors.black,
                      borderRadius: BorderRadius.circular(10),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'slider_admin.image_label'.trParams({
                            'index': '${index + 1}',
                          }),
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        Text(
                          _statusText(
                            hasDefault: hasDefault,
                            isHidden: isHidden,
                            remoteDoc: remoteDoc,
                          ),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: 'MontserratMedium',
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
                      icon: const Icon(CupertinoIcons.arrow_up),
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
                      icon: const Icon(CupertinoIcons.arrow_down),
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
                    itemBuilder: (context) => _buildMenuItems(
                      hasDefault: hasDefault,
                      isHidden: isHidden,
                      remoteDoc: remoteDoc,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(String previewSource) {
    if (previewSource.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: previewSource,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const ColoredBox(
          color: Color(0xFFF1F1F1),
          child: Icon(CupertinoIcons.photo),
        ),
      );
    }
    if (previewSource.isNotEmpty) {
      return Image.asset(
        previewSource,
        fit: BoxFit.cover,
      );
    }
    return const ColoredBox(
      color: Color(0xFFF1F1F1),
      child: Icon(CupertinoIcons.photo),
    );
  }

  String _statusText({
    required bool hasDefault,
    required bool isHidden,
    required QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) {
    if (remoteDoc != null) {
      return 'slider_admin.live'.tr;
    }
    if (hasDefault) {
      return isHidden
          ? 'slider_admin.hidden_default'.tr
          : 'slider_admin.default_image'.tr;
    }
    return 'slider_admin.extra_image'.tr;
  }

  List<PopupMenuEntry<String>> _buildMenuItems({
    required bool hasDefault,
    required bool isHidden,
    required QueryDocumentSnapshot<Map<String, dynamic>>? remoteDoc,
  }) {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'replace',
        child: Text('slider_admin.replace'.tr),
      ),
    ];
    if (isHidden && hasDefault && remoteDoc == null) {
      items.add(
        PopupMenuItem(
          value: 'restore',
          child: Text('slider_admin.reopen'.tr),
        ),
      );
    } else {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Text(hasDefault ? 'common.remove'.tr : 'common.delete'.tr),
        ),
      );
    }
    return items;
  }
}
