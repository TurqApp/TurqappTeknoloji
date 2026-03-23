part of 'account_center_view.dart';

extension AccountCenterViewPasswordProviderBranchPart on AccountCenterView {
  bool _hasPasswordProvider(StoredAccount account) {
    return account.hasPasswordProvider;
  }
}
