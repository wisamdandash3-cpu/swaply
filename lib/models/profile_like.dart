/// إعجاب بعنصر محدد في البروفايل (صورة أو إجابة نصية)، أو سجل هدية (وردة/خاتم/قهوة).
/// [itemId] = id عنصر من [ProfileAnswer]؛ قد يكون null لسجل الهدية.
class ProfileLike {
  const ProfileLike({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.itemId,
    this.createdAt,
    this.giftType,
    this.giftMessage,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  /// معرّف العنصر المُعجَب به (من profile_answers.id)، أو null لسجل الهدية.
  final String? itemId;
  final DateTime? createdAt;
  /// نوع الهدية المرسلة: rose_gift, ring_gift, coffee_gift.
  final String? giftType;
  /// نص الرسالة المرافقة للهدية.
  final String? giftMessage;

  factory ProfileLike.fromJson(Map<String, dynamic> json) {
    return ProfileLike(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      itemId: json['item_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      giftType: json['gift_type'] as String?,
      giftMessage: json['gift_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'item_id': itemId,
      'created_at': createdAt?.toIso8601String(),
      'gift_type': giftType,
      'gift_message': giftMessage,
    };
  }
}
