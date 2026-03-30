String resolvePostCreatorFloodRootDocId(String docId) {
  final lastUnderscore = docId.lastIndexOf('_');
  if (lastUnderscore <= 0) return docId;
  return '${docId.substring(0, lastUnderscore)}_0';
}
