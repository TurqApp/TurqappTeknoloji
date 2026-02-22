String buildConversationId(String userA, String userB) {
  final ids = [userA, userB]..sort();
  return ids.join("_");
}
