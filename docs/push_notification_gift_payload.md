# Push Notification — وصول هدية (Gift Received)

عند إرسال مستخدم هدية (وردة/خاتم/قهوة) مع رسالة، يجب إرسال إشعار فوري للمستلم حتى لا ينتظر فتح التطبيق.

## نص الإشعار (مترجم)

- **العربية:** "لقد أرسل لك [الاسم] هدية (خاتم 💍) مع رسالة خاصة.. افتح لترى ماذا قال!"
- **English:** "[Name] sent you a gift (Ring 💍) with a private message.. Open to see what they said!"
- **Deutsch:** "[Name] hat dir ein Geschenk (Ring 💍) mit einer privaten Nachricht geschickt.. Öffne, um zu sehen, was sie gesagt haben!"

## قيم نوع الهدية للعرض في النص

| gift_type (DB) | عرض عربي | عرض EN | إيموجي |
|---------------|----------|--------|--------|
| rose_gift     | وردة     | Rose   | 🌹     |
| ring_gift     | خاتم     | Ring   | 💍     |
| coffee_gift   | قهوة     | Coffee | ☕     |

## حمولة الإشعار المقترحة (FCM / OneSignal / إلخ)

```json
{
  "title": "هدية جديدة",
  "body": "لقد أرسل لك [sender_name] هدية ([gift_label]) مع رسالة خاصة.. افتح لترى ماذا قال!",
  "data": {
    "type": "gift_received",
    "from_user_id": "<uuid>",
    "gift_type": "ring_gift",
    "gift_message": "..."
  }
}
```

- عند الضغط على الإشعار: فتح التطبيق وإظهار شاشة "وصلك شعور جاد" (GiftReceivedOverlay) أو فتح المحادثة مع المرسل.
- يمكن تنفيذ الإشعار عبر Supabase Edge Function تُستدعى بعد إدراج سجل في `profile_likes` (عند وجود `gift_type`)، أو عبر Trigger في قاعدة البيانات يرسل طلباً لخدمة الإشعارات.
