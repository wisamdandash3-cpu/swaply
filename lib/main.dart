import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'app_locale_scope.dart';
import 'constants/app_languages.dart';
import 'generated/l10n/app_localizations.dart';
import 'pending_onboarding.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/post_registration_onboarding_screen.dart';
import 'services/admin_ban_service.dart';
import 'services/profile_answer_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/subscription_service.dart';

const String _kLocaleKey = 'app_locale';

/// قيم افتراضية للتطوير فقط. للإنتاج استخدم:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const String _kSupabaseUrl = 'https://tjlbzzmudskkwmdtarfn.supabase.co';
const String _kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqbGJ6em11ZHNra3dtZHRhcmZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MTk3NTYsImV4cCI6MjA4ODI5NTc1Nn0.e6ux9UfT1eeJcLAYdAZgJEUX8IvM0NkylhI9rjyse8A';

const String _kEnvUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String _kEnvKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = _kEnvUrl.isNotEmpty ? _kEnvUrl : _kSupabaseUrl;
  final key = _kEnvKey.isNotEmpty ? _kEnvKey : _kSupabaseAnonKey;
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  await initializeRevenueCat();
  final prefs = await SharedPreferences.getInstance();
  final savedCode = prefs.getString(_kLocaleKey);
  final supported = AppLocalizations.supportedLocales;
  runApp(
    SwaplyApp(
      initialLocale: savedCode != null && supported.any((l) => l.languageCode == savedCode)
          ? Locale(savedCode)
          : const Locale('en'),
    ),
  );
}

class SwaplyApp extends StatefulWidget {
  const SwaplyApp({super.key, this.initialLocale});

  /// Default is English. User's saved choice is loaded at startup.
  final Locale? initialLocale;

  @override
  State<SwaplyApp> createState() => _SwaplyAppState();
}

class _SwaplyAppState extends State<SwaplyApp> {
  late Locale _locale;

  static const Set<String> _rtlLanguages = {
    'ar', 'he', 'fa', 'ur', 'yi', 'dv', 'ku', 'ps',
  };

  static bool _isRTL(Locale locale) =>
      _rtlLanguages.contains(locale.languageCode);

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale ?? const Locale('en');
  }

  Future<void> _setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swaply',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en'); // لغة الجهاز غير مدعومة → الإنجليزية
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          brightness: Brightness.light,
          primary: AppColors.forestGreen,
          secondary: AppColors.forestGreen,
          tertiary: AppColors.warmSand,
        ),
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.copyWith(
          titleLarge: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      builder: (context, child) {
        final isRTL = _isRTL(_locale);
        return LocaleScope(
          setLocale: _setLocale,
          child: Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: _AuthGate(
        onLanguageSelected: _setLocale,
        currentLocale: _locale,
      ),
    );
  }
}

/// يعرض Welcome إذا لم يكن المستخدم مسجلاً؛ إذا مسجّل يتحقق من إكمال الـ onboarding ثم يعرض الأسئلة أو الصفحة الرئيسية.
class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.onLanguageSelected,
    required this.currentLocale,
  });

  final Future<void> Function(Locale locale) onLanguageSelected;
  final Locale currentLocale;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      if (event.session != null) {
        await revenueCatLogIn(event.session!.user.id);
        await SubscriptionService.instance.refreshSubscriptionStatus();
      }
      if (mounted) {
        setState(() => _onboardingComplete = null);
      }
    });
    // تحديث حالة الاشتراك وربط RevenueCat عند فتح التطبيق إذا المستخدم مسجّل دخول
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await revenueCatLogIn(user.id);
        await SubscriptionService.instance.refreshSubscriptionStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return SwaplyWelcomeScreen(
        onLanguageSelected: widget.onLanguageSelected,
        currentLocale: widget.currentLocale,
        showAuthScreenFirst: false,
      );
    }
    return _BanCheckGate(
      userId: user.id,
      child: _buildAuthenticatedContent(user.id),
    );
  }

  Widget _buildAuthenticatedContent(String userId) {
    final pending = PendingOnboardingAnswers.list;
    if (pending != null && pending.isNotEmpty) {
      return _SavePendingAnswers(
        userId: userId,
        answers: pending,
        onDone: () {
          PendingOnboardingAnswers.list = null;
          if (mounted) setState(() {});
        },
      );
    }
    if (_onboardingComplete == true) {
      return const HomeScreen();
    }
    return _OnboardingGate(
      userId: userId,
      onComplete: () {
        if (mounted) setState(() => _onboardingComplete = true);
      },
    );
  }
}

/// يتحقق من الحظر الإداري قبل عرض المحتوى.
class _BanCheckGate extends StatefulWidget {
  const _BanCheckGate({
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  State<_BanCheckGate> createState() => _BanCheckGateState();
}

class _BanCheckGateState extends State<_BanCheckGate> {
  bool? _isBanned;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final banned = await AdminBanService().isCurrentUserBanned();
    if (!mounted) return;
    setState(() => _isBanned = banned);
    if (banned) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isBanned == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isBanned == true) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).accountBanned,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

/// يحفظ إجابات الـ onboarding المعلقة (بعد OAuth) ثم يستدعي onDone.
class _SavePendingAnswers extends StatefulWidget {
  const _SavePendingAnswers({
    required this.userId,
    required this.answers,
    required this.onDone,
  });

  final String userId;
  final List<String> answers;
  final VoidCallback onDone;

