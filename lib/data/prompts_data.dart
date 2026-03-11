/// نموذج سؤال/مطالبة للبروفايل.
class Prompt {
  const Prompt({
    required this.id,
    required this.textAr,
    required this.textEn,
    required this.textDe,
    required this.category,
  });

  final String id;
  final String textAr;
  final String textEn;
  final String textDe;
  final String category;

  /// النص حسب اللغة (ar, en, de).
  String textForLocale(String locale) {
    switch (locale) {
      case 'ar':
        return textAr;
      case 'de':
        return textDe;
      default:
        return textEn;
    }
  }
}

/// قائمة الأسئلة/المطالبات المتاحة للبروفايل.
const List<Prompt> kPrompts = [
  // About me
  Prompt(
    id: 'prompt_1',
    textAr: 'أكبر نقاط قوتي',
    textEn: 'My greatest strength',
    textDe: 'Meine größte Stärke',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_2',
    textAr: 'حقيقة عشوائية أحبها هي',
    textEn: 'A random fact I love is',
    textDe: 'Eine zufällige Tatsache, die ich liebe, ist',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_3',
    textAr: 'يوم الأحد المعتاد',
    textEn: 'Typical Sunday',
    textDe: 'Ein typischer Sonntag',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_4',
    textAr: 'اكتشفت مؤخراً أن',
    textEn: 'I recently discovered that',
    textDe: 'Kürzlich habe ich entdeckt, dass',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_5',
    textAr: 'أكثر مخاوفي غير المنطقية',
    textEn: 'My most irrational fear',
    textDe: 'Meine irrationalste Angst',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_6',
    textAr: 'مهارات غير عادية',
    textEn: 'Unusual skills',
    textDe: 'Ungewöhnliche Fähigkeiten',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_7',
    textAr: 'هدف حياتي',
    textEn: 'A life goal of mine',
    textDe: 'Ein Lebensziel von mir',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_8',
    textAr: 'المواعدة معي تشبه',
    textEn: 'Dating me is like',
    textDe: 'Mit mir zu daten ist wie',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_9',
    textAr: 'متاعي البسيطة',
    textEn: 'My simple pleasures',
    textDe: 'Meine einfachen Freuden',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_10',
    textAr: 'هذا العام، أريد حقاً أن',
    textEn: 'This year, I really want to',
    textDe: 'Dieses Jahr möchte ich wirklich',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_11',
    textAr: 'أجنّ من أجله',
    textEn: 'I go crazy for',
    textDe: 'Ich bin verrückt nach',
    category: 'About me',
  ),
  Prompt(
    id: 'prompt_12',
    textAr: 'طريقة كسب قلبي هي',
    textEn: 'The way to win me over is',
    textDe: 'So gewinnst du mich für dich',
    category: 'About me',
  ),
  // Story time
  Prompt(
    id: 'prompt_13',
    textAr: 'قصة مضحكة حدثت لي...',
    textEn: 'A funny story that happened to me...',
    textDe: 'Eine lustige Geschichte, die mir passiert ist...',
    category: 'Story time',
  ),
  Prompt(
    id: 'prompt_14',
    textAr: 'أفضل قرار اتخذته...',
    textEn: 'The best decision I ever made...',
    textDe: 'Die beste Entscheidung, die ich je getroffen habe...',
    category: 'Story time',
  ),
  Prompt(
    id: 'prompt_15',
    textAr: 'أكثر شيء أفتخر به...',
    textEn: 'The thing I\'m most proud of...',
    textDe: 'Das, worauf ich am stolzesten bin...',
    category: 'Story time',
  ),
  // Let's chat about
  Prompt(
    id: 'prompt_16',
    textAr: 'أفضل شيء في المواعدة؟',
    textEn: 'The best thing about dating?',
    textDe: 'Das Beste am Dating?',
    category: 'Let\'s chat about',
  ),
  Prompt(
    id: 'prompt_17',
    textAr: 'أنا أبحث عن...',
    textEn: 'I\'m looking for...',
    textDe: 'Ich suche...',
    category: 'Let\'s chat about',
  ),
  Prompt(
    id: 'prompt_18',
    textAr: 'أفضل طريقة لقضاء يوم عطلة؟',
    textEn: 'The best way to spend a day off?',
    textDe: 'Der beste Weg, einen freien Tag zu verbringen?',
    category: 'Let\'s chat about',
  ),
  // Date vibes
  Prompt(
    id: 'prompt_19',
    textAr: 'أفضل موعد لي كان...',
    textEn: 'My best date was...',
    textDe: 'Mein bestes Date war...',
    category: 'Date vibes',
  ),
  Prompt(
    id: 'prompt_20',
    textAr: 'أفضل مكان للقاء؟',
    textEn: 'The best place to meet?',
    textDe: 'Der beste Ort zum Treffen?',
    category: 'Date vibes',
  ),
  Prompt(
    id: 'prompt_21',
    textAr: 'أفضل نشاط في موعد؟',
    textEn: 'The best activity on a date?',
    textDe: 'Die beste Aktivität bei einem Date?',
    category: 'Date vibes',
  ),
];
