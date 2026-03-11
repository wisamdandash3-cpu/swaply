// ignore_for_file: lines_longer_than_80_chars

/// نصوص شروط الاستخدام وسياسة الخصوصية (متوافقة مع GDPR).
/// تُرجع الإنجليزية لكل اللغات غير المدعومة.
String getTermsOfUseContent(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return termsOfUseAr;
    case 'fr':
      return termsOfUseFr;
    case 'es':
      return termsOfUseEs;
    case 'de':
      return termsOfUseDe;
    case 'pt':
    case 'zh':
    case 'ja':
    case 'ru':
    case 'tr':
    case 'id':
    case 'hi':
      return termsOfUseEn;
    default:
      return termsOfUseEn;
  }
}

String getPrivacyPolicyContent(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return privacyPolicyAr;
    case 'fr':
      return privacyPolicyFr;
    case 'es':
      return privacyPolicyEs;
    case 'de':
      return privacyPolicyDe;
    case 'pt':
    case 'zh':
    case 'ja':
    case 'ru':
    case 'tr':
    case 'id':
    case 'hi':
      return privacyPolicyEn;
    default:
      return privacyPolicyEn;
  }
}

String getSafeDatingTipsContent(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return safeDatingTipsAr;
    case 'pt':
    case 'zh':
    case 'ja':
    case 'ru':
    case 'tr':
    case 'id':
    case 'hi':
      return safeDatingTipsEn;
    default:
      return safeDatingTipsEn;
  }
}

String getMemberPrinciplesContent(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return memberPrinciplesAr;
    case 'pt':
    case 'zh':
    case 'ja':
    case 'ru':
    case 'tr':
    case 'id':
    case 'hi':
      return memberPrinciplesEn;
    default:
      return memberPrinciplesEn;
  }
}

// ———————————————————————————————————————————————————————————————————————————
// TERMS OF USE — ENGLISH (GDPR-oriented, eligibility, data, account deletion)
// ———————————————————————————————————————————————————————————————————————————

const String termsOfUseEn = r'''
SWAPLY — TERMS OF USE

Last updated: 2025

1. ACCEPTANCE OF TERMS

By downloading, accessing or using the Swaply application and related services ("Service"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree, do not use the Service. We may update these Terms; continued use after changes constitutes acceptance.

2. ELIGIBILITY

You must be at least 18 years of age (or the age of legal majority in your jurisdiction, whichever is higher) to use Swaply. By using the Service, you represent and warrant that you meet this age requirement and have the legal capacity to enter into a binding agreement. We may request proof of age and reserve the right to suspend or terminate accounts that do not meet eligibility requirements. The Service is not intended for minors under any circumstances.

3. DESCRIPTION OF SERVICE

Swaply is a dating and social connection application that allows users to create profiles, answer profile questions, discover other users, express interest ("like"), and communicate when there is a mutual match. The Service may change over time; we do not guarantee specific features or availability.

4. ACCOUNT REGISTRATION AND DATA

To use the Service you must register an account. You agree to provide accurate and complete information, including a valid email address and any profile answers or content you submit. You are responsible for keeping your login credentials secure and for all activity under your account. We collect and process personal data as described in our Privacy Policy, in compliance with applicable law including the General Data Protection Regulation (GDPR) where applicable.

5. USER CONDUCT

You agree not to: (a) use the Service for any illegal purpose or in violation of any laws; (b) harass, abuse, threaten, or harm others; (c) impersonate any person or entity; (d) post false, misleading, or offensive content; (e) scrape, automate access, or attempt to gain unauthorized access to the Service or other users' data; (f) use the Service for commercial purposes without our written consent. We may remove content and suspend or terminate accounts for breach of these rules.

6. INTELLECTUAL PROPERTY

The Service, including its design, text, graphics, and software, is owned by us or our licensors. You do not acquire any right to our trademarks or content except a limited right to use the Service in accordance with these Terms.

7. PRIVACY AND DATA PROTECTION

Your use of the Service is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal data, including email addresses and profile answers, and how you can exercise your rights under the GDPR and other laws. By using the Service you consent to such processing.

8. ACCOUNT SUSPENSION AND TERMINATION

We may suspend or terminate your account at any time for violation of these Terms or for any other reason at our discretion. You may close your account at any time through the in-app settings or by contacting us. Upon account closure or termination, we will handle your data as set out in our Privacy Policy (including deletion or retention where required by law).

9. DISCLAIMER OF WARRANTIES

The Service is provided "as is" and "as available" without warranties of any kind, express or implied. We do not warrant that the Service will be uninterrupted, error-free, or free of harmful components.

10. LIMITATION OF LIABILITY

To the maximum extent permitted by law, we and our affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or for any loss of data, revenue, or goodwill, arising from your use or inability to use the Service.

11. GOVERNING LAW AND DISPUTES

These Terms are governed by the laws of the jurisdiction in which we operate, without regard to conflict of law principles. Any disputes shall be resolved in the courts of that jurisdiction, except where prohibited; EU consumers may also use EU dispute resolution mechanisms.

12. CONTACT

For questions about these Terms or the Service, contact us at the support email or address provided in the application or on our website.
''';

// ———————————————————————————————————————————————————————————————————————————
// TERMS OF USE — ARABIC
// ———————————————————————————————————————————————————————————————————————————

