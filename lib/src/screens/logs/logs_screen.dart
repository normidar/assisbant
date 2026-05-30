import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/widgets/branch_chip.dart';
import 'package:assibant/src/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final promptsAsync = ref.watch(promptListNotifierProvider);

    return promptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prompts) {
        // Show prompts that have been executed (done/failed/running)
        final ran = prompts
            .where((p) =>
                p.status.name == 'done' ||
                p.status.name == 'failed' ||
                p.status.name == 'running')
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        _selectedId ??= ran.isNotEmpty ? ran.first.id : null;
        final cur = ran.where((p) => p.id == _selectedId).firstOrNull ?? ran.firstOrNull;

        return Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    s.logs,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ran.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 32, color: c.ink4),
                          const SizedBox(height: 12),
                          Text(s.noLogs, style: TextStyle(color: c.ink3, fontSize: 13)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: run list
                          SizedBox(
                            width: 300,
                            child: ListView.separated(
                              itemCount: ran.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 4),
                              itemBuilder: (_, i) {
                                final p = ran[i];
                                final selected = cur?.id == p.id;
                                return _RunItem(
                                  prompt: p,
                                  strings: s,
                                  selected: selected,
                                  onTap: () => setState(() => _selectedId = p.id),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right: log viewer
                          if (cur != null)
                            Expanded(
                              child: _LogWindow(prompt: cur, strings: s),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RunItem extends StatelessWidget {
  const _RunItem({
    required this.prompt,
    required this.strings,
    required this.selected,
    required this.onTap,
  });
  final PromptEntry prompt;
  final AppStrings strings;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final p = prompt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(
            color: selected ? c.ink : c.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BranchChip(name: p.branch),
                const SizedBox(width: 6),
                StatusBadge(
                  status: p.status,
                  isSkipped: p.isSkipped,
                  strings: strings,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              p.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogWindow extends StatelessWidget {
  const _LogWindow({required this.prompt, required this.strings});
  final PromptEntry prompt;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF16110D);
    const dimText = Color(0xFFE8E2D2);

    return Container(
      decoration: BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log window header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF221A14),
              border: Border(
                bottom: BorderSide(color: Color(0x14E8E2D2)),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const _TrafficLight(color: Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                const _TrafficLight(color: Color(0xFFFEBC2E)),
                const SizedBox(width: 6),
                const _TrafficLight(color: Color(0xFF28C840)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'claude — ${prompt.branch} — ${prompt.id}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11.5,
                      color: dimText.withValues(alpha: 0.75),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  status: prompt.status,
                  isSkipped: prompt.isSkipped,
                  strings: strings,
                ),
              ],
            ),
          ),
          // Log body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SelectableText(
                prompt.output?.isNotEmpty ?? false
                    ? prompt.output!
                    : strings.noLogs,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: dimText.withValues(alpha: 0.6),
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
