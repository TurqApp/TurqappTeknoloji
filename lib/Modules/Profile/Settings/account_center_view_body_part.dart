part of 'account_center_view.dart';

extension AccountCenterViewBodyPart on AccountCenterView {
  Widget _buildBody(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() {
            final items = accountCenter.accounts.toList(growable: false);
            return _buildContent(context, items);
          }),
        );
      },
    );
  }
}