const String termsOfUseAr = r'''
سوابلي — شروط الاستخدام

آخر تحديث: 2025

1. قبول الشروط

بتحميل تطبيق سوابلي أو الوصول إليه أو استخدامه والخدمات المرتبطة به ("الخدمة")، فإنك توافق على الالتزام بشروط الاستخدام هذه ("الشروط"). إذا كنت لا توافق، لا تستخدم الخدمة. قد نحدّث هذه الشروط؛ واستمرارك في الاستخدام بعد التعديلات يُعد قبولاً بها.

2. الأهلية

يجب أن يكون عمرك 18 عاماً على الأقل (أو سن الرشد القانوني في بلدك، أيهما أعلى) لاستخدام سوابلي. باستخدامك الخدمة، فإنك تُقر وتضمن أنك تستوفي شرط العمر هذا ولديك الأهلية القانونية لإبرام اتفاق ملزم. قد نطلب إثبات العمر ونحتفظ بحق تعليق الحسابات أو إنهاؤها عند عدم استيفاء متطلبات الأهلية. الخدمة غير مخصصة للقاصرين تحت أي ظرف.

3. وصف الخدمة

سوابلي تطبيق مواعدة وتواصل اجتماعي يتيح للمستخدمين إنشاء ملفات شخصية، والإجابة على أسئلة الملف، واكتشاف مستخدمين آخرين، والتعبير عن الاهتمام ("إعجاب")، والتواصل عند وجود تطابق متبادل. قد تتغير الخدمة مع الزمن؛ ولا نضمن ميزات أو توفراً معيناً.

4. تسجيل الحساب والبيانات

لاستخدام الخدمة يجب تسجيل حساب. أنت توافق على تقديم معلومات دقيقة وكاملة، بما في ذلك بريد إلكتروني صالح وأي إجابات أو محتوى تقدمه في الملف. أنت مسؤول عن حفظ بيانات الدخول وأمنها وعن كل النشاط تحت حسابك. نجمع ونعالج البيانات الشخصية كما هو موضح في سياسة الخصوصية، وفقاً للقانون المعمول به بما في ذلك اللائحة العامة لحماية البيانات (GDPR) حيثما ينطبق.

5. سلوك المستخدم

أنت توافق على عدم: (أ) استخدام الخدمة لأي غرض غير قانوني أو خرق أي قوانين؛ (ب) مضايقة أو إساءة أو تهديد أو إيذاء الآخرين؛ (ج) انتحال شخصية أي شخص أو كيان؛ (د) نشر محتوى كاذب أو مضلل أو مسيء؛ (هـ) استخراج البيانات أو الوصول الآلي أو محاولة الوصول غير المصرح به إلى الخدمة أو بيانات المستخدمين الآخرين؛ (و) استخدام الخدمة لأغراض تجارية دون موافقتنا الخطية. قد نحذف المحتوى ونعلق الحسابات أو ننهيها عند خرق هذه القواعد.

6. الملكية الفكرية

الخدمة، بما في ذلك تصميمها ونصوصها ورسوماتها وبرمجياتها، مملوكة لنا أو لمرخصينا. أنت لا تكتسب أي حق في علاماتنا التجارية أو محتوانا إلا حقاً محدوداً لاستخدام الخدمة وفقاً لهذه الشروط.

7. الخصوصية وحماية البيانات

استخدامك للخدمة يخضع أيضاً لسياسة الخصوصية الخاصة بنا، التي تصف كيفية جمعنا واستخدامنا وحمايتنا لبياناتك الشخصية، بما في ذلك عناوين البريد الإلكتروني وإجابات الملف الشخصي، وكيفية ممارسة حقوقك بموجب اللائحة العامة لحماية البيانات والقوانين الأخرى. باستخدامك الخدمة فإنك توافق على هذه المعالجة.

8. تعليق الحساب وإنهاؤه

قد نعلق حسابك أو ننهيه في أي وقت بسبب خرق هذه الشروط أو لأي سبب آخر وفق تقديرنا. يمكنك إغلاق حسابك في أي وقت من خلال إعدادات التطبيق أو بالاتصال بنا. عند إغلاق الحساب أو إنهائه، سنتعامل مع بياناتك كما هو منصوص عليه في سياسة الخصوصية (بما في ذلك الحذف أو الاحتفاظ حيث يقتضي القانون).

9. إخلاء المسؤولية عن الضمانات

تُقدّم الخدمة "كما هي" و"حسب التوفر" دون ضمانات من أي نوع، صريحة أو ضمنية. لا نضمن أن الخدمة ستكون دون انقطاع أو أخطاء أو مكونات ضارة.

10. تحديد المسؤولية

في أقصى حد يسمح به القانون، نحن والجهات التابعة لنا غير مسؤولين عن أي أضرار غير مباشرة أو عرضية أو خاصة أو تبعية أو عقابية، أو عن أي فقدان للبيانات أو الإيرادات أو السمعة، الناتجة عن استخدامك أو عدم قدرتك على استخدام الخدمة.

11. القانون الحاكم والمنازعات

تخضع هذه الشروط لقوانين الولاية القضائية التي نعمل فيها، دون اعتبار لمبادئ تنازع القوانين. تُحل أي منازعات في محاكم تلك الولاية، إلا حيثما يُمنع؛ وقد يستخدم المستهلكون في الاتحاد الأوروبي أيضاً آليات حل النزاعات في الاتحاد الأوروبي.

12. الاتصال

للاستفسارات حول هذه الشروط أو الخدمة، تواصل معنا على البريد الإلكتروني أو العنوان المقدم في التطبيق أو على موقعنا.
''';

// ———————————————————————————————————————————————————————————————————————————
// PRIVACY POLICY — ENGLISH (GDPR: legal basis, data, rights, retention, deletion)
// ———————————————————————————————————————————————————————————————————————————

const String privacyPolicyEn = r'''
SWAPLY — PRIVACY POLICY

Last updated: 2025

1. INTRODUCTION

Swaply ("we", "our", "us") operates the Swaply dating and social connection application. This Privacy Policy explains how we collect, use, store, and protect your personal data, and how you can exercise your rights. We process data in accordance with the EU General Data Protection Regulation (GDPR) and other applicable data protection laws.

2. DATA CONTROLLER

The data controller responsible for your personal data is the entity operating the Swaply service, as indicated in the application or on our website. You may contact us or our data protection officer (where designated) for any request related to your data.

3. LEGAL BASIS FOR PROCESSING (GDPR)

We process your personal data only where we have a lawful basis:
• Contract: processing necessary to provide the Service (e.g. account creation, matching, communication).
• Consent: where you have given clear consent (e.g. for optional features or marketing).
• Legitimate interests: for security, fraud prevention, and improving our Service, where not overridden by your rights.
• Legal obligation: where processing is required by law.

4. DATA WE COLLECT

4.1 Account and identification
• Email address (required for registration and account recovery).
• Authentication data (e.g. identifiers from sign-in providers if you use Apple, Google, or phone sign-in).

4.2 Profile and preferences
• Profile answers you provide during onboarding or in your profile (e.g. answers to questions about what you are looking for, how you describe yourself, what matters to you, and other profile questions). These may include sensitive information such as relationship preferences; we process them only as necessary to provide the Service and as permitted by law.

4.3 Usage and technical data
• Log data (e.g. IP address, device type, app version).
• Usage data (e.g. how you use the app, matches, likes) to operate and improve the Service.

5. HOW WE USE YOUR DATA

We use your data to: provide and maintain the Service; create and manage your account; show you relevant profiles and enable matching; communicate with you about the Service; ensure security and prevent abuse; comply with legal obligations; and, where you have consented, send marketing. We do not sell your personal data to third parties.

6. DATA RETENTION

We retain your data only as long as necessary for the purposes set out in this policy or as required by law. If you close your account, we will delete or anonymise your personal data within a reasonable period, except where we must retain it for legal, regulatory, or legitimate operational reasons (e.g. dispute resolution, security). Profile and account data are deleted in accordance with our account closure process.

7. YOUR RIGHTS (GDPR AND SIMILAR LAWS)

You have the right to:
• Access: request a copy of your personal data we hold.
• Rectification: request correction of inaccurate or incomplete data.
• Erasure: request deletion of your data ("right to be forgotten"), subject to legal exceptions.
• Restriction: request restriction of processing in certain circumstances.
• Data portability: receive your data in a structured, machine-readable format where applicable.
• Object: object to processing based on legitimate interests or for direct marketing.
• Withdraw consent: where processing is based on consent, you may withdraw it at any time.
• Lodge a complaint: with a supervisory authority in your country (e.g. in the EU, your national data protection authority).

To exercise these rights, use the in-app options (e.g. account settings, delete account) or contact us. We will respond within the time limits set by applicable law (e.g. one month under GDPR).

8. ACCOUNT DELETION

You may close your account and request deletion of your data at any time via the application settings or by contacting support. Upon account closure, we will delete or anonymise your personal data as described in Section 6, except where retention is required by law. Deletion may take a short period to propagate through our systems.

9. DATA SHARING AND RECIPIENTS

We may share data with: service providers that assist us (e.g. hosting, analytics), who are bound by confidentiality and data protection obligations; law enforcement or public authorities when required by law; or other parties only with your consent or as described in this policy. We do not sell your data. If we transfer data outside the European Economic Area, we ensure appropriate safeguards (e.g. standard contractual clauses) where required.

10. SECURITY

We implement technical and organisational measures to protect your data against unauthorised access, loss, or alteration. No system is completely secure; we encourage you to use a strong password and keep your account details safe.

11. CHILDREN

The Service is not intended for users under 18 (or the applicable age of majority). We do not knowingly collect data from minors. If you believe we have collected data from a minor, please contact us so we can delete it.

12. CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of material changes via the app or by email where appropriate. Continued use after changes constitutes acceptance.

13. CONTACT

For any request or question about this Privacy Policy or your personal data, please contact us at the support email or address provided in the application or on our website. If we have designated a data protection officer, their contact details will be indicated there.
''';

