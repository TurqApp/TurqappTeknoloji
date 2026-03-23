part of 'account_center_view.dart';

Widget _buildAccountCenterRowShell({
  required Widget child,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    ),
  );
}
