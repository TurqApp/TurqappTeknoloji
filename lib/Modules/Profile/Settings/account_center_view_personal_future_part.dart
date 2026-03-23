part of 'account_center_view.dart';

extension AccountCenterViewPersonalFuturePart on _PersonalDetailsSection {
  Widget _buildPersonalFuture(String currentUid) {
    return FutureBuilder<String?>(
      key: ValueKey(currentUid),
      future: _loadPersonalContactDetails(
        currentUserService: currentUserService,
        userRepository: userRepository,
      ),
      builder: (context, snapshot) => _buildPersonalSnapshotState(snapshot),
    );
  }
}