// ———————————————————————————————————————————————————————————————————————————
// PRIVACY POLICY — ARABIC
// ———————————————————————————————————————————————————————————————————————————

const String privacyPolicyAr = r'''
سوابلي — سياسة الخصوصية

آخر تحديث: 2025

1. المقدمة

تدير سوابلي ("نحن"، "خاصتنا"، "نا") تطبيق المواعدة والتواصل الاجتماعي سوابلي. توضح سياسة الخصوصية هذه كيفية جمعنا واستخدامنا وتخزيننا وحمايتنا لبياناتك الشخصية، وكيفية ممارسة حقوقك. نعالج البيانات وفقاً للائحة العامة لحماية البيانات في الاتحاد الأوروبي (GDPR) وقوانين حماية البيانات المعمول بها الأخرى.

2. مسؤول التحكم في البيانات

مسؤول التحكم في بياناتك الشخصية هو الكيان الذي يشغل خدمة سوابلي، كما هو موضح في التطبيق أو على موقعنا. يمكنك الاتصال بنا أو بمسؤول حماية البيانات (إن وُجد) لأي طلب يتعلق ببياناتك.

3. الأساس القانوني للمعالجة (GDPR)

نحن نعالج بياناتك الشخصية فقط عندما يكون لدينا أساس قانوني:
• العقد: المعالجة اللازمة لتقديم الخدمة (مثل إنشاء الحساب، المطابقات، التواصل).
• الموافقة: عندما تكون قد أعطيت موافقة صريحة (مثل الميزات الاختيارية أو التسويق).
• المصالح المشروعة: للأمان، ومنع الاحتيال، وتحسين خدمتنا، عندما لا تتجاوزها حقوقك.
• الالتزام القانوني: عندما تكون المعالجة مطلوبة بموجب القانون.

4. البيانات التي نجمعها

4.1 الحساب والتعريف
• عنوان البريد الإلكتروني (مطلوب للتسجيل واسترداد الحساب).
• بيانات المصادقة (مثل المعرفات من مزودي تسجيل الدخول إذا كنت تستخدم تسجيل الدخول عبر Apple أو Google أو الهاتف).

4.2 الملف الشخصي والتفضيلات
• إجابات الملف الشخصي التي تقدمها أثناء الإعداد أو في ملفك (مثل إجابات الأسئلة حول ما تبحث عنه، كيف تصف نفسك، ما الذي يهمك، وأسئلة الملف الأخرى). قد تتضمن معلومات حساسة مثل تفضيلات العلاقات؛ نعالجها فقط كما هو ضروري لتقديم الخدمة وبما يسمح به القانون.

4.3 بيانات الاستخدام والتقنية
• بيانات السجل (مثل عنوان IP، نوع الجهاز، إصدار التطبيق).
• بيانات الاستخدام (مثل كيفية استخدامك للتطبيق، المطابقات، الإعجابات) لتشغيل الخدمة وتحسينها.

5. كيف نستخدم بياناتك

نستخدم بياناتك من أجل: تقديم الخدمة والحفاظ عليها؛ إنشاء حسابك وإدارته؛ عرض ملفات ذات صلة وتمكين المطابقة؛ التواصل معك بخصوص الخدمة؛ ضمان الأمان ومنع إساءة الاستخدام؛ الامتثال للالتزامات القانونية؛ وإذا وافقت، إرسال التسويق. نحن لا نبيع بياناتك الشخصية لأطراف ثالثة.

6. الاحتفاظ بالبيانات

نحتفظ ببياناتك فقط طالما كان ذلك ضرورياً للأغراض المحددة في هذه السياسة أو كما يقتضي القانون. إذا أغلقت حسابك، سنحذف بياناتك الشخصية أو نُخفي هويتها خلال فترة معقولة، إلا حيث يجب أن نحتفظ بها لأسباب قانونية أو تنظيمية أو تشغيلية مشروعة (مثل حل النزاعات، الأمان). يتم حذف بيانات الملف والحساب وفقاً لعملية إغلاق الحساب.

7. حقوقك (GDPR والقوانين المماثلة)

لديك الحق في:
• الوصول: طلب نسخة من بياناتك الشخصية التي نحتفظ بها.
• التصحيح: طلب تصحيح البيانات غير الدقيقة أو غير الكاملة.
• المحو: طلب حذف بياناتك ("الحق في النسيان")، مع مراعاة الاستثناءات القانونية.
• التقييد: طلب تقييد المعالجة في ظروف معينة.
• قابلية نقل البيانات: استلام بياناتك بتنسيق منظم قابل للقراءة آلياً حيثما ينطبق.
• الاعتراض: الاعتراض على المعالجة القائمة على المصالح المشروعة أو للتسويق المباشر.
• سحب الموافقة: عندما تكون المعالجة قائمة على الموافقة، يمكنك سحبها في أي وقت.
• تقديم شكوى: إلى سلطة رقابة في بلدك (مثل سلطة حماية البيانات الوطنية في الاتحاد الأوروبي).

لممارسة هذه الحقوق، استخدم الخيارات داخل التطبيق (مثل إعدادات الحساب، حذف الحساب) أو تواصل معنا. سنرد ضمن الحدود الزمنية التي يحددها القانون المعمول به (مثل شهر واحد بموجب GDPR).

8. حذف الحساب

يمكنك إغلاق حسابك وطلب حذف بياناتك في أي وقت عبر إعدادات التطبيق أو بالاتصال بالدعم. عند إغلاق الحساب، سنحذف بياناتك الشخصية أو نُخفي هويتها كما هو موضح في القسم 6، إلا حيث يتطلب القانون الاحتفاظ بها. قد يستغرق الحذف فترة قصيرة للانتشار عبر أنظمتنا.

9. مشاركة البيانات والمستلمون

قد نشارك البيانات مع: مزودي الخدمات الذين يساعدوننا (مثل الاستضافة، التحليلات)، والملتزمين بسرية والتزامات حماية البيانات؛ إنفاذ القانون أو السلطات العامة عندما يقتضي القانون ذلك؛ أو أطراف أخرى فقط بموافقتك أو كما هو موضح في هذه السياسة. نحن لا نبيع بياناتك. إذا نُقلت البيانات خارج المنطقة الاقتصادية الأوروبية، نضمن الضمانات المناسبة (مثل البنود التعاقدية القياسية) حيثما يلزم.

10. الأمان

ننفذ تدابير تقنية وتنظيمية لحماية بياناتك من الوصول غير المصرح به أو الفقدان أو التغيير. لا يوجد نظام آمن بالكامل؛ نشجعك على استخدام كلمة مرور قوية والحفاظ على تفاصيل حسابك.

11. الأطفال

الخدمة غير مخصصة للمستخدمين دون 18 (أو سن الرشد المعمول به). نحن لا نجمع بيانات القاصرين عن قصد. إذا كنت تعتقد أننا جمعنا بيانات من قاصر، يرجى الاتصال بنا حتى نتمكن من حذفها.

12. التغييرات على هذه السياسة

قد نحدّث سياسة الخصوصية هذه من وقت لآخر. سنعلمك بالتغييرات الجوهرية عبر التطبيق أو بالبريد الإلكتروني حيثما يكون ذلك مناسباً. استمرارك في الاستخدام بعد التغييرات يُعد قبولاً.

13. الاتصال

لأي طلب أو سؤال حول سياسة الخصوصية هذه أو بياناتك الشخصية، يرجى الاتصال بنا على البريد الإلكتروني أو العنوان المقدم في التطبيق أو على موقعنا. إذا كنا قد عيّنا مسؤول حماية البيانات، فستُشار إلى تفاصيل الاتصال به هناك.
''';

