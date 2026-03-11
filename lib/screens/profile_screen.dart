import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_fields_service.dart';
import '../services/user_settings_service.dart';
import '../utils/profile_completion.dart';
import '../widgets/verified_badge.dart';
import 'edit_profile_screen.dart';
import 'verification_flow_screen.dart';

/// شاشة البروفايل بتصميم مشابه لـ Hinge: قسم عنوان (صورة دائرية، نسبة إنجاز، اسم، غير مكتمل)، تبويبات، ومحتوى.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isVisible = true});

  final bool isVisible;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _profileCompletionPercent;
  String? _profilePhotoUrl; // أول صورة من profile_answers (نوع image)
  bool _isVerified = false;
  final ProfileFieldsService _profileFields = ProfileFieldsService();
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final UserSettingsService _userSettings = UserSettingsService();
  bool _loadedWhenVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _scheduleLoadWhenVisible();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) _scheduleLoadWhenVisible();
  }

  void _scheduleLoadWhenVisible() {
    if (_loadedWhenVisible || !mounted) return;
    _loadedWhenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCompletion();
    });
  }

  Future<void> _loadCompletion() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _profileCompletionPercent = 0;
          _profilePhotoUrl = null;
        });
      }
      return;
    }
    try {
      final fields = await _profileFields.getFields(userId);
      final answers = await _answerService.getByProfileId(userId);
      if (!mounted) return;
      final percent = ProfileCompletion.computePercent(
        answers: answers,
        fields: fields,
      );
      // أول صورة: من إجابات نوع image (sort_order 200–205) ومحتواها رابط
      final firstPhoto =
          answers
              .where((a) => a.isImage && a.content.trim().isNotEmpty)
              .where((a) => a.sortOrder >= 200 && a.sortOrder < 206)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final photoUrl = firstPhoto.isNotEmpty
          ? firstPhoto.first.content.trim()
          : null;
      final verified = await _userSettings.getSelfieVerificationStatus(userId);
      if (!mounted) return;
      setState(() {
        _profileCompletionPercent = percent;
        _profilePhotoUrl = photoUrl;
        _isVerified = verified == 'verified';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileCompletionPercent = 0;
          _profilePhotoUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _ProfileHeader(
            displayName: displayName.isEmpty ? l10n.tabProfile : displayName,
            completionPercent: _profileCompletionPercent ?? 0,
            profilePhotoUrl: _profilePhotoUrl,
            isVerified: _isVerified,
            onEditPhoto: () => _openEditProfile(context),
            onVerificationTap: () => _openVerificationFlow(context),
          ),
          const SizedBox(height: 24),
          _CompleteProfileCard(
            completionPercent: _profileCompletionPercent ?? 0,
            title: l10n.profileCompleteness,
            description: l10n.profileCompletenessMotivation,
            buttonLabel: l10n.editProfile,
            profilePhotoUrl: _profilePhotoUrl,
            onButtonPressed: () => _openEditProfile(context),
          ),
          const SizedBox(height: 16),
          _ProfileCard(
            icon: Icons.help_outline,
            title: l10n.helpCentre,
            description: l10n.helpCentreDesc,
          ),
          const SizedBox(height: 16),
          _ProfileCard(
            icon: Icons.lightbulb_outline,
            title: l10n.whatWorks,
            description: l10n.whatWorksDesc,
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => EditProfileScreen(
              userId: userId,
              onComplete: () => Navigator.of(context).pop(),
            ),
          ),
        )
        .then((_) async {
          await _loadCompletion();
          if (mounted) setState(() {});
        });
  }

  void _openVerificationFlow(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const VerificationFlowScreen(),
          ),
        )
        .then((_) async {
          await _loadCompletion();
          if (mounted) setState(() {});
        });
  }
}

/// علامة توثيق مع أيقونة قلم بداخلها (دائرة سلمونية + قلم أبيض كما في التصميم المرجعي).
class _VerificationBadgeWithEdit extends StatelessWidget {
  const _VerificationBadgeWithEdit({
    required this.size,
    required this.onTap,
    this.isUnverified = false,
  });

  final double size;
  final VoidCallback onTap;
  final bool isUnverified;

  static const Color _penCircleColor = Color(0xFFE8A598);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        isUnverified
            ? Icon(
                Icons.check_circle_outline,
                size: size,
                color: AppColors.darkBlack.withValues(alpha: 0.5),
              )
            : VerifiedBadge(size: size),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: _penCircleColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size * 0.75,
                height: size * 0.75,
                child: Icon(
                  Icons.edit_outlined,
                  size: size * 0.45,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// قسم العنوان: صورة دائرية، أيقونة تعديل، مؤشر نسبة الإنجاز، الاسم مع علامة الصح، وعنوان فرعي "ملف شخصي غير مكتمل".
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.completionPercent,
    this.profilePhotoUrl,
    this.isVerified = false,
    required this.onEditPhoto,
    this.onVerificationTap,
  });

  final String displayName;
  final int completionPercent;
  final String? profilePhotoUrl;
  final bool isVerified;
  final VoidCallback onEditPhoto;
  final VoidCallback? onVerificationTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const double avatarSize = 112;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkWhite,
                border: Border.all(
                  color: AppColors.darkBlack.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                        profilePhotoUrl!,
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 56,
                          color: AppColors.darkBlack.withValues(alpha: 0.25),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 56,
                        color: AppColors.darkBlack.withValues(alpha: 0.25),
                      ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditPhoto,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkBlack.withValues(alpha: 0.75),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.hingePurple,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkBlack.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$completionPercent%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: InkWell(
            onTap: onVerificationTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkBlack,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  _VerificationBadgeWithEdit(
                    size: 24,
                    onTap: onVerificationTap ?? () {},
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  _VerificationBadgeWithEdit(
                    size: 24,
                    onTap: onVerificationTap ?? () {},
                    isUnverified: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.incompleteProfile,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkBlack.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// بطاقة "إكمال البروفايل" بأسلوب Parship: نسبة، شريط تقدم، رسالة تحفيزية.
class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard({
    required this.completionPercent,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.profilePhotoUrl,
    required this.onButtonPressed,
  });

  final int completionPercent;
  final String title;
  final String description;
  final String buttonLabel;
  final String? profilePhotoUrl;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        profilePhotoUrl != null && profilePhotoUrl!.trim().isNotEmpty;
    return GestureDetector(
      onTap: onButtonPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.darkBlack.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlack.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.darkBlack.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? Image.network(
                                profilePhotoUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_outline,
                                  size: 30,
                                  color: AppColors.darkBlack.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person_outline,
                                size: 30,
                                color: AppColors.darkBlack.withValues(alpha: 0.4),
                              ),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCoral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonCoral,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completionPercent%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlack,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completionPercent / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.darkBlack.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.neonCoral,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkBlack.withValues(alpha: 0.65),
                          height: 1.35,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.darkBlack.withValues(alpha: 0.4),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onButtonPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.darkBlack,
                    side: BorderSide(
                      color: AppColors.darkBlack.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBlack.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlack.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.darkBlack.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: AppColors.darkBlack.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBlack.withValues(alpha: 0.65),
                    height: 1.35,
                    fontSize: 14,
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
