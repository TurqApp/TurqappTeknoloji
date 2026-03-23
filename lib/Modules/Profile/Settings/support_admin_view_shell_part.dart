part of 'support_admin_view.dart';

extension _SupportAdminViewShellPart on _SupportAdminViewState {
  Widget _buildPage(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, accessSnap) {
        if (accessSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }
        if (accessSnap.data != true) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  BackButtons(text: 'admin.support.title'.tr),
                  Expanded(
                    child: Center(
                      child: Text(
                        'admin.no_access'.tr,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BackButtons(text: 'admin.support.title'.tr),
                Expanded(
                  child: _buildSupportAdminContent(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
