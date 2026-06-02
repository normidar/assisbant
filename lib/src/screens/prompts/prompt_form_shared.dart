import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Form field label wrapper ─────────────────────────────────────────────────

class PromptFormField extends StatelessWidget {
  const PromptFormField({required this.label, required this.child, super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.ink4,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Browse / action button ───────────────────────────────────────────────────

class FormBrowseButton extends StatelessWidget {
  const FormBrowseButton({
    required this.label,
    required this.onTap,
    required this.c,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 14, color: c.ink3),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal action button ──────────────────────────────────────────────────────

class FormModalBtn extends StatelessWidget {
  const FormModalBtn({
    required this.label,
    required this.onTap,
    required this.c,
    this.primary = false,
    this.ghost = false,
    this.enabled = true,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final AppColors c;
  final bool primary;
  final bool ghost;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (primary) {
      bg = enabled ? c.accent : c.accent.withValues(alpha: 0.5);
      border = bg;
      fg = Colors.white;
    } else if (ghost) {
      bg = Colors.transparent;
      border = Colors.transparent;
      fg = c.ink2;
    } else {
      bg = c.surface;
      border = c.border;
      fg = c.ink;
    }
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Input decoration ─────────────────────────────────────────────────────────

InputDecoration formInputDeco(AppColors c, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: c.ink4),
  filled: true,
  fillColor: c.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: c.border),
    borderRadius: BorderRadius.circular(8),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: c.border),
    borderRadius: BorderRadius.circular(8),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: c.ink3),
    borderRadius: BorderRadius.circular(8),
  ),
);

// ─── Selectable chip ──────────────────────────────────────────────────────────

class FormChip extends StatelessWidget {
  const FormChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.surface,
          border: Border.all(color: selected ? c.ink : c.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            color: selected ? Colors.white : c.ink2,
          ),
        ),
      ),
    );
  }
}

// ─── Claude model selector ────────────────────────────────────────────────────

const claudeModelOptions = <(String, String?)>[
  ('', null),
  ('claude-opus-4-7', 'Opus'),
  ('claude-sonnet-4-6', 'Sonnet'),
  ('claude-haiku-4-5-20251001', 'Haiku'),
];

/// Renders the Opus/Sonnet/Haiku chip row.
/// Returns [SizedBox.shrink] when the global model mode is not [ModelMode.claude].
class ClaudeModelSelector extends ConsumerWidget {
  const ClaudeModelSelector({
    required this.strings,
    required this.selected,
    required this.onSelect,
    required this.c,
    super.key,
  });

  final AppStrings strings;
  final String selected;
  final ValueChanged<String> onSelect;
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);
    if (settings.modelMode != ModelMode.claude) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        PromptFormField(
          label: strings.claudeModelSelect,
          child: Wrap(
            spacing: 6,
            children: claudeModelOptions.map((item) {
              final (id, rawLabel) = item;
              final label = rawLabel ?? strings.claudeModelDefault;
              return FormChip(
                label: label,
                selected: selected == id,
                onTap: () => onSelect(id),
                c: c,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
