part of 'admin_push_view.dart';

extension AdminPushViewShellPart on _AdminPushViewState {
  Widget _buildPage(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canManagePush) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'admin.push.title'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'MontserratSemiBold',
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'admin.no_access'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'admin.push.title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'MontserratSemiBold',
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildAdminPushContent(context),
      ),
    );
  }
}
