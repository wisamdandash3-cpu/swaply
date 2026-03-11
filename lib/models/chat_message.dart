/// رسالة دردشة محفوظة (من Supabase).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.photoUrl,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToPhotoUrl,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  /// رابط الصورة إن كانت الرسالة مرسلة على صورة (من الاكتشاف).
  final String? photoUrl;
  /// معرّف الرسالة المُرد عليها (إن وُجدت).
  final String? replyToId;
  /// نص الرسالة المُقتبسة للعرض داخل فقاعة الرد.
  final String? replyToContent;
  /// معرّف مرسل الرسالة المُقتبسة (لعرض "أنت" أو اسم الشريك).
  final String? replyToSenderId;
  /// نوع الهدية المُرد عليها (rose_gift / ring_gift / coffee_gift) لعرض أيقونة الهدية في الرد.
  final String? replyToPhotoUrl;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      photoUrl: json['photo_url'] as String?,
      replyToId: json['reply_to_id'] as String?,
      replyToContent: json['reply_to_content'] as String?,
      replyToSenderId: json['reply_to_sender_id'] as String?,
      replyToPhotoUrl: json['reply_to_photo_url'] as String?,
    );
  }
}
