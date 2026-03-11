/// سؤال من جدول profile_questions (نص متعدد اللغات).
class ProfileQuestion {
  const ProfileQuestion({
    required this.id,
    this.questionTextAr,
    this.questionTextEn,
    this.questionTextDe,
    this.createdAt,
  });

  final String id;
  final String? questionTextAr;
  final String? questionTextEn;
  final String? questionTextDe;
  final DateTime? createdAt;

  factory ProfileQuestion.fromJson(Map<String, dynamic> json) {
    return ProfileQuestion(
      id: json['id'] as String,
      questionTextAr: json['question_text_ar'] as String?,
      questionTextEn: json['question_text_en'] as String?,
      questionTextDe: json['question_text_de'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text_ar': questionTextAr,
      'question_text_en': questionTextEn,
      'question_text_de': questionTextDe,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
