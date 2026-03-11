import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/filter_preferences_service.dart';
import '../services/subscription_service.dart';
import '../widgets/profile_field_editor_sheet.dart' show showFilterHeightPickerSheet, kOpenToAllFilterValue;
import 'edit_profile_screen.dart';
import 'location_picker_screen.dart';
import 'subscription_screen.dart';

/// شاشة تفضيلات المواعدة (الفلاتر): تفضيلات الأعضاء وتفضيلات المشتركين.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final FilterPreferencesService _prefs = FilterPreferencesService();
  Map<String, String?> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
    SubscriptionService.instance.refreshSubscriptionStatus().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final v = await _prefs.load();
    if (mounted) setState(() => _values = v);
  }

  Future<void> _save(String key, String value) async {
    await _prefs.save(key, value);
    if (mounted) setState(() => _values[key] = value);
  }

  static const String _kOpenToAll = 'Open to all';

  List<(String key, String label)> _ethnicityOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Asian', l10n.filterEthnicityAsian),
    ('Black', l10n.filterEthnicityBlack),
    ('White', l10n.filterEthnicityWhite),
    ('Latino', l10n.filterEthnicityLatino),
    ('Middle Eastern', l10n.filterEthnicityMiddleEastern),
    ('Other', l10n.filterEthnicityOther),
  ];

  List<(String key, String label)> _religionOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Agnostic', l10n.postReligionAgnostic),
    ('Atheist', l10n.postReligionAtheist),
    ('Buddhist', l10n.postReligionBuddhist),
    ('Catholic', l10n.postReligionCatholic),
    ('Christian', l10n.postReligionChristian),
    ('Hindu', l10n.postReligionHindu),
    ('Jewish', l10n.postReligionJewish),
    ('Muslim', l10n.postReligionMuslim),
    ('Other', l10n.postReligionOther),
  ];

  List<(String key, String label)> _relationshipTypeOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Monogamy', l10n.filterRelationshipMonogamy),
    ('Non-monogamy', l10n.filterRelationshipNonMonogamy),
    ('Open to both', l10n.filterRelationshipOpenToBoth),
  ];

  List<(String key, String label)> _datingIntentionsOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Relationship', l10n.filterDatingRelationship),
    ('Something casual', l10n.filterDatingCasual),
    ('Not sure yet', l10n.filterDatingNotSure),
  ];

  List<(String key, String label)> _childrenOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Have kids', l10n.filterChildrenHaveKids),
    ('Want kids', l10n.filterChildrenWantKids),
    ("Don't want kids", l10n.filterChildrenDontWant),
    ('Not sure', l10n.filterChildrenNotSure),
  ];

  List<(String key, String label)> _familyPlansOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Want', l10n.postFamilyWant),
    ("Don't want", l10n.postFamilyDontWant),
    ('Open', l10n.postFamilyOpen),
    ('Not sure', l10n.postFamilyNotSure),
  ];

  List<(String key, String label)> _yesSometimesNoOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Yes', l10n.postYes),
    ('Sometimes', l10n.postSometimes),
    ('No', l10n.postNo),
  ];

  List<(String key, String label)> _politicsOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Liberal', l10n.postPoliticalLiberal),
    ('Moderate', l10n.postPoliticalModerate),
    ('Conservative', l10n.postPoliticalConservative),
    ('Other', l10n.postPoliticalOther),
  ];

  List<(String key, String label)> _educationOptions(AppLocalizations l10n) => [
    (_kOpenToAll, l10n.openToAll),
    ('Secondary', l10n.postEduSecondary),
    ('Undergrad', l10n.postEduUndergrad),
    ('Postgrad', l10n.postEduPostgrad),
  ];

  String _getFilterDisplay(String prefKey, String? valueKey, AppLocalizations l10n) {
    if (valueKey == null || valueKey.isEmpty) return l10n.openToAll;
    final list = switch (prefKey) {
      'ethnicity' => _ethnicityOptions(l10n),
      'religion' => _religionOptions(l10n),
      'relationshipType' => _relationshipTypeOptions(l10n),
      'datingIntentions' => _datingIntentionsOptions(l10n),
      'children' => _childrenOptions(l10n),
      'familyPlans' => _familyPlansOptions(l10n),
      'drugs' || 'smoking' || 'marijuana' || 'drinking' => _yesSometimesNoOptions(l10n),
      'politics' => _politicsOptions(l10n),
      'educationLevel' => _educationOptions(l10n),
      'interestedIn' => [(_kOpenToAll, l10n.openToAll), ('Men', l10n.men), ('Women', l10n.women), ('Everyone', l10n.everyone)],
      _ => <(String, String)>[],
    };
    for (final o in list) {
      if (o.$1 == valueKey) return o.$2;
    }
    return valueKey;
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
          l10n.datingPreferences,
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
          _sectionHeader(l10n.memberPreferences),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              onTap: () {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => EditProfileScreen(
                        userId: userId,
                        onComplete: () {
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                }
              },
              child: Text(
                l10n.completeProfileToUnlock,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.neonCoral,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _filterRow(
            l10n.imInterestedIn,
            _getFilterDisplay('interestedIn', _values['interestedIn'], l10n),
            () => _showChoice(context, 'interestedIn', [
              (_kOpenToAll, l10n.openToAll),
              ('Men', l10n.men),
              ('Women', l10n.women),
              ('Everyone', l10n.everyone),
            ], _values['interestedIn']),
          ),
          _divider(),
          _filterRow(
            l10n.myNeighbourhood,
            _values['neighbourhood'] ?? l10n.openToAll,
            () => _showLocationPicker(context),
          ),
          _divider(),
          _filterRow(
            l10n.maximumDistance,
            _values['maxDistance'] ?? '160 km',
            () => _showDistanceSlider(context),
          ),
          _filterRow(
            l10n.ageRange,
            _values['ageMin'] != null && _values['ageMax'] != null
                ? '${_values['ageMin']}-${_values['ageMax']}'
                : l10n.openToAll,
            () => _showAgeRange(context),
          ),
          _filterRow(
            l10n.ethnicity,
            _getFilterDisplay('ethnicity', _values['ethnicity'], l10n),
            () => _showChoice(context, 'ethnicity', _ethnicityOptions(l10n), _values['ethnicity']),
          ),
          _filterRow(
            l10n.religion,
            _getFilterDisplay('religion', _values['religion'], l10n),
            () => _showChoice(context, 'religion', _religionOptions(l10n), _values['religion']),
          ),
          _filterRow(
            l10n.relationshipType,
            _getFilterDisplay('relationshipType', _values['relationshipType'], l10n),
            () => _showChoice(context, 'relationshipType', _relationshipTypeOptions(l10n), _values['relationshipType']),
          ),
          _sectionDivider(),
          _sectionHeader(l10n.subscriberPreferences),
          _upgradeBox(l10n),
          if (SubscriptionService.instance.isSubscribed) ...[
            _filterRow(
              l10n.height,
              _values['height'] == kOpenToAllFilterValue ? l10n.openToAll : (_values['height'] ?? l10n.openToAll),
              () => _showFilterHeightPicker(context),
            ),
            _filterRow(
              l10n.datingIntentions,
              _getFilterDisplay('datingIntentions', _values['datingIntentions'], l10n),
              () => _showChoice(context, 'datingIntentions', _datingIntentionsOptions(l10n), _values['datingIntentions']),
            ),
            _filterRow(
              l10n.children,
              _getFilterDisplay('children', _values['children'], l10n),
              () => _showChoice(context, 'children', _childrenOptions(l10n), _values['children']),
            ),
            _filterRow(
              l10n.familyPlans,
              _getFilterDisplay('familyPlans', _values['familyPlans'], l10n),
              () => _showChoice(context, 'familyPlans', _familyPlansOptions(l10n), _values['familyPlans']),
            ),
            _filterRow(
              l10n.drugs,
              _getFilterDisplay('drugs', _values['drugs'], l10n),
              () => _showChoice(context, 'drugs', _yesSometimesNoOptions(l10n), _values['drugs']),
            ),
            _filterRow(
              l10n.smoking,
              _getFilterDisplay('smoking', _values['smoking'], l10n),
              () => _showChoice(context, 'smoking', _yesSometimesNoOptions(l10n), _values['smoking']),
            ),
            _filterRow(
              l10n.marijuana,
              _getFilterDisplay('marijuana', _values['marijuana'], l10n),
              () => _showChoice(context, 'marijuana', _yesSometimesNoOptions(l10n), _values['marijuana']),
            ),
            _filterRow(
              l10n.drinking,
              _getFilterDisplay('drinking', _values['drinking'], l10n),
              () => _showChoice(context, 'drinking', _yesSometimesNoOptions(l10n), _values['drinking']),
            ),
            _filterRow(
              l10n.politics,
              _getFilterDisplay('politics', _values['politics'], l10n),
              () => _showChoice(context, 'politics', _politicsOptions(l10n), _values['politics']),
            ),
            _filterRow(
              l10n.educationLevel,
              _getFilterDisplay('educationLevel', _values['educationLevel'], l10n),
              () => _showChoice(context, 'educationLevel', _educationOptions(l10n), _values['educationLevel']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.darkBlack,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.darkBlack.withValues(alpha: 0.08));
  }

  Widget _sectionDivider() {
    return const SizedBox(height: 16);
  }

  Widget _upgradeBox(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hingePurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hingePurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.hingePurple,
              side: const BorderSide(color: AppColors.hingePurple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(l10n.upgrade),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.fineTuneWithSubscription,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkBlack.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(String title, String value, VoidCallback onTap) {
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBlack.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.darkBlack.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDistanceSlider(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentStr = _values['maxDistance'] ?? '160';
    final currentVal = int.tryParse(currentStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 160;
    double value = currentVal.clamp(1, 500).toDouble();

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.maximumDistance,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${value.round()} km',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hingePurple,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: value,
                  min: 1,
                  max: 500,
                  divisions: 499,
                  activeColor: AppColors.hingePurple,
                  onChanged: (v) => setModalState(() => value = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 km', style: TextStyle(fontSize: 12, color: AppColors.darkBlack.withValues(alpha: 0.6))),
                    Text('500 km', style: TextStyle(fontSize: 12, color: AppColors.darkBlack.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.back),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, '${value.round()} km'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.hingePurple),
                        child: Text(l10n.postConfirm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (chosen != null) await _save('maxDistance', chosen);
  }

  Future<void> _showFilterHeightPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentHeight = _values['height'] ?? l10n.openToAll;
    final chosen = await showFilterHeightPickerSheet(
      context: context,
      title: l10n.height,
      currentValue: currentHeight == kOpenToAllFilterValue ? l10n.openToAll : currentHeight,
      openToAllLabel: l10n.openToAll,
    );
    if (chosen != null) await _save('height', chosen);
  }

  Future<void> _showChoice(BuildContext context, String prefKey, List<(String key, String label)> options, String? currentKey) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: ListView(
              shrinkWrap: true,
              children: options
                  .map((o) => ListTile(
                        title: Text(o.$2),
                        onTap: () => Navigator.pop(ctx, o.$1),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
    if (chosen != null) await _save(prefKey, chosen);
  }

  Future<void> _showLocationPicker(BuildContext context) async {
    final address = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => LocationPickerScreen(
          initialAddress: _values['neighbourhood'],
        ),
      ),
    );
    if (address != null && address.isNotEmpty) {
      await _save('neighbourhood', address);
    }
  }

  Future<void> _showAgeRange(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final minVal = int.tryParse(_values['ageMin'] ?? '24') ?? 24;
    final maxVal = int.tryParse(_values['ageMax'] ?? '39') ?? 39;
    RangeValues values = RangeValues(
      minVal.clamp(18, 100).toDouble(),
      maxVal.clamp(18, 100).toDouble(),
    );
    if (values.start > values.end) values = RangeValues(values.end, values.start);

    final chosen = await showModalBottomSheet<({String min, String max})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.ageRange,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${values.start.round()} - ${values.end.round()} ${l10n.years}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hingePurple,
                  ),
                ),
                const SizedBox(height: 20),
                RangeSlider(
                  values: values,
                  min: 18,
                  max: 100,
                  divisions: 82,
                  activeColor: AppColors.hingePurple,
                  onChanged: (v) => setModalState(() => values = v),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18', style: TextStyle(fontSize: 12, color: AppColors.darkBlack.withValues(alpha: 0.6))),
                    Text('100', style: TextStyle(fontSize: 12, color: AppColors.darkBlack.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.back),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, (min: '${values.start.round()}', max: '${values.end.round()}')),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.hingePurple),
                        child: Text(l10n.postConfirm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (chosen != null) {
      await _save('ageMin', chosen.min);
      await _save('ageMax', chosen.max);
    }
  }
}
