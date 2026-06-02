import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/screens/prompts/batch_create_modal.dart';
import 'package:assibant/src/screens/prompts/commit_history_view.dart';
import 'package:assibant/src/screens/prompts/prompt_card.dart';
import 'package:assibant/src/screens/prompts/prompt_detail_panel.dart';
import 'package:assibant/src/screens/prompts/prompt_edit_modal.dart';
import 'package:assibant/src/screens/prompts/prompt_filter_helpers.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({required this.strings, super.key});
  final AppStrings strings;

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

enum _BranchTab { prompts, commits }

// ─── Branch inner tab bar ─────────────────────────────────────────────────────

class _BranchTabBar extends StatelessWidget {
  const _BranchTabBar({
    required this.current,
    required this.strings,
    required this.onChange,
  });

  final _BranchTab current;
  final AppStrings strings;
  final ValueChanged<_BranchTab> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabBtn(
            label: strings.tabPrompts,
            active: current == _BranchTab.prompts,
            onTap: () => onChange(_BranchTab.prompts),
          ),
          const SizedBox(width: 2),
          _TabBtn(
            label: strings.commitHistory,
            active: current == _BranchTab.commits,
            onTap: () => onChange(_BranchTab.commits),
          ),
        ],
      ),
    );
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? c.ink : c.ink3,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notes_outlined, size: 24, color: c.ink4),
          ),
          const SizedBox(height: 12),
          Text(
            strings.queueEmpty,
            style: TextStyle(fontSize: 13, color: c.ink3),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.counts,
    required this.strings,
    required this.onChange,
  });

  final String filter;
  final Map<String, int> counts;
  final AppStrings strings;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final items = [
      ('all', strings.filterAll),
      ('pending', strings.filterPending),
      ('running', strings.filterRunning),
      ('done', strings.filterDone),
      ('failed', strings.filterFailed),
      ('skipped', strings.filterSkipped),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final (key, label) = item;
        final active = filter == key;
        final count = counts[key] ?? 0;
        return GestureDetector(
          onTap: () => onChange(key),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? c.ink : c.surface,
              border: Border.all(color: active ? c.ink : c.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : c.ink2,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: active
                        ? Colors.white.withValues(alpha: 0.7)
                        : c.ink3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.strings,
    required this.branchFilter,
    required this.pendingCount,
    required this.onNew,
    required this.searchCtrl,
    required this.onSearch,
  });

  final AppStrings strings;
  final String? branchFilter;
  final int pendingCount;
  final VoidCallback onNew;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final title = branchFilter ?? strings.prompts;
    final sub = branchFilter != null
        ? strings.branchesSection
        : '$pendingCount ${strings.pending}';

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: branchFilter != null
                ? Text(
                    title,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          const SizedBox(width: 6),
          Text('· $sub', style: TextStyle(fontSize: 12.5, color: c.ink3)),
          const Spacer(),
          // Search field
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 260, minWidth: 80),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, size: 14, color: c.ink4),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: strings.search,
                        hintStyle: TextStyle(color: c.ink4),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: c.surface3,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⌘K',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 10.5, color: c.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // New prompt button
          GestureDetector(
            onTap: onNew,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    strings.newPrompt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

// ─── Toast notification ───────────────────────────────────────────────────────

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

// ─── Main screen state ────────────────────────────────────────────────────────

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  final _searchCtrl = TextEditingController();
  _BranchTab _branchTab = _BranchTab.prompts;
  bool _showEditModal = false;
  bool _showBatchModal = false;
  PromptEntry? _editingPrompt;
  bool _showDeleteConfirm = false;
  String? _deleteTargetId;
  String? _toastMessage;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final promptsAsync = ref.watch(promptListNotifierProvider);
    final filter = ref.watch(filterNotifierProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedId = ref.watch(selectedPromptIdProvider);
    final branchFilter = ref.watch(branchFilterProvider);
    final projectFilter = ref.watch(projectFilterProvider);

    return promptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allPrompts) {
        final (branches, projectPaths, maxPriority) =
            computePromptMetadata(allPrompts);
        final list = applyPromptFilters(
            allPrompts, projectFilter, branchFilter, query, filter);
        final counts = computePromptCounts(
            applyProjectAndBranchFilter(allPrompts, projectFilter, branchFilter));
        final pendingIds = list
            .where((p) => p.status == PromptStatus.pending && !p.isSkipped)
            .map((p) => p.id)
            .toList();
        final selectedPrompt =
            allPrompts.where((p) => p.id == selectedId).firstOrNull;

        // Only show the detail panel when there is enough horizontal space
        final screenWidth = MediaQuery.sizeOf(context).width;
        final showDetailPanel = selectedPrompt != null && screenWidth > 700;

        return Stack(
          children: [
            Column(
              children: [
                _Toolbar(
                  strings: s,
                  branchFilter: branchFilter,
                  pendingCount: allPrompts
                      .where((p) =>
                          !p.isSkipped &&
                          p.status == PromptStatus.pending)
                      .length,
                  onNew: _openNew,
                  searchCtrl: _searchCtrl,
                  onSearch: (v) =>
                      ref.read(searchQueryProvider.notifier).set(v),
                ),
                if (branchFilter != null)
                  _BranchTabBar(
                    current: _branchTab,
                    strings: s,
                    onChange: (t) => setState(() => _branchTab = t),
                  ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _branchTab == _BranchTab.commits
                            ? CommitHistoryView(
                                key: ValueKey('commits_$branchFilter'),
                                branch: branchFilter ?? '',
                                branchPrompts: branchFilter != null
                                    ? allPrompts
                                          .where((p) =>
                                              p.branch == branchFilter)
                                          .toList()
                                    : allPrompts,
                                strings: s,
                                selectedId: selectedId,
                                onSelectPrompt: (id) => ref
                                    .read(selectedPromptIdProvider.notifier)
                                    .toggle(id),
                              )
                            : _PromptListView(
                                list: list,
                                branchFilter: branchFilter,
                                pendingIds: pendingIds,
                                selectedId: selectedId,
                                filter: filter,
                                counts: counts,
                                strings: s,
                                onFilterChange: (v) => ref
                                    .read(filterNotifierProvider.notifier)
                                    .set(v),
                                onSelect: (id) => ref
                                    .read(selectedPromptIdProvider.notifier)
                                    .toggle(id),
                                onEdit: _openEdit,
                                onSkip: _toggleSkip,
                                onDelete: _confirmDelete,
                                onReset: _resetPrompt,
                                onDuplicate: _duplicatePrompt,
                                onMoveUp: (id, peerId) async {
                                  await ref
                                      .read(promptListNotifierProvider
                                          .notifier)
                                      .swapPriority(id, peerId);
                                  _showToast(s.reordered);
                                },
                                onMoveDown: (id, peerId) async {
                                  await ref
                                      .read(promptListNotifierProvider
                                          .notifier)
                                      .swapPriority(id, peerId);
                                  _showToast(s.reordered);
                                },
                              ),
                      ),
                      // Detail panel (only on wide screens)
                      if (showDetailPanel)
                        PromptDetailPanel(
                          prompt: selectedPrompt,
                          strings: s,
                          onClose: () => ref
                              .read(selectedPromptIdProvider.notifier)
                              .select(null),
                          onEdit: _openEdit,
                          onSkip: _toggleSkip,
                          onDelete: _confirmDelete,
                          onReset: _resetPrompt,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Edit modal
            if (_showEditModal)
              PromptEditModal(
                strings: s,
                branches: branches,
                projectPaths: projectPaths,
                maxPriority: maxPriority,
                initial: _editingPrompt,
                initialBranch: _editingPrompt == null ? branchFilter : null,
                initialProjectPath:
                    _editingPrompt == null ? projectFilter : null,
                onSave: ({
                  required content,
                  required branch,
                  required projectPath,
                  required priority,
                  required isSkipped,
                  required sessionId,
                  required claudeModel,
                  required imagePaths,
                  required commitAfterRun,
                }) =>
                    _savePrompt(
                  content,
                  branch,
                  projectPath,
                  priority,
                  isSkipped,
                  sessionId,
                  allPrompts,
                  claudeModel: claudeModel,
                  imagePaths: imagePaths,
                  commitAfterRun: commitAfterRun,
                ),
                onSaveAndStart: _editingPrompt == null
                    ? ({
                        required content,
                        required branch,
                        required projectPath,
                        required priority,
                        required isSkipped,
                        required sessionId,
                        required claudeModel,
                        required imagePaths,
                        required commitAfterRun,
                      }) =>
                        _savePrompt(
                          content,
                          branch,
                          projectPath,
                          priority,
                          isSkipped,
                          sessionId,
                          allPrompts,
                          claudeModel: claudeModel,
                          imagePaths: imagePaths,
                          commitAfterRun: commitAfterRun,
                          startAfterSave: true,
                        )
                    : null,
                onCancel: _closeModal,
                onBatchCreate: _editingPrompt == null ? _openBatch : null,
              ),
            // Batch create modal
            if (_showBatchModal)
              BatchCreateModal(
                strings: s,
                branches: branches,
                projectPaths: projectPaths,
                maxPriority: maxPriority,
                initialBranch: branchFilter,
                initialProjectPath: projectFilter,
                onSave: _saveBatch,
                onCancel: _closeBatchModal,
              ),
            // Delete confirm overlay
            if (_showDeleteConfirm)
              DeleteConfirmOverlay(
                strings: s,
                onConfirm: _doDelete,
                onCancel: () =>
                    setState(() => _showDeleteConfirm = false),
              ),
            // Toast
            if (_toastMessage != null)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(child: _Toast(message: _toastMessage!)),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _closeBatchModal() => setState(() => _showBatchModal = false);
  void _closeModal() => setState(() => _showEditModal = false);

  void _confirmDelete(String id) => setState(() {
        _deleteTargetId = id;
        _showDeleteConfirm = true;
      });

  Future<void> _doDelete() async {
    if (_deleteTargetId == null) return;
    final id = _deleteTargetId!;
    await ref.read(promptListNotifierProvider.notifier).remove(id);
    final selectedId = ref.read(selectedPromptIdProvider);
    if (selectedId == id) {
      ref.read(selectedPromptIdProvider.notifier).select(null);
    }
    setState(() => _showDeleteConfirm = false);
    _showToast(widget.strings.deleted);
  }

  void _openBatch() => setState(() {
        _showEditModal = false;
        _showBatchModal = true;
      });

  void _openEdit(PromptEntry p) => setState(() {
        _editingPrompt = p;
        _showEditModal = true;
      });

  void _openNew() => setState(() {
        _editingPrompt = null;
        _showEditModal = true;
      });

  Future<void> _resetPrompt(String id) async {
    await ref.read(promptListNotifierProvider.notifier).reset(id);
    _showToast(widget.strings.resetToast);
  }

  Future<void> _duplicatePrompt(String id) async {
    await ref.read(promptListNotifierProvider.notifier).duplicate(id);
    _showToast(widget.strings.duplicated);
  }

  Future<void> _saveBatch({
    required List<String> contents,
    required String branch,
    required String projectPath,
    required int basePriority,
    required String sessionId,
    required String claudeModel,
    required String imagePaths,
    required bool commitAfterRun,
  }) async {
    await ref.read(promptListNotifierProvider.notifier).addBatch(
          contents: contents,
          branch: branch,
          projectPath: projectPath,
          basePriority: basePriority,
          sessionId: sessionId,
          claudeModel: claudeModel,
          imagePaths: imagePaths,
          commitAfterRun: commitAfterRun,
        );
    _showToast(widget.strings.batchCreateCount(contents.length));
    _closeBatchModal();
  }

  Future<void> _savePrompt(
    String content,
    String branch,
    String projectPath,
    int priority,
    bool isSkipped,
    String sessionId,
    List<PromptEntry> all, {
    String claudeModel = '',
    String imagePaths = '',
    bool commitAfterRun = false,
    bool startAfterSave = false,
  }) async {
    final notifier = ref.read(promptListNotifierProvider.notifier);
    if (_editingPrompt == null) {
      await notifier.add(
        content: content,
        branch: branch,
        projectPath: projectPath,
        priority: priority,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
      );
      _showToast(widget.strings.created);
    } else {
      await notifier.save(
        id: _editingPrompt!.id,
        content: content,
        branch: branch,
        projectPath: projectPath,
        priority: priority,
        isSkipped: isSkipped,
        sessionId: sessionId,
        claudeModel: claudeModel,
        imagePaths: imagePaths,
        commitAfterRun: commitAfterRun,
      );
      _showToast(widget.strings.saved);
    }
    _closeModal();
    if (startAfterSave) {
      ref.read(execNotifierProvider.notifier).start();
    }
  }

  void _showToast(String msg) {
    setState(() => _toastMessage = msg);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _toggleSkip(String id) async {
    await ref.read(promptListNotifierProvider.notifier).toggleSkip(id);
    final all =
        ref.read(promptListNotifierProvider).value ?? <PromptEntry>[];
    final p = all.where((x) => x.id == id).firstOrNull;
    if (p != null) {
      _showToast(p.isSkipped
          ? widget.strings.skippedToast
          : widget.strings.unskippedToast);
    }
  }
}

// ─── Prompt list + filter chips ───────────────────────────────────────────────

class _PromptListView extends StatelessWidget {
  const _PromptListView({
    required this.list,
    required this.branchFilter,
    required this.pendingIds,
    required this.selectedId,
    required this.filter,
    required this.counts,
    required this.strings,
    required this.onFilterChange,
    required this.onSelect,
    required this.onEdit,
    required this.onSkip,
    required this.onDelete,
    required this.onReset,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final List<PromptEntry> list;
  final String? branchFilter;
  final List<String> pendingIds;
  final String? selectedId;
  final String filter;
  final Map<String, int> counts;
  final AppStrings strings;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<String> onSelect;
  final ValueChanged<PromptEntry> onEdit;
  final ValueChanged<String> onSkip;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onReset;
  final ValueChanged<String> onDuplicate;
  final Future<void> Function(String id, String peerId) onMoveUp;
  final Future<void> Function(String id, String peerId) onMoveDown;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (branchFilter != null)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              s.reorderHint,
              style: TextStyle(fontSize: 12, color: c.ink3),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _FilterChips(
            filter: filter,
            counts: counts,
            strings: s,
            onChange: onFilterChange,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: list.isEmpty
              ? _EmptyState(strings: s)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final idx = pendingIds.indexOf(p.id);
                    return PromptCard(
                      key: ValueKey(p.id),
                      prompt: p,
                      strings: s,
                      selected: selectedId == p.id,
                      onSelect: () => onSelect(p.id),
                      onEdit: () => onEdit(p),
                      onSkip: () => onSkip(p.id),
                      onDelete: () => onDelete(p.id),
                      onReset: () => onReset(p.id),
                      onDuplicate: () => onDuplicate(p.id),
                      canMoveUp: idx > 0,
                      canMoveDown:
                          idx >= 0 && idx < pendingIds.length - 1,
                      onMoveUp: idx > 0
                          ? () => onMoveUp(p.id, pendingIds[idx - 1])
                          : null,
                      onMoveDown:
                          idx >= 0 && idx < pendingIds.length - 1
                          ? () => onMoveDown(p.id, pendingIds[idx + 1])
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
