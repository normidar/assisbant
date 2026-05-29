import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/services/image_gen_service.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/providers/database_providers.dart';
import 'package:assibant/src/screens/prompts/prompt_form_shared.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:assibant/src/utils/session_id_generator.dart';
import 'package:google_fonts/google_fonts.dart';

class PromptEditModal extends ConsumerStatefulWidget {
  const PromptEditModal({
    required this.strings,
    required this.branches,
    required this.projectPaths,
    required this.maxPriority,
    required this.onSave,
    required this.onCancel,
    this.initial,
    this.initialBranch,
    this.initialProjectPath,
    this.onBatchCreate,
    this.onSaveAndStart,
    super.key,
  });

  final AppStrings strings;
  final List<String> branches;
  final List<String> projectPaths;
  final int maxPriority;
  final PromptEntry? initial;
  final String? initialBranch;
  final String? initialProjectPath;
  final void Function({
    required String content,
    required String branch,
    required String projectPath,
    required int priority,
    required bool isSkipped,
    required String sessionId,
    required String claudeModel,
    required String imagePaths,
    required bool commitAfterRun,
  }) onSave;
  final void Function({
    required String content,
    required String branch,
    required String projectPath,
    required int priority,
    required bool isSkipped,
    required String sessionId,
    required String claudeModel,
    required String imagePaths,
    required bool commitAfterRun,
  })? onSaveAndStart;
  final VoidCallback onCancel;
  final VoidCallback? onBatchCreate;

  @override
  ConsumerState<PromptEditModal> createState() => _PromptEditModalState();
}

