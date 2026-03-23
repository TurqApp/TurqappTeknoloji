part of 'account_center_view.dart';

extension AccountCenterViewBodyLoadingPart on AccountCenterView {
  Widget _buildBodyLoadingState() {
    return const Center(child: CupertinoActivityIndicator());
  }
}
