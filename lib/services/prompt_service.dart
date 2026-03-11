import '../data/prompts_data.dart';

/// خدمة جلب الأسئلة/المطالبات للبروفايل.
class PromptService {
  static final PromptService _instance = PromptService._();
  factory PromptService() => _instance;

  PromptService._();

  /// جلب كل الأسئلة.
  List<Prompt> getAllPrompts() => List.from(kPrompts);

  /// جلب الأسئلة حسب الفئة.
  List<Prompt> getPromptsByCategory(String category) {
    return kPrompts.where((p) => p.category == category).toList();
  }

  /// جلب الفئات المميزة (بالترتيب).
  List<String> getCategories() {
    final seen = <String>{};
    return kPrompts
        .map((p) => p.category)
        .where((c) => seen.add(c))
        .toList();
  }

  /// جلب سؤال بالمعرّف.
  Prompt? getPromptById(String id) {
    try {
      return kPrompts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
