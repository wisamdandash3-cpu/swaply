import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../data/country_dial_codes.dart';
import '../generated/l10n/app_localizations.dart';
import '../pending_onboarding.dart';
import '../services/profile_answer_service.dart';

/// قائمة دول العالم لاختيار رمز الاتصال (تُستورد من country_dial_codes).
final List<({String code, String dialCode, String flag})> kCountryCodes = kCountryDialCodes;

/// شاشة إدخال رقم الهاتف للتحقق (مثل الصورة المرجعية).
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({
    super.key,
    this.pendingAnswers,
  });

  final List<String>? pendingAnswers;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  int _selectedCountryIndex = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone {
    final dial = kCountryCodes[_selectedCountryIndex].dialCode;
    final num = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (dial == '+0') return num.isNotEmpty ? '+$num' : '';
    return '$dial$num';
  }

  Future<void> _sendOtp() async {
    final full = _fullPhone;
    if (full.isEmpty || full.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).phoneNumberInvalid)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: full);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerifyScreen(
            phone: full,
            pendingAnswers: widget.pendingAnswers,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final msg = e is AuthException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final country = kCountryCodes[_selectedCountryIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.darkBlack,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.phone_in_talk_outlined,
                      size: 56,
                      color: AppColors.darkBlack,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.whatsYourPhoneNumber,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlack,
                          ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  final idx = await showModalBottomSheet<int>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => DraggableScrollableSheet(
                                      initialChildSize: 0.6,
                                      maxChildSize: 0.9,
                                      minChildSize: 0.3,
                                      expand: false,
                                      builder: (_, scrollController) => Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(
                                              l10n.selectCountry,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              controller: scrollController,
                                              itemCount: kCountryCodes.length,
                                              itemBuilder: (_, i) {
                                                final c = kCountryCodes[i];
                                                return ListTile(
                                                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                                                  title: Text('${c.dialCode}'),
                                                  onTap: () => Navigator.pop(ctx, i),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (idx != null && mounted) {
                                    setState(() => _selectedCountryIndex = idx);
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  country.dialCode == '+0'
                                      ? '+'
                                      : country.dialCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.darkBlack,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down,
                                    color: AppColors.darkBlack),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            autofocus: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                            ],
                            decoration: InputDecoration(
                              hintText: '123 456 7890',
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.darkBlack.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.darkBlack.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.hingePurple, width: 2),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.darkBlack,
                            ),
                            onSubmitted: (_) => _sendOtp(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _isLoading
                              ? null
                              : () => _sendOtp(),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.warmSand,
                            foregroundColor: AppColors.darkBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.phoneVerificationMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkBlack.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.whatIfNumberChanges)),
                        );
                      },
                      child: Text(
                        l10n.whatIfNumberChanges,
                        style: const TextStyle(
                          color: AppColors.hingePurple,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة إدخال رمز التحقق (OTP) وإكمال تسجيل الدخول بالهاتف.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.phone,
    this.pendingAnswers,
  });

  final String phone;
  final List<String>? pendingAnswers;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendSeconds = 60;
    });
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) _canResend = true;
      });
      return _resendSeconds > 0;
    });
  }

  Future<void> _savePendingAndPop() async {
    final pending = widget.pendingAnswers;
    if (pending != null && pending.isNotEmpty && mounted) {
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
    PendingOnboardingAnswers.list = null;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _verify() async {
    final code = _codeController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enterCodeHint)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        phone: widget.phone,
        token: code,
      );
      await _savePendingAndPop();
    } catch (e) {
      if (mounted) {
        final msg = e is AuthException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resend() async {
    if (!_canResend || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: widget.phone);
      if (mounted) _startResendTimer();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.enterVerificationCode,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlack,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlack,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.warmSand.withValues(alpha: 0.2),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.hingePurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.verify),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _canResend && !_isLoading ? _resend : null,
                child: Text(
                  _canResend
                      ? l10n.resendCode
                      : '${l10n.resendCode} ($_resendSeconds)',
                  style: const TextStyle(color: AppColors.hingePurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
