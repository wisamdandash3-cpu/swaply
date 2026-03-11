import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../services/delete_account_service.dart';
import '../services/subscription_service.dart';
import '../services/user_settings_service.dart';
import '../app_locale_scope.dart';
import '../constants/app_languages.dart';
import '../generated/l10n/app_localizations.dart';
import '../widgets/edit_email_sheet.dart';
import 'block_list_screen.dart';
import 'comment_filter_screen.dart';
import 'download_data_screen.dart';
import 'edit_profile_screen.dart';
import 'legal_screen.dart';
import 'licenses_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_preferences_screen.dart';
import 'verification_flow_screen.dart';
import 'subscription_screen.dart';
import 'units_screen.dart';

const String _kPrefPause = 'settings_pause';
const String _kPrefShowLastActive = 'settings_show_last_active';
const String _kPrefAudioTranscripts = 'settings_audio_transcripts';
const String _kPrefGoogleConnected = 'settings_google_connected';
const String _kPrefAppleConnected = 'settings_apple_connected';
const String _kPrefUnits = 'settings_units';

/// شاشة إعدادات الحساب: الملف الشخصي، الأمان، الهاتف والبريد، الإشعارات، الاشتراك، اللغة، الحسابات المرتبطة، قانوني، المجتمع، تسجيل الخروج وحذف الحساب.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pause = false;
  bool _showLastActive = true;
  bool _audioTranscripts = false;
  bool _googleConnected = false;
  bool _appleConnected = false;
  String _unitsDisplay = 'Kilometres, Centimetres';
  /// ضمير المخاطب في رسائل الهدية: 'male' (له) أو 'female' (لها)
  String _recipientPronoun = 'male';

  final UserSettingsService _userSettings = UserSettingsService();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var pause = prefs.getBool(_kPrefPause) ?? false;
    var showLastActive = prefs.getBool(_kPrefShowLastActive) ?? true;
    if (userId != null) {
      pause = await _userSettings.isPaused(userId);
      showLastActive = await _userSettings.getShowLastActive(userId);
      await prefs.setBool(_kPrefPause, pause);
      await prefs.setBool(_kPrefShowLastActive, showLastActive);
    }
    var unitsDisplay = 'Kilometres, Centimetres';
    final u = prefs.getString(_kPrefUnits);
    if (userId != null) {
      final units = await _userSettings.getUnits(userId) ?? u;
      if (units == 'mi_ft') unitsDisplay = 'Miles, Feet';
    } else if (u == 'mi_ft') {
      unitsDisplay = 'Miles, Feet';
    }
    var recipientPronoun = 'male';
    if (userId != null) {
      recipientPronoun = await _userSettings.getPreferredRecipientPronoun(userId);
    }
    if (mounted) {
      setState(() {
        _pause = pause;
        _showLastActive = showLastActive;
        _audioTranscripts = prefs.getBool(_kPrefAudioTranscripts) ?? false;
        _googleConnected = prefs.getBool(_kPrefGoogleConnected) ?? false;
        _appleConnected = prefs.getBool(_kPrefAppleConnected) ?? false;
        _unitsDisplay = unitsDisplay;
        _recipientPronoun = recipientPronoun;
      });
    }
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.accountSettings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _sectionHeader(l10n.profileSection),
          _switchRow(
            title: l10n.settingsPause,
            subtitle: l10n.settingsPauseDesc,
            value: _pause,
            onChanged: (v) async {
              setState(() => _pause = v);
              await _setPref(_kPrefPause, v);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) await _userSettings.setPause(userId, v);
            },
          ),
          _divider(),
          _switchRow(
            title: l10n.showLastActive,
            subtitle: l10n.showLastActiveDesc,
            value: _showLastActive,
            onChanged: (v) async {
              setState(() => _showLastActive = v);
              await _setPref(_kPrefShowLastActive, v);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) await _userSettings.setShowLastActive(userId, v);
            },
          ),
          _sectionDivider(),
          _sectionHeader(l10n.safetySection),
          _navRow(
            title: l10n.selfieVerification,
            subtitle: l10n.selfieVerificationDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const VerificationFlowScreen(),
              ),
            ),
          ),
          _divider(),
          _navRow(
            title: l10n.blockList,
            subtitle: l10n.blockListDesc,
            onTap: () => _openBlockList(context),
          ),
          _divider(),
          _navRow(
            title: l10n.commentFilter,
            subtitle: l10n.commentFilterDesc,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CommentFilterScreen(),
              ),
            ),
          ),
          _sectionDivider(),
          _sectionHeader(l10n.phoneAndEmail),
          if (phone.isNotEmpty)
            _valueRow(phone, verified: true),
          if (phone.isNotEmpty) _divider(),
          if (email.isNotEmpty)
            _valueRow(email, verified: true, trailing: l10n.edit, onTap: () => _openEditEmail(context, email)),
          if (email.isEmpty && phone.isEmpty)
            _navRow(title: l10n.phoneAndEmail, subtitle: l10n.edit, onTap: () => _showComingSoon(context)),
          _sectionDivider(),
          _sectionHeader(l10n.notificationsSection),
          _navRow(title: l10n.pushNotifications, onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsSettingsScreen(isPush: true),
            ),
          )),
          _divider(),
          _navRow(title: l10n.emailNotifications, onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsSettingsScreen(isPush: false),
            ),
          )),
          _sectionDivider(),
          _sectionHeader(l10n.subscriptionSection),
          _navRow(
            title: l10n.completeProfileMember,
            subtitle: l10n.notSubscribed,
            onTap: () => _openCompleteProfile(context),
          ),
          _divider(),
          _navRow(title: l10n.subscribeToApp, onTap: () => _openSubscription(context)),
          _divider(),
          _navRow(title: l10n.restoreSubscription, onTap: () => _restoreSubscription(context)),
          _sectionDivider(),
          _sectionHeader(l10n.languageAndRegion),
          _navRow(
            title: l10n.appLanguage,
            subtitle: _localeDisplayName(context),
            onTap: () => _openAppLanguagePicker(context),
          ),
          _divider(),
          _switchRow(
            title: l10n.audioTranscripts,
            subtitle: l10n.audioTranscriptsDesc,
            value: _audioTranscripts,
            onChanged: (v) async {
              setState(() => _audioTranscripts = v);
              await _setPref(_kPrefAudioTranscripts, v);
            },
          ),
          _divider(),
          _navRow(
            title: l10n.unitsOfMeasurement,
            subtitle: _unitsDisplay,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UnitsScreen(),
              ),
            ).then((_) => _loadPrefs()),
          ),
          _divider(),
          _navRow(
            title: l10n.pronounSettingLabel,
            subtitle: _recipientPronoun == 'female'
                ? l10n.pronounOptionFemale
                : l10n.pronounOptionMale,
            onTap: () => _openPronounPicker(context),
          ),
          _sectionDivider(),
          _sectionHeader(l10n.connectedAccounts),
          _switchRow(
            title: 'Google',
            value: _googleConnected,
            onChanged: (v) async {
              setState(() => _googleConnected = v);
              await _setPref(_kPrefGoogleConnected, v);
            },
          ),
          _divider(),
          _switchRow(
            title: 'Apple',
            value: _appleConnected,
            onChanged: (v) async {
              setState(() => _appleConnected = v);
              await _setPref(_kPrefAppleConnected, v);
            },
          ),
          _sectionDivider(),
          _sectionHeader(l10n.legalSection),
          _navRow(
            title: l10n.privacyPolicy,
            onTap: () => _openLegal(context, LegalType.privacy),
          ),
          _divider(),
          _navRow(
            title: l10n.termsOfUse,
            onTap: () => _openLegal(context, LegalType.terms),
          ),
          _divider(),
          _navRow(title: l10n.privacyPreferences, onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrivacyPreferencesScreen(),
            ),
          )),
          _divider(),
          _navRow(title: l10n.licences, onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LicensesScreen(),
            ),
          )),
          _divider(),
          _navRow(title: l10n.downloadMyData, onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DownloadDataScreen(),
            ),
          )),
          _sectionDivider(),
          _sectionHeader(l10n.communitySection),
          _navRow(title: l10n.safeDatingTips, onTap: () => _openLegal(context, LegalType.safeDatingTips)),
          _divider(),
          _navRow(title: l10n.memberPrinciples, onTap: () => _openLegal(context, LegalType.memberPrinciples)),
          _sectionDivider(),
          const SizedBox(height: 16),
          _actionButton(
            context,
            label: l10n.logOut,
            onTap: () => _onLogOut(context),
          ),
          const SizedBox(height: 12),
          _actionButton(
            context,
            label: l10n.deleteOrPauseAccount,
            onTap: () => _onDeleteOrPause(context),
          ),
        ],
      ),
    );
  }

  String _localeDisplayName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final match = kWorldLanguages.where((l) => l.code == code);
    return match.isEmpty ? code : match.first.name;
  }

  Future<void> _openPronounPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.pronounSettingLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlack,
                ),
              ),
            ),
            ListTile(
              title: Text(l10n.pronounOptionMale),
              onTap: () => Navigator.pop(ctx, 'male'),
            ),
            ListTile(
              title: Text(l10n.pronounOptionFemale),
              onTap: () => Navigator.pop(ctx, 'female'),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      await _userSettings.setPreferredRecipientPronoun(userId, chosen);
      setState(() => _recipientPronoun = chosen);
    }
  }

  void _openAppLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.warmSand,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  AppLocalizations.of(context).chooseLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: kWorldLanguages.length,
                  itemBuilder: (_, index) {
                    final lang = kWorldLanguages[index];
                    final currentCode = Localizations.localeOf(context).languageCode;
                    final isSelected = currentCode == lang.code;
                    return Material(
                      color: isSelected
                          ? AppColors.darkBlack.withOpacity(0.08)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await LocaleScope.of(context).setLocale(Locale(lang.code));
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Text(
                            lang.name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.darkBlack,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkBlack.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.darkBlack.withValues(alpha: 0.08));
  }

  Widget _sectionDivider() {
    return const SizedBox(height: 8);
  }

  Widget _switchRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBlack.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.hingePurple.withValues(alpha: 0.5),
            activeThumbColor: AppColors.hingePurple,
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlack,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkBlack),
          ],
        ),
      ),
    );
  }

  Widget _valueRow(
    String value, {
    bool verified = false,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkBlack,
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check, size: 18, color: AppColors.forestGreen),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.hingePurple,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlack,
          ),
        ),
      ),
    );
  }

  Future<void> _openBlockList(BuildContext context) async {
    final goToFeatured = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const BlockListScreen(),
      ),
    );
    if (goToFeatured == true && context.mounted) {
      Navigator.of(context).pop(1);
    }
  }

  void _openLegal(BuildContext context, LegalType type) {
    final locale = Localizations.localeOf(context).languageCode;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LegalScreen(type: type, languageCode: locale),
      ),
    );
  }

  void _openEditEmail(BuildContext context, String currentEmail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditEmailSheet(
        currentEmail: currentEmail,
        onSaved: () {
          _loadPrefs();
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).comingSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCompleteProfile(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditProfileScreen(
          userId: userId,
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openSubscription(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _restoreSubscription(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (!SubscriptionService.instance.isPaymentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentComingSoon),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await SubscriptionService.instance.refreshSubscriptionStatus();
    if (!context.mounted) return;
    if (SubscriptionService.instance.isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionRestoreSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionRestoreFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onLogOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _onDeleteOrPause(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteOrPauseAccount),
        content: Text(AppLocalizations.of(context).deleteOrPauseDialogDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'pause'),
            child: Text(AppLocalizations.of(context).pauseAccount),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: Text(
              AppLocalizations.of(context).postConfirm,
              style: const TextStyle(color: AppColors.neonCoral),
            ),
          ),
        ],
      ),
    );
    if (choice == 'pause' && context.mounted) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _userSettings.setPause(userId, true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kPrefPause, true);
        if (context.mounted) {
          setState(() => _pause = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).answerSaved),
              backgroundColor: AppColors.forestGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (choice == 'delete' && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).deleteOrPauseAccount),
          content: Text(AppLocalizations.of(context).deletePermanentWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppLocalizations.of(context).postConfirm,
                style: const TextStyle(color: AppColors.neonCoral),
              ),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      final l10n = AppLocalizations.of(context);
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }
      final err = await DeleteAccountService().deleteCurrentUser();
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        if (err == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.answerSaved),
              backgroundColor: AppColors.forestGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $err'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
