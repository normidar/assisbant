import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/widgets/branch_chip.dart';
import 'package:assibant/src/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Prompt detail side panel ─────────────────────────────────────────────────

class PromptDetailPanel extends StatelessWidget {
  const PromptDetailPanel({
    required this.prompt,
    required this.strings,
    required this.onClose,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
    super.key,
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
          _DetailHeader(prompt: p, strings: s, onClose: onClose, c: c),
          Expanded(child: _DetailBody(prompt: p, strings: s, c: c)),
          _DetailFooter(
            prompt: p,
            strings: s,
            onEdit: onEdit,
            onSkip: onSkip,
            onDelete: onDelete,
            onReset: onReset,
            c: c,
          ),
        ],
      ),
    );
  }
}

// ─── Panel header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.prompt,
    required this.strings,
    required this.onClose,
    required this.c,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final VoidCallback onClose;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BranchChip(name: prompt.branch),
              const SizedBox(width: 8),
              StatusBadge(
                status: prompt.status,
                isSkipped: prompt.isSkipped,
                strings: strings,
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '#${prompt.priority} · ${prompt.id}',
            style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.ink3),
          ),
        ],
      ),
    );
  }
}

// ─── Panel body (scrollable content + metadata) ───────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.prompt,
    required this.strings,
    required this.c,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final p = prompt;
    final s = strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSection(
            label: s.detailContent,
            child: Text(
              p.content,
              style: const TextStyle(fontSize: 13, height: 1.55),
            ),
          ),
          const SizedBox(height: 18),
          DetailSection(
            label: s.detailMeta,
            child: KeyValueList(
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
          DetailSection(
            label: s.detailLogs,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: p.output?.isNotEmpty ?? false
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: SelectableText(
                        p.output!,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 12, height: 1.5, color: c.ink),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Text(
                        s.noLogs,
                        style: TextStyle(fontSize: 12.5, color: c.ink3),
                      ),
                    ),
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

// ─── Panel footer (action buttons) ───────────────────────────────────────────

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({
    required this.prompt,
    required this.strings,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
    required this.c,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final ValueChanged<PromptEntry> onEdit;
  final ValueChanged<String> onSkip;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onReset;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final p = prompt;
    final s = strings;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border2)),
      ),
      child: Row(
        children: [
          if (p.status == PromptStatus.pending || p.isSkipped) ...[
            DetailActionBtn(
              label: s.edit,
              icon: Icons.edit_outlined,
              onTap: () => onEdit(p),
            ),
            const SizedBox(width: 8),
          ],
          if (p.status != PromptStatus.running &&
              p.status != PromptStatus.done) ...[
            DetailActionBtn(
              label: p.isSkipped ? s.unskip : s.skip,
              icon: Icons.skip_next_outlined,
              onTap: () => onSkip(p.id),
            ),
            const SizedBox(width: 8),
          ],
          if (p.status == PromptStatus.done ||
              p.status == PromptStatus.failed)
            DetailActionBtn(
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
    );
  }
}

// ─── Small action button used in the detail panel footer ─────────────────────

class DetailActionBtn extends StatelessWidget {
  const DetailActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
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
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Labelled section within the detail panel ────────────────────────────────

class DetailSection extends StatelessWidget {
  const DetailSection({
    required this.label,
    required this.child,
    super.key,
  });

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

// ─── Key-value metadata list ──────────────────────────────────────────────────

class KeyValueList extends StatelessWidget {
  const KeyValueList({
    required this.entries,
    this.copyKeys = const {},
    super.key,
  });

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
                  style:
                      GoogleFonts.ibmPlexMono(fontSize: 12, color: c.ink),
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

// ─── Copy-to-clipboard icon button ───────────────────────────────────────────

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

// ─── Delete confirm overlay ───────────────────────────────────────────────────

class DeleteConfirmOverlay extends StatelessWidget {
  const DeleteConfirmOverlay({
    required this.strings,
    required this.onConfirm,
    required this.onCancel,
    super.key,
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
                        Text(s.delete,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(s.confirmDelete,
                            style: TextStyle(
                                fontSize: 13.5, color: c.ink2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border(top: BorderSide(color: c.border2)),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            alignment: Alignment.center,
                            child: Text(
                              s.cancel,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
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
                                  color: Colors.white),
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