// ———————————————————————————————————————————————————————————————————————————
// TERMS OF USE — FRENCH (GDPR, eligibility, data, account deletion)
// ———————————————————————————————————————————————————————————————————————————

const String termsOfUseFr = r'''
SWAPLY — CONDITIONS D'UTILISATION

Dernière mise à jour : 2025

1. ACCEPTATION DES CONDITIONS

En téléchargeant, en accédant ou en utilisant l'application Swaply et les services associés (« Service »), vous acceptez d'être lié par ces conditions d'utilisation (« Conditions »). Si vous n'acceptez pas, n'utilisez pas le Service. Nous pouvons modifier ces Conditions ; une utilisation continue après modification vaut acceptation.

2. ÉLIGIBILITÉ

Vous devez avoir au moins 18 ans (ou l'âge de la majorité légale dans votre juridiction, le plus élevé étant retenu) pour utiliser Swaply. En utilisant le Service, vous déclarez et garantissez que vous remplissez cette condition d'âge et avez la capacité juridique de conclure un accord contraignant. Nous pouvons demander une preuve d'âge et nous nous réservons le droit de suspendre ou de résilier les comptes qui ne respectent pas les conditions d'éligibilité. Le Service n'est en aucun cas destiné aux mineurs.

3. DESCRIPTION DU SERVICE

Swaply est une application de rencontres et de connexion sociale permettant aux utilisateurs de créer des profils, de répondre à des questions de profil, de découvrir d'autres utilisateurs, d'exprimer leur intérêt (« like ») et de communiquer en cas de correspondance mutuelle. Le Service peut évoluer ; nous ne garantissons pas des fonctionnalités ou une disponibilité spécifiques.

4. INSCRIPTION ET DONNÉES DU COMPTE

Pour utiliser le Service, vous devez créer un compte. Vous acceptez de fournir des informations exactes et complètes, notamment une adresse e-mail valide et toute réponse ou contenu de profil que vous soumettez. Vous êtes responsable de la confidentialité de vos identifiants et de toute activité sous votre compte. Nous collectons et traitons les données personnelles comme décrit dans notre Politique de confidentialité, conformément au droit applicable, notamment au Règlement général sur la protection des données (RGPD) lorsqu'il s'applique.

5. COMPORTEMENT DE L'UTILISATEUR

Vous vous engagez à ne pas : (a) utiliser le Service à des fins illégales ou en violation des lois ; (b) harceler, abuser, menacer ou nuire à autrui ; (c) usurper l'identité d'une personne ou d'une entité ; (d) publier un contenu faux, trompeur ou offensant ; (e) extraire des données, accéder de manière automatisée ou tenter d'accéder sans autorisation au Service ou aux données d'autres utilisateurs ; (f) utiliser le Service à des fins commerciales sans notre consentement écrit. Nous pouvons supprimer du contenu et suspendre ou résilier des comptes en cas de violation.

6. PROPRIÉTÉ INTELLECTUELLE

Le Service, y compris sa conception, textes, graphismes et logiciels, est la propriété de nous ou de nos concédants de licence. Vous n'acquérez aucun droit sur nos marques ou notre contenu, sauf un droit limité d'utilisation du Service conformément à ces Conditions.

7. CONFIDENTIALITÉ ET PROTECTION DES DONNÉES

Votre utilisation du Service est également régie par notre Politique de confidentialité, qui décrit comment nous collectons, utilisons et protégeons vos données personnelles (notamment adresses e-mail et réponses de profil) et comment vous pouvez exercer vos droits au titre du RGPD et d'autres lois. En utilisant le Service, vous consentez à ce traitement.

8. SUSPENSION ET RÉSILIATION DU COMPTE

Nous pouvons suspendre ou résilier votre compte à tout moment en cas de violation de ces Conditions ou pour toute autre raison à notre discrétion. Vous pouvez fermer votre compte à tout moment via les paramètres de l'application ou en nous contactant. Lors de la fermeture ou de la résiliation du compte, nous traiterons vos données comme indiqué dans notre Politique de confidentialité (y compris suppression ou conservation lorsque la loi l'exige).

9. EXCLUSION DE GARANTIES

Le Service est fourni « tel quel » et « selon disponibilité » sans garantie d'aucune sorte, expresse ou implicite. Nous ne garantissons pas que le Service sera ininterrompu, exempt d'erreurs ou de composants nuisibles.

10. LIMITATION DE RESPONSABILITÉ

Dans la mesure maximale permise par la loi, nous et nos affiliés ne serons pas responsables des dommages indirects, accessoires, spéciaux, consécutifs ou punitifs, ni de toute perte de données, de revenus ou de réputation résultant de votre utilisation ou de votre incapacité à utiliser le Service.

11. DROIT APPLICABLE ET LITIGES

Ces Conditions sont régies par les lois de la juridiction dans laquelle nous opérons. Tout litige sera résolu devant les tribunaux de cette juridiction, sauf interdiction ; les consommateurs de l'UE peuvent également utiliser les mécanismes de résolution des litiges de l'UE.

12. CONTACT

Pour toute question concernant ces Conditions ou le Service, contactez-nous à l'adresse e-mail ou postale indiquée dans l'application ou sur notre site web.
''';

// ———————————————————————————————————————————————————————————————————————————
// TERMS OF USE — SPANISH
// ———————————————————————————————————————————————————————————————————————————

