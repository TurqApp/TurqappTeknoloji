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

BoxDecoration _buildAccountCenterCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black12),
  );
}
