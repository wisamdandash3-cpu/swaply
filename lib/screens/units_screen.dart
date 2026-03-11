import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';

const String _kPrefUnits = 'settings_units';

/// خيارات وحدات القياس.
enum UnitsOption {
  metric('Kilometres, Centimetres', 'km_cm'),
  imperial('Miles, Feet', 'mi_ft');

  const UnitsOption(this.displayName, this.value);
  final String displayName;
  final String value;
}

/// شاشة اختيار وحدات القياس.
class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final UserSettingsService _userSettings = UserSettingsService();
  String _selected = 'km_cm';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    var selected = prefs.getString(_kPrefUnits) ?? 'km_cm';
    if (userId != null) {
      final fromDb = await _userSettings.getUnits(userId);
      if (fromDb != null) {
        selected = fromDb;
        await prefs.setString(_kPrefUnits, selected);
      }
    }
    if (mounted) {
      setState(() {
        _selected = selected;
        _loading = false;
      });
    }
  }

  Future<void> _select(UnitsOption opt) async {
    setState(() => _selected = opt.value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefUnits, opt.value);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _userSettings.setUnits(userId, opt.value);
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
          l10n.unitsOfMeasurement,
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
              children: UnitsOption.values
                  .map(
                    (opt) => RadioListTile<String>(
                      title: Text(opt.displayName),
                      value: opt.value,
                      groupValue: _selected,
                      onChanged: (_) => _select(opt),
                      activeColor: AppColors.hingePurple,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
