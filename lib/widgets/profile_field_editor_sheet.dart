import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

/// قيم الطول بالسنتيمتر للعجلة (140–220 سم).
const int kHeightPickerMinCm = 140;
const int kHeightPickerMaxCm = 220;

/// قيمة ثابتة محفوظة للفلتر "مفتوح للجميع" — مستقلة عن اللغة.
const String kOpenToAllFilterValue = '__OPEN_TO_ALL__';

/// يستخرج الطول بالسنتيمتر من النص المحفوظ (مثلاً "175 cm" أو "171-180 cm").
int parseHeightFromValue(String? value) {
  if (value == null || value.trim().isEmpty) return 170;
  final trimmed = value.trim();
  final cmMatch = RegExp(
    r'(\d{2,3})\s*cm|cm\s*(\d{2,3})',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (cmMatch != null) {
    final g = cmMatch.group(1) ?? cmMatch.group(2);
    if (g != null) return int.tryParse(g) ?? 170;
  }
  final singleNum = RegExp(r'^\d{2,3}$').firstMatch(trimmed);
  if (singleNum != null) return int.tryParse(trimmed) ?? 170;
  if (trimmed.contains('181+')) return 185;
  if (trimmed.contains('171') && trimmed.contains('180')) return 175;
  if (trimmed.contains('161') && trimmed.contains('170')) return 165;
  if (trimmed.contains('150') && trimmed.contains('160')) return 155;
  if (trimmed.toLowerCase().contains('short')) return 165;
  if (trimmed.toLowerCase().contains('tall')) return 185;
  if (trimmed.toLowerCase().contains('average')) return 170;
  return 170;
}

/// ورقة من الأسفل لاختيار الطول في التفضيلات (فلاتر): مفتوح للجميع + عجلة سم.
Future<String?> showFilterHeightPickerSheet({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String openToAllLabel,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FilterHeightPickerSheet(
      title: title,
      currentValue: currentValue,
      openToAllLabel: openToAllLabel,
    ),
  );
}

/// يفسّر قيمة الطول المحفوظة في الفلتر: إما مفتوح للجميع أو "min - max cm".
({bool isOpenToAll, int minCm, int maxCm}) _parseFilterHeightValue(
  String? value,
  String openToAllLabel,
) {
  final v = (value ?? '').trim();
  if (v.isEmpty || v == kOpenToAllFilterValue || v == openToAllLabel) {
    return (isOpenToAll: true, minCm: 160, maxCm: 180);
  }
  if (v.toLowerCase().contains('open') && v.toLowerCase().contains('all')) {
    return (isOpenToAll: true, minCm: 160, maxCm: 180);
  }
  if (RegExp(r'مفتوح\s*للجميع', caseSensitive: false).hasMatch(v)) {
    return (isOpenToAll: true, minCm: 160, maxCm: 180);
  }
  final rangeMatch = RegExp(
    r'(\d{2,3})\s*-\s*(\d{2,3})\s*cm',
    caseSensitive: false,
  ).firstMatch(v);
  if (rangeMatch != null) {
    final a = int.tryParse(rangeMatch.group(1)!) ?? 160;
    final b = int.tryParse(rangeMatch.group(2)!) ?? 180;
    final min = a.clamp(kHeightPickerMinCm, kHeightPickerMaxCm);
    final max = b.clamp(kHeightPickerMinCm, kHeightPickerMaxCm);
    return (
      isOpenToAll: false,
      minCm: min <= max ? min : max,
      maxCm: min <= max ? max : min,
    );
  }
  final single = parseHeightFromValue(v);
  return (isOpenToAll: false, minCm: single, maxCm: single);
}

class _FilterHeightPickerSheet extends StatefulWidget {
  const _FilterHeightPickerSheet({
    required this.title,
    required this.currentValue,
    required this.openToAllLabel,
  });

  final String title;
  final String currentValue;
  final String openToAllLabel;

  @override
  State<_FilterHeightPickerSheet> createState() =>
      _FilterHeightPickerSheetState();
}

class _FilterHeightPickerSheetState extends State<_FilterHeightPickerSheet> {
  late bool _isOpenToAll;
  late int _minCm;
  late int _maxCm;
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _maxController;
  static final List<int> _cmValues = List.generate(
    kHeightPickerMaxCm - kHeightPickerMinCm + 1,
    (i) => kHeightPickerMinCm + i,
  );

  int _cmToIndex(int cm) {
    final i = _cmValues.indexOf(cm);
    return i >= 0 ? i : _cmValues.indexOf(170);
  }

  @override
  void initState() {
    super.initState();
    final parsed = _parseFilterHeightValue(
      widget.currentValue,
      widget.openToAllLabel,
    );
    _isOpenToAll = parsed.isOpenToAll;
    _minCm = parsed.minCm;
    _maxCm = parsed.maxCm;
    if (_minCm > _maxCm) {
      final t = _minCm;
      _minCm = _maxCm;
      _maxCm = t;
    }
    _minController = FixedExtentScrollController(
      initialItem: _cmToIndex(_minCm),
    );
    _maxController = FixedExtentScrollController(
      initialItem: _cmToIndex(_maxCm),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _save() {
    final value = _isOpenToAll ? kOpenToAllFilterValue : '$_minCm - $_maxCm cm';
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(widget.openToAllLabel),
                  selected: _isOpenToAll,
                  onSelected: (v) => setState(() => _isOpenToAll = true),
                  selectedColor: AppColors.hingePurple.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.hingePurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: Text(l10n.heightRangeOption),
                  selected: !_isOpenToAll,
                  onSelected: (v) => setState(() => _isOpenToAll = false),
                  selectedColor: AppColors.hingePurple.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.hingePurple,
                ),
              ),
            ],
          ),
          if (!_isOpenToAll) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.fromLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlack.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 160,
                        child: CupertinoPicker.builder(
                          scrollController: _minController,
                          itemExtent: 40,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.hingePurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                bottom: BorderSide(
                                  color: AppColors.hingePurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _minCm = _cmValues[index];
                              if (_minCm > _maxCm) {
                                _maxCm = _minCm;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (_maxController.hasClients) {
                                    final i = _cmToIndex(_maxCm);
                                    _maxController.jumpToItem(i);
                                  }
                                });
                              }
                            });
                          },
                          itemBuilder: (context, index) => Center(
                            child: Text(
                              'cm ${_cmValues[index]}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkBlack,
                              ),
                            ),
                          ),
                          childCount: _cmValues.length,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.toLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlack.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 160,
                        child: CupertinoPicker.builder(
                          scrollController: _maxController,
                          itemExtent: 40,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.hingePurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                bottom: BorderSide(
                                  color: AppColors.hingePurple.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _maxCm = _cmValues[index];
                              if (_maxCm < _minCm) {
                                _minCm = _maxCm;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (_minController.hasClients) {
                                    final i = _cmToIndex(_minCm);
                                    _minController.jumpToItem(i);
                                  }
                                });
                              }
                            });
                          },
                          itemBuilder: (context, index) => Center(
                            child: Text(
                              'cm ${_cmValues[index]}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkBlack,
                              ),
                            ),
                          ),
                          childCount: _cmValues.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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