  @override
  State<_SavePendingAnswers> createState() => _SavePendingAnswersState();
}

class _SavePendingAnswersState extends State<_SavePendingAnswers> {
  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    try {
      for (var i = 0; i < widget.answers.length; i++) {
        await ProfileAnswerService().insertAnswer(
          profileId: widget.userId,
          content: widget.answers[i],
          sortOrder: i,
        ).timeout(const Duration(seconds: 10));
      }
    } on TimeoutException catch (_) {
      // تجنّب التجمّد: المتابعة حتى لو تأخر الحفظ
    } catch (_) {}
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// يتحقق من عدد إجابات الـ onboarding: إن كانت 3 فأكثر → الصفحة الرئيسية، وإلا → شاشة الأسئلة.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({
    required this.userId,
    required this.onComplete,
  });

  final String userId;
  final VoidCallback onComplete;

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late Future<int> _answersCountFuture;

  @override
  void initState() {
    super.initState();
    _answersCountFuture = _getAnswersCount();
  }

  Future<int> _getAnswersCount() async {
    try {
      final list = await ProfileAnswerService()
          .getByProfileId(widget.userId)
          .timeout(const Duration(seconds: 8));
      return list.length;
    } on TimeoutException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _answersCountFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final count = snapshot.hasData ? snapshot.data! : 0;
        if (snapshot.hasError) {
          return PostRegistrationOnboardingScreen(
            userId: widget.userId,
            onComplete: widget.onComplete,
          );
        }
        if (count >= 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onComplete();
          });
          return const HomeScreen();
        }
        return PostRegistrationOnboardingScreen(
          userId: widget.userId,
          onComplete: widget.onComplete,
        );
      },
    );
  }
}

/// شاشة الدخول بأسلوب Hinge: إنشاء حساب أولاً ثم تسجيل الدخول، بعدها الأسئلة.
class SwaplyWelcomeScreen extends StatefulWidget {
  const SwaplyWelcomeScreen({
    super.key,
    required this.onLanguageSelected,
    required this.currentLocale,
    this.showAuthScreenFirst = false,
  });

  final Future<void> Function(Locale locale) onLanguageSelected;
  final Locale currentLocale;
  /// عند true تُعرض شاشة التسجيل (إنشاء حساب) أولاً فوق شاشة الترحيب.
  final bool showAuthScreenFirst;

  @override
  State<SwaplyWelcomeScreen> createState() => _SwaplyWelcomeScreenState();
}

class _SwaplyWelcomeScreenState extends State<SwaplyWelcomeScreen> {
  bool _showLanguageSheet = false;
  final ScrollController _sheetScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.showAuthScreenFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuthScreen(initialSignUp: true),
          ),
        );
      });
    }
  }

  void _goToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(initialSignUp: true),
      ),
    );
  }

  void _goToSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(initialSignUp: false),
      ),
    );
  }

  @override
  void dispose() {
    _sheetScrollController.dispose();
    super.dispose();
  }

  /// لوغو التطبيق مع بديل إذا فشل تحميل الصورة.
  Widget _buildLogo({required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size == 72 ? 20 : 24),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.darkBlack,
            borderRadius: BorderRadius.circular(size == 72 ? 20 : 24),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// نص الشروط مع خطوط تحت "Terms of Use" و "Privacy Policy" (مثل Hinge).
  static const Color _termsLinkColor = Color(0xFF7BA3FF);
  Widget _buildTermsRichText(BuildContext context, AppLocalizations l10n) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      height: 1.4,
      fontSize: 13,
      shadows: const [
        Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0xCC000000)),
        Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x99000000)),
      ],
    );
    final linkStyle = baseStyle?.copyWith(
      color: _termsLinkColor,
      decoration: TextDecoration.underline,
      decorationColor: _termsLinkColor,
    );
    final locale = Localizations.localeOf(context);
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: l10n.entryAgreeIntro),
          TextSpan(
            text: l10n.termsOfUse,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LegalScreen(
                      type: LegalType.terms,
                      languageCode: locale.languageCode,
                    ),
                  ),
                );
              },
          ),
          TextSpan(text: l10n.entryAgreeAnd),
          TextSpan(
            text: l10n.privacyPolicy,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LegalScreen(
                      type: LegalType.privacy,
                      languageCode: locale.languageCode,
                    ),
                  ),
                );
              },
          ),
          TextSpan(text: l10n.entryAgreeEnd),
        ],
      ),
    );
  }

  Widget _buildLanguageSheetContent() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.chooseLanguage,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlack,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: _sheetScrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: kWorldLanguages.length,
            itemBuilder: (context, index) {
              final lang = kWorldLanguages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    await widget.onLanguageSelected(Locale(lang.code));
                    if (mounted) setState(() => _showLanguageSheet = false);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Text(
                          lang.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.darkBlack),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_showLanguageSheet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _showLanguageSheet = false),
                child: _buildLogo(size: 72),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.warmSand,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _buildLanguageSheetContent(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const Color overlayColor = Color(0x99000000); // شفافية لجعل الخلفية متلاشية
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: overlayColor,
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showLanguageSheet = true),
                    icon: Icon(Icons.language, size: 20, color: Colors.white),
                    label: Text(
                      l10n.chooseLanguage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0xCC000000)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildLogo(size: 104),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Swaply',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Color(0xCC000000)),
                                const Shadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x99000000)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.tagline,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                const Shadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0xCC000000)),
                                const Shadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x99000000)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildTermsRichText(context, l10n),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _goToCreateAccount,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.neonCoral,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                l10n.createAccount,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _goToSignIn,
                            child: Text(
                              l10n.signInLink,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                shadows: [
                                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0xCC000000)),
                                  Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x99000000)),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

