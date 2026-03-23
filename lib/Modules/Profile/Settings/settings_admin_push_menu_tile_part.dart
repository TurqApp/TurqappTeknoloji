part of 'settings.dart';

class _AdminPushMenuTile extends StatefulWidget {
  const _AdminPushMenuTile({required this.buildRow});

  final Widget Function(String, IconData, VoidCallback, {bool isNew}) buildRow;

  @override
  State<_AdminPushMenuTile> createState() => _AdminPushMenuTileState();
}

class _AdminPushMenuTileState extends State<_AdminPushMenuTile> {
  late final Future<bool> _canShowFuture;

  Future<bool> _canShowAdminPushMenu() async {
    if (CurrentUserService.instance.effectiveUserId.isEmpty) return false;

    final isAdmin = await AdminAccessService.canManageSliders();
    if (!isAdmin) return false;

    final data = await ConfigRepository.ensure().getAdminConfigDoc(
          'admin',
          preferCache: true,
        ) ??
        <String, dynamic>{};
    return data["pushSend"] == true;
  }

  @override
  void initState() {
    super.initState();
    _canShowFuture = _canShowAdminPushMenu();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canShowFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return widget.buildRow(
          "settings.admin_push".tr,
          CupertinoIcons.paperplane,
          () => Get.to(() => const AdminPushView()),
        );
      },
    );
  }
}
