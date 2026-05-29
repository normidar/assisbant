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
  final _promptCtrl = TextEditingController();
  final _negativeCtrl = TextEditingController();
  Uint8List? _generatedImage;
  bool _generating = false;
  String? _error;

  // 512, 768, 1024
  int _selectedSize = 512;
  static const _sizes = [512, 768, 1024];

  @override
  void dispose() {
    _promptCtrl.dispose();
    _negativeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _generating = true;
      _error = null;
      _generatedImage = null;
    });
    try {
      final settings = ref.read(settingsStateProvider);
      final bytes = await ImageGenService.generate(
        apiUrl: settings.imageGenApiUrl,
        prompt: prompt,
        negativePrompt: _negativeCtrl.text.trim(),
        model: settings.imageGenModel,
        width: _selectedSize,
        height: _selectedSize,
        steps: 20,
      );
      if (mounted) setState(() => _generatedImage = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveImage() async {
    final bytes = _generatedImage;
    if (bytes == null) return;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save generated image',
      fileName: 'generated_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    if (path == null) return;
    await File(path).writeAsBytes(bytes);
    widget.onAttach(path);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = widget.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image prompt
          PromptFormField(
            label: s.imageGenPrompt,
            child: TextField(
              controller: _promptCtrl,
              maxLines: 3,
              minLines: 2,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.ibmPlexMono(fontSize: 12.5),
              decoration: formInputDeco(c, s.imageGenPromptPlaceholder),
            ),
          ),
          const SizedBox(height: 12),
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
          // Size selector
          Column(
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
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _sizes.map((sz) {
                  final selected = _selectedSize == sz;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSize = sz),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? c.accent : c.surface3,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: selected ? c.accent : c.border),
                      ),
                      child: Text(
                        '${sz}×$sz',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : c.ink2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Generate button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: (_generating || _promptCtrl.text.trim().isEmpty)
                  ? null
                  : _generate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: (_generating || _promptCtrl.text.trim().isEmpty)
                      ? c.surface3
                      : c.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_generating || _promptCtrl.text.trim().isEmpty)
                        ? c.border
                        : c.accent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_generating) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.ink3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.imageGenGenerating,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.ink3),
                      ),
                    ] else ...[
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 14,
                        color: _promptCtrl.text.trim().isEmpty
                            ? c.ink4
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.imageGenGenerate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _promptCtrl.text.trim().isEmpty
                              ? c.ink4
                              : Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Preview / result area
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 160),
            decoration: BoxDecoration(
              color: c.surface2,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 28, color: Colors.red.shade400),
                        const SizedBox(height: 8),
                        Text(
                          s.imageGenFailed,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          style:
                              TextStyle(fontSize: 11.5, color: c.ink4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _generatedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          _generatedImage!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.image_outlined,
                                size: 32, color: c.ink4),
                            const SizedBox(height: 8),
                            Text(
                              s.imageGenIdle,
                              style: TextStyle(
                                  fontSize: 12.5, color: c.ink4),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
          ),
          if (_generatedImage != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _saveImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                          Text(s.imageGenSave,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
