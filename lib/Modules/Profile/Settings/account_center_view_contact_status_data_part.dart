part of 'account_center_view.dart';

extension AccountCenterViewContactStatusDataPart on _ContactStatusRow {
  Color get accountCenterStatusColor =>
      isVerified ? Colors.green : Colors.blueAccent;

  String get accountCenterStatusText =>
      isVerified ? verifiedLabel : pendingLabel;
}
