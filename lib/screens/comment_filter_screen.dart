import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';

const String _kPrefCommentFilter = 'settings_comment_filter';

/// شاشة تصفية التعليقات: إخفاء الإعجابات من أشخاص يستخدمون لغة غير محترمة.
class CommentFilterScreen extends StatefulWidget {
  const CommentFilterScreen({super.key});

  @override
  State<CommentFilterScreen> createState() => _CommentFilterScreenState();
}

class _CommentFilterScreenState extends State<CommentFilterScreen> {
  final UserSettingsService _userSettings = UserSettingsService();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var enabled = prefs.getBool(_kPrefCommentFilter) ?? false;
    if (userId != null) {
      enabled = await _userSettings.getCommentFilterEnabled(userId);
      await prefs.setBool(_kPrefCommentFilter, enabled);
    }
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefCommentFilter, value);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _userSettings.setCommentFilterEnabled(userId, value);
    }
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
        title: Text(
          l10n.commentFilter,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.commentFilterDesc,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkBlack.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: Text(
                      l10n.commentFilter,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    subtitle: Text(
                      'Hide likes from people who use disrespectful language',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.6),
                      ),
                    ),
                    value: _enabled,
                    onChanged: _setEnabled,
                    activeThumbColor: AppColors.hingePurple,
                  ),
                ],
              ),
            ),
    );
  }
}
