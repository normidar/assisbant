import 'dart:io';

import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/screens/settings/env_overrides_dialog.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Mode enum ────────────────────────────────────────────────────────────────

/// ユーザーに提示する「実行モード」。
///
/// 内部的には [AppSettings.cliTool] と [AppSettings.modelMode] の 2 フィールドの
/// 組み合わせだが、意味のある組み合わせは次の 3 通りだけなので UI ではこの enum
/// として 1 つに束ねて扱う:
///
/// - [claudeWithClaude] → (cliTool: claudeCode, modelMode: claude)
/// - [claudeWithLocal]  → (cliTool: claudeCode, modelMode: local)
/// - [aiderWithLocal]   → (cliTool: aider,      modelMode: local)
///
/// Aider は常にローカルモデルを使うため (aider, claude) の組み合わせは存在しない。
enum ConnectMode { claudeWithClaude, claudeWithLocal, aiderWithLocal }

/// [ConnectMode] を保存用の 2 フィールド（cliTool / modelMode）へ変換する。
extension _ModeX on ConnectMode {
  CliTool get cliTool =>
      this == ConnectMode.aiderWithLocal ? CliTool.aider : CliTool.claudeCode;

  /// claudeWithClaude のみ Claude モデル。残り 2 つはローカルモデル扱い。
  ModelMode get modelMode =>
      this == ConnectMode.claudeWithClaude ? ModelMode.claude : ModelMode.local;

  bool get usesAider => this == ConnectMode.aiderWithLocal;
}

/// 保存済み [AppSettings] から現在の [ConnectMode] を復元する（逆変換）。
///
/// cliTool == aider なら modelMode の値に関わらず [aiderWithLocal] とみなす
/// （Aider は常にローカルモデルのため）。この前提により判定順は入れ替え不可。
ConnectMode _modeFromSettings(AppSettings s) {
  if (s.cliTool == CliTool.aider) return ConnectMode.aiderWithLocal;
  if (s.modelMode == ModelMode.local) return ConnectMode.claudeWithLocal;
  return ConnectMode.claudeWithClaude;
}

String modeSummary(AppSettings s) {
  if (s.cliTool == CliTool.aider) {
    final m = s.localModelName.isEmpty ? '…' : s.localModelName;
    return 'Aider · $m';
  }
  if (s.modelMode == ModelMode.local) {
    final m = s.localModelName.isEmpty ? '…' : s.localModelName;
    return 'Claude Code · $m';
  }
  return 'Claude Code · Claude';
}

// ─── Modal ────────────────────────────────────────────────────────────────────

class ConnectionSettingsModal extends ConsumerStatefulWidget {
  const ConnectionSettingsModal({
    required this.c,
    required this.s,
    super.key,
  });
  final AppColors c;
  final AppStrings s;

  @override
  ConsumerState<ConnectionSettingsModal> createState() =>
      _ConnectionSettingsModalState();
}