const String termsOfUseEs = r'''
SWAPLY — TÉRMINOS DE USO

Última actualización: 2025

1. ACEPTACIÓN DE LOS TÉRMINOS

Al descargar, acceder o utilizar la aplicación Swaply y los servicios relacionados (« Servicio »), usted acepta quedar vinculado por estos Términos de uso (« Términos »). Si no está de acuerdo, no utilice el Servicio. Podemos actualizar estos Términos; el uso continuado tras los cambios constituye aceptación.

2. ELEGIBILIDAD

Debe tener al menos 18 años (o la edad de mayoría legal en su jurisdicción, la que sea mayor) para usar Swaply. Al usar el Servicio, declara y garantiza que cumple este requisito de edad y tiene capacidad legal para celebrar un acuerdo vinculante. Podemos solicitar prueba de edad y nos reservamos el derecho de suspender o dar de baja cuentas que no cumplan los requisitos. El Servicio no está dirigido a menores en ningún caso.

3. DESCRIPCIÓN DEL SERVICIO

Swaply es una aplicación de citas y conexión social que permite crear perfiles, responder a preguntas de perfil, descubrir a otros usuarios, expresar interés (« like ») y comunicarse cuando hay un match mutuo. El Servicio puede cambiar; no garantizamos funciones o disponibilidad concretas.

4. REGISTRO Y DATOS DE LA CUENTA

Para usar el Servicio debe registrarse. Acepta proporcionar información veraz y completa, incluido un correo electrónico válido y las respuestas o el contenido de perfil que envíe. Es responsable de mantener seguras sus credenciales y de toda la actividad en su cuenta. Recogemos y tratamos datos personales según nuestra Política de privacidad, en cumplimiento de la ley aplicable, incluido el Reglamento general de protección de datos (RGPD) cuando corresponda.

5. CONDUCTA DEL USUARIO

Acepta no: (a) usar el Servicio con fines ilegales o en violación de leyes; (b) acosar, abusar, amenazar o dañar a otros; (c) suplantar a personas o entidades; (d) publicar contenido falso, engañoso u ofensivo; (e) rastrear datos, acceder de forma automatizada o intentar acceder sin autorización al Servicio o a datos de otros usuarios; (f) usar el Servicio con fines comerciales sin nuestro consentimiento por escrito. Podemos eliminar contenido y suspender o dar de baja cuentas por incumplimiento.

6. PROPIEDAD INTELECTUAL

El Servicio, incluido su diseño, textos, gráficos y software, es propiedad nuestra o de nuestros licenciantes. No adquiere ningún derecho sobre nuestras marcas o contenido, salvo un derecho limitado a usar el Servicio conforme a estos Términos.

7. PRIVACIDAD Y PROTECCIÓN DE DATOS

El uso del Servicio se rige también por nuestra Política de privacidad, que describe cómo recogemos, usamos y protegemos sus datos personales (incluidos correo electrónico y respuestas de perfil) y cómo puede ejercer sus derechos bajo el RGPD y otras leyes. Al usar el Servicio consiente dicho tratamiento.

8. SUSPENSIÓN Y CESE DE LA CUENTA

Podemos suspender o dar de baja su cuenta en cualquier momento por incumplimiento de estos Términos o por cualquier otro motivo a nuestra discreción. Puede cerrar su cuenta en cualquier momento desde la configuración de la aplicación o contactándonos. Al cerrar o dar de baja la cuenta, trataremos sus datos según nuestra Política de privacidad (incluida supresión o conservación cuando la ley lo exija).

9. EXENCIÓN DE GARANTÍAS

El Servicio se proporciona « tal cual » y « según disponibilidad » sin garantías de ningún tipo, expresas o implícitas. No garantizamos que el Servicio sea ininterrumpido, exento de errores o de componentes nocivos.

10. LIMITACIÓN DE RESPONSABILIDAD

En la máxima medida permitida por la ley, nosotros y nuestros afiliados no seremos responsables de daños indirectos, incidentales, especiales, consecuentes o punitivos, ni de pérdida de datos, ingresos o reputación, derivados de su uso o imposibilidad de usar el Servicio.

11. LEY APLICABLE Y DISPUTAS

Estos Términos se rigen por las leyes de la jurisdicción en que operamos. Cualquier disputa se resolverá en los tribunales de dicha jurisdicción, salvo prohibición; los consumidores de la UE también pueden usar los mecanismos de resolución de disputas de la UE.

12. CONTACTO

Para preguntas sobre estos Términos o el Servicio, contáctenos en el correo o dirección indicados en la aplicación o en nuestro sitio web.
''';

// ———————————————————————————————————————————————————————————————————————————
// TERMS OF USE — GERMAN
// ———————————————————————————————————————————————————————————————————————————

const String termsOfUseDe = r'''
SWAPLY — NUTZUNGSBEDINGUNGEN

Zuletzt aktualisiert: 2025

1. ANNAHME DER BEDINGUNGEN

Durch das Herunterladen, Zugreifen auf oder Nutzen der Swaply-Anwendung und zugehöriger Dienste (« Dienst ») erklären Sie sich mit diesen Nutzungsbedingungen (« Bedingungen ») einverstanden. Wenn Sie nicht einverstanden sind, nutzen Sie den Dienst nicht. Wir können diese Bedingungen aktualisieren; fortgesetzte Nutzung nach Änderungen gilt als Annahme.

2. VORAUSSETZUNGEN

Sie müssen mindestens 18 Jahre alt sein (oder das gesetzliche Mindestalter in Ihrem Land), um Swaply zu nutzen. Mit der Nutzung des Dienstes versichern Sie, dass Sie diese Altersanforderung erfüllen und die rechtliche Handlungsfähigkeit haben, einen verbindlichen Vertrag zu schließen. Wir können einen Altersnachweis verlangen und behalten uns vor, Konten zu sperren oder zu kündigen, die die Voraussetzungen nicht erfüllen. Der Dienst ist in keinem Fall für Minderjährige bestimmt.

3. BESCHREIBUNG DES DIENSTES

Swaply ist eine Dating- und Social-Connection-App, mit der Nutzer Profile erstellen, Profilfragen beantworten, andere Nutzer entdecken, Interesse ausdrücken (« Like ») und bei gegenseitigem Match kommunizieren können. Der Dienst kann sich ändern; wir garantieren keine bestimmten Funktionen oder Verfügbarkeit.

4. KONTOREGISTRIERUNG UND DATEN

Zur Nutzung des Dienstes müssen Sie ein Konto anlegen. Sie verpflichten sich, wahrheitsgemäße und vollständige Angaben zu machen, einschließlich einer gültigen E-Mail-Adresse und aller Profilantworten oder Inhalte. Sie sind für die Sicherheit Ihrer Anmeldedaten und alle Aktivitäten unter Ihrem Konto verantwortlich. Wir erheben und verarbeiten personenbezogene Daten wie in unserer Datenschutzrichtlinie beschrieben, in Übereinstimmung mit dem geltenden Recht, einschließlich der DSGVO, soweit anwendbar.

5. NUTZERVERHALTEN

Sie verpflichten sich, den Dienst nicht (a) für illegale Zwecke oder unter Verstoß gegen Gesetze zu nutzen; (b) andere zu belästigen, zu missbrauchen, zu bedrohen oder zu schädigen; (c) eine Person oder Organisation zu imitieren; (d) falsche, irreführende oder anstößige Inhalte zu veröffentlichen; (e) Daten zu scrapen, automatisiert zuzugreifen oder unbefugt auf den Dienst oder Nutzerdaten zuzugreifen; (f) den Dienst ohne unsere schriftliche Zustimmung kommerziell zu nutzen. Wir können Inhalte entfernen und Konten bei Verstößen sperren oder kündigen.

6. GEISTIGES EIGENTUM

Der Dienst, einschließlich Design, Text, Grafiken und Software, gehört uns oder unseren Lizenzgebern. Sie erwerben keine Rechte an unseren Marken oder Inhalten, außer einem begrenzten Recht zur Nutzung des Dienstes gemäß diesen Bedingungen.

7. DATENSCHUTZ

Ihre Nutzung des Dienstes unterliegt auch unserer Datenschutzrichtlinie, die beschreibt, wie wir Ihre personenbezogenen Daten (einschließlich E-Mail und Profilantworten) erheben, nutzen und schützen und wie Sie Ihre Rechte nach der DSGVO und anderen Gesetzen ausüben können. Mit der Nutzung des Dienstes willigen Sie in diese Verarbeitung ein.

8. KONTOSPERRUNG UND -KÜNDIGUNG

Wir können Ihr Konto jederzeit bei Verstoß gegen diese Bedingungen oder aus anderem Grund nach unserem Ermessen sperren oder kündigen. Sie können Ihr Konto jederzeit über die App-Einstellungen oder durch Kontaktaufnahme schließen. Bei Schließung oder Kündigung werden Ihre Daten gemäß unserer Datenschutzrichtlinie behandelt (einschließlich Löschung oder Aufbewahrung, soweit gesetzlich vorgeschrieben).

9. HAFTUNGSAUSSCHLUSS

Der Dienst wird « wie besehen » und « nach Verfügbarkeit » ohne Gewähr jeglicher Art bereitgestellt. Wir garantieren nicht, dass der Dienst ununterbrochen, fehlerfrei oder frei von schädlichen Komponenten ist.

10. HAFTUNGSBESCHRÄNKUNG

Im größtmöglichen gesetzlich zulässigen Umfang haften wir und unsere verbundenen Unternehmen nicht für indirekte, zufällige, besondere, Folgeschäden oder Strafschäden oder für Daten-, Einnahme- oder Reputationsverluste aus Ihrer Nutzung oder Unfähigkeit zur Nutzung des Dienstes.

11. ANWENDBARES RECHT UND STREITIGKEITEN

Diese Bedingungen unterliegen dem Recht des Landes, in dem wir tätig sind. Streitigkeiten werden vor den Gerichten dieses Landes ausgetragen; EU-Verbraucher können auch EU-Streitschlichtungsmechanismen nutzen.

12. KONTAKT

Bei Fragen zu diesen Bedingungen oder dem Dienst kontaktieren Sie uns unter der in der App oder auf unserer Website angegebenen E-Mail oder Adresse.
''';

