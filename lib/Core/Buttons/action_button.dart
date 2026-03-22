import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';

enum ActionButtonPermissionScope {
  none,
  scholarships,
  practiceExams,
  jobFinder,
}

class ActionButton extends StatefulWidget {
  final BuildContext context;
  final List<PullDownMenuItem> menuItems;
  final ActionButtonPermissionScope permissionScope;
  final String? semanticsLabel;
  final double size;
  final double lift;
  final Color backgroundColor;
  final Color iconColor;

  const ActionButton({
    super.key,
    required this.context,
    required this.menuItems,
    this.permissionScope = ActionButtonPermissionScope.none,
    this.semanticsLabel,
    this.size = 60,
    this.lift = 60,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  late final Future<Map<String, bool>> _permissionsFuture;
  static const String _yellowBadgeTier = 'sari';
  static const Map<String, Set<String>> _menuTitleVariantsByKey = {
    'scholarship.create_title': {
      'scholarship.create_title',
      'burs oluştur',
      'create scholarship',
      'stipendium erstellen',
      'creer une bourse',
      'créer une bourse',
      'crea borsa di studio',
      'создать стипендию',
    },
    'scholarship.my_listings': {
      'scholarship.my_listings',
      'burs ilanlarım',
      'my scholarship listings',
      'meine stipendienanzeigen',
      'mes annonces de bourse',
      'i miei annunci di borsa',
      'мои объявления о стипендии',
    },
    'common.create': {
      'common.create',
      'oluştur',
      'create',
      'erstellen',
      'creer',
      'créer',
      'crea',
      'создать',
    },
    'pasaj.common.published': {
      'pasaj.common.published',
      'yayınladıklarım',
      'published',
      'veröffentlichte',
      'publiées',
      'pubblicati',
      'опубликованные',
    },
    'pasaj.common.post_listing': {
      'pasaj.common.post_listing',
      'ilan ver',
      'post listing',
      'inserat erstellen',
      'publier une annonce',
      'pubblica annuncio',
      'разместить объявление',
    },
    'pasaj.market.my_listings': {
      'pasaj.market.my_listings',
      'ilanlarım',
      'my listings',
      'meine anzeigen',
      'mes annonces',
      'i miei annunci',
      'мои объявления',
    },
    'pasaj.common.slider_admin': {
      'pasaj.common.slider_admin',
      'slider yönetimi',
      'slider management',
      'slider-verwaltung',
    },
  };

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _loadPermissions();
  }

  Future<bool> _canManageSliders() async {
    return AdminAccessService.canManageSliders();
  }

  Future<Map<String, bool>> _loadPermissions() async {
    final canUseYellowTier = await currentUserHasRozetPermission(
      _yellowBadgeTier,
    );
    final canManageSliders = await _canManageSliders();
    return {
      'canUseYellowTier': canUseYellowTier,
      'canManageSliders': canManageSliders,
    };
  }

  bool _matchesLocalizedTitle(PullDownMenuItem item, List<String> titleKeys) {
    final title = normalizeSearchText(item.title);
    for (final key in titleKeys) {
      final variants = _menuTitleVariantsByKey[key] ?? {key};
      if (variants.contains(title)) {
        return true;
      }
    }
    return false;
  }

  bool _shouldHideForScope(PullDownMenuItem item, bool canUseYellowTier) {
    if (canUseYellowTier) return false;

    switch (widget.permissionScope) {
      case ActionButtonPermissionScope.scholarships:
        return _matchesLocalizedTitle(item, [
          'scholarship.create_title',
          'scholarship.my_listings',
        ]);
      case ActionButtonPermissionScope.practiceExams:
        return _matchesLocalizedTitle(item, [
          'common.create',
          'pasaj.common.published',
        ]);
      case ActionButtonPermissionScope.jobFinder:
        return _matchesLocalizedTitle(item, [
          'pasaj.common.post_listing',
          'pasaj.market.my_listings',
        ]);
      case ActionButtonPermissionScope.none:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = false.obs;
    final effectiveBackgroundColor = widget.backgroundColor == Colors.white
        ? Colors.white.withValues(alpha: 0.88)
        : widget.backgroundColor;
    return Transform.translate(
      offset: Offset(0, -widget.lift),
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        child: Obx(
          () => Opacity(
            opacity: isPressed.value ? 0.5 : 1.0,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: FutureBuilder<Map<String, bool>>(
                future: _permissionsFuture,
                builder: (context, snapshot) {
                  final canUseYellowTier =
                      snapshot.data?['canUseYellowTier'] ?? false;
                  final canManageSliders =
                      snapshot.data?['canManageSliders'] ?? false;
                  return PullDownButton(
                    itemBuilder: (context) => widget.menuItems
                        .map((item) {
                          if (_shouldHideForScope(item, canUseYellowTier)) {
                            return null;
                          }
                          if (_matchesLocalizedTitle(item, [
                                'pasaj.common.slider_admin',
                              ]) &&
                              !canManageSliders) {
                            return null;
                          }
                          return item;
                        })
                        .whereType<PullDownMenuItem>()
                        .toList(),
                    buttonBuilder: (context, showMenu) => Semantics(
                      label: widget.semanticsLabel,
                      button: true,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: widget.size,
                            height: widget.size,
                            decoration: BoxDecoration(
                              color: effectiveBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.backgroundColor == Colors.white
                                    ? Colors.black.withValues(alpha: 0.06)
                                    : widget.backgroundColor
                                        .withValues(alpha: 0.24),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: IconButton(
                              icon: Icon(
                                Icons.grid_view_outlined,
                                color: widget.iconColor,
                                size: widget.size <= 56 ? 23 : 25,
                              ),
                              onPressed: showMenu,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
