import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ac;
    final s = strings;
    final promptsAsync = ref.watch(promptListNotifierProvider);

    return promptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (prompts) {
        final branches = prompts.map((p) => p.branch).toSet().toList()..sort();
        return Column(
          children: [
            // Toolbar
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
                    s.branches,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${branches.length} branches',
                    style: TextStyle(fontSize: 12.5, color: c.ink3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: branches.isEmpty
                  ? Center(
                      child: Text(
                        s.branchEmpty,
                        style: TextStyle(color: c.ink3, fontSize: 13),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisExtent: 130,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: branches.length,
                      itemBuilder: (_, i) => _BranchCard(
                        branch: branches[i],
                        prompts: prompts.where((p) => p.branch == branches[i]).toList(),
                        strings: s,
                        onOpen: (b) {
                          ref.read(currentTabProvider.notifier).set(AppTab.prompts);
                          ref.read(branchFilterProvider.notifier).set(b);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BranchCard extends StatefulWidget {
  const _BranchCard({
    required this.branch,
    required this.prompts,
    required this.strings,
    required this.onOpen,
  });
  final String branch;
  final List<PromptEntry> prompts;
  final AppStrings strings;
  final ValueChanged<String> onOpen;

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final ps = widget.prompts;
    final total = ps.length;
    final done = ps.where((p) => p.status == PromptStatus.done).length;
    final failed = ps.where((p) => p.status == PromptStatus.failed).length;
    final skipped = ps.where((p) => p.isSkipped).length;
    final pending = ps.where((p) => !p.isSkipped && p.status == PromptStatus.pending).length;

    final donePct = total > 0 ? done / total : 0.0;
    final failedPct = total > 0 ? failed / total : 0.0;
    final skippedPct = total > 0 ? skipped / total : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onOpen(widget.branch),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: _hovered ? c.ink4 : c.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: c.ink.withValues(alpha: 0.04), blurRadius: 4)]
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.call_split_rounded, size: 14, color: c.ink3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.branch,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$done/$total',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: c.ink3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stacked progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (donePct * 1000).round(),
                        child: Container(color: c.stDone),
                      ),
                      Flexible(
                        flex: (failedPct * 1000).round(),
                        child: Container(color: c.stFailed),
                      ),
                      Flexible(
                        flex: (skippedPct * 1000).round(),
                        child: Container(color: c.stSkipped),
                      ),
                      Flexible(
                        flex: ((1 - donePct - failedPct - skippedPct).clamp(0, 1) * 1000).round(),
                        child: Container(color: c.surface3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(value: pending, label: s.pending, c: c),
                  const SizedBox(width: 14),
                  _Stat(value: done, label: s.completed, c: c),
                  if (failed > 0) ...[
                    const SizedBox(width: 14),
                    _Stat(value: failed, label: s.failed, c: c, color: c.stFailed),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.c, this.color});
  final int value;
  final String label;
  final AppColors c;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color ?? c.ink,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: color ?? c.ink3),
        ),
      ],
    );
  }
}
