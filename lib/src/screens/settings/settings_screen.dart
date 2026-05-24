import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:flutterapptemp/src/data/database/app_database.dart';
import 'package:flutterapptemp/src/data/services/import_export_service.dart';
import 'package:flutterapptemp/src/i18n/app_strings.dart';
import 'package:flutterapptemp/src/providers/database_providers.dart';
import 'package:flutterapptemp/src/screens/settings/connection_settings_modal.dart';
import 'package:flutterapptemp/src/screens/settings/env_overrides_dialog.dart';
import 'package:flutterapptemp/src/state/prompt_notifier.dart';
import 'package:flutterapptemp/src/state/ui_providers.dart';
import 'package:google_fonts/google_fonts.dart';

enum ExportFormat {
  json,
  csv,
  excel,
  binary;

  String get label => switch (this) {
        ExportFormat.json => 'JSON',
        ExportFormat.csv => 'CSV',
        ExportFormat.excel => 'Excel (.xlsx)',
        ExportFormat.binary => 'Binary (.ab)',
      };

  String get defaultFileName => switch (this) {
        ExportFormat.json => 'assisbant_export.json',
        ExportFormat.csv => 'assisbant_export.csv',
        ExportFormat.excel => 'assisbant_export.xlsx',
        ExportFormat.binary => 'assisbant_export.ab',
      };

