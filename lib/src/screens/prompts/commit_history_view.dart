import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:assibant/src/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Commit history list view ─────────────────────────────────────────────────

class CommitHistoryView extends ConsumerStatefulWidget {
  const CommitHistoryView({
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
  ConsumerState<CommitHistoryView> createState() => _CommitHistoryViewState();
}

class _CommitHistoryViewState extends ConsumerState<CommitHistoryView> {
  List<CommitInfo>? _commits;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCommits();
  }

  @override
  void didUpdateWidget(CommitHistoryView old) {
    super.didUpdateWidget(old);
    if (old.branch != widget.branch) _loadCommits();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: c.stFailed),
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(fontSize: 12.5, color: c.ink3),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final commits = _commits ?? [];
    if (commits.isEmpty) {
      return Center(
        child: Text(s.noCommits,
            style: TextStyle(fontSize: 13, color: c.ink3)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      itemCount: commits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => CommitCard(
        commit: commits[i],
        strings: s,
        selectedId: widget.selectedId,
        timeAgo: _timeAgo(commits[i].date),
        onSelect: commits[i].hasMatch
            ? () =>
                widget.onSelectPrompt(commits[i].matchedPrompts.first.id)
            : null,
      ),
    );
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
        ['log', '--max-count=100', '--format=format:%H|||%aI|||%s', widget.branch],
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

      final commits = _parseGitLog(result.stdout as String);
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

  List<CommitInfo> _parseGitLog(String output) {
    const sep = '|||';
    final commits = <CommitInfo>[];

    for (final line in output.trim().split('\n')) {
      if (line.trim().isEmpty) continue;
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

      commits.add(CommitInfo(
          hash: hash, date: date, message: message, matchedPrompts: matched));
    }
    return commits;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Single commit card ───────────────────────────────────────────────────────

class CommitCard extends StatefulWidget {
  const CommitCard({
    required this.commit,
    required this.strings,
    required this.selectedId,
    required this.timeAgo,
    this.onSelect,
    super.key,
  });

  final CommitInfo commit;
  final AppStrings strings;
  final String? selectedId;
  final String timeAgo;
  final VoidCallback? onSelect;

  @override
  State<CommitCard> createState() => _CommitCardState();
}

class _CommitCardState extends State<CommitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final commit = widget.commit;
    final isSelected =
        commit.matchedPrompts.any((p) => p.id == widget.selectedId);

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
                        horizontal: 7, vertical: 2),
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
                  Text(widget.timeAgo,
                      style: TextStyle(fontSize: 12, color: c.ink3)),
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

// ─── Commit data model ────────────────────────────────────────────────────────

class CommitInfo {
  const CommitInfo({
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
