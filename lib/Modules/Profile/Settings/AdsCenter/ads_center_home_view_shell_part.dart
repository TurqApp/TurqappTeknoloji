part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewShellPart on _AdsCenterHomeViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller.canAccess.value) {
          return _buildAdminOnlyState();
        }

        final error = _controller.errorText.value;
        if (error != null && error.isNotEmpty) {
          return _buildErrorState(error);
        }

        return _buildTabs();
      }),
    );
  }
}
