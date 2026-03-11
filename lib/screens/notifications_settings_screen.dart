import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

const String _kPrefPushEnabled = 'settings_push_notifications';
const String _kPrefNewMatches = 'settings_push_new_matches';
const String _kPrefNewMessages = 'settings_push_new_messages';
const String _kPrefLikes = 'settings_push_likes';

const String _kPrefEmailEnabled = 'settings_email_notifications';
const String _kPrefEmailMatches = 'settings_email_matches';
const String _kPrefEmailMessages = 'settings_email_messages';

/// شاشة إعدادات الإشعارات (دفع + بريد).
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key, required this.isPush});

  final bool isPush;

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _mainEnabled = false;
  bool _newMatches = true;
  bool _newMessages = true;
  bool _likes = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.isPush) {
      setState(() {
        _mainEnabled = prefs.getBool(_kPrefPushEnabled) ?? false;
        _newMatches = prefs.getBool(_kPrefNewMatches) ?? true;
        _newMessages = prefs.getBool(_kPrefNewMessages) ?? true;
        _likes = prefs.getBool(_kPrefLikes) ?? true;
        _loading = false;
      });
    } else {
      setState(() {
        _mainEnabled = prefs.getBool(_kPrefEmailEnabled) ?? false;
        _newMatches = prefs.getBool(_kPrefEmailMatches) ?? true;
        _newMessages = prefs.getBool(_kPrefEmailMessages) ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.isPush
        ? l10n.pushNotifications
        : l10n.emailNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  title: Text(
                    widget.isPush
                        ? 'Enable push notifications'
                        : 'Enable email notifications',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlack,
                    ),
                  ),
                  value: _mainEnabled,
                  onChanged: (v) => _set(
                    widget.isPush ? _kPrefPushEnabled : _kPrefEmailEnabled,
                    v,
                  ),
                  activeThumbColor: AppColors.hingePurple,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('New matches'),
                  value: _newMatches,
                  onChanged: _mainEnabled
                      ? (v) => _set(
                          widget.isPush ? _kPrefNewMatches : _kPrefEmailMatches,
                          v,
                        )
                      : null,
                  activeThumbColor: AppColors.hingePurple,
                ),
                SwitchListTile(
                  title: const Text('New messages'),
                  value: _newMessages,
                  onChanged: _mainEnabled
                      ? (v) => _set(
                          widget.isPush
                              ? _kPrefNewMessages
                              : _kPrefEmailMessages,
                          v,
                        )
                      : null,
                  activeThumbColor: AppColors.hingePurple,
                ),
                if (widget.isPush)
                  SwitchListTile(
                    title: const Text('Likes'),
                    value: _likes,
                    onChanged: _mainEnabled
                        ? (v) => _set(_kPrefLikes, v)
                        : null,
                    activeThumbColor: AppColors.hingePurple,
                  ),
              ],
            ),
    );
  }
}
