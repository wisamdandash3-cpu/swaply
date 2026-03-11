/// عنصر واحد في البروفايل (سؤال+جواب نصي أو صورة).
/// كل عنصر له [id] يستخدم كـ [item_id] عند الإعجاب.
class ProfileAnswer {
  const ProfileAnswer({
    required this.id,
    required this.profileId,
    this.questionId,
    required this.itemType,
    required this.content,
    this.sortOrder = 0,
    this.createdAt,
  });

  /// المعرّف الفريد للعنصر — يُرسل كـ item_id عند الإعجاب.
  final String id;
  final String profileId;
  final String? questionId;
  /// 'text' أو 'image'
  final String itemType;
  final String content;
  final int sortOrder;
  final DateTime? createdAt;

  bool get isImage => itemType == 'image';
  bool get isText => itemType == 'text';
  bool get isVideo => itemType == 'video';
  bool get isPoll => itemType == 'poll';

  factory ProfileAnswer.fromJson(Map<String, dynamic> json) {
    return ProfileAnswer(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      questionId: json['question_id'] as String?,
      itemType: json['item_type'] as String,
      content: json['content'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'question_id': questionId,
      'item_type': itemType,
      'content': content,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
