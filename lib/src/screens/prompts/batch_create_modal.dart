import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:flutterapptemp/src/i18n/app_strings.dart';
import 'package:flutterapptemp/src/providers/database_providers.dart';
import 'package:flutterapptemp/src/screens/prompts/prompt_form_shared.dart';
import 'package:flutterapptemp/src/utils/session_id_generator.dart';
import 'package:google_fonts/google_fonts.dart';

class BatchCreateModal extends ConsumerStatefulWidget {
  const BatchCreateModal({
    required this.strings,
    required this.branches,
    required this.projectPaths,
    required this.maxPriority,
    required this.onSave,
    required this.onCancel,
    this.initialBranch,
    this.initialProjectPath,
    super.key,
  });

  final AppStrings strings;
  final List<String> branches;
  final List<String> projectPaths;
  final int maxPriority;
  final String? initialBranch;
  final String? initialProjectPath;
  final void Function({
    required List<String> contents,
    required String branch,
    required String projectPath,
    required int basePriority,
    required String sessionId,
    required String claudeModel,
    required String imagePaths,
    required bool commitAfterRun,
  }) onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<BatchCreateModal> createState() => _BatchCreateModalState();
}

class _BatchCreateModalState extends ConsumerState<BatchCreateModal> {
  late final TextEditingController _branch;
  late final TextEditingController _projectPath;
  late final TextEditingController _priority;
  late final TextEditingController _sessionId;
  final TextEditingController _inputCtrl = TextEditingController();
  final List<String> _items = [];
  final List<String> _imagePaths = [];
  String _claudeModel = '';

  bool _commitAfterRun = true;
  List<String> _gitBranches = [];
  bool _loadingBranches = false;
  static final Map<String, List<String>> _branchCache = {};
  List<String> _sessionIdCandidates = [];
  bool _showAllSessionIds = false;

  static const _sessionIdPreviewCount = 5;

  @override
  void initState() {
    super.initState();
    _branch = TextEditingController(text: widget.initialBranch ?? '');
    _projectPath =
        TextEditingController(text: widget.initialProjectPath ?? '');
    _priority =
        TextEditingController(text: (widget.maxPriority + 1).toString());
    _sessionId = TextEditingController();

    final initial = widget.initialProjectPath ?? '';
    if (initial.isNotEmpty) unawaited(_fetchGitBranches(initial));
    unawaited(_fetchSessionIds());
  }

  @override
  void dispose() {
    _branch.dispose();
    _projectPath.dispose();
    _priority.dispose();
    _sessionId.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSessionIds() async {
    final path = _projectPath.text.trim();
    final branch = _branch.text.trim();
    if (path.isEmpty || branch.isEmpty) {
      if (mounted) setState(() => _sessionIdCandidates = []);
      return;
    }
    final repo = ref.read(promptRepositoryProvider);
    final ids = await repo.getSessionIds(path, branch);
    if (mounted) setState(() => _sessionIdCandidates = ids);
  }

  String _generateSessionId() => generateSessionId();

  Future<void> _fetchGitBranches(String path) async {
    final expanded = _expandHome(path);
    if (expanded.isEmpty) {
      setState(() => _gitBranches = []);
      return;
    }
    if (_branchCache.containsKey(expanded)) {
      setState(() => _gitBranches = _branchCache[expanded]!);
      return;
    }
    setState(() => _loadingBranches = true);
    try {
      final result = await Process.run(
        '/usr/bin/git',
        ['branch'],
        workingDirectory: expanded,
      );
      if (!mounted) return;
      if (result.exitCode == 0) {
        String? current;
        final lines = (result.stdout as String)
            .split('\n')
            .map((l) {
              if (l.contains('*')) {
                current = l.replaceFirst('*', '').trim();
                return current!;
              }
              return l.trim();
            })
            .where((l) => l.isNotEmpty)
            .toList();
        if (current != null) {
          lines.remove(current);
          lines.insert(0, current!);
        }
        _branchCache[expanded] = lines;
        setState(() => _gitBranches = lines);
      } else {
        setState(() => _gitBranches = []);
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _gitBranches = []);
    } finally {
      if (mounted) setState(() => _loadingBranches = false);
    }
  }

  String _expandHome(String path) {
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ?? '';
      return home + path.substring(1);
    }
    return path;
  }

