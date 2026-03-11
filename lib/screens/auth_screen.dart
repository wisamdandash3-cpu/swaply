import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../pending_onboarding.dart';
import '../services/profile_answer_service.dart';
import 'legal_screen.dart';
import 'phone_auth_screen.dart';

/// شاشة تسجيل الدخول و إنشاء حساب (أسلوب Hinge).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.pendingAnswers,
    this.initialSignUp = false,
  });

  /// إجابات الـ onboarding المجمعة قبل تسجيل الدخول؛ تُحفظ بعد نجاح Auth.
  final List<String>? pendingAnswers;

  /// true = عرض إنشاء حساب أولاً، false = عرض تسجيل الدخول.
  final bool initialSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  /// true = عرض اختيارات Hinge (Apple, Google, هاتف)، false = عرض نموذج البريد/كلمة المرور.
  final bool _showHingePicker = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    final pending = widget.pendingAnswers;
    if (pending != null && pending.isNotEmpty) {
      PendingOnboardingAnswers.list = List<String>.from(pending);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    final pending = widget.pendingAnswers;
    if (pending != null && pending.isNotEmpty) {
      final profileId = Supabase.instance.client.auth.currentUser?.id;
      if (profileId != null) {
        try {
          for (var i = 0; i < pending.length; i++) {
            await ProfileAnswerService().insertAnswer(
              profileId: profileId,
              content: pending[i],
              sortOrder: i,
            );
          }
        } catch (_) {}
      }
    }
    if (!mounted) return;
    // العودة للجذر حتى يعرض AuthGate إما Onboarding (إن لم يكمل الأسئلة) أو Home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _authErrorMessage(Object e) {
    if (e is AuthException) return e.message;
    return e.toString();
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      if (_isSignUp) {
        final res = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (res.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).checkEmailToConfirm),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      await _navigateAfterAuth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_authErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    bool sending = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.forgotPasswordTitle),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.forgotPasswordHint,
                    style: TextStyle(
                      color: AppColors.darkBlack.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.warmSand.withValues(alpha: 0.2),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.email : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => navigator.pop(),
                child: Text(l10n.back),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => sending = true);
                        try {
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(
                                emailController.text.trim(),
                                redirectTo: _kOAuthRedirectUrl,
                              );
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.resetLinkSent)),
                          );
                        } catch (e) {
                          setDialogState(() => sending = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(_authErrorMessage(e))),
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                ),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.sendResetLink),
              ),
            ],
          );
        },
      ),
    );
    emailController.dispose();
  }

  /// عنوان إعادة التوجيه بعد تسجيل الدخول بـ Google (أضفه في Supabase: Authentication → URL Configuration → Redirect URLs).
  static const String _kOAuthRedirectUrl = 'swaply://auth-callback';

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: _kOAuthRedirectUrl,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context);
        final String message =
            e is PlatformException &&
                (e.message?.contains('url_launcher') == true ||
                    e.code == 'channel-error')
            ? l10n.socialLoginSimulatorError
            : _authErrorMessage(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_showHingePicker) {
      return _buildHingeStylePicker(context, l10n);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isSignUp ? l10n.createAccount : l10n.signInLink,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isSignUp ? _buildSignUpView(l10n) : _buildLoginView(l10n),
        ),
      ),
    );
  }

  /// شاشة بأسلوب Hinge: خلفية داكنة، لوجو أبيض، قانوني، أزرار Apple و Google و رقم الهاتف، رجوع.
  Widget _buildHingeStylePicker(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1520), Color(0xFF2D2438), Color(0xFF1A1520)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Swaply',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _buildTermsRichText(context, l10n),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _hingeButton(
                      context: context,
                      label: l10n.signInWithApple,
                      icon: Icons.apple,
                      iconColor: Colors.black,
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      onTap: () => _signInWithOAuth(OAuthProvider.apple),
                    ),
                    const SizedBox(height: 12),
                    _hingeButton(
                      context: context,
                      label: l10n.signInWithGoogle,
                      icon: Icons.g_mobiledata,
                      iconColor: const Color(0xFF4285F4),
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      onTap: () => _signInWithOAuth(OAuthProvider.google),
                    ),
                    const SizedBox(height: 12),
                    _hingeButton(
                      context: context,
                      label: l10n.signInWithPhoneNumber,
                      icon: Icons.phone_android,
                      iconColor: Colors.white,
                      backgroundColor: AppColors.hingePurple,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhoneEntryScreen(
                              pendingAnswers: widget.pendingAnswers,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.back,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static const Color _termsLinkColor = Color(0xFF7BA3FF);
  Widget _buildTermsRichText(BuildContext context, AppLocalizations l10n) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      height: 1.45,
      fontSize: 13,
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

  Widget _hingeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// صورة ١: تسجيل الدخول — Trouble logging in?، بريد، كلمة مرور، Or log in with، أزرار اجتماعية.
  Widget _buildLoginView(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showForgotPasswordDialog(context, l10n),
            child: Text(
              l10n.forgotPassword,
              style: const TextStyle(
                color: AppColors.forestGreen,
                decoration: TextDecoration.underline,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: AppColors.warmSand.withValues(alpha: 0.3),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.email : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: AppColors.warmSand.withValues(alpha: 0.3),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.darkBlack,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? l10n.password : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submitEmailPassword,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neonCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.signInButton),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _isSignUp = true),
              child: Text(
                l10n.signUp,
                style: const TextStyle(
                  color: AppColors.neonCoral,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// صورة ٢: إنشاء حساب — أنشئ حسابك، هل لديك حساب؟، بريد، التالي، أو اشترك بـ، شروط.
  Widget _buildSignUpView(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            l10n.createYourAccount,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.alreadyHaveAccount,
                style: TextStyle(
                  color: AppColors.darkBlack.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isSignUp = false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.signIn,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.firstEnterEmail,
            style: TextStyle(
              color: AppColors.darkBlack.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: l10n.email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: AppColors.warmSand.withValues(alpha: 0.3),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.email : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: AppColors.warmSand.withValues(alpha: 0.3),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.darkBlack,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.password;
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submitEmailPassword,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.next),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              l10n.bySigningUpAccept(l10n.termsOfUse, l10n.privacyPolicy),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