// ———————————————————————————————————————————————————————————————————————————
// PRIVACY POLICY — FRENCH
// ———————————————————————————————————————————————————————————————————————————

const String privacyPolicyFr = r'''
SWAPLY — POLITIQUE DE CONFIDENTIALITÉ

Dernière mise à jour : 2025

1. INTRODUCTION

Swaply (« nous », « notre », « nos ») exploite l'application de rencontres et de connexion sociale Swaply. Cette Politique de confidentialité explique comment nous collectons, utilisons, stockons et protégeons vos données personnelles, et comment vous pouvez exercer vos droits. Nous traitons les données conformément au Règlement général sur la protection des données (RGPD) de l'UE et aux autres lois applicables.

2. RESPONSABLE DU TRAITEMENT

Le responsable du traitement de vos données personnelles est l'entité exploitant le service Swaply, comme indiqué dans l'application ou sur notre site. Vous pouvez nous contacter ou notre délégué à la protection des données pour toute demande relative à vos données.

3. BASE JURIDIQUE DU TRAITEMENT (RGPD)

Nous traitons vos données personnelles uniquement lorsque nous disposons d'une base légale : contrat (fourniture du Service) ; consentement ; intérêts légitimes (sécurité, prévention de la fraude, amélioration du Service) ; obligation légale.

4. DONNÉES COLLECTÉES

4.1 Compte et identification : adresse e-mail (inscription et récupération de compte) ; données d'authentification (ex. identifiants des fournisseurs de connexion Apple, Google, téléphone).

4.2 Profil et préférences : réponses de profil que vous fournissez lors de l'onboarding ou dans votre profil (ex. réponses aux questions sur ce que vous recherchez, comment vous vous décrivez, ce qui compte pour vous). Elles peuvent inclure des informations sensibles (ex. préférences relationnelles) ; nous les traitons uniquement comme nécessaire pour le Service et dans les limites autorisées par la loi.

4.3 Données d'utilisation et techniques : journaux (adresse IP, type d'appareil, version de l'app) ; données d'utilisation pour faire fonctionner et améliorer le Service.

5. UTILISATION DES DONNÉES

Nous utilisons vos données pour : fournir et maintenir le Service ; créer et gérer votre compte ; vous montrer des profils pertinents et permettre les correspondances ; communiquer avec vous ; assurer la sécurité et prévenir les abus ; respecter les obligations légales ; et, si vous avez consenti, envoyer du marketing. Nous ne vendons pas vos données personnelles.

6. CONSERVATION DES DONNÉES

Nous conservons vos données uniquement le temps nécessaire aux finalités de cette politique ou comme la loi l'exige. Si vous fermez votre compte, nous supprimerons ou anonymiserons vos données personnelles dans un délai raisonnable, sauf conservation requise pour des raisons légales, réglementaires ou opérationnelles légitimes.

7. VOS DROITS (RGPD)

Vous avez le droit à : l'accès ; la rectification ; l'effacement (« droit à l'oubli ») ; la limitation du traitement ; la portabilité des données ; l'opposition ; le retrait du consentement ; et le dépôt d'une plainte auprès d'une autorité de contrôle (ex. CNIL en France). Pour exercer ces droits, utilisez les options dans l'application (paramètres du compte, suppression du compte) ou contactez-nous. Nous répondrons dans les délais légaux (ex. un mois selon le RGPD).

8. SUPPRESSION DU COMPTE

Vous pouvez fermer votre compte et demander la suppression de vos données à tout moment via les paramètres de l'application ou en contactant le support. Lors de la fermeture, nous supprimerons ou anonymiserons vos données comme décrit à la section 6, sauf conservation légale. La suppression peut prendre un court délai.

9. PARTAGE DES DONNÉES

Nous pouvons partager des données avec : des prestataires nous assistant (hébergement, analytiques), soumis à des obligations de confidentialité et de protection des données ; les autorités lorsque la loi l'exige ; ou d'autres tiers uniquement avec votre consentement ou comme décrit ici. Nous ne vendons pas vos données. En cas de transfert hors EEE, nous mettons en place des garanties appropriées (ex. clauses contractuelles types) si nécessaire.

10. SÉCURITÉ

Nous mettons en œuvre des mesures techniques et organisationnelles pour protéger vos données contre l'accès non autorisé, la perte ou l'altération. Aucun système n'est totalement sécurisé ; nous vous encourageons à utiliser un mot de passe robuste.

11. ENFANTS

Le Service n'est pas destiné aux utilisateurs de moins de 18 ans. Nous ne collectons pas sciemment de données concernant des mineurs. Si vous pensez que nous avons collecté des données d'un mineur, contactez-nous pour les supprimer.

12. MODIFICATIONS

Nous pouvons mettre à jour cette Politique. Nous vous informerons des changements importants via l'application ou par e-mail. L'utilisation continue vaut acceptation.

13. CONTACT

Pour toute demande ou question sur cette Politique ou vos données personnelles, contactez-nous à l'adresse indiquée dans l'application ou sur notre site. Les coordonnées de notre délégué à la protection des données, le cas échéant, y figurent.
''';

// ———————————————————————————————————————————————————————————————————————————
// PRIVACY POLICY — SPANISH
// ———————————————————————————————————————————————————————————————————————————