/// ورقة من الأسفل لاختيار الطول بعجلة (سم).
Future<({String value, String visibility})?> showHeightPickerSheet({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String currentVisibility,
  bool allowAlwaysVisible = true,
  bool allowAlwaysHidden = false,
}) async {
  return showModalBottomSheet<({String value, String visibility})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _HeightPickerSheet(
      title: title,
      initialCm: parseHeightFromValue(currentValue),
      currentVisibility: currentVisibility,
      allowAlwaysVisible: allowAlwaysVisible,
      allowAlwaysHidden: allowAlwaysHidden,
    ),
  );
}

class _HeightPickerSheet extends StatefulWidget {
  const _HeightPickerSheet({
    required this.title,
    required this.initialCm,
    required this.currentVisibility,
    this.allowAlwaysVisible = true,
    this.allowAlwaysHidden = false,
  });

  final String title;
  final int initialCm;
  final String currentVisibility;
  final bool allowAlwaysVisible;
  final bool allowAlwaysHidden;

  @override
  State<_HeightPickerSheet> createState() => _HeightPickerSheetState();
}

class _HeightPickerSheetState extends State<_HeightPickerSheet> {
  late FixedExtentScrollController _controller;
  late String _visibility;
  late int _selectedIndex;
  static final List<int> _cmValues = List.generate(
    kHeightPickerMaxCm - kHeightPickerMinCm + 1,
    (i) => kHeightPickerMinCm + i,
  );

