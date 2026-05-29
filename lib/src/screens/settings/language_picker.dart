import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/ui_providers.dart';

// Add entries here when adding new languages — the picker dialog reflects this list automatically.
const kLanguages = [
  ('en', 'English'),
  ('zh', '中文'),
  ('ja', '日本語'),
];

// ─── Language picker row ──────────────────────────────────────────────────────

class LangPickerRow extends ConsumerWidget {
  const LangPickerRow({
    required this.label,
    required this.description,
    required this.c,
    super.key,
  });

  final String label;
  final String description;
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langNotifierProvider);
    final langLabel = kLanguages
        .firstWhere((e) => e.$1 == lang, orElse: () => ('en', 'English'))
        .$2;

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => LangPickerDialog(c: c),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(fontSize: 11.5, color: c.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(langLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.ink2)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: c.ink3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language picker dialog ───────────────────────────────────────────────────

class LangPickerDialog extends ConsumerWidget {
  const LangPickerDialog({required this.c, super.key});
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langNotifierProvider);
    final s = AppStrings.forLang(lang);

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Text(
                s.language,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink),
              ),
            ),
            Divider(color: c.border, height: 1),
            ...kLanguages.map((entry) {
              final (key, label) = entry;
              final selected = lang == key;
              return GestureDetector(
                onTap: () {
                  ref.read(langNotifierProvider.notifier).set(key);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: BoxDecoration(
                    color: selected ? c.surface2 : Colors.transparent,
                    border:
                        Border(bottom: BorderSide(color: c.border2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                color: c.ink,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            size: 16, color: c.ink),
                    ],
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(14),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(fontSize: 13, color: c.ink3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
