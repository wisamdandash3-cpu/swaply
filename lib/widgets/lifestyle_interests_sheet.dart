import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../data/lifestyle_interests.dart';
import '../generated/l10n/app_localizations.dart';

/// يفتح ورقة اختيار اهتمامات الـ Lifestyle (فئات + chips) ويُرجع قائمة IDs المختارة أو null عند الإلغاء.
Future<List<String>?> showLifestyleInterestsSheet({
  required BuildContext context,
  required List<String> initialSelectedIds,
  bool isArabic = false,
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (_, scrollController) => _LifestyleInterestsSheet(
        initialSelectedIds: initialSelectedIds,
        isArabic: isArabic,
        scrollController: scrollController,
      ),
    ),
  );
}

class _LifestyleInterestsSheet extends StatefulWidget {
  const _LifestyleInterestsSheet({
    required this.initialSelectedIds,
    required this.isArabic,
    required this.scrollController,
  });

  final List<String> initialSelectedIds;
  final bool isArabic;
  final ScrollController scrollController;

  @override
  State<_LifestyleInterestsSheet> createState() => _LifestyleInterestsSheetState();
}

class _LifestyleInterestsSheetState extends State<_LifestyleInterestsSheet> {
  late Set<String> _selectedIds;
  late List<LifestyleCategory> _categories;
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelectedIds);
    _categories = getLifestyleCategories();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _label(LifestyleOption opt) =>
      widget.isArabic ? opt.labelAr : opt.labelEn;

  String _categoryLabel(LifestyleCategory cat) =>
      widget.isArabic ? cat.labelAr : cat.labelEn;

  List<LifestyleOption> _filteredOptions() {
    final cat = _categories[_selectedCategoryIndex];
    var list = cat.options;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((o) =>
              _label(o).toLowerCase().contains(_searchQuery) ||
              o.id.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = _filteredOptions();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                Text(
                  'Lifestyle',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlack,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: selected
                        ? AppColors.hingePurple.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategoryIndex = index),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        alignment: Alignment.center,
                        child: Text(
                          _categoryLabel(cat),
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? AppColors.hingePurple
                                : AppColors.darkBlack.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    final selected = _selectedIds.contains(opt.id);
                    return _InterestChip(
                      label: _label(opt),
                      icon: opt.icon,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(opt.id);
                          } else {
                            _selectedIds.add(opt.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.hingePurple.withValues(alpha: 0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.hingePurple.withValues(alpha: 0.6)
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.hingePurple.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.hingePurple
                      : AppColors.darkBlack.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.hingePurple
                      : AppColors.darkBlack.withValues(alpha: 0.85),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.hingePurple,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// تحويل القيمة المحفوظة (JSON array) إلى قائمة IDs.
List<String> parseLifestyleInterestsIds(String? jsonValue) {
  if (jsonValue == null || jsonValue.trim().isEmpty) return [];
  try {
    final list = jsonDecode(jsonValue.trim());
    if (list is List) {
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
  } catch (_) {}
  return [];
}