const String privacyPolicyEs = r'''
SWAPLY — POLÍTICA DE PRIVACIDAD

Última actualización: 2025

1. INTRODUCCIÓN

Swaply (« nosotros », « nuestro ») opera la aplicación de citas y conexión social Swaply. Esta Política de privacidad explica cómo recogemos, usamos, almacenamos y protegemos sus datos personales y cómo puede ejercer sus derechos. Tratamos los datos de conformidad con el Reglamento general de protección de datos (RGPD) de la UE y otras leyes aplicables.

2. RESPONSABLE DEL TRATAMIENTO

El responsable del tratamiento de sus datos personales es la entidad que opera el servicio Swaply, como se indica en la aplicación o en nuestro sitio web. Puede contactarnos o a nuestro delegado de protección de datos para cualquier solicitud relativa a sus datos.

3. BASE LEGAL DEL TRATAMIENTO (RGPD)

Tratamos sus datos personales solo cuando tenemos una base legal: contrato (prestación del Servicio); consentimiento; intereses legítimos (seguridad, prevención del fraude, mejora del Servicio); obligación legal.

4. DATOS QUE RECOGEMOS

4.1 Cuenta e identificación: dirección de correo electrónico (registro y recuperación de cuenta); datos de autenticación (p. ej. identificadores de proveedores de inicio de sesión Apple, Google, teléfono).

4.2 Perfil y preferencias: respuestas de perfil que proporciona durante el onboarding o en su perfil (p. ej. respuestas a preguntas sobre qué busca, cómo se describe, qué le importa). Pueden incluir información sensible (p. ej. preferencias de relación); las tratamos solo según lo necesario para el Servicio y según permita la ley.

4.3 Datos de uso y técnicos: registros (dirección IP, tipo de dispositivo, versión de la app); datos de uso para operar y mejorar el Servicio.

5. USO DE LOS DATOS

Usamos sus datos para: proporcionar y mantener el Servicio; crear y gestionar su cuenta; mostrarle perfiles relevantes y permitir matches; comunicarnos con usted; garantizar la seguridad y prevenir abusos; cumplir obligaciones legales; y, si ha consentido, enviar marketing. No vendemos sus datos personales.

6. CONSERVACIÓN DE DATOS

Conservamos sus datos solo el tiempo necesario para los fines de esta política o según exija la ley. Si cierra su cuenta, eliminaremos o anonimizaremos sus datos personales en un plazo razonable, salvo conservación por razones legales, regulatorias u operativas legítimas.

7. SUS DERECHOS (RGPD)

Tiene derecho a: acceso; rectificación; supresión (« derecho al olvido »); limitación del tratamiento; portabilidad de datos; oposición; retirada del consentimiento; y a presentar una reclamación ante una autoridad de control (p. ej. AEPD en España). Para ejercer estos derechos, use las opciones en la aplicación (configuración de cuenta, eliminar cuenta) o contáctenos. Responderemos en los plazos legales (p. ej. un mes según el RGPD).

8. ELIMINACIÓN DE LA CUENTA

Puede cerrar su cuenta y solicitar la eliminación de sus datos en cualquier momento a través de la configuración de la aplicación o contactando a soporte. Al cerrar, eliminaremos o anonimizaremos sus datos como se describe en la sección 6, salvo conservación legal. La eliminación puede tardar un breve período.

9. COMPARTIR DATOS

Podemos compartir datos con: proveedores de servicios que nos asisten (alojamiento, analíticas), sujetos a obligaciones de confidencialidad y protección de datos; autoridades cuando la ley lo exija; u otros terceros solo con su consentimiento o como se describe aquí. No vendemos sus datos. En transferencias fuera del EEE, aplicamos garantías adecuadas (p. ej. cláusulas contractuales tipo) cuando sea necesario.

10. SEGURIDAD

Aplicamos medidas técnicas y organizativas para proteger sus datos frente al acceso no autorizado, la pérdida o la alteración. Ningún sistema es completamente seguro; le animamos a usar una contraseña segura.

11. MENORES

El Servicio no está dirigido a usuarios menores de 18 años. No recogemos conscientemente datos de menores. Si cree que hemos recogido datos de un menor, contáctenos para eliminarlos.

12. CAMBIOS

Podemos actualizar esta Política. Le informaremos de cambios sustanciales por la aplicación o por correo electrónico. El uso continuado constituye aceptación.

13. CONTACTO

Para cualquier solicitud o pregunta sobre esta Política o sus datos personales, contáctenos en la dirección indicada en la aplicación o en nuestro sitio web. Los datos de contacto de nuestro delegado de protección de datos, si se ha designado, figurarán allí.
''';

// ———————————————————————————————————————————————————————————————————————————
// PRIVACY POLICY — GERMAN
// ———————————————————————————————————————————————————————————————————————————

const String privacyPolicyDe = r'''
SWAPLY — DATENSCHUTZRICHTLINIE

Zuletzt aktualisiert: 2025

1. EINLEITUNG

Swaply (« wir », « unser ») betreibt die Dating- und Social-Connection-App Swaply. Diese Datenschutzrichtlinie erläutert, wie wir Ihre personenbezogenen Daten erheben, nutzen, speichern und schützen und wie Sie Ihre Rechte ausüben können. Wir verarbeiten Daten in Übereinstimmung mit der EU-Datenschutz-Grundverordnung (DSGVO) und anderen anwendbaren Gesetzen.

2. VERANTWORTLICHER

Verantwortlicher für Ihre personenbezogenen Daten ist die den Swaply-Dienst betreibende Stelle, wie in der App oder auf unserer Website angegeben. Sie können uns oder unseren Datenschutzbeauftragten (falls benannt) für Anfragen zu Ihren Daten kontaktieren.

3. RECHTSGRUNDLAGE DER VERARBEITUNG (DSGVO)

Wir verarbeiten Ihre personenbezogenen Daten nur, wenn eine Rechtsgrundlage besteht: Vertrag (Erbringung des Dienstes); Einwilligung; berechtigte Interessen (Sicherheit, Betrugsprävention, Verbesserung des Dienstes); gesetzliche Verpflichtung.

4. ERHOBENE DATEN

4.1 Konto und Identifikation: E-Mail-Adresse (Registrierung und Kontowiederherstellung); Authentifizierungsdaten (z. B. Kennungen von Anmeldeanbietern wie Apple, Google, Telefon).

4.2 Profil und Präferenzen: Profilantworten, die Sie beim Onboarding oder in Ihrem Profil angeben (z. B. Antworten auf Fragen zu dem, was Sie suchen, wie Sie sich beschreiben, was Ihnen wichtig ist). Sie können sensible Informationen (z. B. Beziehungspräferenzen) enthalten; wir verarbeiten sie nur wie für den Dienst erforderlich und gesetzlich zulässig.

4.3 Nutzungs- und technische Daten: Protokolldaten (IP-Adresse, Gerätetyp, App-Version); Nutzungsdaten zum Betrieb und zur Verbesserung des Dienstes.

5. NUTZUNG IHRER DATEN

Wir nutzen Ihre Daten, um: den Dienst bereitzustellen und zu betreiben; Ihr Konto zu erstellen und zu verwalten; Ihnen relevante Profile anzuzeigen und Matches zu ermöglichen; mit Ihnen zu kommunizieren; Sicherheit zu gewährleisten und Missbrauch zu verhindern; gesetzliche Verpflichtungen zu erfüllen; und bei Einwilligung Marketing zu senden. Wir verkaufen Ihre personenbezogenen Daten nicht.

6. DATENAUFBEWAHRUNG

Wir speichern Ihre Daten nur so lange wie für die in dieser Richtlinie genannten Zwecke oder gesetzlich erforderlich. Wenn Sie Ihr Konto schließen, löschen oder anonymisieren wir Ihre personenbezogenen Daten innerhalb einer angemessenen Frist, sofern keine Aufbewahrung aus rechtlichen, behördlichen oder legitimen betrieblichen Gründen erforderlich ist.

7. IHRE RECHTE (DSGVO)

Sie haben das Recht auf: Zugang; Berichtigung; Löschung (« Recht auf Vergessenwerden »); Einschränkung der Verarbeitung; Datenübertragbarkeit; Widerspruch; Widerruf der Einwilligung; und Beschwerde bei einer Aufsichtsbehörde (z. B. Landesdatenschutzbeauftragter in Deutschland). Um diese Rechte auszuüben, nutzen Sie die Optionen in der App (Kontoeinstellungen, Konto löschen) oder kontaktieren Sie uns. Wir antworten innerhalb der gesetzlichen Fristen (z. B. einen Monat gemäß DSGVO).

8. KONTO LöSCHUNG

Sie können Ihr Konto jederzeit schließen und die Löschung Ihrer Daten über die App-Einstellungen oder den Support anfordern. Bei Schließung löschen oder anonymisieren wir Ihre Daten wie in Abschnitt 6 beschrieben, sofern keine gesetzliche Aufbewahrung gilt. Die Löschung kann kurz dauern.

9. WEITERGABE VON DATEN

Wir können Daten weitergeben an: Dienstleister, die uns unterstützen (Hosting, Analysen), die Vertraulichkeits- und Datenschutzpflichten unterliegen; Behörden, wenn gesetzlich vorgeschrieben; oder andere Dritte nur mit Ihrer Zustimmung oder wie hier beschrieben. Wir verkaufen Ihre Daten nicht. Bei Übermittlungen außerhalb des EWR sorgen wir für geeignete Garantien (z. B. Standardvertragsklauseln), soweit erforderlich.

10. SICHERHEIT

Wir setzen technische und organisatorische Maßnahmen ein, um Ihre Daten vor unbefugtem Zugriff, Verlust oder Änderung zu schützen. Kein System ist vollständig sicher; wir empfehlen ein starkes Passwort.

11. KINDER

Der Dienst ist nicht für Nutzer unter 18 Jahren bestimmt. Wir erheben wissentlich keine Daten von Minderjährigen. Wenn Sie glauben, dass wir Daten eines Minderjährigen erhoben haben, kontaktieren Sie uns zur Löschung.

12. ÄNDERUNGEN

Wir können diese Richtlinie aktualisieren. Wir informieren Sie über wesentliche Änderungen per App oder E-Mail. Fortgesetzte Nutzung gilt als Annahme.

13. KONTAKT

Bei Anfragen oder Fragen zu dieser Richtlinie oder Ihren personenbezogenen Daten kontaktieren Sie uns unter der in der App oder auf unserer Website angegebenen Adresse. Die Kontaktdaten unseres Datenschutzbeauftragten, falls bestellt, sind dort angegeben.
''';

