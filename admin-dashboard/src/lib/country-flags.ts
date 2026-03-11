/**
 * Convert ISO 3166-1 alpha-2 country code to flag emoji (no external deps).
 */
export function countryCodeToFlag(code: string): string {
  if (!code || code.length !== 2 || !/^[a-zA-Z]+$/.test(code)) return '🌐';
  const offset = 127397;
  return Array.from(code.toUpperCase())
    .map((letter) => String.fromCodePoint(letter.charCodeAt(0) + offset))
    .join('');
}

/** Country name (EN/AR) or code -> ISO 2-letter code. */
const COUNTRY_TO_ISO: Record<string, string> = {
  // English
  germany: 'DE',
  'saudi arabia': 'SA',
  'united states': 'US',
  'united arab emirates': 'AE',
  egypt: 'EG',
  jordan: 'JO',
  lebanon: 'LB',
  syria: 'SY',
  iraq: 'IQ',
  kuwait: 'KW',
  bahrain: 'BH',
  qatar: 'QA',
  oman: 'OM',
  yemen: 'YE',
  palestine: 'PS',
  morocco: 'MA',
  algeria: 'DZ',
  tunisia: 'TN',
  libya: 'LY',
  sudan: 'SD',
  turkey: 'TR',
  iran: 'IR',
  pakistan: 'PK',
  india: 'IN',
  'united kingdom': 'GB',
  france: 'FR',
  italy: 'IT',
  spain: 'ES',
  netherlands: 'NL',
  canada: 'CA',
  australia: 'AU',
  russia: 'RU',
  china: 'CN',
  japan: 'JP',
  brazil: 'BR',
  mexico: 'MX',
  argentina: 'AR',
  'south africa': 'ZA',
  nigeria: 'NG',
  kenya: 'KE',
  indonesia: 'ID',
  malaysia: 'MY',
  singapore: 'SG',
  // Arabic (transliterated / common)
  'المملكة العربية السعودية': 'SA',
  السعودية: 'SA',
  مصر: 'EG',
  الأردن: 'JO',
  لبنان: 'LB',
  سوريا: 'SY',
  العراق: 'IQ',
  الكويت: 'KW',
  البحرين: 'BH',
  قطر: 'QA',
  عمان: 'OM',
  اليمن: 'YE',
  فلسطين: 'PS',
  المغرب: 'MA',
  الجزائر: 'DZ',
  تونس: 'TN',
  ليبيا: 'LY',
  السودان: 'SD',
  'ألمانيا': 'DE',
  'الإمارات': 'AE',
  'الإمارات العربية المتحدة': 'AE',
  'تركيا': 'TR',
  'إيران': 'IR',
  'باكستان': 'PK',
  'الهن\u062F': 'IN',
  'بريطانيا': 'GB',
  'فرنسا': 'FR',
  'إيطاليا': 'IT',
  'إسبانيا': 'ES',
  'هولندا': 'NL',
  'كندا': 'CA',
  'أستراليا': 'AU',
  'روسيا': 'RU',
  'الصين': 'CN',
  'اليابان': 'JP',
  'البرازيل': 'BR',
  'المكسيك': 'MX',
  'الأرجنتين': 'AR',
  'جنوب أفريقيا': 'ZA',
  'نيجيريا': 'NG',
  'كينيا': 'KE',
  'إندونيسيا': 'ID',
  'ماليزيا': 'MY',
  'سنغافورة': 'SG',
};

function normalize(s: string): string {
  return s.trim().toLowerCase().replace(/\s+/g, ' ');
}

export function getCountryFlag(countryNameOrCode: string): string {
  if (!countryNameOrCode || !countryNameOrCode.trim()) return '🌐';
  const s = countryNameOrCode.trim();
  if (s.length === 2 && /^[a-zA-Z]+$/.test(s)) return countryCodeToFlag(s.toUpperCase());
  const key = normalize(s);
  const iso = COUNTRY_TO_ISO[key] || COUNTRY_TO_ISO[s];
  if (iso) return countryCodeToFlag(iso);
  return '🌐';
}
