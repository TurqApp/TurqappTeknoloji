part of 'account_center_view.dart';

Future<String?> _loadFallbackPersonalContactDetails({
  required CurrentUserService currentUserService,
  required UserRepository userRepository,
}) async {
  final uid = currentUserService.effectiveUserId;
  if (uid.isEmpty) return null;
  final raw = await userRepository.getUserRaw(uid, preferCache: true);
  if (raw == null) return null;

  final fallbackParts = <String>[];
  final email = (raw['email'] ?? '').toString().trim();
  final phone = (raw['phoneNumber'] ?? '').toString().trim();
  if (email.isNotEmpty) fallbackParts.add(email);
  if (phone.isNotEmpty) fallbackParts.add(phone);
  if (fallbackParts.isEmpty) return null;
  return fallbackParts.join(', ');
}
