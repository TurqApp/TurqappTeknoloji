part of 'account_center_view.dart';

extension AccountCenterViewPersonalLoadingPart on _PersonalDetailsSection {
  Widget _buildPersonalLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: const CupertinoActivityIndicator(),
    );
  }
}
