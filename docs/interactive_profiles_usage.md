# Interactive Profiles — الاستخدام

## الفكرة
مثل Hinge: المستخدم يعجب **بعنصر محدد** (صورة أو إجابة سؤال) وليس البروفايل كاملاً. الطرف الآخر يرى بالضبط ما الذي أُعجب به عبر `item_id`.

## قاعدة البيانات (Supabase)

- **profile_questions**: أسئلة البروفايل (نص عربي/إنجليزي/ألماني).
- **profile_answers**: كل صف = عنصر واحد (سؤال+جواب نصي أو صورة) وله `id`.
- **profile_likes**: عند الإعجاب يُخزَّن `from_user_id`, `to_user_id`, **item_id** (مرجع لـ `profile_answers.id`).

تشغيل الـ migration:
```bash
supabase db push
# أو نسخ محتوى supabase/migrations/001_interactive_profiles.sql وتنفيذه من لوحة Supabase.
```

## من واجهة التطبيق

عند عرض بروفايل، كل بطاقة (صورة أو سؤال/جواب) يجب أن تعرض زر إعجاب مرتبط بـ `item_id` ذلك العنصر:

```dart
// مثال: عرض عنصر بروفايل مع زر إعجاب
ProfileAnswer answer = ...; // من profile_answers
final likeService = ProfileLikeService();

// زر الإعجاب يرسل item_id
ElevatedButton(
  onPressed: () async {
    await likeService.likeItem(
      toUserId: answer.profileId,
      itemId: answer.id,  // ← هذا يحدد الصورة أو النص المُعجَب به
    );
  },
  child: Text('Like this'),
)
```

عند استقبال الإعجابات، استخدم `ProfileLikeService.getIncomingLikes()` ثم اعرض لكل like الـ `item_id` واربطه بعنصر البروفايل لعرض "أعجب بـ [هذه الصورة/هذا الجواب]".