  bool get _canSave =>
      _items.isNotEmpty &&
      _branch.text.trim().isNotEmpty &&
      _projectPath.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    widget.onSave(
      contents: List.unmodifiable(_items),
      branch: _branch.text.trim(),
      projectPath: _projectPath.text.trim(),
      basePriority: int.tryParse(_priority.text) ?? (widget.maxPriority + 1),
      sessionId: _sessionId.text.trim(),
      claudeModel: _claudeModel,
      imagePaths: _imagePaths.isEmpty ? '' : jsonEncode(_imagePaths),
      commitAfterRun: _commitAfterRun,
    );
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _projectPath.text = result);
      await _fetchGitBranches(result);
      unawaited(_fetchSessionIds());
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      final paths = result.paths.whereType<String>().toList();
      setState(() => _imagePaths.addAll(paths));
    }
  }

  void _removeImage(int index) => setState(() => _imagePaths.removeAt(index));

  void _handleInputChange(String value) {
    if (value.contains('\n')) {
      final parts = value
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      setState(() {
        _items.addAll(parts);
        _inputCtrl.clear();
      });
    }
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;

    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: c.ink.withValues(alpha: 0.14),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.batchCreateTitle,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(s.batchInputHint,
                            style: TextStyle(fontSize: 12.5, color: c.ink3)),
                      ],
                    ),
                  ),
                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project path
                          PromptFormField(
                            label: s.projectPath,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _projectPath,
                                        onChanged: (v) {
                                          setState(() {});
                                          unawaited(
                                              _fetchGitBranches(v.trim()));
                                          unawaited(_fetchSessionIds());
                                        },
                                        style: GoogleFonts.ibmPlexMono(
                                            fontSize: 13),
                                        decoration: formInputDeco(
                                            c, s.projectPathPlaceholder),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FormBrowseButton(
                                        label: s.pickFolder,
                                        onTap: _pickFolder,
                                        c: c),
                                  ],
                                ),
                                if (widget.projectPaths.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: widget.projectPaths.map((path) {
                                      return Tooltip(
                                        message: path,
                                        child: FormChip(
                                          label: path.split('/').last,
                                          selected: _projectPath.text == path,
                                          onTap: () {
                                            setState(() =>
                                                _projectPath.text = path);
                                            unawaited(_fetchGitBranches(path));
                                            unawaited(_fetchSessionIds());
                                          },
                                          c: c,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Branch
                          PromptFormField(
                            label: s.branch,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _branch,
                                  onChanged: (_) {
                                    setState(() {});
                                    unawaited(_fetchSessionIds());
                                  },
                                  style:
                                      GoogleFonts.ibmPlexMono(fontSize: 13),
                                  decoration:
                                      formInputDeco(c, s.branchPlaceholder),
                                ),
                                if (_projectPath.text.trim().isNotEmpty) ...[
                                  if (_loadingBranches) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 1.5, color: c.ink4),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Loading branches…',
                                            style: TextStyle(
                                                fontSize: 11.5, color: c.ink4)),
                                      ],
                                    ),
                                  ] else if (_gitBranches.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _gitBranches
                                          .map(
                                            (b) => FormChip(
                                              label: b,
                                              selected: _branch.text == b,
                                              onTap: () {
                                                setState(
                                                    () => _branch.text = b);
                                                unawaited(_fetchSessionIds());
                                              },
                                              c: c,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Session ID
                          PromptFormField(
                            label: s.sessionId,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _sessionId,
                                        onChanged: (_) => setState(() {}),
                                        style: GoogleFonts.ibmPlexMono(
                                            fontSize: 13),
                                        decoration: formInputDeco(
                                            c, s.sessionIdPlaceholder),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FormBrowseButton(
                                      label: s.generateId,
                                      onTap: () => setState(() =>
                                          _sessionId.text =
                                              _generateSessionId()),
                                      c: c,
                                    ),
                                  ],
                                ),
                                if (_sessionIdCandidates.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      ...(_showAllSessionIds
                                              ? _sessionIdCandidates
                                              : _sessionIdCandidates.take(
                                                  _sessionIdPreviewCount))
                                          .map((id) => FormChip(
                                                label: id,
                                                selected:
                                                    _sessionId.text == id,
                                                onTap: () => setState(
                                                    () => _sessionId.text = id),
                                                c: c,
                                              )),
                                      if (_sessionIdCandidates.length >
                                          _sessionIdPreviewCount)
                                        FormChip(
                                          label: _showAllSessionIds
                                              ? '▲'
                                              : '+${_sessionIdCandidates.length - _sessionIdPreviewCount}',
                                          selected: false,
                                          onTap: () => setState(() =>
                                              _showAllSessionIds =
                                                  !_showAllSessionIds),
                                          c: c,
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(s.sessionIdHint,
                                    style: TextStyle(
                                        fontSize: 11.5, color: c.ink4)),
                              ],
                            ),
                          ),
                          // Claude model selector
                          ClaudeModelSelector(
                            strings: s,
                            selected: _claudeModel,
                            onSelect: (v) => setState(() => _claudeModel = v),
                            c: c,
                          ),
                          const SizedBox(height: 14),
                          // Priority
                          PromptFormField(
                            label: s.priority,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: TextField(
                                    controller: _priority,
                                    keyboardType: TextInputType.number,
                                    style:
                                        GoogleFonts.ibmPlexMono(fontSize: 13),
                                    decoration: formInputDeco(c, ''),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(s.priorityHint,
                                    style: TextStyle(
                                        fontSize: 11.5, color: c.ink4)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: c.border2),
                          const SizedBox(height: 14),
                          // Prompts input + list
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.promptContent.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.ink4,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      height: 22,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7),
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        border: Border.all(color: c.border),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image_outlined,
                                              size: 11, color: c.ink3),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.attachImages,
                                            style: TextStyle(
                                                fontSize: 11, color: c.ink3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (_imagePaths.isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: List.generate(
                                    _imagePaths.length,
                                    (i) => _BatchImageChip(
                                      path: _imagePaths[i],
                                      onRemove: () => _removeImage(i),
                                      c: c,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _inputCtrl,
                                  maxLines: null,
                                  autofocus: true,
                                  onChanged: _handleInputChange,
                                  style:
                                      GoogleFonts.ibmPlexMono(fontSize: 12.5),
                                  decoration: formInputDeco(c, s.batchInputHint),
                                ),
                                const SizedBox(height: 12),
                                if (_items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Center(
                                      child: Text(s.batchEmpty,
                                          style: TextStyle(
                                              fontSize: 13, color: c.ink3)),
                                    ),
                                  )
                                else
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 300),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: List.generate(_items.length,
                                            (i) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                                bottom: i < _items.length - 1
                                                    ? 6
                                                    : 0),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: c.surface2,
                                                border: Border.all(
                                                    color: c.border),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 22,
                                                    height: 22,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: c.surface3,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      '${i + 1}',
                                                      style: GoogleFonts
                                                          .ibmPlexMono(
                                                              fontSize: 10.5,
                                                              color: c.ink3),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      _items[i],
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          height: 1.4),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _removeItem(i),
                                                    child: Icon(Icons.close,
                                                        size: 14,
                                                        color: c.ink3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border(top: BorderSide(color: c.border2)),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _commitAfterRun,
                              onChanged: (v) =>
                                  setState(() => _commitAfterRun = v ?? true),
                              activeColor: c.accent,
                            ),
                            Expanded(
                              child: Text(
                                s.commitAfterAgent,
                                style:
                                    TextStyle(fontSize: 13, color: c.ink2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FormModalBtn(
                                label: s.cancel,
                                ghost: true,
                                onTap: widget.onCancel,
                                c: c),
                            const SizedBox(width: 8),
                            FormModalBtn(
                              label: _items.isEmpty
                                  ? s.batchCreateBtn
                                  : s.batchCreateCount(_items.length),
                              primary: true,
                              enabled: _canSave,
                              onTap: _canSave ? _save : () {},
                              c: c,
                            ),
                          ],
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

class _BatchImageChip extends StatelessWidget {
  const _BatchImageChip({
    required this.path,
    required this.onRemove,
    required this.c,
  });

  final String path;
  final VoidCallback onRemove;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').last;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 12, color: c.ink3),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              style: TextStyle(fontSize: 12, color: c.ink2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: c.ink3),
          ),
        ],
      ),
    );
  }
}
