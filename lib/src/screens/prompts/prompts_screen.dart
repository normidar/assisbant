import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/screens/prompts/batch_create_modal.dart';
import 'package:assibant/src/screens/prompts/prompt_card.dart';
import 'package:assibant/src/screens/prompts/prompt_edit_modal.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:assibant/src/widgets/branch_chip.dart';
import 'package:assibant/src/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

enum _BranchTab { prompts, commits }

// ─── Branch inner tab bar ─────────────────────────────────────────────────────

class _BranchTabBar extends StatelessWidget {
  const _BranchTabBar({
    required this.current,
    required this.strings,
    required this.onChange,
  });

  final _BranchTab current;
  final AppStrings strings;
  final ValueChanged<_BranchTab> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabBtn(
            label: strings.tabPrompts,
            active: current == _BranchTab.prompts,
            onTap: () => onChange(_BranchTab.prompts),
          ),
          const SizedBox(width: 2),
          _TabBtn(
            label: strings.commitHistory,
            active: current == _BranchTab.commits,
            onTap: () => onChange(_BranchTab.commits),
          ),
        ],
      ),
    );
  }
}

class _CommitCard extends StatefulWidget {
  const _CommitCard({
    required this.commit,
    required this.strings,
    required this.selectedId,
    required this.timeAgo,
    this.onSelect,
  });

  final _CommitInfo commit;
  final AppStrings strings;
  final String? selectedId;
  final String timeAgo;
  final VoidCallback? onSelect;

  @override
  State<_CommitCard> createState() => _CommitCardState();
}