  bool get isBinary =>
      this == ExportFormat.excel || this == ExportFormat.binary;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _toastMessage;

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _openConnectionSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ConnectionSettingsModal(
        c: context.ac,
        s: widget.strings,
      ),
    );
  }

  Future<void> _openEnvOverridesDialog() async {
    final settings = ref.read(settingsStateProvider);
    final s = widget.strings;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EnvOverridesDialog(
        initial: settings.envOverrides,
        strings: s,
        c: context.ac,
      ),
    );
    if (result != null && mounted) {
      ref.read(settingsStateProvider.notifier).update(
            settings.copyWith(envOverrides: result),
          );
    }
  }

  Future<void> _openExportDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ExportDialog(strings: widget.strings),
    );
    if (result == true && mounted) {
      _showToast(widget.strings.exportSuccess);
    }
  }

  Future<void> _doImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    try {
      final jsonStr = await File(path).readAsString();
      final entries = ImportExportService.importFromJson(jsonStr);
      final repo = ref.read(promptRepositoryProvider);
      final count = await repo.importBatch(entries);
      ref.invalidate(promptListNotifierProvider);
      if (mounted) _showToast(widget.strings.importSuccessCount(count));
    } catch (_) {
      if (mounted) _showToast(widget.strings.importFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final settings = ref.watch(settingsStateProvider);
    final lang = ref.watch(langNotifierProvider);

    void upd(AppSettings updated) =>
        ref.read(settingsStateProvider.notifier).update(updated);

    return Stack(
      children: [
        Column(
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
                    s.settings,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      // Execution card
                      _SetCard(
                        title: lang == 'zh'
                            ? '执行配置'
                            : lang == 'ja'
                                ? '実行設定'
                                : 'Execution',
                        subtitle: lang == 'zh'
                            ? '控制 AI 工具如何被调用'
                            : lang == 'ja'
                                ? 'プロンプトの実行設定'
                                : 'Prompt execution settings',
                        c: c,
                        children: [
                          // ─ Connect Settings ───────────────────────────────
                          GestureDetector(
                            onTap: _openConnectionSettings,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: c.border2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.connectSettings,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.connectSettingsDesc,
                                          style: TextStyle(
                                              fontSize: 11.5, color: c.ink3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        modeSummary(settings),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: c.ink2),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right_rounded,
                                          size: 16, color: c.ink3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ─ 共通設定 ──────────────────────────────────────
                          _SetRowSwitch(
                            label: s.autoCheckout,
                            description: s.autoCheckoutDesc,
                            value: settings.autoCheckout,
                            onChanged: (v) =>
                                upd(settings.copyWith(autoCheckout: v)),
                            c: c,
                          ),
                          _SetRowSwitch(
                            label: s.pauseOnFail,
                            description: s.pauseOnFailDesc,
                            value: settings.pauseOnFail,
                            onChanged: (v) =>
                                upd(settings.copyWith(pauseOnFail: v)),
                            c: c,
                          ),
                          _SetRowSwitch(
                            label: s.commitAfterPrompt,
                            description: s.commitAfterPromptDesc,
                            value: settings.commitAfterPrompt,
                            onChanged: (v) =>
                                upd(settings.copyWith(commitAfterPrompt: v)),
                            c: c,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Appearance card
                      _SetCard(
                        title: s.appearance,
                        subtitle: lang == 'zh'
                            ? '语言和主题'
                            : lang == 'ja'
                                ? '言語とテーマ'
                                : 'Language and theme',
                        c: c,
                        children: [
                          _LangPickerRow(
                            label: s.language,
                            description: s.languageDesc,
                            c: c,
                          ),
                          _SetRowWidget(
                            label: s.theme,
                            description: s.themeDesc,
                            c: c,
                            child: _SegControl(
                              items: [
                                (
                                  lang == 'ja'
                                      ? 'ライト'
                                      : lang == 'zh'
                                          ? '浅色'
                                          : 'Light',
                                  lang == 'ja'
                                      ? 'ライト'
                                      : lang == 'zh'
                                          ? '浅色'
                                          : 'Light'
                                ),
                                (
                                  lang == 'ja'
                                      ? 'ダーク'
                                      : lang == 'zh'
                                          ? '深色'
                                          : 'Dark',
                                  lang == 'ja'
                                      ? 'ダーク'
                                      : lang == 'zh'
                                          ? '深色'
                                          : 'Dark'
                                ),
                              ],
                              selected: lang == 'ja'
                                  ? 'ライト'
                                  : lang == 'zh'
                                      ? '浅色'
                                      : 'Light',
                              onSelect: (_) {},
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Data management card
                      _SetCard(
                        title: s.dataManagement,
                        subtitle: s.dataManagementDesc,
                        c: c,
                        children: [
                          _SetRowWidget(
                            label: s.exportData,
                            description: s.exportDataDesc,
                            c: c,
                            child: _ActionBtn(
                              label: s.exportBtn,
                              onTap: _openExportDialog,
                              c: c,
                            ),
                          ),
                          _SetRowWidget(
                            label: s.importData,
                            description: s.importDataDesc,
                            c: c,
                            child: _ActionBtn(
                              label: s.importBtn,
                              onTap: _doImport,
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // About card
                      _SetCard(
                        title: lang == 'zh'
                            ? '关于'
                            : lang == 'ja'
                                ? 'このアプリについて'
                                : 'About',
                        c: c,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Row(
                              children: [
                                const Text(
                                  'assisbant',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'v0.1.0',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    color: c.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_toastMessage != null)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _Toast(message: _toastMessage!)),
          ),
      ],
    );
  }
}

// ─── Export Dialog ────────────────────────────────────────────────────────────

class _ExportDialog extends ConsumerStatefulWidget {
  const _ExportDialog({required this.strings});
  final AppStrings strings;

  @override
  ConsumerState<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<_ExportDialog> {
  List<String> _projects = [];
  bool _hasUnassigned = false;
  Set<String> _selected = {};
  bool _includeUnassigned = false;
  bool _loading = true;
  bool _exporting = false;
  ExportFormat _format = ExportFormat.json;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final repo = ref.read(promptRepositoryProvider);
    final paths = await repo.getProjectPaths();
    final unassigned = await repo.getUnassigned();
    if (!mounted) return;
    setState(() {
      _projects = paths;
      _hasUnassigned = unassigned.isNotEmpty;
      _selected = Set.from(paths);
      _includeUnassigned = unassigned.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      final repo = ref.read(promptRepositoryProvider);
      final prompts = <dynamic>[];

      if (_selected.isNotEmpty) {
        prompts.addAll(await repo.getByProjectPaths(_selected.toList()));
      }
      if (_includeUnassigned) {
        prompts.addAll(await repo.getUnassigned());
      }

      if (prompts.isEmpty) {
        if (mounted) setState(() => _exporting = false);
        return;
      }

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: widget.strings.exportDialogTitle,
        fileName: _format.defaultFileName,
      );

      if (outputPath != null) {
        final typed = prompts.cast<dynamic>().cast<PromptEntry>();
        if (_format == ExportFormat.binary) {
          await File(outputPath)
              .writeAsBytes(ImportExportService.exportToBinary(typed));
        } else if (_format == ExportFormat.excel) {
          await File(outputPath)
              .writeAsBytes(ImportExportService.exportToExcel(typed));
        } else if (_format == ExportFormat.csv) {
          await File(outputPath)
              .writeAsString(ImportExportService.exportToCsv(typed));
        } else {
          await File(outputPath)
              .writeAsString(ImportExportService.exportToJson(typed));
        }
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    } catch (_) {
      // ignore file picker cancel
    }
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final allSelected =
        _selected.length == _projects.length &&
        (!_hasUnassigned || _includeUnassigned);

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.exportDialogTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: c.ink3),
                  ),
                ],
              ),
            ),
            // Body
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.exportSelectProjects,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: c.ink2,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (allSelected) {
                            _selected.clear();
                            _includeUnassigned = false;
                          } else {
                            _selected = Set.from(_projects);
                            _includeUnassigned = _hasUnassigned;
                          }
                        });
                      },
                      child: Text(
                        allSelected ? s.deselectAll : s.selectAll,
                        style: TextStyle(
                            fontSize: 12,
                            color: c.accent,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      if (_hasUnassigned)
                        _ProjectCheckbox(
                          label: s.unassignedProject,
                          checked: _includeUnassigned,
                          onChanged: (v) =>
                              setState(() => _includeUnassigned = v),
                          c: c,
                        ),
                      ..._projects.map(
                        (path) => _ProjectCheckbox(
                          label: path,
                          checked: _selected.contains(path),
                          onChanged: (v) => setState(() {
                            if (v) {
                              _selected.add(path);
                            } else {
                              _selected.remove(path);
                            }
                          }),
                          c: c,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Format selector
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      s.exportFormat,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.ink2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 6,
                      children: ExportFormat.values.map((f) {
                        final active = _format == f;
                        return GestureDetector(
                          onTap: () => setState(() => _format = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? c.accent : c.surface3,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: active ? c.accent : c.border,
                              ),
                            ),
                            child: Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active ? Colors.white : c.ink2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                    onTap: (_loading || _exporting) ? null : _doExport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _exporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.exportBtn,
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
    );
  }
}

class _ProjectCheckbox extends StatelessWidget {
  const _ProjectCheckbox({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.c,
  });
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: checked ? c.accent.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? c.accent : c.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: c.ink,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared settings widgets ──────────────────────────────────────────────────

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.title,
    required this.c,
    required this.children,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final AppColors c;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(fontSize: 12, color: c.ink3)),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SetRowInput extends StatelessWidget {
  const _SetRowInput({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.c,
    this.placeholder = '',
  });
  final String label;
  final String description;
  final String value;
  final ValueChanged<String> onChanged;
  final AppColors c;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 280,
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              style: GoogleFonts.ibmPlexMono(fontSize: 13),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: c.ink4),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
          ),
        ],
      ),
    );
  }
}

class _SetRowSwitch extends StatelessWidget {
  const _SetRowSwitch({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.c,
  });
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                color: value ? c.accent : c.surface3,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: value ? c.accent : c.border),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    left: value ? 17 : 1,
                    top: 1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
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

class _SetRowWidget extends StatelessWidget {
  const _SetRowWidget({
    required this.label,
    required this.description,
    required this.c,
    required this.child,
  });
  final String label;
  final String description;
  final AppColors c;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(fontSize: 11.5, color: c.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          child,
        ],
      ),
    );
  }
}

class _SegControl extends StatelessWidget {
  const _SegControl({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.c,
  });
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final (key, label) = item;
          final active = selected == key;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? c.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : c.ink3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    required this.c,
  });
  final String label;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: c.ink),
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

// ─── Language picker ──────────────────────────────────────────────────────────

// Add entries here when adding new languages — the picker dialog reflects this list automatically.
const _kLanguages = [
  ('en', 'English'),
  ('zh', '中文'),
  ('ja', '日本語'),
];

class _LangPickerRow extends ConsumerWidget {
  const _LangPickerRow({
    required this.label,
    required this.description,
    required this.c,
  });
  final String label;
  final String description;
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langNotifierProvider);
    final langLabel =
        _kLanguages.firstWhere((e) => e.$1 == lang, orElse: () => ('en', 'English')).$2;

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _LangPickerDialog(c: c),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(fontSize: 11.5, color: c.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(langLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.ink2)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: c.ink3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangPickerDialog extends ConsumerWidget {
  const _LangPickerDialog({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langNotifierProvider);
    final s = AppStrings.forLang(lang);

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Text(
                s.language,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink),
              ),
            ),
            Divider(color: c.border, height: 1),
            ..._kLanguages.map((entry) {
              final (key, label) = entry;
              final selected = lang == key;
              return GestureDetector(
                onTap: () {
                  ref.read(langNotifierProvider.notifier).set(key);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: BoxDecoration(
                    color: selected ? c.surface2 : Colors.transparent,
                    border: Border(bottom: BorderSide(color: c.border2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                color: c.ink,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded, size: 16, color: c.ink),
                    ],
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(14),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(fontSize: 13, color: c.ink3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
