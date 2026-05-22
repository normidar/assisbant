import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';
import 'package:flutterapptemp/src/i18n/app_strings.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.status,
    required this.isSkipped,
    required this.strings,
    super.key,
  });

  final PromptStatus status;
  final bool isSkipped;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final (label, fg, bg, pulsing) = _resolve(c);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: fg, pulsing: pulsing),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color, bool) _resolve(AppColors c) {
    if (isSkipped) {
      return (strings.statusSkipped, c.stSkipped, c.stSkippedBg, false);
    }
    return switch (status) {
      PromptStatus.pending =>
        (strings.statusPending, c.stPending, c.stPendingBg, false),
      PromptStatus.running =>
        (strings.statusRunning, c.stRunning, c.stRunningBg, true),
      PromptStatus.done =>
        (strings.statusDone, c.stDone, c.stDoneBg, false),
      PromptStatus.failed =>
        (strings.statusFailed, c.stFailed, c.stFailedBg, false),
    };
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulsing});
  final Color color;
  final bool pulsing;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacity =
        Tween<double>(begin: 1, end: 0.4).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale =
        Tween<double>(begin: 1, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulsing) unawaited(_ctrl.repeat(reverse: true));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulsing) {
      return _dot(1, 1);
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => _dot(_opacity.value, _scale.value),
    );
  }

  Widget _dot(double opacity, double scale) => Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}
