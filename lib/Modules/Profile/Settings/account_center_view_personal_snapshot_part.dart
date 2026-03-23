part of 'account_center_view.dart';

extension AccountCenterViewPersonalSnapshotPart on _PersonalDetailsSection {
  Widget _buildPersonalSnapshotState(AsyncSnapshot<String?> snapshot) {
    if (snapshot.connectionState != ConnectionState.done &&
        !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
      return _buildPersonalLoadingState();
    }

    return _buildPersonalLoadedState(snapshot.data);
  }
}
