import 'package:flutter/material.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';
import 'package:flutterapptemp/src/i18n/app_strings.dart';
import 'package:flutterapptemp/src/widgets/branch_chip.dart';
import 'package:flutterapptemp/src/widgets/status_badge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

class PromptCard extends StatefulWidget {
  const PromptCard({
    required this.prompt,
    required this.strings,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onSkip;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<PromptCard> {
  bool _hovered = false;

  bool get _canReorder =>
      widget.prompt.status == PromptStatus.pending && !widget.prompt.isSkipped;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final p = widget.prompt;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(
              color: widget.selected
                  ? c.ink
                  : (_hovered ? c.ink4 : c.border),
              width: widget.selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: (widget.selected || _hovered)
                ? [BoxShadow(color: c.ink.withValues(alpha: 0.04), blurRadius: 4)]
                : null,
          ),
          child: Opacity(
            opacity: p.isSkipped ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrioCell(
                    priority: p.priority,
                    canReorder: _canReorder,
                    canMoveUp: widget.canMoveUp,
                    canMoveDown: widget.canMoveDown,
                    onMoveUp: widget.onMoveUp,
                    onMoveDown: widget.onMoveDown,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (p.projectPath.isNotEmpty)
                              _ProjectChip(path: p.projectPath),
                            BranchChip(name: p.branch),
                            StatusBadge(
                              status: p.status,
                              isSkipped: p.isSkipped,
                              strings: widget.strings,
                            ),
                            if (p.sessionId.isNotEmpty)
                              _SessionChip(sessionId: p.sessionId),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _timeAgo(p.updatedAt),
                              style: TextStyle(fontSize: 11.5, color: c.ink4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovered ? 1 : 0,
                    child: _Actions(
                      prompt: p,
                      strings: widget.strings,
                      onEdit: widget.onEdit,
                      onSkip: widget.onSkip,
                      onDelete: widget.onDelete,
                      onReset: widget.onReset,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PrioCell extends StatelessWidget {
  const _PrioCell({
    required this.priority,
    required this.canReorder,
    required this.canMoveUp,
    required this.canMoveDown,
    this.onMoveUp,
    this.onMoveDown,
  });

  final int priority;
  final bool canReorder;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return SizedBox(
      width: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canReorder)
            _ArrowBtn(onPressed: canMoveUp ? onMoveUp : null, isUp: true)
          else
            const SizedBox(height: 20),
          Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$priority',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink3,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (canReorder)
            _ArrowBtn(onPressed: canMoveDown ? onMoveDown : null, isUp: false)
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.onPressed, required this.isUp});
  final VoidCallback? onPressed;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return SizedBox(
      height: 20,
      width: 44,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 14,
        padding: EdgeInsets.zero,
        icon: Icon(
          isUp
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: onPressed != null ? c.ink3 : c.border,
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.prompt,
    required this.strings,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
  });

  final PromptEntry prompt;
  final AppStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onSkip;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final p = prompt;
    final canEdit = p.status == PromptStatus.pending || p.isSkipped;
    final canSkip = p.status != PromptStatus.running &&
        p.status != PromptStatus.done;
    final canReset = p.status == PromptStatus.done ||
        p.status == PromptStatus.failed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canEdit)
          _IconBtn(
            icon: Icons.edit_outlined,
            tooltip: strings.edit,
            color: c.ink3,
            onTap: onEdit,
          ),
        if (canSkip)
          _IconBtn(
            icon: Icons.skip_next_outlined,
            tooltip: p.isSkipped ? strings.unskip : strings.skip,
            color: c.ink3,
            onTap: onSkip,
          ),
        if (canReset)
          _IconBtn(
            icon: Icons.refresh_rounded,
            tooltip: strings.reset,
            color: c.ink3,
            onTap: onReset,
          ),
        _IconBtn(
          icon: Icons.delete_outline,
          tooltip: strings.delete,
          color: c.stFailed,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final name = p.basename(path);
    return Tooltip(
      message: path,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: c.surface3,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 11, color: c.ink4),
            const SizedBox(width: 4),
            Text(
              name,
              style: GoogleFonts.ibmPlexMono(fontSize: 11, color: c.ink3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFBDC7F5)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 11, color: c.ink4),
          const SizedBox(width: 4),
          Text(
            sessionId,
            style: GoogleFonts.ibmPlexMono(
                fontSize: 11, color: const Color(0xFF4F5FA0)),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 26,
        height: 26,
        child: IconButton(
          onPressed: onTap,
          iconSize: 14,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }
}
