part of 'account_center_view.dart';

String? _loadDirectPersonalContactDetails(
  CurrentUserService currentUserService,
) {
  final current = currentUserService.currentUser;
  final parts = <String>[];

  final directEmail = (current?.email ?? currentUserService.email).trim();
  final directPhone =
      (current?.phoneNumber ?? currentUserService.phoneNumber).trim();
  if (directEmail.isNotEmpty) parts.add(directEmail);
  if (directPhone.isNotEmpty) parts.add(directPhone);
  if (parts.isEmpty) return null;
  return parts.join(', ');
}
