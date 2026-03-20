import 'package:turqappv2/Core/Utils/bool_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

String normalizeAccountStatus(dynamic raw) {
  return normalizeSearchText(raw?.toString() ?? '');
}

bool isPendingDeletionAccountStatus(dynamic raw) {
  return normalizeAccountStatus(raw) == 'pending_deletion';
}

bool isDeletedAccountStatus(dynamic raw) {
  return normalizeAccountStatus(raw) == 'deleted';
}

bool isDeactivatedAccount({
  required dynamic accountStatus,
  required dynamic isDeleted,
}) {
  return parseFlexibleBool(isDeleted, fallback: false) ||
      isPendingDeletionAccountStatus(accountStatus) ||
      isDeletedAccountStatus(accountStatus);
}

bool parseAccountFlag(dynamic raw, {required bool fallback}) {
  return parseFlexibleBool(raw, fallback: fallback);
}
