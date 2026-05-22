import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/data/database/prompt_status.dart';
import 'package:flutterapptemp/src/i18n/app_strings.dart';
import 'package:flutterapptemp/src/state/exec_notifier.dart';
import 'package:google_fonts/google_fonts.dart';

class ExecBar extends StatefulWidget {
  const ExecBar({
    required this.exec,
    required this.prompts,
    required this.strings,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    super.key,
  });

  final ExecState exec;
  final List<PromptEntry> prompts;
  final AppStrings strings;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  State<ExecBar> createState() => _ExecBarState();
}

class _ExecBarState extends State<ExecBar> {
  bool _outputExpanded = true;
  final ScrollController _scrollCtrl = ScrollController();

  DateTime? _scheduledTime;
  Timer? _tickTimer;

  @override
  void dispose() {
    _tickTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExecBar old) {
    super.didUpdateWidget(old);
    // Cancel scheduled timer when execution leaves idle
    if (widget.exec.status != ExecStatus.idle && old.exec.status == ExecStatus.idle) {
      _tickTimer?.cancel();
      _tickTimer = null;
      _scheduledTime = null;
    }
    // Auto-scroll to bottom when new output arrives
    if (widget.exec.currentOutput != old.exec.currentOutput && _outputExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    }
    // Auto-expand when execution starts
    if (widget.exec.status == ExecStatus.running &&
        old.exec.status == ExecStatus.idle) {
      _outputExpanded = true;
    }
  }

  Future<void> _showTimerDialog(BuildContext context, AppStrings strings) async {
    final target = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _TimerSetupDialog(strings: strings),
    );
    if (target == null || !mounted) return;

    setState(() => _scheduledTime = target);
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _tickTimer?.cancel();
        return;
      }
      final remaining = _scheduledTime?.difference(DateTime.now());
      if (remaining == null || remaining.inSeconds <= 0) {
        _tickTimer?.cancel();
        final hadSchedule = _scheduledTime != null;
        setState(() => _scheduledTime = null);
        if (hadSchedule) widget.onStart();
      } else {
        setState(() {});
      }
    });
  }

  void _cancelTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
    setState(() => _scheduledTime = null);
  }

  String _formatCountdown() {
    final target = _scheduledTime;
    if (target == null) return '';
    final d = target.difference(DateTime.now());
    if (d.isNegative) return '00:00';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final exec = widget.exec;
    final prompts = widget.prompts;
    final strings = widget.strings;
    final queue = prompts
        .where((p) => !p.isSkipped && p.status == PromptStatus.pending)
        .toList();
    final total = exec.totalCount > 0 ? exec.totalCount : queue.length;
    final done = exec.completedCount;
    final pct = total > 0 ? done / total : 0.0;
    final current = exec.status == ExecStatus.running
        ? prompts.where((p) => p.id == exec.currentPromptId).firstOrNull
        : null;
    final isActive = exec.status != ExecStatus.idle;
    final hasOutput = exec.currentOutput.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live output panel
        if (isActive && hasOutput)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _outputExpanded ? 180 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1A17),
              border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.4))),
            ),
            child: _outputExpanded
                ? Column(
                    children: [
                      // Output panel header
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.07)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.stRunning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              current != null
                                  ? '${current.branch} · ${current.projectPath.split('/').last}'
                                  : strings.nowRunning,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _outputExpanded = false),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable output
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollCtrl,
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            child: SelectableText(
                              exec.currentOutput,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11.5,
                                color: Colors.white70,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

        // Collapsed output toggle
        if (isActive && hasOutput && !_outputExpanded)
          GestureDetector(
            onTap: () => setState(() => _outputExpanded = true),
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1A17),
                border:
                    Border(top: BorderSide(color: c.border.withValues(alpha: 0.4))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_arrow_up,
                      size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    'output',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 10.5, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),

        // Main control bar
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (exec.status == ExecStatus.idle) ...[
                if (queue.isEmpty && _scheduledTime == null) ...[
                  _BarBtn(
                    label: strings.schedule,
                    icon: Icons.schedule_rounded,
                    onTap: () => _showTimerDialog(context, strings),
                  ),
                ] else ...[
                  _BarBtn(
                    label: strings.start,
                    icon: Icons.play_arrow_rounded,
                    isPrimary: true,
                    enabled: queue.isNotEmpty,
                    onTap: widget.onStart,
                  ),
                  const SizedBox(width: 6),
                  if (_scheduledTime != null)
                    _TimerCountdownChip(
                      countdown: _formatCountdown(),
                      onCancel: _cancelTimer,
                      onEdit: () => _showTimerDialog(context, strings),
                      c: c,
                    )
                  else
                    _ClockBtn(
                      onTap: () => _showTimerDialog(context, strings),
                      c: c,
                    ),
                ],
              ] else if (exec.status == ExecStatus.running)
                _BarBtn(
                  label: strings.pause,
                  icon: Icons.pause_rounded,
                  onTap: widget.onPause,
                )
              else ...[
                _BarBtn(
                  label: strings.resume,
                  icon: Icons.play_arrow_rounded,
                  isPrimary: true,
                  onTap: widget.onResume,
                ),
                const SizedBox(width: 6),
                _BarBtn(
                  label: strings.stop,
                  icon: Icons.stop_rounded,
                  onTap: widget.onStop,
                ),
              ],

              const SizedBox(width: 16),

              Text(
                exec.status == ExecStatus.idle
                    ? (queue.isNotEmpty
                        ? '${strings.progress}: 0/${queue.length}'
                        : strings.queueEmpty)
                    : '${strings.progress}: $done/$total',
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _ProgressBar(
                  value: pct,
                  running: exec.status == ExecStatus.running,
                ),
              ),

              if (current != null) ...[
                const SizedBox(width: 16),
                Text(
                  '${strings.nowRunning}: ${current.branch}',
                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: c.ink2),
                ),
              ] else if (exec.status == ExecStatus.paused) ...[
                const SizedBox(width: 16),
                Text(
                  '⏸ ${strings.runPaused}',
                  style: TextStyle(fontSize: 12, color: c.stSkipped),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BarBtn extends StatelessWidget {
  const _BarBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isPrimary ? c.accent : c.surface,
            border: Border.all(color: isPrimary ? c.accent : c.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isPrimary ? Colors.white : c.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? Colors.white : c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockBtn extends StatelessWidget {
  const _ClockBtn({required this.onTap, required this.c});
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.ink, width: 1.5),
        ),
        child: Icon(Icons.schedule_rounded, size: 16, color: c.ink),
      ),
    );
  }
}

