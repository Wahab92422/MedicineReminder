/// Appends a dictated phrase to existing text with sensible spacing.
String appendDictatedPhrase(String existing, String phrase) {
  final p = phrase.trim();
  if (p.isEmpty) return existing;
  final e = existing;
  if (e.trim().isEmpty) return p;
  if (e.endsWith(' ') || e.endsWith('\n')) {
    return '$e$p';
  }
  return '$e $p';
}