class _CommitCardState extends State<_CommitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final commit = widget.commit;
    final isSelected = commit.matchedPrompts.any(
      (p) => p.id == widget.selectedId,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? c.accentSoft : c.surface,
            border: Border.all(
              color: isSelected
                  ? c.accent.withValues(alpha: 0.35)
                  : _hovered && widget.onSelect != null
                  ? c.ink4
                  : c.border,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      commit.shortHash,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11.5,
                        color: c.ink2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.timeAgo,
                    style: TextStyle(fontSize: 12, color: c.ink3),
                  ),
                  const Spacer(),
                  if (commit.hasMatch)
                    StatusBadge(
                      status: commit.matchedPrompts.first.status,
                      isSkipped: commit.matchedPrompts.first.isSkipped,
                      strings: s,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                commit.message,
                style: TextStyle(fontSize: 13, color: c.ink, height: 1.45),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommitHistoryView extends ConsumerStatefulWidget {
  const _CommitHistoryView({
    required this.branch,
    required this.branchPrompts,
    required this.strings,
    required this.selectedId,
    required this.onSelectPrompt,
    super.key,
  });

  final String branch;
  final List<PromptEntry> branchPrompts;
  final AppStrings strings;
  final String? selectedId;
  final ValueChanged<String> onSelectPrompt;

  @override
  ConsumerState<_CommitHistoryView> createState() => _CommitHistoryViewState();
}

class _CommitHistoryViewState extends ConsumerState<_CommitHistoryView> {
  List<_CommitInfo>? _commits;
  String? _error;
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: c.stFailed),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 12.5, color: c.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final commits = _commits ?? [];

    if (commits.isEmpty) {
      return Center(
        child: Text(s.noCommits, style: TextStyle(fontSize: 13, color: c.ink3)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      itemCount: commits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CommitCard(
        commit: commits[i],
        strings: s,
        selectedId: widget.selectedId,
        timeAgo: _timeAgo(commits[i].date),
        onSelect: commits[i].hasMatch
            ? () => widget.onSelectPrompt(commits[i].matchedPrompts.first.id)
            : null,
      ),
    );
  }

  @override
  void didUpdateWidget(_CommitHistoryView old) {
    super.didUpdateWidget(old);
    if (old.branch != widget.branch) {
      _loadCommits();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  Future<void> _loadCommits() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final settings = ref.read(settingsStateProvider);

    var rawWorkdir = settings.workdir;
    for (final p in widget.branchPrompts) {
      if (p.projectPath.isNotEmpty) {
        rawWorkdir = p.projectPath;
        break;
      }
    }

    final workdir = rawWorkdir.startsWith('~/')
        ? (Platform.environment['HOME'] ?? '') + rawWorkdir.substring(1)
        : rawWorkdir;

    if (workdir.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Working directory not configured.';
          _loading = false;
        });
      }
      return;
    }

    try {
      final result = await Process.run(
        '/usr/bin/git',
        [
          'log',
          '--max-count=100',
          '--format=format:%H|||%aI|||%s',
          widget.branch,
        ],
        workingDirectory: workdir,
      );

      if (!mounted) return;

      if (result.exitCode != 0) {
        final stderr = (result.stderr as String).trim();
        setState(() {
          _error = stderr.isNotEmpty
              ? stderr
              : 'git log failed (exit ${result.exitCode})';
          _loading = false;
        });
        return;
      }

      final output = (result.stdout as String).trim();
      final commits = <_CommitInfo>[];

      for (final line in output.split('\n')) {
        if (line.trim().isEmpty) continue;
        const sep = '|||';
        final idx1 = line.indexOf(sep);
        if (idx1 < 0) continue;
        final idx2 = line.indexOf(sep, idx1 + sep.length);
        if (idx2 < 0) continue;

        final hash = line.substring(0, idx1);
        final dateStr = line.substring(idx1 + sep.length, idx2);
        final message = line.substring(idx2 + sep.length);

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }

        final matched = widget.branchPrompts.where((p) {
          final firstLine = p.content.split('\n').first.trim();
          return firstLine == message.trim() ||
              p.content.trim() == message.trim();
        }).toList();

        commits.add(
          _CommitInfo(
            hash: hash,
            date: date,
            message: message,
            matchedPrompts: matched,
          ),
        );
      }

      setState(() {
        _commits = commits;
        _loading = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Commit history ───────────────────────────────────────────────────────────

class _CommitInfo {
  const _CommitInfo({
    required this.hash,
    required this.date,
    required this.message,
    this.matchedPrompts = const [],
  });

  final String hash;
  final DateTime date;
  final String message;
  final List<PromptEntry> matchedPrompts;

  bool get hasMatch => matchedPrompts.isNotEmpty;
  String get shortHash => hash.length >= 7 ? hash.substring(0, 7) : hash;
}

class _CopyIconButton extends StatefulWidget {
  const _CopyIconButton({required this.value});
  final String value;

  @override
  State<_CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<_CopyIconButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return GestureDetector(
      onTap: _copy,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          _copied ? Icons.check : Icons.copy_outlined,
          size: 13,
          color: _copied ? c.stDone : c.ink3,
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _copied = false);
  }
}

// ─── Delete confirm ───────────────────────────────────────────────────────────

class _DeleteConfirm extends StatelessWidget {
  const _DeleteConfirm({
    required this.strings,
    required this.onConfirm,
    required this.onCancel,
  });
  final AppStrings strings;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = strings;
    return Stack(
      children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(color: Colors.black38),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: c.ink.withValues(alpha: 0.14),
                    blurRadius: 50,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.delete,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.confirmDelete,
                          style: TextStyle(fontSize: 13.5, color: c.ink2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border(top: BorderSide(color: c.border2)),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.cancel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: c.ink2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: c.stFailed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.delete,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBtn extends StatelessWidget {
  const _DetailBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail panel ─────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.prompt,
    required this.strings,
    required this.onClose,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final VoidCallback onClose;
  final ValueChanged<PromptEntry> onEdit;
  final ValueChanged<String> onSkip;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = strings;
    final p = prompt;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(left: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BranchChip(name: p.branch),
                    const SizedBox(width: 8),
                    StatusBadge(
                      status: p.status,
                      isSkipped: p.isSkipped,
                      strings: s,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '#${p.priority} · ${p.id}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailSec(
                    label: s.detailContent,
                    child: Text(
                      p.content,
                      style: const TextStyle(fontSize: 13, height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailSec(
                    label: s.detailMeta,
                    child: _KV(
                      entries: [
                        ('id', p.id),
                        ('branch', p.branch),
                        ('priority', '${p.priority}'),
                        ('status', p.isSkipped ? 'skipped' : p.status.name),
                        if (p.sessionId.isNotEmpty) ('session_id', p.sessionId),
                        if (p.claudeSessionId.isNotEmpty)
                          ('claude_session', p.claudeSessionId),
                        if (p.startedAt != null &&
                            (p.status == PromptStatus.done ||
                                p.status == PromptStatus.failed))
                          ('duration', _duration(p.startedAt!, p.updatedAt)),
                        ('created', _timeAgo(p.createdAt)),
                        ('updated', _timeAgo(p.updatedAt)),
                      ],
                      copyKeys: const {'session_id', 'claude_session'},
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailSec(
                    label: s.detailLogs,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surface2,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: p.output?.isNotEmpty ?? false
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: SelectableText(
                                p.output!,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: c.ink,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Text(
                                s.noLogs,
                                style: TextStyle(fontSize: 12.5, color: c.ink3),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border2)),
            ),
            child: Row(
              children: [
                if (p.status == PromptStatus.pending || p.isSkipped) ...[
                  _DetailBtn(
                    label: s.edit,
                    icon: Icons.edit_outlined,
                    onTap: () => onEdit(p),
                  ),
                  const SizedBox(width: 8),
                ],
                if (p.status != PromptStatus.running &&
                    p.status != PromptStatus.done) ...[
                  _DetailBtn(
                    label: p.isSkipped ? s.unskip : s.skip,
                    icon: Icons.skip_next_outlined,
                    onTap: () => onSkip(p.id),
                  ),
                  const SizedBox(width: 8),
                ],
                if (p.status == PromptStatus.done ||
                    p.status == PromptStatus.failed)
                  _DetailBtn(
                    label: s.reset,
                    icon: Icons.refresh_rounded,
                    onTap: () => onReset(p.id),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => onDelete(p.id),
                  icon: Icon(Icons.delete_outline, color: c.stFailed, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _duration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) {
      final s = diff.inSeconds % 60;
      return '${diff.inMinutes}m ${s}s';
    }
    final m = diff.inMinutes % 60;
    return '${diff.inHours}h ${m}m';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DetailSec extends StatelessWidget {
  const _DetailSec({required this.label, required this.child});
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: c.ink4,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notes_outlined, size: 24, color: c.ink4),
          ),
          const SizedBox(height: 12),
          Text(
            strings.queueEmpty,
            style: TextStyle(fontSize: 13, color: c.ink3),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.counts,
    required this.strings,
    required this.onChange,
  });

  final String filter;
  final Map<String, int> counts;
  final AppStrings strings;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final items = [
      ('all', strings.filterAll),
      ('pending', strings.filterPending),
      ('running', strings.filterRunning),
      ('done', strings.filterDone),
      ('failed', strings.filterFailed),
      ('skipped', strings.filterSkipped),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final (key, label) = item;
        final active = filter == key;
        final count = counts[key] ?? 0;
        return GestureDetector(
          onTap: () => onChange(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? c.ink : c.surface,
              border: Border.all(color: active ? c.ink : c.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : c.ink2,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: active
                        ? Colors.white.withValues(alpha: 0.7)
                        : c.ink3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.entries, this.copyKeys = const {}});
  final List<(String, String)> entries;
  final Set<String> copyKeys;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Column(
      children: entries.map((e) {
        final (key, val) = e;
        final copyable = copyKeys.contains(key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: c.ink3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  val,
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyable) _CopyIconButton(value: val),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  final _searchCtrl = TextEditingController();
  _BranchTab _branchTab = _BranchTab.prompts;
  bool _showEditModal = false;
  bool _showBatchModal = false;
  PromptEntry? _editingPrompt;
  bool _showDeleteConfirm = false;
  String? _deleteTargetId;
  String? _toastMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final promptsAsync = ref.watch(promptListNotifierProvider);
    final filter = ref.watch(filterNotifierProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedId = ref.watch(selectedPromptIdProvider);
    final branchFilter = ref.watch(branchFilterProvider);
    final projectFilter = ref.watch(projectFilterProvider);

    return promptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allPrompts) {
        // Sort by most recently updated prompt so the first entry is the most recent.
        final branchTimes = <String, DateTime>{};
        for (final p in allPrompts) {
          final t = branchTimes[p.branch];
          if (t == null || p.updatedAt.isAfter(t))
            branchTimes[p.branch] = p.updatedAt;
        }
        final branches = branchTimes.keys.toList()
          ..sort((a, b) => branchTimes[b]!.compareTo(branchTimes[a]!));

        final pathTimes = <String, DateTime>{};
        for (final p in allPrompts) {
          if (p.projectPath.isEmpty) continue;
          final t = pathTimes[p.projectPath];
          if (t == null || p.updatedAt.isAfter(t))
            pathTimes[p.projectPath] = p.updatedAt;
        }
        final projectPaths = pathTimes.keys.toList()
          ..sort((a, b) => pathTimes[b]!.compareTo(pathTimes[a]!));
        final maxPriority = allPrompts.isEmpty
            ? 0
            : allPrompts.map((p) => p.priority).reduce((a, b) => a > b ? a : b);

        // Build filtered + sorted list
        var list = allPrompts;
        if (projectFilter != null) {
          list = list.where((p) => p.projectPath == projectFilter).toList();
        }
        if (branchFilter != null) {
          list = list.where((p) => p.branch == branchFilter).toList();
        }
        if (query.isNotEmpty) {
          final q = query.toLowerCase();
          list = list
              .where(
                (p) =>
                    p.content.toLowerCase().contains(q) ||
                    p.branch.toLowerCase().contains(q),
              )
              .toList();
        }
        if (filter == 'skipped') {
          list = list.where((p) => p.isSkipped).toList();
        } else if (filter != 'all') {
          list = list.where((p) {
            if (!p.isSkipped) {
              return p.status.name == filter;
            }
            return false;
          }).toList();
        }
        list.sort((a, b) => b.priority.compareTo(a.priority));

        // Counts
        var src = allPrompts;
        if (projectFilter != null) {
          src = src.where((p) => p.projectPath == projectFilter).toList();
        }
        if (branchFilter != null) {
          src = src.where((p) => p.branch == branchFilter).toList();
        }
        final counts = _computeCounts(src);

        // Pending IDs for arrow navigation
        final pendingIds = list
            .where((p) => p.status == PromptStatus.pending && !p.isSkipped)
            .map((p) => p.id)
            .toList();

        final selectedPrompt = allPrompts
            .where((p) => p.id == selectedId)
            .firstOrNull;

        return Stack(
          children: [
            Column(
              children: [
                // Toolbar
                _Toolbar(
                  strings: s,
                  branchFilter: branchFilter,
                  pendingCount: allPrompts
                      .where(
                        (p) => !p.isSkipped && p.status == PromptStatus.pending,
                      )
                      .length,
                  onNew: _openNew,
                  searchCtrl: _searchCtrl,
                  onSearch: (v) =>
                      ref.read(searchQueryProvider.notifier).set(v),
                ),
                if (branchFilter != null)
                  _BranchTabBar(
                    current: _branchTab,
                    strings: s,
                    onChange: (t) => setState(() => _branchTab = t),
                  ),
                // Content area
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _branchTab == _BranchTab.commits
                            ? _CommitHistoryView(
                                key: ValueKey('commits_$branchFilter'),
                                branch: branchFilter ?? '',
                                branchPrompts: branchFilter != null
                                    ? allPrompts
                                          .where(
                                            (p) => p.branch == branchFilter,
                                          )
                                          .toList()
                                    : allPrompts,
                                strings: s,
                                selectedId: selectedId,
                                onSelectPrompt: (id) => ref
                                    .read(selectedPromptIdProvider.notifier)
                                    .toggle(id),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reorder hint
                                  if (branchFilter != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        16,
                                        24,
                                        0,
                                      ),
                                      child: Text(
                                        s.reorderHint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.ink3,
                                        ),
                                      ),
                                    ),
                                  // Filter chips
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      16,
                                      24,
                                      0,
                                    ),
                                    child: _FilterChips(
                                      filter: filter,
                                      counts: counts,
                                      strings: s,
                                      onChange: (v) => ref
                                          .read(filterNotifierProvider.notifier)
                                          .set(v),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Prompt list
                                  Expanded(
                                    child: list.isEmpty
                                        ? _EmptyState(strings: s)
                                        : ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              12,
                                              24,
                                              28,
                                            ),
                                            itemCount: list.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (_, i) {
                                              final p = list[i];
                                              final idx = pendingIds.indexOf(
                                                p.id,
                                              );
                                              return PromptCard(
                                                key: ValueKey(p.id),
                                                prompt: p,
                                                strings: s,
                                                selected: selectedId == p.id,
                                                onSelect: () => ref
                                                    .read(
                                                      selectedPromptIdProvider
                                                          .notifier,
                                                    )
                                                    .toggle(p.id),
                                                onEdit: () => _openEdit(p),
                                                onSkip: () => _toggleSkip(p.id),
                                                onDelete: () =>
                                                    _confirmDelete(p.id),
                                                onReset: () =>
                                                    _resetPrompt(p.id),
                                                canMoveUp: idx > 0,
                                                canMoveDown:
                                                    idx >= 0 &&
                                                    idx < pendingIds.length - 1,
                                                onMoveUp: idx > 0
                                                    ? () async {
                                                        await ref
                                                            .read(
                                                              promptListNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .swapPriority(
                                                              p.id,
                                                              pendingIds[idx -
                                                                  1],
                                                            );
                                                        _showToast(s.reordered);
                                                      }
                                                    : null,
                                                onMoveDown:
                                                    idx >= 0 &&
                                                        idx <
                                                            pendingIds.length -
                                                                1
                                                    ? () async {
                                                        await ref
                                                            .read(
                                                              promptListNotifierProvider
                                                                  .notifier,
                                                            )
                                                            .swapPriority(
                                                              p.id,
                                                              pendingIds[idx +
                                                                  1],
                                                            );
                                                        _showToast(s.reordered);
                                                      }
                                                    : null,
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                      ),
                      // Detail panel
                      if (selectedPrompt != null)
                        _DetailPanel(
                          prompt: selectedPrompt,
                          strings: s,
                          onClose: () => ref
                              .read(selectedPromptIdProvider.notifier)
                              .select(null),
                          onEdit: _openEdit,
                          onSkip: _toggleSkip,
                          onDelete: _confirmDelete,
                          onReset: _resetPrompt,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Edit modal
            if (_showEditModal)
              PromptEditModal(
                strings: s,
                branches: branches,
                projectPaths: projectPaths,
                maxPriority: maxPriority,
                initial: _editingPrompt,
                initialBranch: _editingPrompt == null ? branchFilter : null,
                initialProjectPath: _editingPrompt == null
                    ? projectFilter
                    : null,
                onSave:
                    ({
                      required content,
                      required branch,
                      required projectPath,
                      required priority,
                      required isSkipped,
                      required sessionId,
                      required claudeModel,
                      required imagePaths,
                      required commitAfterRun,
                    }) => _savePrompt(
                      content,
                      branch,
                      projectPath,
                      priority,
                      isSkipped,
                      sessionId,
                      allPrompts,
                      claudeModel: claudeModel,
                      imagePaths: imagePaths,
                      commitAfterRun: commitAfterRun,
                    ),
                onSaveAndStart: _editingPrompt == null
                    ? ({
                        required content,
                        required branch,
                        required projectPath,
                        required priority,
                        required isSkipped,
                        required sessionId,
                        required claudeModel,
                        required imagePaths,
                        required commitAfterRun,
                      }) =>
                        _savePrompt(
                          content,
                          branch,
                          projectPath,
                          priority,
                          isSkipped,
                          sessionId,
                          allPrompts,
                          claudeModel: claudeModel,
                          imagePaths: imagePaths,
                          commitAfterRun: commitAfterRun,
                          startAfterSave: true,
                        )
                    : null,
                onCancel: _closeModal,
                onBatchCreate: _editingPrompt == null ? _openBatch : null,
              ),
            // Batch create modal
            if (_showBatchModal)
              BatchCreateModal(
                strings: s,
                branches: branches,
                projectPaths: projectPaths,
                maxPriority: maxPriority,
                initialBranch: branchFilter,
                initialProjectPath: projectFilter,
                onSave: _saveBatch,
                onCancel: _closeBatchModal,
              ),
            // Delete confirm
            if (_showDeleteConfirm)
              _DeleteConfirm(
                strings: s,
                onConfirm: _doDelete,
                onCancel: () => setState(() => _showDeleteConfirm = false),
              ),
            // Toast
            if (_toastMessage != null)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(child: _Toast(message: _toastMessage!)),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeBatchModal() => setState(() => _showBatchModal = false);

  void _closeModal() => setState(() => _showEditModal = false);

  Map<String, int> _computeCounts(List<PromptEntry> src) {
    final c = <String, int>{
      'all': 0,
      'pending': 0,
      'running': 0,
      'done': 0,
      'failed': 0,
      'skipped': 0,
    };
    for (final p in src) {
      c['all'] = c['all']! + 1;
      if (p.isSkipped) {
        c['skipped'] = c['skipped']! + 1;
      } else {
        c[p.status.name] = (c[p.status.name] ?? 0) + 1;
      }
    }
    return c;
  }

  void _confirmDelete(String id) => setState(() {
    _deleteTargetId = id;
    _showDeleteConfirm = true;
  });

  Future<void> _doDelete() async {
    if (_deleteTargetId == null) return;
    final id = _deleteTargetId!;
    await ref.read(promptListNotifierProvider.notifier).remove(id);
    final selectedId = ref.read(selectedPromptIdProvider);
    if (selectedId == id)
      ref.read(selectedPromptIdProvider.notifier).select(null);
    setState(() => _showDeleteConfirm = false);
    _showToast(widget.strings.deleted);
  }

  void _openBatch() => setState(() {
    _showEditModal = false;
    _showBatchModal = true;
  });

  void _openEdit(PromptEntry p) => setState(() {
    _editingPrompt = p;
    _showEditModal = true;
  });

  void _openNew() => setState(() {
    _editingPrompt = null;
    _showEditModal = true;
  });

  Future<void> _resetPrompt(String id) async {
    await ref.read(promptListNotifierProvider.notifier).reset(id);
    _showToast(widget.strings.resetToast);
  }

  Future<void> _saveBatch({
    required List<String> contents,
    required String branch,
    required String projectPath,
    required int basePriority,
    required String sessionId,
    required String claudeModel,
    required String imagePaths,
    required bool commitAfterRun,
  }) async {
    await ref
        .read(promptListNotifierProvider.notifier)
        .addBatch(
          contents: contents,
          branch: branch,
          projectPath: projectPath,
          basePriority: basePriority,
          sessionId: sessionId,
          claudeModel: claudeModel,
          imagePaths: imagePaths,
          commitAfterRun: commitAfterRun,
        );
    _showToast(widget.strings.batchCreateCount(contents.length));
    _closeBatchModal();
  }

  Future<void> _savePrompt(
    String content,
    String branch,
    String projectPath,
    int priority,
    bool isSkipped,
    String sessionId,
    List<PromptEntry> all, {
    String claudeModel = '',
    String imagePaths = '',
    bool commitAfterRun = false,
    bool startAfterSave = false,
  }) async {
    final notifier = ref.read(promptListNotifierProvider.notifier);
    if (_editingPrompt == null) {
      await notifier.add(
        content: content,
        branch: branch,
        projectPath: projectPath,
        priority: priority,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
      );
      _showToast(widget.strings.created);
    } else {
      await notifier.save(
        id: _editingPrompt!.id,
        content: content,
        branch: branch,
        projectPath: projectPath,
        priority: priority,
        isSkipped: isSkipped,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
      );
      _showToast(widget.strings.saved);
    }
    _closeModal();
    if (startAfterSave) {
      ref.read(execNotifierProvider.notifier).start();
    }
  }

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _toggleSkip(String id) async {
    await ref.read(promptListNotifierProvider.notifier).toggleSkip(id);
    final all = ref.read(promptListNotifierProvider).value ?? <PromptEntry>[];
    final p = all.where((x) => x.id == id).firstOrNull;
    if (p != null) {
      _showToast(
        p.isSkipped
            ? widget.strings.skippedToast
            : widget.strings.unskippedToast,
      );
    }
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? c.ink : c.ink3,
          ),
        ),
      ),
    );
  }
}

// ─── Toast ────────────────────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A17),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 14)],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.strings,
    required this.branchFilter,
    required this.pendingCount,
    required this.onNew,
    required this.searchCtrl,
    required this.onSearch,
  });

  final AppStrings strings;
  final String? branchFilter;
  final int pendingCount;
  final VoidCallback onNew;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final title = branchFilter ?? strings.prompts;
    final sub = branchFilter != null
        ? strings.branchesSection
        : '$pendingCount ${strings.pending}';

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: branchFilter != null
                ? Text(
                    title,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $sub',
            style: TextStyle(fontSize: 12.5, color: c.ink3),
          ),
          const Spacer(),
          // Search
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260, minWidth: 80),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, size: 14, color: c.ink4),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: strings.search,
                        hintStyle: TextStyle(color: c.ink4),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface3,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⌘K',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10.5,
                        color: c.ink3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // New button
          GestureDetector(
            onTap: onNew,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    strings.newPrompt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
