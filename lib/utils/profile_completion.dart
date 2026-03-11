import 'dart:convert';

import '../models/profile_answer.dart';

/// ثوابت وحساب نسبة إكتمال البروفايل (25% أسئلة، 10% لكل صورة، 15% حقول).
class ProfileCompletion {
  ProfileCompletion._();

  /// الحد الأدنى لإرسال الإعجابات (مثل Parship).
  static const int minPercentToLike = 50;

  /// الحد الأدنى للصور المطلوبة (صورة واحدة على الأقل).
  static const int minPhotosRequired = 1;

  static const int writtenPromptSortBase = 100;
  static const int writtenPromptCount = 3;
  static const int questionsWeight = 25;
  static const int perPhotoPercent = 10;
  static const int maxPhotos = 6;
  static const int fieldsWeight = 15;

  static const List<String> fieldKeys = [
    'pronouns', 'gender', 'sexuality', 'im_interested_in', 'match_note',
    'work', 'job_title', 'college_or_university', 'education_level', 'religious_beliefs',
    'home_town', 'politics', 'languages_spoken', 'dating_intentions', 'relationship_type',
    'name', 'age', 'height', 'location', 'ethnicity', 'children', 'family_plans',
    'covid_vaccine', 'pets', 'zodiac_sign', 'drinking', 'smoking', 'marijuana', 'drugs',
  ];

  /// يحسب نسبة الإكتمال من الإجابات وحقول البروفايل.
  static int computePercent({
    required List<ProfileAnswer> answers,
    required Map<String, ({String value, String visibility})> fields,
  }) {
    final q = _filledQuestionsCount(answers);
    final photos = _filledPhotosCount(answers);
    final f = _filledFieldsCount(fields);
    final questionsPart = (q / writtenPromptCount) * questionsWeight;
    final photosPart = photos * perPhotoPercent;
    final fieldsPart = fieldKeys.isEmpty ? 0.0 : (f / fieldKeys.length) * fieldsWeight;
    return (questionsPart + photosPart + fieldsPart).round().clamp(0, 100);
  }

  static int _filledQuestionsCount(List<ProfileAnswer> answers) {
    var n = 0;
    for (final a in answers) {
      if (a.itemType != 'text') continue;
      if (a.sortOrder < writtenPromptSortBase || a.sortOrder >= writtenPromptSortBase + writtenPromptCount) continue;
      if (!_isWrittenPromptWithAnswer(a.content)) continue;
      n++;
    }
    return n.clamp(0, writtenPromptCount);
  }

  static bool _isWrittenPromptWithAnswer(String content) {
    if (content.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return false;
      final answer = ((decoded['answer']?.toString()) ?? '').trim();
      return decoded.containsKey('prompt_id') &&
          decoded['prompt_id'] != null &&
          decoded['prompt_id'].toString().trim().isNotEmpty &&
          answer.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static int _filledPhotosCount(List<ProfileAnswer> answers) {
    return answers
        .where((a) => a.isImage && a.content.trim().isNotEmpty)
        .length
        .clamp(0, maxPhotos);
  }

  static int _filledFieldsCount(Map<String, ({String value, String visibility})> fields) {
    var n = 0;
    for (final key in fieldKeys) {
      final v = fields[key]?.value ?? '';
      if (v.trim().isNotEmpty) n++;
    }
    return n;
  }
}
