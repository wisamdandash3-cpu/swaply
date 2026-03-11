import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';

const String _kPrefProfileVisibility = 'settings_profile_visibility';
const String _kPrefShowDistance = 'settings_show_distance';

/// شاشة تفضيلات الخصوصية.
class PrivacyPreferencesScreen extends StatefulWidget {
  const PrivacyPreferencesScreen({super.key});

  @override
  State<PrivacyPreferencesScreen> createState() =>
      _PrivacyPreferencesScreenState();
}

class _PrivacyPreferencesScreenState extends State<PrivacyPreferencesScreen> {
  final UserSettingsService _userSettings = UserSettingsService();
  String _profileVisibility = 'everyone';
  bool _showDistance = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var visibility = prefs.getString(_kPrefProfileVisibility) ?? 'everyone';
    var showDistance = prefs.getBool(_kPrefShowDistance) ?? true;
    if (userId != null) {
      final fromDb = await _userSettings.getPrivacyPreferences(userId);
      if (fromDb != null) {
        visibility = fromDb['visibility'] ?? visibility;
        showDistance = fromDb['show_distance'] ?? showDistance;
        await prefs.setString(_kPrefProfileVisibility, visibility);
        await prefs.setBool(_kPrefShowDistance, showDistance);
      }
    }
    if (mounted) {
      setState(() {
        _profileVisibility = visibility;
        _showDistance = showDistance;
        _loading = false;
      });
    }
  }

  Future<void> _setVisibility(String v) async {
    setState(() => _profileVisibility = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefProfileVisibility, v);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _userSettings.setPrivacyPreferences(
        userId,
        visibility: v,
        showDistance: _showDistance,
      );
    }
  }

  Future<void> _setShowDistance(bool v) async {
    setState(() => _showDistance = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefShowDistance, v);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _userSettings.setPrivacyPreferences(
        userId,
        visibility: _profileVisibility,
        showDistance: v,
      );
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
          l10n.privacyPreferences,
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
                Text(
                  'Profile visibility',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkBlack.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Everyone'),
                  value: 'everyone',
                  groupValue: _profileVisibility,
                  onChanged: (v) => v != null ? _setVisibility(v) : null,
                  activeColor: AppColors.hingePurple,
                ),
                RadioListTile<String>(
                  title: const Text('Only my matches'),
                  value: 'matches_only',
                  groupValue: _profileVisibility,
                  onChanged: (v) => v != null ? _setVisibility(v) : null,
                  activeColor: AppColors.hingePurple,
                ),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Show distance on profile'),
                  subtitle: const Text(
                    'Others can see approximate distance to you',
                  ),
                  value: _showDistance,
                  onChanged: _setShowDistance,
                  activeThumbColor: AppColors.hingePurple,
                ),
              ],
            ),
    );
  }
}
