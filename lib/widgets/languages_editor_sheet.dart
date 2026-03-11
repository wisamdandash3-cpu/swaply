import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../constants/app_languages.dart';
import '../generated/l10n/app_localizations.dart';

/// ورقة اختيار اللغات (اختيار متعدد).
/// [currentValue] القيمة الحالية: "English, العربية" أو "en,ar" (مفصولة بفاصلة).
/// تُرجع القيمة المحفوظة: "English, العربية" (أسماء العرض).
Future<({String value, String visibility})?> showLanguagesEditorSheet({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String currentVisibility,
}) async {
  return showModalBottomSheet<({String value, String visibility})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LanguagesEditorSheet(
      title: title,
      currentValue: currentValue,
      currentVisibility: currentVisibility,
    ),
  );
}

class _LanguagesEditorSheet extends StatefulWidget {
  const _LanguagesEditorSheet({
    required this.title,
    required this.currentValue,
    required this.currentVisibility,
  });

  final String title;
  final String currentValue;
  final String currentVisibility;

  @override
  State<_LanguagesEditorSheet> createState() => _LanguagesEditorSheetState();
}

class _LanguagesEditorSheetState extends State<_LanguagesEditorSheet> {
  late Set<String> _selectedNames;
  late String _visibility;

  @override
  void initState() {
    super.initState();
    _selectedNames = _parseCurrentValue(widget.currentValue);
    final valid = ['hidden', 'visible', 'always_visible', 'always_hidden'];
    _visibility = valid.contains(widget.currentVisibility)
        ? widget.currentVisibility
        : 'hidden';
  }

  Set<String> _parseCurrentValue(String value) {
    if (value.trim().isEmpty) return {};
    final parts = value
        .split(RegExp(r'[,،،\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final names = kWorldLanguages.map((l) => l.name).toSet();
    final codes = kWorldLanguages.map((l) => l.code).toSet();
    final result = <String>{};
    for (final p in parts) {
      if (names.contains(p)) {
        result.add(p);
      } else if (codes.contains(p)) {
        final lang = kWorldLanguages.firstWhere((l) => l.code == p);
        result.add(lang.name);
      }
    }
    return result;
  }

  void _toggle(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  void _save() {
    final value = _selectedNames.toList()..sort();
    Navigator.of(
      context,
    ).pop((value: value.join(', '), visibility: _visibility));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: kWorldLanguages.length,
              itemBuilder: (context, index) {
                final lang = kWorldLanguages[index];
                final isSelected = _selectedNames.contains(lang.name);
                return InkWell(
                  onTap: () => _toggle(lang.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected
                              ? AppColors.hingePurple
                              : AppColors.darkBlack.withValues(alpha: 0.4),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.darkBlack,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Visibility',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlack.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.hingePurple, width: 2),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'hidden', child: Text(l10n.hidden)),
              DropdownMenuItem(value: 'visible', child: Text(l10n.visible)),
              DropdownMenuItem(
                value: 'always_visible',
                child: Text(l10n.alwaysVisible),
              ),
              DropdownMenuItem(
                value: 'always_hidden',
                child: Text(l10n.alwaysHidden),
              ),
            ],
            onChanged: (v) => setState(() => _visibility = v ?? 'hidden'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBlack,
                    side: BorderSide(
                      color: AppColors.darkBlack.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.hingePurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.postConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
