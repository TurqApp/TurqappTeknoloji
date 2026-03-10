import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
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

  const ActionButton({
    super.key,
    required this.context,
    required this.menuItems,
    this.permissionScope = ActionButtonPermissionScope.none,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  late final Future<Map<String, bool>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = _loadPermissions();
  }

  Future<bool> _canManageSliders() async {
    return AdminAccessService.canManageSliders();
  }

  Future<Map<String, bool>> _loadPermissions() async {
    final canUseYellowTier = await currentUserHasRozetPermission('Sarı');
    final canManageSliders = await _canManageSliders();
    return {
      'canUseYellowTier': canUseYellowTier,
      'canManageSliders': canManageSliders,
    };
  }

  bool _shouldHideForScope(PullDownMenuItem item, bool canUseYellowTier) {
    if (canUseYellowTier) return false;

    switch (widget.permissionScope) {
      case ActionButtonPermissionScope.scholarships:
        return item.title == 'Burs Oluştur' || item.title == 'İlanlarım';
      case ActionButtonPermissionScope.practiceExams:
        return item.title == 'Oluştur' || item.title == 'Yayınladıklarım';
      case ActionButtonPermissionScope.jobFinder:
        return item.title == 'İlan Ver' || item.title == 'İlanlarım';
      case ActionButtonPermissionScope.none:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = false.obs;
    return Transform.translate(
      offset: const Offset(0, -60),
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        child: Obx(
          () => Opacity(
            opacity: isPressed.value ? 0.5 : 1.0,
            child: SizedBox(
              width: 60,
              height: 60,
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
                          if (item.title == 'Slider Yönetimi' &&
                              !canManageSliders) {
                            return null;
                          }
                          return item;
                        })
                        .whereType<PullDownMenuItem>()
                        .toList(),
                    buttonBuilder: (context, showMenu) => ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
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
                              color: Colors.black,
                              size: Theme.of(context).iconTheme.size ?? 25,
                            ),
                            onPressed: showMenu,
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