  @override
  void initState() {
    super.initState();
    final index = _cmValues.indexOf(widget.initialCm);
    _selectedIndex = index >= 0 ? index : _cmValues.indexOf(170);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
    final valid = ['hidden', 'visible', 'always_visible', 'always_hidden'];
    _visibility = valid.contains(widget.currentVisibility)
        ? widget.currentVisibility
        : 'hidden';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final cm = _selectedIndex >= 0 && _selectedIndex < _cmValues.length
        ? _cmValues[_selectedIndex]
        : widget.initialCm;
    Navigator.of(context).pop((value: '$cm cm', visibility: _visibility));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
          SizedBox(
            height: 180,
            child: CupertinoPicker.builder(
              scrollController: _controller,
              itemExtent: 44,
              selectionOverlay: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.hingePurple.withValues(alpha: 0.3),
                    ),
                    bottom: BorderSide(
                      color: AppColors.hingePurple.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              onSelectedItemChanged: (int index) {
                setState(() => _selectedIndex = index);
              },
              itemBuilder: (context, index) => Center(
                child: Text(
                  'cm ${_cmValues[index]}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkBlack,
                  ),
                ),
              ),
              childCount: _cmValues.length,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.fieldVisibility,
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
              if (widget.allowAlwaysVisible)
                DropdownMenuItem(
                  value: 'always_visible',
                  child: Text(l10n.alwaysVisible),
                ),
              if (widget.allowAlwaysHidden)
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

/// نوع الحقل: نص حر، أو اختيار من قائمة.
enum ProfileFieldType { text, choice }

/// ورقة من الأسفل لتعديل حقل بروفايل: قيمة + ظهور.
Future<({String value, String visibility})?> showProfileFieldEditorSheet({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String currentVisibility,
  ProfileFieldType type = ProfileFieldType.text,
  List<String>? choices,
  String? hint,
  bool allowAlwaysVisible = false,
  bool allowAlwaysHidden = false,
}) async {
  return showModalBottomSheet<({String value, String visibility})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProfileFieldEditorSheet(
      title: title,
      currentValue: currentValue,
      currentVisibility: currentVisibility,
      type: type,
      choices: choices ?? [],
      hint: hint,
      allowAlwaysVisible: allowAlwaysVisible,
      allowAlwaysHidden: allowAlwaysHidden,
    ),
  );
}

class _ProfileFieldEditorSheet extends StatefulWidget {
  const _ProfileFieldEditorSheet({
    required this.title,
    required this.currentValue,
    required this.currentVisibility,
    required this.type,
    required this.choices,
    this.hint,
    this.allowAlwaysVisible = false,
    this.allowAlwaysHidden = false,
  });

  final String title;
  final String currentValue;
  final String currentVisibility;
  final ProfileFieldType type;
  final List<String> choices;
  final String? hint;
  final bool allowAlwaysVisible;
  final bool allowAlwaysHidden;

  @override
  State<_ProfileFieldEditorSheet> createState() =>
      _ProfileFieldEditorSheetState();
}

class _ProfileFieldEditorSheetState extends State<_ProfileFieldEditorSheet> {
  late TextEditingController _controller;
  late String _visibility;
  late String _selectedChoice;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _selectedChoice = widget.currentValue;
    final valid = ['hidden', 'visible', 'always_visible', 'always_hidden'];
    _visibility = valid.contains(widget.currentVisibility)
        ? widget.currentVisibility
        : 'hidden';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = widget.type == ProfileFieldType.text
        ? _controller.text.trim()
        : _selectedChoice;
    Navigator.of(context).pop((value: value, visibility: _visibility));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
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
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: widget.type == ProfileFieldType.text
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.hint ?? widget.title,
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.hingePurple,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _save(),
                    )
                  : widget.choices.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.choices
                          .map(
                            (choice) => InkWell(
                              onTap: () =>
                                  setState(() => _selectedChoice = choice),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedChoice == choice
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: _selectedChoice == choice
                                          ? AppColors.hingePurple
                                          : AppColors.darkBlack.withValues(
                                              alpha: 0.4,
                                            ),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        choice,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.darkBlack,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.fieldVisibility,
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
              if (widget.allowAlwaysVisible)
                DropdownMenuItem(
                  value: 'always_visible',
                  child: Text(l10n.alwaysVisible),
                ),
              if (widget.allowAlwaysHidden)
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
