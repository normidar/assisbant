import 'dart:io';

import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/services/import_export_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Export format options ────────────────────────────────────────────────────

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

// ─── Export dialog ────────────────────────────────────────────────────────────

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
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
    final allSelected = _selected.length == _projects.length &&
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
                    child:
                        Icon(Icons.close_rounded, size: 18, color: c.ink3),
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
                        ExportProjectCheckbox(
                          label: s.unassignedProject,
                          checked: _includeUnassigned,
                          onChanged: (v) =>
                              setState(() => _includeUnassigned = v),
                          c: c,
                        ),
                      ..._projects.map(
                        (path) => ExportProjectCheckbox(
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

// ─── Project checkbox row ─────────────────────────────────────────────────────

class ExportProjectCheckbox extends StatelessWidget {
  const ExportProjectCheckbox({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.c,
    super.key,
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
          color: checked
              ? c.accent.withValues(alpha: 0.06)
              : Colors.transparent,
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