class _TimerCountdownChip extends StatelessWidget {
  const _TimerCountdownChip({
    required this.countdown,
    required this.onCancel,
    required this.onEdit,
    required this.c,
  });
  final String countdown;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: c.ink, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6, top: 0, bottom: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: c.ink),
                  const SizedBox(width: 5),
                  Text(
                    countdown,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 10),
              child: Icon(Icons.close, size: 14, color: c.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timer setup dialog ───────────────────────────────────────────────────────

class _TimerSetupDialog extends StatefulWidget {
  const _TimerSetupDialog({required this.strings});
  final AppStrings strings;

  @override
  State<_TimerSetupDialog> createState() => _TimerSetupDialogState();
}

class _TimerSetupDialogState extends State<_TimerSetupDialog> {
  bool _isCountdown = false;

  // Time mode
  late int _timeHour;
  late int _timeMinute;

  // Countdown mode
  int _cdHours = 0;
  int _cdMinutes = 30;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timeHour = (now.hour + 1) % 24;
    _timeMinute = 0;
  }

  DateTime get _target {
    if (_isCountdown) {
      return DateTime.now().add(Duration(hours: _cdHours, minutes: _cdMinutes));
    }
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, _timeHour, _timeMinute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  bool get _valid => !_isCountdown || (_cdHours > 0 || _cdMinutes > 0);

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.timerStartTitle),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode toggle
            Row(
              children: [
                Expanded(
                  child: _ModeToggleBtn(
                    label: s.timerModeTime,
                    selected: !_isCountdown,
                    onTap: () => setState(() => _isCountdown = false),
                    c: c,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeToggleBtn(
                    label: s.timerModeCountdown,
                    selected: _isCountdown,
                    onTap: () => setState(() => _isCountdown = true),
                    c: c,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (!_isCountdown)
              _TimeSelector(
                hour: _timeHour,
                minute: _timeMinute,
                onHourChanged: (h) => setState(() => _timeHour = h),
                onMinuteChanged: (m) => setState(() => _timeMinute = m),
                c: c,
              )
            else
              _CountdownSelector(
                hours: _cdHours,
                minutes: _cdMinutes,
                onHoursChanged: (h) => setState(() => _cdHours = h),
                onMinutesChanged: (m) => setState(() => _cdMinutes = m),
                c: c,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          onPressed: _valid ? () => Navigator.pop(context, _target) : null,
          child: Text(s.timerSet),
        ),
      ],
    );
  }
}

class _ModeToggleBtn extends StatelessWidget {
  const _ModeToggleBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
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
        height: 34,
        decoration: BoxDecoration(
          color: selected ? c.accent : Colors.transparent,
          border: Border.all(color: selected ? c.accent : c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : c.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.hour,
    required this.minute,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.c,
  });
  final int hour;
  final int minute;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Spinner(
          value: hour,
          min: 0,
          max: 23,
          onChanged: onHourChanged,
          c: c,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            ':',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              color: c.ink,
            ),
          ),
        ),
        _Spinner(
          value: minute,
          min: 0,
          max: 59,
          onChanged: onMinuteChanged,
          c: c,
        ),
      ],
    );
  }
}

class _CountdownSelector extends StatelessWidget {
  const _CountdownSelector({
    required this.hours,
    required this.minutes,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.c,
  });
  final int hours;
  final int minutes;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Spinner(
          value: hours,
          min: 0,
          max: 23,
          unit: 'h',
          onChanged: onHoursChanged,
          c: c,
        ),
        const SizedBox(width: 24),
        _Spinner(
          value: minutes,
          min: 0,
          max: 59,
          unit: 'm',
          onChanged: onMinutesChanged,
          c: c,
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.c,
    this.unit,
  });
  final int value;
  final int min;
  final int max;
  final String? unit;
  final ValueChanged<int> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final canUp = value < max;
    final canDown = value > min;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: canUp ? () => onChanged(value + 1) : null,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 24,
            color: canUp ? c.ink : c.ink3,
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: c.ink,
          ),
        ),
        GestureDetector(
          onTap: canDown ? () => onChanged(value - 1) : null,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: canDown ? c.ink : c.ink3,
          ),
        ),
        if (unit != null) ...[
          const SizedBox(height: 4),
          Text(unit!, style: TextStyle(fontSize: 12, color: c.ink3)),
        ],
      ],
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.running});
  final double value;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: c.surface3,
          valueColor: AlwaysStoppedAnimation<Color>(
            running ? c.stRunning : c.accent,
          ),
        ),
      ),
    );
  }
}
