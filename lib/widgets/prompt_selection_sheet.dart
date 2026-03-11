import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../data/prompts_data.dart';
import '../services/prompt_service.dart';

/// نتيجة اختيار سؤال: id ونصه.
typedef SelectedPrompt = ({String id, String text});

/// ورقة من الأسفل لاختيار سؤال من prompts_data.
/// تُرجع (id, text) عند الاختيار.
Future<SelectedPrompt?> showPromptSelectionSheet(BuildContext context) {
  return showModalBottomSheet<SelectedPrompt>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const PromptSelectionSheet(),
  );
}

class PromptSelectionSheet extends StatefulWidget {
  const PromptSelectionSheet({super.key});

  @override
  State<PromptSelectionSheet> createState() => _PromptSelectionSheetState();
}

class _PromptSelectionSheetState extends State<PromptSelectionSheet> {
  final PromptService _promptService = PromptService();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final categories = _promptService.getCategories();
    if (categories.isNotEmpty && _selectedCategory == null) {
      _selectedCategory = categories.first;
    }
  }

  String get _locale {
    return Localizations.localeOf(context).languageCode;
  }

  List<Prompt> get _filteredPrompts {
    if (_selectedCategory == null) return _promptService.getAllPrompts();
    return _promptService.getPromptsByCategory(_selectedCategory!);
  }

  void _onPromptTap(Prompt prompt) {
    final text = prompt.textForLocale(_locale);
    Navigator.of(context).pop((id: prompt.id, text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = _promptService.getCategories();
    final prompts = _filteredPrompts;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              l10n.selectPrompt,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlack,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: AppColors.hingePurple.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.hingePurple,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.hingePurple
                          : AppColors.darkBlack.withValues(alpha: 0.7),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                final text = prompt.textForLocale(_locale);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onPromptTap(prompt),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 4,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.darkBlack,
                          height: 1.4,
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
    );
  }
}
