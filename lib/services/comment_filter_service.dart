/// خدمة تصفية التعليقات: كشف لغة غير محترمة في النص.
class CommentFilterService {
  /// قائمة كلمات تعتبر غير محترمة (عربي + إنجليزي) — يمكن توسيعها.
  static const List<String> _badWords = [
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'idiot',
    'أحمق',
    'غبي',
  ];

  /// هل النص يحتوي على لغة غير محترمة؟
  static bool containsDisrespectfulLanguage(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.toLowerCase().trim();
    for (final word in _badWords) {
      if (word.trim().isEmpty) continue;
      if (lower.contains(word.toLowerCase())) return true;
    }
    return false;
  }
}
