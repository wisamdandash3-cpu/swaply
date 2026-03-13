(function () {
  'use strict';

  const translations = {
    en: {
      hero1: 'Cross paths.<br>Date local.',
      hero2: "Discover who's around you.",
      hero3: 'Real connections, nearby.',
      heroSub: 'Swaply — Dating app to discover new relationships.',
      trustLabel: 'TRUSTED BY',
      trustCount: 'Users worldwide',
      appStore: 'App Store',
      googlePlay: 'Google Play',
      featuresTitle: 'Why Swaply',
      feature1Title: 'Discover',
      feature1Desc: 'Swipe through profiles and like what you love. Match when it\'s mutual.',
      feature2Title: 'Chat',
      feature2Desc: 'Message your matches and get to know each other before meeting.',
      feature3Title: 'Gifts & Roses',
      feature3Desc: 'Send roses and small gifts to stand out and show you care.',
      feature4Title: 'Safe & Verified',
      feature4Desc: 'Verification and reporting tools to keep the community safe.',
      footerTagline: 'Open 24/7',
      footerCompany: 'Company',
      footerTerms: 'Terms of service',
      footerPrivacy: 'Privacy policy',
      footerCookies: 'Cookies',
      footerUsers: 'Users',
      footerSafety: 'Safety Center',
      footerFaq: 'FAQ',
      footerLegal: 'Legal',
      footerTermsLink: 'Terms',
      footerPrivacyLink: 'Privacy',
    },
    de: {
      hero1: 'Kreuz deinen Weg.<br>Date lokal.',
      hero2: 'Entdecke, wer in deiner Nähe ist.',
      hero3: 'Echte Begegnungen, in der Nähe.',
      heroSub: 'Swaply — Dating-App für neue Beziehungen.',
      trustLabel: 'VERTRAUT VON',
      trustCount: 'Nutzer weltweit',
      appStore: 'App Store',
      googlePlay: 'Google Play',
      featuresTitle: 'Warum Swaply',
      feature1Title: 'Entdecken',
      feature1Desc: 'Wische durch Profile und like, was dir gefällt. Match bei Gegenseitigkeit.',
      feature2Title: 'Chat',
      feature2Desc: 'Schreib deinen Matches und lern euch kennen, bevor ihr euch trefft.',
      feature3Title: 'Geschenke & Rosen',
      feature3Desc: 'Schick Rosen und kleine Geschenke, um aufzufallen und zu zeigen, dass es dir wichtig ist.',
      feature4Title: 'Sicher & verifiziert',
      feature4Desc: 'Verifizierung und Meldeoptionen für eine sichere Community.',
      footerTagline: '24/7 verfügbar',
      footerCompany: 'Unternehmen',
      footerTerms: 'Nutzungsbedingungen',
      footerPrivacy: 'Datenschutz',
      footerCookies: 'Cookies',
      footerUsers: 'Nutzer',
      footerSafety: 'Sicherheitscenter',
      footerFaq: 'FAQ',
      footerLegal: 'Rechtliches',
      footerTermsLink: 'AGB',
      footerPrivacyLink: 'Datenschutz',
    },
    ar: {
      hero1: 'تتقاطع المسارات.<br>تواعد محلياً.',
      hero2: 'اكتشف من حولك.',
      hero3: 'علاقات حقيقية، قريبة منك.',
      heroSub: 'Swaply — تطبيق مواعدة لاكتشاف علاقات جديدة.',
      trustLabel: 'موثوق من',
      trustCount: 'مستخدمين حول العالم',
      appStore: 'App Store',
      googlePlay: 'Google Play',
      featuresTitle: 'لماذا Swaply',
      feature1Title: 'اكتشف',
      feature1Desc: 'تصفح الملفات وأعجب بما يعجبك. تطابق عندما يكون متبادلاً.',
      feature2Title: 'دردشة',
      feature2Desc: 'راسل تطابقاتك وتعرّف عليهم قبل اللقاء.',
      feature3Title: 'هدايا وورود',
      feature3Desc: 'أرسل الورود والهدايا الصغيرة لتميّز نفسك وتُظهر اهتمامك.',
      feature4Title: 'آمن ومُتحقق',
      feature4Desc: 'التحقق وأدوات الإبلاغ للحفاظ على مجتمع آمن.',
      footerTagline: 'متاح 24/7',
      footerCompany: 'الشركة',
      footerTerms: 'شروط الخدمة',
      footerPrivacy: 'سياسة الخصوصية',
      footerCookies: 'الكوكيز',
      footerUsers: 'المستخدمون',
      footerSafety: 'مركز الأمان',
      footerFaq: 'الأسئلة الشائعة',
      footerLegal: 'قانوني',
      footerTermsLink: 'الشروط',
      footerPrivacyLink: 'الخصوصية',
    },
  };

  const STORAGE_KEY = 'swaply_website_lang';
  let currentLang = localStorage.getItem(STORAGE_KEY) || 'en';

  function applyLang(lang) {
    if (!translations[lang]) lang = 'en';
    currentLang = lang;
    localStorage.setItem(STORAGE_KEY, lang);
    document.documentElement.lang = lang === 'ar' ? 'ar' : lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';

    document.querySelectorAll('.lang-btn').forEach(function (btn) {
      btn.classList.toggle('active', btn.getAttribute('data-lang') === lang);
    });

    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      const key = el.getAttribute('data-i18n');
      const text = translations[lang][key];
      if (text != null) {
        el.innerHTML = text;
      }
    });
  }

  function initHeroCarousel() {
    const slides = document.querySelectorAll('.hero-slide');
    if (slides.length < 2) return;
    let index = 0;
    setInterval(function () {
      slides[index].classList.remove('active');
      index = (index + 1) % slides.length;
      slides[index].classList.add('active');
    }, 4000);
  }

  function initLangButtons() {
    document.querySelectorAll('.lang-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        applyLang(btn.getAttribute('data-lang'));
      });
    });
  }

  function init() {
    applyLang(currentLang);
    initHeroCarousel();
    initLangButtons();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