// ———————————————————————————————————————————————————————————————————————————
// SAFE DATING TIPS — ENGLISH
// ———————————————————————————————————————————————————————————————————————————

const String safeDatingTipsEn = r'''
SWAPLY — SAFE DATING TIPS

1. Take your time getting to know someone before meeting in person. Use the in-app chat to build trust gradually.

2. Meet in public places for first dates. Choose well-lit, populated locations like cafés, restaurants, or parks.

3. Tell a friend or family member where you're going and who you're meeting. Share your location if possible.

4. Trust your instincts. If something feels wrong, leave. Your safety comes first.

5. Don't share personal financial information, passwords, or sensitive data with someone you've just met.

6. Stay sober enough to make clear decisions. Avoid excessive alcohol on first meetings.

7. Use your own transportation to and from the date so you can leave whenever you want.

8. Be cautious about sharing your home address or workplace until you know someone well.

9. Report suspicious or abusive behaviour through the app. We take safety seriously.

10. Remember: you can unmatch or block anyone at any time. Your comfort and safety matter.
''';

const String safeDatingTipsAr = r'''
سوابلي — نصائح المواعدة الآمنة

1. خذ وقتك في التعرف على الشخص قبل اللقاء وجهاً لوجه. استخدم الدردشة داخل التطبيق لبناء الثقة تدريجياً.

2. التقِ في أماكن عامة في المواعيد الأولى. اختر أماكن مضاءة ومزدحمة مثل المقاهي أو المطاعم أو الحدائق.

3. أخبر صديقاً أو أحد أفراد العائلة أين ستذهب ومع من ستلتقي. شارك موقعك إن أمكن.

4. ثق بحدسك. إذا شعرت أن شيئاً غير صحيح، انسحب. سلامتك أولاً.

5. لا تشارك معلوماتك المالية أو كلمات المرور أو البيانات الحساسة مع شخص التقيت به للتو.

6. ابقَ في وعيك الكافي لاتخاذ قرارات واضحة. تجنب الإفراط في الكحول في اللقاءات الأولى.

7. استخدم وسيلة نقلك الخاصة للذهاب والعودة من الموعد حتى تتمكن من المغادرة متى شئت.

8. كن حذراً في مشاركة عنوان منزلك أو مكان عملك حتى تعرف الشخص جيداً.

9. أبلغ عن السلوك المشبوه أو المسيء عبر التطبيق. نأخذ السلامة على محمل الجد.

10. تذكر: يمكنك إلغاء المطابقة أو حظر أي شخص في أي وقت. راحتك وسلامتك مهمتان.
''';

// ———————————————————————————————————————————————————————————————————————————
// MEMBER PRINCIPLES — ENGLISH
// ———————————————————————————————————————————————————————————————————————————

const String memberPrinciplesEn = r'''
SWAPLY — MEMBER PRINCIPLES

We expect all Swaply members to uphold these principles:

1. RESPECT
Treat everyone with respect and dignity. No harassment, hate speech, or discrimination based on race, religion, gender, orientation, or any other characteristic.

2. HONESTY
Be genuine in your profile and in your conversations. Authenticity builds trust and better connections.

3. CONSENT
Respect boundaries. Consent is essential in all interactions. No means no.

4. KINDNESS
Choose kindness. A little compassion goes a long way in making connections meaningful.

5. SAFETY
Prioritise your safety and that of others. Report harmful behaviour. We're here to support a safe community.

6. PRIVACY
Respect others' privacy. Don't share personal information without permission.

7. INTEGRITY
Don't impersonate others, use fake photos, or mislead. Be yourself.

8. COMMUNITY
Help build a positive community. Support others, give feedback constructively, and contribute to a welcoming environment.

Violations may result in warnings, suspension, or permanent removal from Swaply.
''';

const String memberPrinciplesAr = r'''
سوابلي — مبادئ الأعضاء

نتوقع من جميع أعضاء سوابلي الالتزام بهذه المبادئ:

1. الاحترام
عامل الجميع باحترام وكرامة. لا مضايقة ولا خطاب كراهية ولا تمييز على أساس العرق أو الدين أو الجنس أو التوجه أو أي خاصية أخرى.

2. الصدق
كن صادقاً في ملفك وفي محادثاتك. الأصالة تبني الثقة والروابط الأفضل.

3. الموافقة
احترم الحدود. الموافقة ضرورية في كل التفاعلات. لا تعني لا.

4. اللطف
اختر اللطف. القليل من التعاطف يقطع شوطاً طويلاً في جعل الروابط ذات معنى.

5. السلامة
أولِ سلامتك وسلامة الآخرين الأولوية. أبلغ عن السلوك الضار. نحن هنا لدعم مجتمع آمن.

6. الخصوصية
احترم خصوصية الآخرين. لا تشارك المعلومات الشخصية دون إذن.

7. النزاهة
لا تنتحل شخصية الآخرين ولا تستخدم صوراً مزيفة ولا تضلل. كن نفسك.

8. المجتمع
ساعد في بناء مجتمع إيجابي. ادعم الآخرين، قدم ملاحظات بناءة، وساهم في بيئة ترحيبية.

قد تؤدي المخالفات إلى تحذيرات أو تعليق أو إزالة دائمة من سوابلي.
''';
