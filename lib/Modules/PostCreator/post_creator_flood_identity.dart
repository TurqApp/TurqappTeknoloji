String resolvePostCreatorFloodRootDocId(String docId) {
  final lastUnderscore = docId.lastIndexOf('_');
  if (lastUnderscore <= 0) return docId;
  final index = int.tryParse(docId.substring(lastUnderscore + 1)) ?? 0;
  if (index == 0) return docId;
  return '${docId}_0';
}
