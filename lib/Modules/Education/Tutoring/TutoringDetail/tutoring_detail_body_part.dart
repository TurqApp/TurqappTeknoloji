part of 'tutoring_detail.dart';

extension TutoringDetailBodyPart on TutoringDetail {
  Widget buildContent(BuildContext context) {
    final TutoringDetailController controller = Get.put(
      TutoringDetailController(),
    );
    final SavedTutoringsController savedController =
        Get.isRegistered<SavedTutoringsController>()
            ? Get.find<SavedTutoringsController>()
            : Get.put(SavedTutoringsController());
    final TutoringController tutoringController =
        Get.isRegistered<TutoringController>()
            ? Get.find<TutoringController>()
            : Get.put(TutoringController());
    final String? currentUserId = getCurrentUserId();

    Future<void> deleteTutoring(String docId) async {
      try {
        await FirebaseFirestore.instance
            .collection('educators')
            .doc(docId)
            .delete();
        Get.back();
        AppSnackbar('Başarılı', 'İlan silindi!');
      } catch (_) {
        AppSnackbar('Hata', 'İlan silinirken bir hata oluştu.');
      }
    }

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
          'Özel Ders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: EducationFeedShareIconButton(
              onTap: () =>
                  shareService.shareTutoring(controller.tutoring.value),
              size: AppIconSurface.kSize,
              iconSize: AppIconSurface.kIconSize,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Obx(() {
              final isSaved = savedController.savedTutoringIds.contains(
                controller.tutoring.value.docID,
              );
              return AppHeaderActionButton(
                onTap: () async {
                  if (currentUserId == null) return;
                  final success = await tutoringController.toggleFavorite(
                    controller.tutoring.value.docID,
                    currentUserId,
                    isSaved,
                  );
                  if (!success) return;
                  if (isSaved) {
                    savedController.removeSavedTutoring(
                      controller.tutoring.value.docID,
                    );
                  } else {
                    savedController.addSavedTutoring(
                      controller.tutoring.value.docID,
                    );
                  }
                },
                child: Icon(
                  isSaved
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  size: AppIconSurface.kIconSize,
                  color: isSaved ? Colors.orange : Colors.black87,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: pullDownMenu(controller),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CupertinoActivityIndicator());
          }

          final current = controller.tutoring.value;
          final user = controller.users[current.userID] ?? const <String, dynamic>{};
          final teacherName = (user['nickname'] ??
                  user['username'] ??
                  user['displayName'] ??
                  '')
              .toString()
              .trim();

          return ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _heroImage(current),
              const SizedBox(height: 14),
              Text(
                current.baslik,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${current.sehir}, ${current.ilce}  •  ${teacherName.isEmpty ? current.brans : teacherName}',
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
                current.aciklama.trim().isEmpty
                    ? 'Bu ilan için açıklama eklenmemiş.'
                    : current.aciklama,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'Ders Bilgileri',
                children: [
                  _infoRow('Branş', current.brans),
                  if (current.dersYeri.isNotEmpty)
                    _infoRow('Ders Yeri', current.dersYeri.join(', ')),
                  _infoRow('Ücret', _formatPrice(current.fiyat)),
                  _infoRow(
                    'İletişim',
                    current.telefon == true ? 'Telefon + Mesaj' : 'Sadece Mesaj',
                  ),
                  if (current.cinsiyet.trim().isNotEmpty)
                    _infoRow('Cinsiyet Tercihi', current.cinsiyet),
                  if (_availabilityText(current).isNotEmpty)
                    _infoRow('Müsaitlik', _availabilityText(current)),
                ],
              ),
              const SizedBox(height: 18),
              _infoCard(
                title: 'İlan Bilgileri',
                children: [
                  _infoRow(
                    'Eğitmen',
                    teacherName.isEmpty ? 'Belirtilmedi' : teacherName,
                  ),
                  _infoRow('Şehir', '${current.sehir}, ${current.ilce}'),
                  _infoRow('Görüntülenme', '${current.viewCount ?? 0}'),
                  _infoRow(
                    'Durum',
                    current.ended == true ? 'Pasif' : 'Aktif',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Konum',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 10),
              _locationCard(current),
              const SizedBox(height: 18),
              _teacherCard(current, user, currentUserId),
              const SizedBox(height: 18),
              _actionSection(
                controller: controller,
                currentUserId: currentUserId,
                onDelete: deleteTutoring,
              ),
              const SizedBox(height: 18),
              _buildSimilarSection(controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _heroImage(TutoringModel model) {
    final imageUrl =
        model.imgs != null && model.imgs!.isNotEmpty ? model.imgs!.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1.18,
        child: imageUrl.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3F5F7),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.photo,
        color: Colors.black38,
        size: 36,
      ),
    );
  }

  String _formatPrice(num value) {
    final digits = value.toInt().toString();
    final reversed = digits.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    final formatted = chunks
        .map((chunk) => chunk.split('').reversed.join())
        .toList()
        .reversed
        .join('.');
    return '$formatted TL';
  }

  String _availabilityText(TutoringModel model) {
    final availability = model.availability;
    if (availability == null || availability.isEmpty) return '';
    return availability.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join(' • ');
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(TutoringModel model) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.location_solid, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${model.sehir}, ${model.ilce}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherCard(
    TutoringModel model,
    Map<String, dynamic> user,
    String? currentUserId,
  ) {
    final avatarUrl = (user['avatarUrl'] ?? '').toString().trim();
    final nickname = (user['nickname'] ??
            user['username'] ??
            user['displayName'] ??
            '')
        .toString()
        .trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: GestureDetector(
        onTap: model.userID == currentUserId
            ? null
            : () => Get.to(() => SocialProfile(userID: model.userID)),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _imageFallback(),
                      )
                    : _imageFallback(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nickname.isEmpty ? model.brans : nickname,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RozetContent(size: 14, userID: model.userID),
                    ],
                  ),
                  if (nickname.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@$nickname',
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
            if (model.userID != currentUserId)
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionSection({
    required TutoringDetailController controller,
    required String? currentUserId,
    required Future<void> Function(String docId) onDelete,
  }) {
    final current = controller.tutoring.value;
    final isOwner = currentUserId == current.userID;

    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const CreateTutoringView(), arguments: current),
              child: _solidAction('Düzenle'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => ChatListing()),
              child: _outlinedAction('Mesajlar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                noYesAlert(
                  title: 'İlanı Kaldır',
                  message:
                      'Bu özel ders ilanını yayından kaldırmak istediğinizden emin misiniz?',
                  yesText: 'Kaldır',
                  cancelText: 'Vazgeç',
                  onYesPressed: () async {
                    await controller.unpublishTutoring();
                    AppSnackbar('Başarılı', 'İlan yayından kaldırıldı.');
                  },
                );
              },
              child: _dangerAction('Kaldır'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openTutorChat(
              currentUserId: currentUserId,
              model: current,
              chatListingController: chatListingController,
            ),
            child: _solidAction('Mesaj'),
          ),
        ),
        if (current.telefon == true) ...[
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _callTutor(
                model: current,
                ownerRaw: controller.users[current.userID] ??
                    const <String, dynamic>{},
              ),
              child: _outlinedAction('Ara'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openTutorChat({
    required String? currentUserId,
    required TutoringModel model,
    required ChatListingController chatListingController,
  }) async {
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      AppSnackbar('Giriş Gerekli', 'Mesaj göndermek için giriş yapmalısın.');
      return;
    }
    if (currentUserId == model.userID) {
      AppSnackbar('Bilgi', 'Kendi ilanına mesaj gönderemezsin.');
      return;
    }
    final existing = chatListingController.list.firstWhereOrNull(
      (val) => val.userID == model.userID,
    );
    if (existing != null) {
      await Get.to(
        () => ChatView(
          chatID: existing.chatID,
          userID: model.userID,
          isNewChat: false,
          openKeyboard: true,
        ),
      );
      return;
    }
    final chatId = buildConversationId(currentUserId, model.userID);
    await Get.to(
      () => ChatView(
        chatID: chatId,
        userID: model.userID,
        isNewChat: true,
        openKeyboard: true,
      ),
    );
    await chatListingController.getList(forceServer: true);
  }

  Future<void> _callTutor({
    required TutoringModel model,
    required Map<String, dynamic> ownerRaw,
  }) async {
    if (model.telefon != true) {
      AppSnackbar('Bilgi', 'Bu ilanda arama izni kapalı.');
      return;
    }
    final rawPhone = (ownerRaw['phoneNumber'] ?? '').toString().trim();
    if (rawPhone.isEmpty) {
      AppSnackbar('Bilgi Yok', 'Eğitmenin telefon bilgisi bulunamadı.');
      return;
    }
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    String dialValue = rawPhone;
    if (digits.startsWith('90') && digits.length == 12) {
      dialValue = '+$digits';
    } else if (digits.startsWith('0') && digits.length == 11) {
      dialValue = '+9$digits';
    } else if (digits.length == 10 && digits.startsWith('5')) {
      dialValue = '+90$digits';
    }
    final opened = await launchUrl(Uri.parse('tel:$dialValue'));
    if (!opened) {
      AppSnackbar('Hata', 'Telefon uygulaması açılamadı.');
    }
  }

  Widget _solidAction(String text) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _outlinedAction(String text) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _dangerAction(String text) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE45858)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE45858),
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
