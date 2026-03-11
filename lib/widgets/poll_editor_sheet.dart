import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';

/// محتوى الاستطلاع المحفوظ: سؤال + قائمة خيارات.
({String question, List<String> options}) parsePollContent(String? content) {
  if (content == null || content.trim().isEmpty) {
    return (question: '', options: <String>[]);
  }
  try {
    final map = jsonDecode(content) as Map<String, dynamic>;
    final question = (map['question'] as String?)?.trim() ?? '';
    final opts = map['options'];
    if (opts is List) {
      final list = opts.map((e) => (e?.toString() ?? '').trim()).where((s) => s.isNotEmpty).toList();
      return (question: question, options: list);
    }
    return (question: question, options: <String>[]);
  } catch (_) {
    return (question: '', options: <String>[]);
  }
}

String encodePollContent(String question, List<String> options) {
  return jsonEncode({
    'question': question.trim(),
    'options': options.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
  });
}

/// ورقة من الأسفل لإنشاء أو تعديل استطلاع: سؤال + خيارات.
Future<({String question, List<String> options})?> showPollEditorSheet({
  required BuildContext context,
  required String title,
  String? initialQuestion,
  List<String>? initialOptions,
}) async {
  return showModalBottomSheet<({String question, List<String> options})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PollEditorSheet(
      title: title,
      initialQuestion: initialQuestion ?? '',
      initialOptions: initialOptions ?? [],
    ),
  );
}

class _PollEditorSheet extends StatefulWidget {
  const _PollEditorSheet({
    required this.title,
    required this.initialQuestion,
    required this.initialOptions,
  });

  final String title;
  final String initialQuestion;
  final List<String> initialOptions;

  @override
  State<_PollEditorSheet> createState() => _PollEditorSheetState();
}

class _PollEditorSheetState extends State<_PollEditorSheet> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.initialQuestion);
    _optionControllers = [
      if (widget.initialOptions.isNotEmpty)
        ...widget.initialOptions.map((t) => TextEditingController(text: t))
      else
        TextEditingController(),
        TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _save() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (question.isEmpty) return;
    if (options.length < 2) return;
    Navigator.of(context).pop((question: question, options: options));
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
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              labelText: l10n.writeYourQuestion,
              hintText: l10n.writeYourQuestion,
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.hingePurple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addYourOptions,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlack.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_optionControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              hintText: '${l10n.addYourOptions} ${i + 1}',
                              isDense: true,
                              border: const OutlineInputBorder(),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.hingePurple, width: 2),
                              ),
                            ),
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            onPressed: () => _removeOption(i),
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.neonCoral),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add, color: AppColors.hingePurple),
            label: Text(
              l10n.addYourOptions,
              style: const TextStyle(color: AppColors.hingePurple),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkBlack,
                    side: BorderSide(color: AppColors.darkBlack.withValues(alpha: 0.3)),
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
