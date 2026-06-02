import 'package:assibant/src/app/theme.dart';
import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/i18n/app_strings.dart';
import 'package:assibant/src/remote/server/remote_server_service.dart';
import 'package:assibant/src/screens/branches/branches_screen.dart';
import 'package:assibant/src/screens/logs/logs_screen.dart';
import 'package:assibant/src/screens/prompts/prompts_screen.dart';
import 'package:assibant/src/screens/settings/settings_screen.dart';
import 'package:assibant/src/state/exec_notifier.dart';
import 'package:assibant/src/state/prompt_notifier.dart';
import 'package:assibant/src/state/ui_providers.dart';
import 'package:assibant/src/widgets/exec_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WindowListener {
  bool _questionDialogOpen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep remote server alive for the lifetime of the app shell
    ref.read(remoteServerProvider);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _showQuestionDialog(String question, AppStrings strings) {
    if (_questionDialogOpen) return;
    _questionDialogOpen = true;

    final controller = TextEditingController();
    final c = context.ac;

    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Text(
              strings.claudeQuestion,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: SelectableText(
                  question,
                  style: TextStyle(fontSize: 13, color: c.ink, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                style: TextStyle(fontSize: 13, color: c.ink),
                decoration: InputDecoration(
                  hintText: strings.typeYourAnswer,
                  hintStyle: TextStyle(color: c.ink3),
                  filled: true,
                  fillColor: c.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.accent),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final answer = controller.text.trim();
              if (answer.isNotEmpty) Navigator.of(ctx).pop(answer);
            },
            child: Text(
              strings.submitAnswer,
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).then((answer) {
      _questionDialogOpen = false;
      if (answer != null && answer.isNotEmpty) {
        ref.read(execNotifierProvider.notifier).answerQuestion(answer);
      }
    });
  }

  @override
  Future<void> onWindowClose() async {
    final exec = ref.read(execNotifierProvider);
    final isActive = exec.status == ExecStatus.running ||
        exec.status == ExecStatus.paused;

    if (!isActive) {
      await windowManager.destroy();
      return;
    }

    if (!mounted) return;
    final lang = ref.read(langNotifierProvider);
    final s = AppStrings.forLang(lang);
    final c = context.ac;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        title: Text(
          s.closeWhileRunning,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          s.closeWhileRunningMsg,
          style: TextStyle(fontSize: 13, color: c.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel, style: TextStyle(color: c.ink2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.closeAnyway,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldClose ?? false) {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langNotifierProvider);
    final strings = AppStrings.forLang(lang);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 720;

    ref.listen<ExecState>(execNotifierProvider, (prev, next) {
      if (next.pendingQuestion != null &&
          prev?.pendingQuestion == null &&
          mounted) {
        _showQuestionDialog(next.pendingQuestion!, strings);
      }
    });

    return isWide
        ? _DesktopLayout(strings: strings)
        : _MobileLayout(strings: strings);
  }
}

// ─── Desktop layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ac;
    final tab = ref.watch(currentTabProvider);
    final promptsAsync = ref.watch(promptListNotifierProvider);
    final exec = ref.watch(execNotifierProvider);

    final allPrompts = promptsAsync.value ?? <PromptEntry>[];

    return Scaffold(
      backgroundColor: c.bg,
      body: Row(
        children: [
          _Sidebar(strings: strings),
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: exec.status == ExecStatus.running
                      ? const _RunningTopBar(key: ValueKey('topbar'))
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                Expanded(
                  child: _currentScreen(tab, strings),
                ),
                ExecBar(
                  exec: exec,
                  prompts: allPrompts,
                  strings: strings,
                  onStart: () => ref
                      .read(execNotifierProvider.notifier)
                      .start(),
                  onPause: () =>
                      ref.read(execNotifierProvider.notifier).pause(),
                  onResume: () =>
                      ref.read(execNotifierProvider.notifier).resume(),
                  onStop: () =>
                      ref.read(execNotifierProvider.notifier).stop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentScreen(AppTab tab, AppStrings s) {
    return switch (tab) {
      AppTab.prompts => PromptsScreen(strings: s),
      AppTab.branches => BranchesScreen(strings: s),
      AppTab.logs => LogsScreen(strings: s),
      AppTab.settings => SettingsScreen(strings: s),
    };
  }
}

// ─── Mobile layout ────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ac;
    final tab = ref.watch(currentTabProvider);
    final promptsAsync = ref.watch(promptListNotifierProvider);
    final exec = ref.watch(execNotifierProvider);
    final allPrompts = promptsAsync.value ?? <PromptEntry>[];
    final s = strings;

    return Scaffold(
      backgroundColor: c.bg,
      body: _currentScreen(tab, s),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact exec bar for mobile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xE61C1A17),
              border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                if (exec.status == ExecStatus.idle)
                  _MobileExecBtn(
                    label: s.start,
                    onTap: allPrompts.isNotEmpty
                        ? () => ref
                            .read(execNotifierProvider.notifier)
                            .start()
                        : null,
                  )
                else if (exec.status == ExecStatus.running)
                  _MobileExecBtn(
                    label: s.pause,
                    onTap: () => ref.read(execNotifierProvider.notifier).pause(),
                  )
                else
                  _MobileExecBtn(
                    label: s.resume,
                    onTap: () =>
                        ref.read(execNotifierProvider.notifier).resume(),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exec.status == ExecStatus.idle
                            ? (allPrompts.isNotEmpty
                                ? '${executableQueue(allPrompts).length} ${s.pending}'
                                : s.idle)
                            : '${exec.completedCount}/${exec.totalCount}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: exec.progress,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              exec.status == ExecStatus.running
                                  ? c.stRunning
                                  : c.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation
          NavigationBar(
            backgroundColor: c.surface,
            indicatorColor: c.accent.withValues(alpha: 0.12),
            selectedIndex: _tabIndex(tab),
            onDestinationSelected: (i) => ref
                .read(currentTabProvider.notifier)
                .set(AppTab.values[i]),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.notes_outlined),
                selectedIcon: Icon(Icons.notes, color: c.accent),
                label: s.prompts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.call_split_outlined),
                selectedIcon: Icon(Icons.call_split, color: c.accent),
                label: s.branches,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: c.accent),
                label: s.logs,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: c.accent),
                label: s.settings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _tabIndex(AppTab tab) => switch (tab) {
        AppTab.prompts => 0,
        AppTab.branches => 1,
        AppTab.logs => 2,
        AppTab.settings => 3,
      };

  Widget _currentScreen(AppTab tab, AppStrings s) {
    return switch (tab) {
      AppTab.prompts => PromptsScreen(strings: s),
      AppTab.branches => BranchesScreen(strings: s),
      AppTab.logs => LogsScreen(strings: s),
      AppTab.settings => SettingsScreen(strings: s),
    };
  }
}

class _MobileExecBtn extends StatelessWidget {
  const _MobileExecBtn({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFC2502F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Sidebar (desktop) ────────────────────────────────────────────────────────

class _Sidebar extends ConsumerStatefulWidget {
  const _Sidebar({required this.strings});
  final AppStrings strings;

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  String? _expandedProject;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final s = widget.strings;
    final tab = ref.watch(currentTabProvider);
    final promptsAsync = ref.watch(promptListNotifierProvider);
    final settings = ref.watch(settingsStateProvider);
    final exec = ref.watch(execNotifierProvider);
    final isRunning = exec.status == ExecStatus.running;

    final allPrompts = promptsAsync.value ?? <PromptEntry>[];
    final projectPaths = allPrompts
        .map((e) => e.projectPath)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final branchFilter = ref.watch(branchFilterProvider);
    final projectFilter = ref.watch(projectFilterProvider);
    final projectPendingCounts = <String, int>{};
    final branchPendingCounts = <String, int>{};
    for (final e in allPrompts) {
      if (!e.isSkipped && e.status.name == 'pending') {
        if (e.projectPath.isNotEmpty) {
          projectPendingCounts[e.projectPath] =
              (projectPendingCounts[e.projectPath] ?? 0) + 1;
        }
        branchPendingCounts[e.branch] =
            (branchPendingCounts[e.branch] ?? 0) + 1;
      }
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'a/',
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'assisbant',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRunning) ...[
                          const SizedBox(width: 6),
                          _PulsingDot(color: c.stRunning),
                        ],
                      ],
                    ),
                    Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 11, color: c.ink3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main nav items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _NavItem(
                  icon: Icons.notes_outlined,
                  label: s.prompts,
                  count: allPrompts.length,
                  active: tab == AppTab.prompts && branchFilter == null && projectFilter == null,
                  onTap: () {
                    ref.read(currentTabProvider.notifier).set(AppTab.prompts);
                    ref.read(branchFilterProvider.notifier).set(null);
                    ref.read(projectFilterProvider.notifier).set(null);
                    setState(() => _expandedProject = null);
                  },
                  c: c,
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: s.logs,
                  active: tab == AppTab.logs,
                  onTap: () =>
                      ref.read(currentTabProvider.notifier).set(AppTab.logs),
                  c: c,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  active: tab == AppTab.settings,
                  onTap: () =>
                      ref.read(currentTabProvider.notifier).set(AppTab.settings),
                  c: c,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Projects section with expandable branches
          if (projectPaths.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                s.projectsSection.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink4,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  children: projectPaths.expand((path) {
                    final isProjectActive = projectFilter == path;
                    final isExpanded = _expandedProject == path;
                    final name = p.basename(path);
                    final projectBranches = allPrompts
                        .where((e) => e.projectPath == path)
                        .map((e) => e.branch)
                        .toSet()
                        .toList()
                      ..sort();

                    return <Widget>[
                      Tooltip(
                        message: path,
                        child: GestureDetector(
                          onTap: () {
                            ref.read(currentTabProvider.notifier).set(AppTab.prompts);
                            if (isExpanded && isProjectActive) {
                              setState(() => _expandedProject = null);
                              ref.read(projectFilterProvider.notifier).set(null);
                              ref.read(branchFilterProvider.notifier).set(null);
                            } else {
                              setState(() => _expandedProject = path);
                              ref.read(projectFilterProvider.notifier).set(path);
                              ref.read(branchFilterProvider.notifier).set(null);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isProjectActive
                                  ? c.ink.withValues(alpha: 0.07)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined,
                                    size: 12, color: c.ink4),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.ibmPlexMono(
                                      fontSize: 12.5,
                                      color: isProjectActive ? c.ink : c.ink2,
                                      fontWeight: isProjectActive
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if ((projectPendingCounts[path] ?? 0) > 0)
                                  Text(
                                    '${projectPendingCounts[path]}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.ink3,
                                      fontFamily:
                                          GoogleFonts.ibmPlexMono().fontFamily,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14,
                                  color: c.ink4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isExpanded)
                        ...projectBranches.map((b) {
                          final isBranchActive =
                              branchFilter == b && isProjectActive;
                          return GestureDetector(
                            onTap: () {
                              ref.read(branchFilterProvider.notifier)
                                  .set(isBranchActive ? null : b);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              padding: const EdgeInsets.only(
                                  left: 28, right: 10, top: 5, bottom: 5),
                              decoration: BoxDecoration(
                                color: isBranchActive
                                    ? c.ink.withValues(alpha: 0.07)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: c.ink4,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b,
                                      style: GoogleFonts.ibmPlexMono(
                                        fontSize: 12,
                                        color: isBranchActive ? c.ink : c.ink2,
                                        fontWeight: isBranchActive
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if ((branchPendingCounts[b] ?? 0) > 0)
                                    Text(
                                      '${branchPendingCounts[b]}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.ink3,
                                        fontFamily:
                                            GoogleFonts.ibmPlexMono().fontFamily,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ];
                  }).toList(),
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC2502F), Color(0xFF8E3C26)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'ai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.workdir,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: c.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${s.connected} · claude 1.0.34',
                        style: TextStyle(fontSize: 10.5, color: c.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.c,
    this.count,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors c;
  final int? count;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    Color bg;
    Color fg;
    if (widget.active) {
      bg = c.ink;
      fg = Colors.white;
    } else if (_hovered) {
      bg = c.ink.withValues(alpha: 0.04);
      fg = c.ink2;
    } else {
      bg = Colors.transparent;
      fg = c.ink2;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (widget.count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? Colors.white.withValues(alpha: 0.16)
                        : c.ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: widget.active ? Colors.white : c.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RunningTopBar extends StatelessWidget {
  const _RunningTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        backgroundColor: c.stRunningBg,
        valueColor: AlwaysStoppedAnimation<Color>(c.stRunning),
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
