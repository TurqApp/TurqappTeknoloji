import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Buttons/scroll_to_top_button.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/TypeWriter/type_writer.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'dart:ui' as ui;
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/Widgets/scale_tap.dart';

class ScholarshipsView extends StatefulWidget {
  const ScholarshipsView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;

  @override
  State<ScholarshipsView> createState() => _ScholarshipsViewState();
}

class _ScholarshipsViewState extends State<ScholarshipsView> {
  final ScholarshipsController controller = Get.put(ScholarshipsController());
  final ScholarshipDetailController detailController = Get.put(
    ScholarshipDetailController(),
  );
  final DateTime startTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  ScrollController get _scrollController => controller.scrollController;
  late final VoidCallback _scrollListener;

  @override
  void initState() {
    super.initState();
    _scrollListener = () {
      controller.scrollOffset.value = _scrollController.offset;
    };
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Stack(
        children: [
          Column(
            children: [
              _buildBody(),
            ],
          ),
          if (widget.showEmbeddedControls) _buildScrollToTopButton(),
          if (widget.showEmbeddedControls) _buildActionButton(context),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildSearchField(),
                _buildBody(),
              ],
            ),
            _buildScrollToTopButton(),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(AppIcons.arrowLeft, color: Colors.black, size: 25),
              ),
              Obx(() {
                final isSearching = controller.searchQuery.value.isNotEmpty;
                final count = isSearching
                    ? controller.visibleScholarships.length
                    : controller.totalCount.value;
                final text = isSearching
                    ? "Arama Sonuçları ($count)"
                    : "Burslar ($count)";
                return TypewriterText(text: text);
              }),
            ],
          ),
        ),
        IconButton(
          icon: Icon(AppIcons.settings, color: Colors.black, size: 24),
          onPressed: () => controller.settings(Get.context!),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _searchController,
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Ara',
          hintStyle: TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(CupertinoIcons.search, size: 20),
          suffixIcon: Obx(() {
            final hasQuery = controller.searchQuery.value.isNotEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: hasQuery
                  ? GestureDetector(
                      key: const ValueKey('clear'),
                      onTap: () {
                        _searchController.clear();
                        controller.resetSearch();
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            );
          }),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.03),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
        style: const TextStyle(fontFamily: 'MontserratMedium', fontSize: 14),
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: Obx(
        () => RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: () async {
            await controller.fetchScholarships();
            await controller.refreshTotalCount();
          },
          child: Stack(
            children: [
              _shouldShowLoading()
                  ? _buildLoadingIndicator()
                  : _buildScholarshipsList(),
              Positioned.fill(
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowLoading() {
    return controller.isLoading.value &&
        controller.allScholarships.isEmpty &&
        DateTime.now().difference(startTime).inSeconds < 10;
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CupertinoActivityIndicator(animating: true));
  }

  Widget _buildScholarshipsList() {
    final isSearching = controller.searchQuery.value.isNotEmpty;
    final items = controller.visibleScholarships;
    if (items.isEmpty && !_shouldShowLoading()) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length +
          ((controller.hasMoreData.value && !isSearching) ? 1 : 0),
      itemBuilder: (context, index) {
        // Son eleman (yükleme veya fallback reklam)
        if (index == items.length) {
          // 4'ten az burs varsa, en sonda reklam göster
          if (items.length < 4) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: AdmobKare(key: ValueKey('scholarship-ad-end')),
                ),
                if (controller.hasMoreData.value && !isSearching) ...[
                  // Yükleme devam ediyorsa loader'ı da göster
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const CupertinoActivityIndicator(animating: true),
                    ),
                  )
                ],
              ],
            );
          }
          // 5 veya daha fazla ise yalnızca yükleme göstergesi (varsa)
          if (controller.hasMoreData.value && !isSearching) {
            controller.loadMoreScholarships();
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(animating: true),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return _buildScholarshipCard(index, items);
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearching = controller.searchQuery.value.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: Get.height * 0.15),
        Icon(
          isSearching ? CupertinoIcons.search : CupertinoIcons.doc_text,
          size: 48,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            isSearching ? 'Sonuç bulunamadı' : 'Henüz burs yok',
            style: const TextStyle(
              fontFamily: 'MontserratBold',
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (isSearching) ...[
          Center(
            child: Text(
              '"${controller.searchQuery.value}" için sonuç bulunamadı',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'İpucu: Farklı anahtar kelimeler deneyin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchTipsChips(),
        ] else ...[
          Center(
            child: Text(
              'Yeni burslar yakında eklenecek',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchTipsChips() {
    final tips = [
      'Başlık',
      'Şehir',
      'Üniversite',
      'Burs veren',
      'Kullanıcı adı',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Şunlara göre arayabilirsiniz:',
            style: TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tips.map((tip) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  tip,
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarshipCard(int index, List<Map<String, dynamic>> items) {
    // İlk 10 kayıt geldikten sonra kullanıcı 5. karta indiğinde
    // arka planda +5 daha çek.
    final isSearching = controller.searchQuery.value.isNotEmpty;
    if (!isSearching && index == 4 && controller.hasMoreData.value) {
      controller.loadMoreScholarships();
    }

    final scholarshipData = items[index];
    final burs = scholarshipData['model'];
    final type = 'bireysel';
    final userData = scholarshipData['userData'] as Map<String, dynamic>?;
    final firmaData = null;
    final docId = scholarshipData['docId'] as String;
    final daysDiff = _calculateDaysDiff(type, burs);

    final children = <Widget>[];

    if (burs.img.isNotEmpty) {
      children.add(
        Row(
          children: [
            Expanded(child: _buildUserHeader(type, userData, firmaData)),
            if (userData?['userID']?.toString() !=
                FirebaseAuth.instance.currentUser?.uid)
              PullDownButton(
                itemBuilder: (context) => [
                  PullDownMenuItem(
                    onTap: () {
                      Get.to(() => ReportUser(
                            userID: userData?['userID']?.toString() ?? '',
                            postID: scholarshipData['docId']?.toString() ?? '',
                            commentID: 'scholarships',
                          ));
                    },
                    title: "Şikayet Et",
                    icon: AppIcons.info,
                    iconColor: Colors.red,
                  ),
                ],
                buttonBuilder: (context, showMenu) => TextButton(
                  onPressed: showMenu,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Icon(
                    AppIcons.ellipsisVertical,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            5.pw,
          ],
        ),
      );
      children.add(8.ph);
      children.add(_buildScholarshipImage(index, type, burs, scholarshipData));
    }

    children.add(
      _buildScholarshipContent(
        index,
        type,
        burs,
        userData,
        firmaData,
        daysDiff,
        scholarshipData,
        docId,
      ),
    );

    // Her 4 burs sonrası kare reklam
    if ((index + 1) % 4 == 0) {
      final slot = ((index + 1) ~/ 4);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AdmobKare(key: ValueKey('scholarship-ad-$slot')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  int _calculateDaysDiff(String type, dynamic burs) {
    if (type != 'bireysel' || burs is! IndividualScholarshipsModel) return -1;

    final endDate = DateFormat('dd.MM.yyyy').parse(burs.bitisTarihi);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return endDateOnly.difference(todayOnly).inDays;
  }

  Widget _buildUserHeader(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildUserInfo(type, userData, firmaData)),
          if (_shouldShowFollowButton(userData)) _buildFollowButton(userData),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    return GestureDetector(
      onTap: _getUserTapHandler(type, userData),
      child: Row(
        children: [
          _buildUserAvatar(type, userData, firmaData),
          8.pw,
          Text(
            _getUserDisplayName(type, userData, firmaData),
            style: TextStyle(
              fontSize: 15,
              fontFamily: "MontserratBold",
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          if (type == 'bireysel')
            RozetContent(
              size: 16,
              userID: userData?['userID']?.toString() ?? '',
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    final imageUrl = (userData?['avatarUrl'] ??
            userData?['avatarUrl'] ??
            userData?['avatarUrl'] ??
            '')
        .toString();
    return CircleAvatar(
      radius: 15,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => CupertinoActivityIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            )
          : Icon(Icons.person, size: 20),
    );
  }

  VoidCallback? _getUserTapHandler(
      String type, Map<String, dynamic>? userData) {
    final uid = userData?['userID']?.toString() ?? '';
    if (uid != FirebaseAuth.instance.currentUser?.uid) {
      return () {
        Get.to(() => SocialProfile(userID: uid))?.then((_) async {
          final isNowFollowing = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('followers')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then((d) => d.exists);
          controller.followedUsers[uid] = isNowFollowing;
          controller.allScholarships.refresh();
        });
      };
    }
    return null;
  }

  String _getUserDisplayName(String type, Map<String, dynamic>? userData,
      Map<String, dynamic>? firmaData) {
    // Her zaman nickname göster; yoksa fallback
    final nick = (userData?['displayName'] ??
            userData?['username'] ??
            userData?['nickname'])
        ?.toString();
    if (nick != null && nick.isNotEmpty) return nick;
    final first = userData?['firstName']?.toString() ?? '';
    final last = userData?['lastName']?.toString() ?? '';
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : 'Kullanıcı';
  }

  bool _shouldShowFollowButton(Map<String, dynamic>? userData) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return userData?['userID']?.toString() != currentUid;
  }

  Widget _buildFollowButton(Map<String, dynamic>? userData) {
    final userId = userData?['userID']?.toString() ?? '';
    return Obx(
      () {
        final isLoading = controller.followLoading[userId] ?? false;
        return ScaleTap(
          enabled: !isLoading,
          onPressed: isLoading ? null : () => _handleFollowTap(userData),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getFollowButtonColor(userData),
              border: Border.all(width: 1, color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _getFollowButtonTextColor(userData)),
                    ),
                  )
                : Text(
                    _getFollowButtonText(userData),
                    style: TextStyle(
                      color: _getFollowButtonTextColor(userData),
                      fontSize: 12,
                      fontFamily: "MontserratBold",
                    ),
                  ),
          ),
        );
      },
    );
  }

  Color _getFollowButtonColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.white : Colors.black;
  }

  String _getFollowButtonText(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? 'Takip Ediyorsun' : 'Takip Et';
  }

  Color _getFollowButtonTextColor(Map<String, dynamic>? userData) {
    final isFollowing =
        controller.followedUsers[userData?['userID']?.toString() ?? ''] ??
            false;
    return isFollowing ? Colors.black : Colors.white;
  }

  Future<void> _handleFollowTap(Map<String, dynamic>? userData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackbar("Hata", "Lütfen oturum açın.");
      return;
    }

    final followedId = userData?['userID']?.toString() ?? '';
    if (followedId.isNotEmpty) {
      controller.followLoading[followedId] = true;
      await detailController.toggleFollowStatus(followedId);
      controller.followedUsers[followedId] = detailController.isFollowing.value;
      controller.followLoading[followedId] = false;
    } else {
      AppSnackbar("Hata", "Takip edilecek kullanıcı bulunamadı.");
    }
  }

  Widget _buildScholarshipImage(int index, String type, dynamic burs,
      Map<String, dynamic> scholarshipData) {
    return GestureDetector(
      onTap: () =>
          Get.to(() => ScholarshipDetailView(), arguments: scholarshipData),
      onDoubleTap: () => controller.toggleLike(scholarshipData['docId'], type),
      child: _hasMultipleImages(type, burs)
          ? _buildMultipleImagesView(index, burs)
          : _buildSingleImageView(burs),
    );
  }

  bool _hasMultipleImages(String type, dynamic burs) {
    return type == 'bireysel' &&
        burs is IndividualScholarshipsModel &&
        burs.img2.isNotEmpty;
  }

  Widget _buildMultipleImagesView(int index, IndividualScholarshipsModel burs) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: 2,
            itemBuilder: (context, pageIndex) {
              final imageUrl = pageIndex == 0 ? burs.img : burs.img2;
              return _buildNetworkImage(imageUrl);
            },
            onPageChanged: (pageIndex) =>
                controller.updatePageIndex(index, pageIndex),
          ),
        ),
        8.ph,
        _buildPageIndicators(index),
      ],
    );
  }

  Widget _buildSingleImageView(dynamic burs) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _buildNetworkImage(burs.img),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    final safeUrl = imageUrl.trim();
    if (safeUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: safeUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.red, size: 40),
    );
  }

  Widget _buildPageIndicators(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (dotIndex) {
        return Obx(
          () => Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (controller.pageIndices[index]?.value ?? 0) == dotIndex
                  ? Colors.black
                  : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  bool _isTextLongerThanTwoLines(String text, BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: "Montserrat",
          color: Colors.black,
        ),
      ),
      maxLines: 2,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 30);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildScholarshipContent(
    int index,
    String type,
    dynamic burs,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
    int daysDiff,
    Map<String, dynamic> scholarshipData,
    String docId,
  ) {
    final displayDescription = _getDisplayDescription(type, burs);
    final canExpandDescription =
        displayDescription == burs.aciklama && displayDescription.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          10.ph,
          _buildScholarshipTitle(index, type, burs, daysDiff),
          5.ph,
          _buildScholarshipProvider(type, userData, firmaData, burs),
          5.ph,
          _buildScholarshipDescription(index, type, burs),
          if (type == 'bireysel' &&
              canExpandDescription &&
              (_isTextLongerThanTwoLines(displayDescription, Get.context!) ||
                  _isTextLongerThanTwoLines(
                    "${burs.baslik} 2025 - 2026 BURS BAŞVURULARI",
                    Get.context!,
                  )))
            _buildExpandButton(index),
          10.ph,
          _buildActionRow(type, userData, scholarshipData, docId),
          15.ph,
        ],
      ),
    );
  }

  Widget _buildScholarshipTitle(
    int index,
    String type,
    dynamic burs,
    int daysDiff,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: type == 'bireysel'
              ? GestureDetector(
                  onTap: () => controller.toggleExpanded(index),
                  child: Obx(
                    () => Text(
                      "${burs.baslik} 2025 - 2026 BURS BAŞVURULARI",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "MontserratBold",
                        color: Colors.black,
                      ),
                      overflow: controller.isExpandedList[index].value
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      maxLines:
                          controller.isExpandedList[index].value ? null : 2,
                    ),
                  ),
                )
              : Text(
                  burs.baslik,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "MontserratBold",
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
        ),
        _buildDeadlineIndicator(daysDiff),
      ],
    );
  }

  Widget _buildDeadlineIndicator(int daysDiff) {
    if (daysDiff < 0) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          '(Süre Doldu)',
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    if (daysDiff == 0) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          'Son gün',
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    if (daysDiff > 0 && daysDiff <= 6) {
      return Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          '(Son ${daysDiff + 1} gün)',
          style: TextStyle(
            fontSize: 14,
            fontFamily: "MontserratBold",
            color: Colors.red,
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildScholarshipProvider(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
    dynamic burs,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: _getProviderTapHandler(type, userData),
          child: Text(
            _getProviderDisplayName(type, userData, firmaData, burs),
            style: TextStyle(
              fontSize: 14,
              fontFamily: "MontserratBold",
              color: Colors.blue.shade900,
            ),
          ),
        ),
        RozetContent(
          size: 16,
          userID: userData?['userID']?.toString() ?? '',
        ),
      ],
    );
  }

  VoidCallback? _getProviderTapHandler(
      String type, Map<String, dynamic>? userData) {
    return () => Get.to(
          SocialProfile(
            userID: userData?['userID']?.toString() ?? '',
          ),
        );
  }

  String _getProviderDisplayName(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? firmaData,
    dynamic burs,
  ) {
    // Her zaman kullanıcı nickname göster
    final nick = userData?['nickname']?.toString();
    if (nick != null && nick.isNotEmpty) return nick;
    final first = userData?['firstName']?.toString() ?? '';
    final last = userData?['lastName']?.toString() ?? '';
    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : 'Bilinmeyen Kullanıcı';
  }

  Widget _buildScholarshipDescription(int index, String type, dynamic burs) {
    if (type == 'bireysel') {
      final description = _getDisplayDescription(type, burs);
      final canExpand = description == burs.aciklama && description.isNotEmpty;
      if (!canExpand) {
        return Text(
          description,
          style: TextStyle(
            fontSize: 13,
            fontFamily: "Montserrat",
            color: Colors.black,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Obx(
        () => GestureDetector(
          onTap: () => controller.toggleExpanded(index),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              fontFamily: "Montserrat",
              color: Colors.black,
            ),
            maxLines: controller.isExpandedList[index].value ? null : 2,
            overflow: controller.isExpandedList[index].value
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      return Text(
        _getDisplayDescription(type, burs),
        style: TextStyle(
          fontSize: 13,
          fontFamily: "Montserrat",
          color: Colors.black,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _getDisplayDescription(String type, dynamic burs) {
    if (type == 'bireysel' && burs is IndividualScholarshipsModel) {
      final summary = burs.shortDescription.trim();
      if (summary.isNotEmpty) return summary;
      return burs.aciklama;
    }
    return burs.aciklama ?? '';
  }

  Widget _buildExpandButton(int index) {
    return Column(
      children: [
        5.ph,
        Obx(
          () => GestureDetector(
            onTap: () => controller.toggleExpanded(index),
            child: Text(
              controller.isExpandedList[index].value
                  ? 'Daha Az Göster'
                  : 'Daha Fazla Göster',
              style: TextStyle(
                fontSize: 13,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic> scholarshipData,
    String docId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: _buildMainActionButton(type, userData, scholarshipData)),
        _buildInteractionButtons(scholarshipData, docId, type),
      ],
    );
  }

  Widget _buildMainActionButton(
    String type,
    Map<String, dynamic>? userData,
    Map<String, dynamic> scholarshipData,
  ) {
    final isOwnScholarship = type == 'bireysel' &&
        userData?['userID']?.toString() ==
            FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: () =>
          Get.to(() => ScholarshipDetailView(), arguments: scholarshipData),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isOwnScholarship ? Colors.red.shade800 : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getMainActionButtonText(type, isOwnScholarship),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getMainActionButtonText(String type, bool isOwnScholarship) {
    if (isOwnScholarship) return 'Bursu İncele';
    if (type == 'bireysel') return 'Başvur';
    return 'Ayrıntılı Bilgi';
  }

  Widget _buildInteractionButtons(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Wrap(
      spacing: 0,
      children: [
        _buildLikeButton(scholarshipData, docId, type),
        _buildBookmarkButton(scholarshipData, docId, type),
        _buildShareButton(scholarshipData),
      ],
    );
  }

  Widget _buildLikeButton(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => controller.toggleLike(docId, type),
            icon: Icon(
              controller.likedScholarships[docId] ?? false
                  ? CupertinoIcons.hand_thumbsup_fill
                  : CupertinoIcons.hand_thumbsup,
              size: 20,
              color: controller.likedScholarships[docId] ?? false
                  ? Colors.blue
                  : Colors.black,
            ),
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Text(
              NumberFormatter.format(scholarshipData['likesCount'].toInt()),
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkButton(
      Map<String, dynamic> scholarshipData, String docId, String type) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => controller.toggleBookmark(docId, type),
            icon: Icon(
              controller.bookmarkedScholarships[docId] ?? false
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              size: 20,
              color: controller.bookmarkedScholarships[docId] ?? false
                  ? Colors.orange
                  : Colors.black,
            ),
          ),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Text(
              NumberFormatter.format(scholarshipData['bookmarksCount'].toInt()),
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Montserrat",
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(Map<String, dynamic> scholarshipData) {
    return IconButton(
      onPressed: () {
        final ctx = Get.context ?? Get.overlayContext;
        if (ctx == null) {
          AppSnackbar('Hata', 'Paylaşım başlatılamadı');
          return;
        }
        controller.shareScholarship(scholarshipData, ctx);
      },
      icon: const Icon(
        CupertinoIcons.share_up,
        size: 20,
        color: Colors.black,
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return ScrollTotopButton(
      scrollController: _scrollController,
      visibilityThreshold: 350,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Obx(
      () => Positioned(
        bottom: 20,
        right: 20,
        child: Visibility(
          visible: controller.scrollOffset.value <= 350,
          child: ActionButton(
            context: context,
            permissionScope: ActionButtonPermissionScope.scholarships,
            menuItems: [
              PullDownMenuItem(
                title: 'Burs Oluştur',
                icon: CupertinoIcons.add_circled,
                onTap: () async {
                  final allowed = await ensureCurrentUserRozetPermission(
                    minimumRozet: 'Sarı',
                    featureName: 'Burs oluşturma',
                  );
                  if (!allowed) return;
                  Get.delete<CreateScholarshipController>(force: true);
                  Get.to(CreateScholarshipView())?.then((_) async {
                    await controller.fetchScholarships();
                    await controller.refreshTotalCount();
                  });
                },
              ),
              PullDownMenuItem(
                title: 'İlanlarım',
                icon: CupertinoIcons.doc_text,
                onTap: () async {
                  final allowed = await ensureCurrentUserRozetPermission(
                    minimumRozet: 'Sarı',
                    featureName: 'Burs ilanları',
                  );
                  if (!allowed) return;
                  Get.to(MyScholarshipView())?.then((_) async {
                    await controller.fetchScholarships();
                    await controller.refreshTotalCount();
                  });
                },
              ),
              PullDownMenuItem(
                title: 'Kaydedilenler',
                icon: CupertinoIcons.bookmark,
                onTap: () => Get.to(() => SavedItemsView()),
              ),
              PullDownMenuItem(
                title: 'Başvurular',
                icon: CupertinoIcons.doc_plaintext,
                onTap: () => Get.to(() => ApplicationsView()),
              ),
              PullDownMenuItem(
                title: 'Sana Özel',
                icon: CupertinoIcons.star,
                onTap: () => Get.to(PersonalizedView()),
              ),
              PullDownMenuItem(
                title: 'Ayarlar',
                icon: CupertinoIcons.gear,
                onTap: () => controller.settings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
