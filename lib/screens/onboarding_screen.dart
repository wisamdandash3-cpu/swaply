import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/profile_answer_service.dart';

/// Hinge-style onboarding: progress bar, one question per screen, neon coral buttons.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.fromAuthScreen = true,
    this.onComplete,
    this.preAuth = false,
    this.onPreAuthComplete,
  });

  /// true عند المجيء من شاشة تسجيل الدخول (استبدال)، false عند العرض داخل AuthGate.
  final bool fromAuthScreen;
  /// يُستدعى عند إكمال آخر سؤال لتنبيه الأب (مثلاً AuthGate) لتحديث العرض.
  final VoidCallback? onComplete;
  /// true = الأسئلة قبل تسجيل الدخول؛ الإجابات تُجمّع محلياً ثم تُمرّر لشاشة Auth.
  final bool preAuth;
  /// عند preAuth وإكمال آخر سؤال، يُستدعى مع قائمة الإجابات للانتقال لشاشة تسجيل الدخول.
  final void Function(List<String> answers)? onPreAuthComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  bool _isSaving = false;
  final List<String> _pendingAnswers = [];

  List<({String question, List<String> options})> _buildQuestions(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      (
        question: l10n.onboardingQuestion1,
        options: [
          l10n.onboardingQ1Relationship,
          l10n.onboardingQ1Friends,
          l10n.onboardingQ1NotSure,
        ],
      ),
      (
        question: l10n.onboardingQuestion2,
        options: [
          l10n.onboardingQ2Adventurous,
          l10n.onboardingQ2Thoughtful,
          l10n.onboardingQ2Creative,
          l10n.onboardingQ2EasyGoing,
        ],
      ),
      (
        question: l10n.onboardingQuestion3,
        options: [
          l10n.onboardingQ3Honesty,
          l10n.onboardingQ3Humor,
          l10n.onboardingQ3Kindness,
          l10n.onboardingQ3Ambition,
        ],
      ),
      (
        question: l10n.onboardingQuestion4,
        options: [
          l10n.onboardingQ4No,
          l10n.onboardingQ4YesWithMe,
          l10n.onboardingQ4YesNotWithMe,
          l10n.onboardingQ4PreferNot,
        ],
      ),
      (
        question: l10n.onboardingQuestion5,
        options: [
          l10n.onboardingQ5Morning,
          l10n.onboardingQ5Night,
          l10n.onboardingQ5Both,
        ],
      ),
      (
        question: l10n.onboardingQuestion6,
        options: [
          l10n.onboardingQ6No,
          l10n.onboardingQ6Yes,
          l10n.onboardingQ6Sometimes,
        ],
      ),
      (
        question: l10n.onboardingQuestion7,
        options: [
          l10n.onboardingQ7Regular,
          l10n.onboardingQ7Vegetarian,
          l10n.onboardingQ7Halal,
          l10n.onboardingQ7Vegan,
        ],
      ),
      (
        question: l10n.onboardingQuestion8,
        options: [
          l10n.onboardingQ8Single,
          l10n.onboardingQ8Divorced,
          l10n.onboardingQ8Widowed,
          l10n.onboardingQ8PreferNot,
        ],
      ),
      (
        question: l10n.onboardingQuestion9,
        options: [
          l10n.onboardingQ9Outdoors,
          l10n.onboardingQ9AtHome,
          l10n.onboardingQ9WithFriends,
          l10n.onboardingQ9NewThings,
        ],
      ),
      (
        question: l10n.onboardingQuestion10,
        options: [
          l10n.onboardingQ10Comedy,
          l10n.onboardingQ10Drama,
          l10n.onboardingQ10Action,
          l10n.onboardingQ10Romance,
          l10n.onboardingQ10Documentary,
        ],
      ),
      (
        question: l10n.onboardingQuestion11,
        options: [
          l10n.onboardingQ11Fun,
          l10n.onboardingQ11Calm,
          l10n.onboardingQ11Ambitious,
          l10n.onboardingQ11Creative,
          l10n.onboardingQ11Kind,
        ],
      ),
      (
        question: l10n.onboardingQuestion12,
        options: [
          l10n.onboardingQ12Local,
          l10n.onboardingQ12Malls,
          l10n.onboardingQ12Online,
          l10n.onboardingQ12Boutiques,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final questions = _buildQuestions(context);
    final total = questions.length;
    final progress = total > 0 ? (_currentIndex + 1) / total : 0.0;
    final q = questions[_currentIndex];
    final canGoBack = _currentIndex > 0;
    final canGoForward = _currentIndex < questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (canGoBack) {
                        setState(() => _currentIndex--);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.darkBlack,
                  ),
                  IconButton(
                    onPressed: () {
                      if (canGoForward) {
                        setState(() => _currentIndex++);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    color: AppColors.darkBlack,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.warmSandBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.neonCoral,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Padding(
                  key: ValueKey<int>(_currentIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        q.question,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlack,
                            ),
                      ),
                      const SizedBox(height: 32),
                      ...q.options.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _onOptionSelected(option),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.neonCoral,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(option),
                            ),
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
    );
  }

  Future<void> _onOptionSelected(String selectedOption) async {
    if (_isSaving) return;
    final questions = _buildQuestions(context);

    if (widget.preAuth) {
      while (_pendingAnswers.length <= _currentIndex) {
        _pendingAnswers.add('');
      }
      _pendingAnswers[_currentIndex] = selectedOption;
      if (!mounted) return;
      if (_currentIndex < questions.length - 1) {
        setState(() => _currentIndex++);
      } else {
        widget.onPreAuthComplete?.call(List<String>.from(_pendingAnswers));
      }
      return;
    }

    final profileId =
        Supabase.instance.client.auth.currentUser?.id;
    if (profileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mustSignInFirst),
          ),
        );
      }
      return;
    }
    try {
      setState(() => _isSaving = true);
      await ProfileAnswerService().insertAnswer(
        profileId: profileId,
        content: selectedOption,
        sortOrder: _currentIndex,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).answerSaved),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).authError} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    if (_currentIndex < questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      widget.onComplete?.call();
      if (widget.fromAuthScreen) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
