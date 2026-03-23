part of 'account_center_view.dart';

Widget _buildAccountCenterCard({
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  return Container(
    decoration: _buildAccountCenterCardDecoration(),
    padding: padding,
    child: child,
  );
}