class _PromptEditModalState extends ConsumerState<PromptEditModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _content;
  late final TextEditingController _branch;
  late final TextEditingController _projectPath;
  late final TextEditingController _priority;
  late final TextEditingController _sessionId;
  late bool _isSkipped;
  late bool _commitAfterAgent;
  late String _claudeModel;
  late List<String> _imagePaths;

  List<String> _gitBranches = [];
  bool _loadingBranches = false;
  static final Map<String, List<String>> _branchCache = {};
  List<String> _sessionIdCandidates = [];
  bool _showAllSessionIds = false;
  bool _submitted = false;

  static const _sessionIdPreviewCount = 5;

  bool get _isNew => widget.initial == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (_isNew) {
      final draft = ref.read(newPromptDraftProvider);
      if (!draft.isEmpty) {
        _content = TextEditingController(text: draft.content);
        _branch = TextEditingController(
            text: draft.branch.isNotEmpty
                ? draft.branch
                : (widget.initialBranch ?? ''));
        _projectPath = TextEditingController(
            text: draft.projectPath.isNotEmpty
                ? draft.projectPath
                : (widget.initialProjectPath ?? ''));
        _priority = TextEditingController(
            text: draft.priority.isNotEmpty
                ? draft.priority
                : (widget.maxPriority + 1).toString());
        _sessionId = TextEditingController(text: draft.sessionId);
        _isSkipped = draft.isSkipped;
        _commitAfterAgent = draft.commitAfterAgent;
        _claudeModel = draft.claudeModel;
        _imagePaths = List<String>.from(draft.imagePaths);
        final path = _projectPath.text;
        if (path.isNotEmpty) unawaited(_fetchGitBranches(path));
        unawaited(_fetchSessionIds());
        return;
      }
    }
    _content = TextEditingController(text: widget.initial?.content ?? '');
    _branch = TextEditingController(
        text: widget.initial?.branch ?? widget.initialBranch ?? '');
    _projectPath = TextEditingController(
        text: widget.initial?.projectPath ?? widget.initialProjectPath ?? '');
    _priority = TextEditingController(
      text: (widget.initial?.priority ?? (widget.maxPriority + 1)).toString(),
    );
    _sessionId =
        TextEditingController(text: widget.initial?.sessionId ?? '');
    _isSkipped = widget.initial?.isSkipped ?? false;
    _commitAfterAgent = true;
    _claudeModel = widget.initial?.claudeModel ?? '';
    final raw = widget.initial?.imagePaths ?? '';
    _imagePaths = raw.isEmpty
        ? []
        : List<String>.from(jsonDecode(raw) as List);

    final initial =
        widget.initial?.projectPath ?? widget.initialProjectPath ?? '';
    if (initial.isNotEmpty) unawaited(_fetchGitBranches(initial));
    unawaited(_fetchSessionIds());
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isNew && !_submitted) {
      final hasInput = _content.text.isNotEmpty ||
          _branch.text.isNotEmpty ||
          _projectPath.text.isNotEmpty ||
          _sessionId.text.isNotEmpty;
      if (hasInput) {
        ref.read(newPromptDraftProvider.notifier).save(NewPromptDraft(
              content: _content.text,
              branch: _branch.text,
              projectPath: _projectPath.text,
              sessionId: _sessionId.text,
              priority: _priority.text,
              isSkipped: _isSkipped,
              commitAfterAgent: _commitAfterAgent,
              claudeModel: _claudeModel,
              imagePaths: _imagePaths,
            ));
      } else {
        ref.read(newPromptDraftProvider.notifier).clear();
      }
    }
    _content.dispose();
    _branch.dispose();
    _projectPath.dispose();
    _priority.dispose();
    _sessionId.dispose();
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
      _content.text.trim().isNotEmpty &&
      _branch.text.trim().isNotEmpty &&
      _projectPath.text.trim().isNotEmpty;

  void _save() {
    final content = _content.text.trim();
    final branch = _branch.text.trim();
    final projectPath = _projectPath.text.trim();
    final priority = int.tryParse(_priority.text) ?? (widget.maxPriority + 1);
    final sessionId = _sessionId.text.trim();
    if (!_canSave) return;
    _submitted = true;
    if (_isNew) ref.read(newPromptDraftProvider.notifier).clear();
    widget.onSave(
      content: content,
      branch: branch,
      projectPath: projectPath,
      priority: priority,
      isSkipped: _isSkipped,
      sessionId: sessionId,
      claudeModel: _claudeModel,
      imagePaths: _imagePaths.isEmpty ? '' : jsonEncode(_imagePaths),
      commitAfterRun: _isNew && _commitAfterAgent,
    );
  }

  void _saveAndStart() {
    final content = _content.text.trim();
    final branch = _branch.text.trim();
    final projectPath = _projectPath.text.trim();
    final priority = int.tryParse(_priority.text) ?? (widget.maxPriority + 1);
    final sessionId = _sessionId.text.trim();
    if (!_canSave) return;
    _submitted = true;
    if (_isNew) ref.read(newPromptDraftProvider.notifier).clear();
    widget.onSaveAndStart?.call(
      content: content,
      branch: branch,
      projectPath: projectPath,
      priority: priority,
      isSkipped: _isSkipped,
      sessionId: sessionId,
      claudeModel: _claudeModel,
      imagePaths: _imagePaths.isEmpty ? '' : jsonEncode(_imagePaths),
      commitAfterRun: _isNew && _commitAfterAgent,
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
              width: 560,
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
                  _ModalHeader(
                    title: _isNew ? s.createPrompt : s.editPrompt,
                    subtitle: _isNew ? s.priorityHint : null,
                    c: c,
                    action: _isNew && widget.onBatchCreate != null
                        ? GestureDetector(
                            onTap: widget.onBatchCreate,
                            child: Container(
                              height: 28,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: c.surface,
                                border: Border.all(color: c.border),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.list_alt_outlined,
                                      size: 13, color: c.ink3),
                                  const SizedBox(width: 5),
                                  Text(
                                    s.batchCreate,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: c.ink2,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border2)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: c.accent,
                      labelColor: c.accent,
                      unselectedLabelColor: c.ink3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      tabs: [
                        Tab(text: s.promptTab),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_outlined, size: 13),
                              const SizedBox(width: 5),
                              Text(s.imageGenTab),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── Tab 0: Prompt form ──────────────────────────────
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Content
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
                                            border:
                                                Border.all(color: c.border),
                                            borderRadius:
                                                BorderRadius.circular(5),
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
                                                    fontSize: 11,
                                                    color: c.ink3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _content,
                                    autofocus: true,
                                    maxLines: 5,
                                    minLines: 4,
                                    onChanged: (_) => setState(() {}),
                                    style:
                                        GoogleFonts.ibmPlexMono(fontSize: 12.5),
                                    decoration:
                                        formInputDeco(c, s.promptPlaceholder),
                                  ),
                                  if (_imagePaths.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: List.generate(
                                        _imagePaths.length,
                                        (i) => _ImageChip(
                                          path: _imagePaths[i],
                                          onRemove: () => _removeImage(i),
                                          c: c,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 14),
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
                                          c: c,
                                        ),
                                      ],
                                    ),
                                    if (widget.projectPaths.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children:
                                            widget.projectPaths.map((path) {
                                          return Tooltip(
                                            message: path,
                                            child: FormChip(
                                              label: path.split('/').last,
                                              selected:
                                                  _projectPath.text == path,
                                              onTap: () {
                                                setState(() =>
                                                    _projectPath.text = path);
                                                unawaited(
                                                    _fetchGitBranches(path));
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
                                    if (_projectPath.text
                                        .trim()
                                        .isNotEmpty) ...[
                                      if (_loadingBranches) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: c.ink4,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Loading branches…',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: c.ink4),
                                            ),
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
                                                    unawaited(
                                                        _fetchSessionIds());
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
                                          onTap: () => setState(() {
                                            _sessionId.text =
                                                _generateSessionId();
                                          }),
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
                                                    onTap: () => setState(() =>
                                                        _sessionId.text = id),
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
                                    Text(
                                      s.sessionIdHint,
                                      style: TextStyle(
                                          fontSize: 11.5, color: c.ink4),
                                    ),
                                  ],
                                ),
                              ),
                              // Claude model selector
                              ClaudeModelSelector(
                                strings: s,
                                selected: _claudeModel,
                                onSelect: (v) =>
                                    setState(() => _claudeModel = v),
                                c: c,
                              ),
                              const SizedBox(height: 14),
                              // Priority + skip
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PromptFormField(
                                      label: s.priority,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: _priority,
                                            keyboardType: TextInputType.number,
                                            style: GoogleFonts.ibmPlexMono(
                                                fontSize: 13),
                                            decoration: formInputDeco(c, ''),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            s.priorityHint,
                                            style: TextStyle(
                                                fontSize: 11.5, color: c.ink4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PromptFormField(
                                      label: ' ',
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _isSkipped,
                                              onChanged: (v) => setState(() =>
                                                  _isSkipped = v ?? false),
                                              activeColor: c.accent,
                                            ),
                                            Expanded(
                                              child: Text(
                                                s.skipThis,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: c.ink2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isNew) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _commitAfterAgent,
                                      onChanged: (v) => setState(() =>
                                          _commitAfterAgent = v ?? true),
                                      activeColor: c.accent,
                                    ),
                                    Expanded(
                                      child: Text(
                                        s.commitAfterAgent,
                                        style: TextStyle(
                                            fontSize: 13, color: c.ink2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // ── Tab 1: Image Generation ─────────────────────────
                        _ImageGenTab(
                          strings: s,
                          c: c,
                          onAttach: (path) =>
                              setState(() => _imagePaths.add(path)),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 1) {
                        return Container(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            border:
                                Border(top: BorderSide(color: c.border2)),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FormModalBtn(
                                label: s.cancel,
                                ghost: true,
                                onTap: widget.onCancel,
                                c: c,
                              ),
                            ],
                          ),
                        );
                      }
                      return Builder(builder: (context) {
                        final execStatus =
                            ref.watch(execNotifierProvider).status;
                        final allPrompts =
                            ref.watch(promptListNotifierProvider).value ??
                                <PromptEntry>[];
                        final hasPending = allPrompts.any((p) =>
                            p.status == PromptStatus.pending && !p.isSkipped);
                        final showCreateAndStart = _isNew &&
                            widget.onSaveAndStart != null &&
                            execStatus == ExecStatus.idle &&
                            !hasPending;
                        return Container(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          decoration: BoxDecoration(
                            color: c.surface2,
                            border:
                                Border(top: BorderSide(color: c.border2)),
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FormModalBtn(
                                label: s.cancel,
                                ghost: true,
                                onTap: widget.onCancel,
                                c: c,
                              ),
                              const SizedBox(width: 8),
                              FormModalBtn(
                                label: _isNew ? s.create : s.save,
                                primary: true,
                                enabled: _canSave,
                                onTap: _canSave ? _save : () {},
                                c: c,
                              ),
                              if (showCreateAndStart) ...[
                                const SizedBox(width: 8),
                                FormModalBtn(
                                  label: s.createAndStart,
                                  primary: true,
                                  enabled: _canSave,
                                  onTap: _canSave ? _saveAndStart : () {},
                                  c: c,
                                ),
                              ],
                            ],
                          ),
                        );
                      });
                    },
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

// ─── Image Generation Tab ─────────────────────────────────────────────────────

class _ImageGenTab extends ConsumerStatefulWidget {
  const _ImageGenTab({
    required this.strings,
    required this.c,
    required this.onAttach,
  });

  final AppStrings strings;
  final AppColors c;
  final void Function(String imagePath) onAttach;

  @override
  ConsumerState<_ImageGenTab> createState() => _ImageGenTabState();
}

class _ImageGenTabState extends ConsumerState<_ImageGenTab> {
  final _promptCtrls = <TextEditingController>[TextEditingController()];
  final _negativeCtrl = TextEditingController();

  List<Uint8List?> _results = [];
  bool _generating = false;
  int _generatingIndex = -1; // which prompt slot is currently running
  String? _lastError; // stores last per-prompt error message

  int _selectedPreset = 0;

  // (ratio label, width, height) — all dims are multiples of 64 for SD compatibility
  static const _presets = [
    (ratio: '1:1',    w: 512,  h: 512),
    (ratio: '3:2',    w: 768,  h: 512),
    (ratio: '2:3',    w: 512,  h: 768),
    (ratio: '4:3',    w: 768,  h: 576),
    (ratio: '3:4',    w: 576,  h: 768),
    (ratio: '16:9',   w: 896,  h: 512),
    (ratio: '9:16',   w: 512,  h: 896),
    (ratio: '1:1 XL', w: 1024, h: 1024),
  ];

  ({String ratio, int w, int h}) get _preset => _presets[_selectedPreset];

  bool get _canGenerate =>
      !_generating &&
      _promptCtrls.any((ctrl) => ctrl.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final ctrl in _promptCtrls) {
      ctrl.dispose();
    }
    _negativeCtrl.dispose();
    super.dispose();
  }

  void _addPrompt() {
    setState(() {
      _promptCtrls.add(TextEditingController());
    });
  }

  void _removePrompt(int index) {
    if (_promptCtrls.length <= 1) return;
    _promptCtrls[index].dispose();
    setState(() {
      _promptCtrls.removeAt(index);
      if (_results.length > index) _results.removeAt(index);
    });
  }

  Future<void> _generateAll() async {
    if (!_canGenerate) return;
    setState(() {
      _generating = true;
      _generatingIndex = -1;
      _lastError = null;
      _results = List<Uint8List?>.filled(_promptCtrls.length, null);
    });

    final settings = ref.read(settingsStateProvider);

    for (var i = 0; i < _promptCtrls.length; i++) {
      final prompt = _promptCtrls[i].text.trim();
      if (prompt.isEmpty) continue;
      if (!mounted) break;
      setState(() => _generatingIndex = i);
      try {
        final bytes = await ImageGenService.generate(
          apiUrl: settings.imageGenApiUrl,
          prompt: prompt,
          negativePrompt: _negativeCtrl.text.trim(),
          model: settings.imageGenModel,
          width: _preset.w,
          height: _preset.h,
          steps: 20,
        );
        if (mounted) {
          setState(() => _results[i] = bytes);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _lastError = '#${i + 1}: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _generating = false;
        _generatingIndex = -1;
      });
    }
  }

  Future<void> _saveImage(int index) async {
    final bytes = _results.length > index ? _results[index] : null;
    if (bytes == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save generated image',
      fileName: 'generated_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes);
    widget.onAttach(path);
  }

  Widget _buildAspectRatioPreview(int w, int h, AppColors c) {
    const boxSize = 72.0;
    const inner = boxSize - 16.0;
    final double rectW, rectH;
    if (w >= h) {
      rectW = inner;
      rectH = (inner * h / w).clamp(8.0, inner);
    } else {
      rectH = inner;
      rectW = (inner * w / h).clamp(8.0, inner);
    }
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: rectW,
          height: rectH,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            border: Border.all(color: c.accent, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                '${w}×$h',
                key: ValueKey('$w×$h'),
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSection(AppColors c, AppStrings s) {
    final p = _preset;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.imageGenSize.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.ink4,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_presets.length, (i) {
                  final preset = _presets[i];
                  final selected = _selectedPreset == i;
                  return GestureDetector(
                    onTap: _generating
                        ? null
                        : () => setState(() => _selectedPreset = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? c.accent : c.surface3,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: selected ? c.accent : c.border),
                      ),
                      child: Text(
                        preset.ratio,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : c.ink2,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                '${p.w} × ${p.h} px',
                style: TextStyle(fontSize: 11.5, color: c.ink4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _buildAspectRatioPreview(p.w, p.h, c),
      ],
    );
  }

  Widget _buildGenerateButton(AppColors c, AppStrings s) {
    final activeCount = _promptCtrls
        .where((ctrl) => ctrl.text.trim().isNotEmpty)
        .length;
    final enabled = _canGenerate;

    return GestureDetector(
      onTap: enabled ? _generateAll : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? c.accent : c.surface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? c.accent : c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_generating) ...[
              SizedBox(
                width: 14,
                height: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: c.ink3),
              ),
              const SizedBox(width: 8),
              Text(
                _generatingIndex >= 0
                    ? s.imageGenProgressOf(
                        _generatingIndex + 1, _promptCtrls.length)
                    : s.imageGenGenerating,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.ink3),
              ),
            ] else ...[
              Icon(Icons.auto_awesome_outlined,
                  size: 14, color: enabled ? Colors.white : c.ink4),
              const SizedBox(width: 6),
              Text(
                s.imageGenGenerateAllCount(activeCount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : c.ink4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.strings;
    final hasResults = _results.isNotEmpty && _results.any((r) => r != null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Shared settings ────────────────────────────────────────────────
          // Negative prompt
          PromptFormField(
            label: s.imageGenNegative,
            child: TextField(
              controller: _negativeCtrl,
              maxLines: 2,
              minLines: 1,
              style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
              decoration: formInputDeco(c, s.imageGenNegativePlaceholder),
            ),
          ),
          const SizedBox(height: 12),
          // Size selector with aspect ratio preview
          _buildSizeSection(c, s),
          const SizedBox(height: 16),
          // ── Prompt list ────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                s.imageGenPrompt.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.ink4,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _generating ? null : _addPrompt,
                child: Container(
                  height: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 11, color: c.ink3),
                      const SizedBox(width: 3),
                      Text(s.imageGenAddPrompt,
                          style: TextStyle(fontSize: 11, color: c.ink3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_promptCtrls.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index badge
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 9, right: 8),
                    decoration: BoxDecoration(
                      color: c.surface3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _promptCtrls[i],
                      maxLines: 2,
                      minLines: 1,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
                      decoration:
                          formInputDeco(c, s.imageGenPromptPlaceholder),
                    ),
                  ),
                  // Remove button (only when multiple prompts)
                  if (_promptCtrls.length > 1)
                    GestureDetector(
                      onTap: _generating ? null : () => _removePrompt(i),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 10),
                        child: Icon(Icons.close, size: 16, color: c.ink3),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // ── Generate button ────────────────────────────────────────────────
          _buildGenerateButton(c, s),
          // ── Error banner ───────────────────────────────────────────────────
          if (_lastError != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _lastError!,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ── Results ────────────────────────────────────────────────────────
          if (hasResults) ...[
            const SizedBox(height: 16),
            Divider(color: c.border2),
            const SizedBox(height: 8),
            ...List.generate(_results.length, (i) {
              final bytes = _results[i];
              if (bytes == null) return const SizedBox.shrink();
              final promptPreview = _promptCtrls.length > i
                  ? _promptCtrls[i].text.trim()
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                            ),
                          ),
                        ),
                        if (promptPreview.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              promptPreview,
                              style:
                                  TextStyle(fontSize: 11.5, color: c.ink3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    // Save button
                    GestureDetector(
                      onTap: () => _saveImage(i),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_alt_outlined,
                                size: 13, color: c.ink2),
                            const SizedBox(width: 5),
                            Text(
                              '${s.imageGenSave}  ·  ${s.imageGenAttach}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: c.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (!_generating) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_outlined, size: 28, color: c.ink4),
                  const SizedBox(height: 8),
                  Text(
                    s.imageGenIdle,
                    style: TextStyle(fontSize: 12.5, color: c.ink4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Prompt image chip ─────────────────────────────────────────────────────────

class _ImageChip extends StatelessWidget {
  const _ImageChip({
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

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.title,
    required this.c,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final AppColors c;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(fontSize: 12.5, color: c.ink3)),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}
