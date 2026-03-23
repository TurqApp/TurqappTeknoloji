part of 'account_center_view.dart';

extension AccountCenterViewBodySnapshotPart on AccountCenterView {
  Widget _buildBodySnapshot(
    BuildContext context,
    AsyncSnapshot<void> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return _buildBodyLoadingState();
    }

    return _buildBodyContent(context);
  }
}