class _ConnectionSettingsModalState
    extends ConsumerState<ConnectionSettingsModal> {
  late ConnectMode _mode;
  bool _detecting = true;
  String? _claudePath; // null = not found in PATH
  String? _aiderPath;

  late final TextEditingController _claudeCtrl;
  late final TextEditingController _aiderCtrl;
  late final TextEditingController _modelCtrl;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsStateProvider);
    _mode = _modeFromSettings(settings);
    _claudeCtrl = TextEditingController(text: settings.cliPath);
    _aiderCtrl = TextEditingController(text: settings.aiderPath);
    _modelCtrl = TextEditingController(text: settings.localModelName);
    _detect();
  }

  @override
  void dispose() {
    _claudeCtrl.dispose();
    _aiderCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    final home = Platform.environment['HOME'] ?? '';
    final extra =
        '/usr/local/bin:/opt/homebrew/bin:$home/.local/bin:$home/.npm-global/bin';

    Future<String?> which(String name) async {
      try {
        final r = await Process.run('/bin/bash', [
          '-lc',
          'export PATH="$extra:\$PATH"; which $name',
        ]);
        if (r.exitCode == 0) {
          final p = (r.stdout as String).trim();
          if (p.isNotEmpty) return p;
        }
      } catch (_) {}
      return null;
    }

    final results = await Future.wait([which('claude'), which('aider')]);
    if (!mounted) return;
    setState(() {
      _claudePath = results[0];
      _aiderPath = results[1];
      _detecting = false;
    });
  }

  bool _claudeOk() => _claudePath != null || _claudeCtrl.text.trim().isNotEmpty;
  bool _aiderOk() => _aiderPath != null || _aiderCtrl.text.trim().isNotEmpty;
  bool _canSave() => _mode.usesAider ? _aiderOk() : _claudeOk();

  Future<void> _openEnvOverrides(BuildContext ctx) async {
    final settings = ref.read(settingsStateProvider);
    final result = await showDialog<Map<String, String>>(
      context: ctx,
      builder: (_) => EnvOverridesDialog(
        initial: settings.envOverrides,
        strings: widget.s,
        c: widget.c,
      ),
    );
    if (result != null) {
      ref
          .read(settingsStateProvider.notifier)
          .update(
            settings.copyWith(envOverrides: result),
          );
      setState(() {});
    }
  }

  void _save() {
    if (!_canSave()) return;
    final settings = ref.read(settingsStateProvider);
    ref
        .read(settingsStateProvider.notifier)
        .update(
          settings.copyWith(
            cliTool: _mode.cliTool,
            modelMode: _mode.modelMode,
            cliPath: _claudeCtrl.text.trim(),
            aiderPath: _aiderCtrl.text.trim(),
            localModelName: _modelCtrl.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.s;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(c, s),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    _ModeCard(
                      c: c,
                      selected: _mode == ConnectMode.claudeWithClaude,
                      onTap: () =>
                          setState(() => _mode = ConnectMode.claudeWithClaude),
                      title: 'Claude Code + Claude',
                      description: s.connectModeClaudeDesc,
                      detecting: _detecting,
                      detectedPath: _claudePath,
                      available: _claudeOk(),
                      s: s,
                      expandedChildren: [
                        _FormField(
                          label: _claudePath != null
                              ? '${s.cli} (${s.optionalOverride})'
                              : s.cli,
                          placeholder: '/usr/local/bin/claude',
                          ctrl: _claudeCtrl,
                          onChanged: (_) => setState(() {}),
                          c: c,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ModeCard(
                      c: c,
                      selected: _mode == ConnectMode.claudeWithLocal,
                      onTap: () =>
                          setState(() => _mode = ConnectMode.claudeWithLocal),
                      title: 'Claude Code + ${s.modelModeLocal}',
                      description: s.connectModeLocalDesc,
                      detecting: _detecting,
                      detectedPath: _claudePath,
                      available: _claudeOk(),
                      s: s,
                      expandedChildren: [
                        _FormField(
                          label: _claudePath != null
                              ? '${s.cli} (${s.optionalOverride})'
                              : s.cli,
                          placeholder: '/usr/local/bin/claude',
                          ctrl: _claudeCtrl,
                          onChanged: (_) => setState(() {}),
                          c: c,
                        ),
                        const SizedBox(height: 10),
                        _FormField(
                          label: s.localModelName,
                          placeholder: s.localModelNamePlaceholder,
                          ctrl: _modelCtrl,
                          c: c,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ModeCard(
                      c: c,
                      selected: _mode == ConnectMode.aiderWithLocal,
                      onTap: () =>
                          setState(() => _mode = ConnectMode.aiderWithLocal),
                      title: 'Aider + ${s.modelModeLocal}',
                      description: s.connectModeAiderDesc,
                      detecting: _detecting,
                      detectedPath: _aiderPath,
                      available: _aiderOk(),
                      s: s,
                      expandedChildren: [
                        _FormField(
                          label: _aiderPath != null
                              ? '${s.aiderPath} (${s.optionalOverride})'
                              : s.aiderPath,
                          placeholder: '/usr/local/bin/aider',
                          ctrl: _aiderCtrl,
                          onChanged: (_) => setState(() {}),
                          c: c,
                        ),
                        const SizedBox(height: 10),
                        _FormField(
                          label: s.localModelName,
                          placeholder: s.localModelNamePlaceholder,
                          ctrl: _modelCtrl,
                          c: c,
                        ),
                      ],
                    ),
                    // ─ Env Overrides ──────────────────────────────────────
                    const SizedBox(height: 10),
                    Builder(
                      builder: (ctx) {
                        final overrides = ref
                            .watch(settingsStateProvider)
                            .envOverrides;
                        return GestureDetector(
                          onTap: () => _openEnvOverrides(ctx),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.envOverrides,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.envOverridesDesc,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: c.ink3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: overrides.isEmpty
                                        ? c.surface3
                                        : c.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    overrides.isEmpty
                                        ? s.envOverridesNone
                                        : 'Active (${overrides.length})',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: overrides.isEmpty
                                          ? c.ink3
                                          : c.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: c.ink3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(c, s),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c, AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.connectSettings,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.connectSettingsDesc,
                  style: TextStyle(fontSize: 12, color: c.ink3),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close_rounded, size: 18, color: c.ink3),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppColors c, AppStrings s) {
    final ok = _canSave();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
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
            onTap: ok ? _save : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: ok ? c.accent : c.surface3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.save,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ok ? Colors.white : c.ink3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.c,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.description,
    required this.detecting,
    required this.detectedPath,
    required this.available,
    required this.s,
    required this.expandedChildren,
  });

  final AppColors c;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String description;
  final bool detecting;
  final String? detectedPath;
  final bool
  available; // true if tool can be used (detected or custom path set)
  final AppStrings s;
  final List<Widget> expandedChildren;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.04) : c.surface,
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  _Radio(selected: selected, available: available, c: c),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: available ? c.ink : c.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(fontSize: 11.5, color: c.ink3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (detecting)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: c.ink4,
                      ),
                    )
                  else
                    _StatusChip(found: detectedPath != null, s: s),
                ],
              ),
            ),
            // ─ Expanded fields when selected
            if (selected) ...[
              Divider(height: 1, color: c.border2),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!detecting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DetectionRow(
                          path:
                              detectedPath ??
                              'Not found in PATH — specify a path below',
                          found: detectedPath != null,
                          c: c,
                        ),
                      ),
                    ...expandedChildren,
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _Radio extends StatelessWidget {
  const _Radio({
    required this.selected,
    required this.available,
    required this.c,
  });
  final bool selected;
  final bool available;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.accent : (available ? c.ink3 : c.border),
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                ),
              ),
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.found, required this.s});
  final bool found;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final color = found ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final bg = found
        ? const Color(0xFF22C55E).withValues(alpha: 0.10)
        : const Color(0xFFF59E0B).withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            found ? Icons.check_rounded : Icons.warning_amber_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            found ? s.toolFound : s.toolNotFound,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.path,
    required this.found,
    required this.c,
  });
  final String path;
  final bool found;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          found
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          size: 13,
          color: found ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            path,
            style: GoogleFonts.ibmPlexMono(fontSize: 11, color: c.ink2),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.placeholder,
    required this.ctrl,
    required this.c,
    this.onChanged,
  });
  final String label;
  final String placeholder;
  final TextEditingController ctrl;
  final AppColors c;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: c.ink2,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          onChanged: onChanged,
          style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: c.ink4, fontSize: 12),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
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
          ),
        ),
      ],
    );
  }
}
