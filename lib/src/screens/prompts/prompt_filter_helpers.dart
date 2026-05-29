import 'package:assibant/src/data/database/app_database.dart';

/// Returns (branches sorted by most-recently-updated, project paths sorted
/// by most-recently-updated, max priority across all prompts).
(List<String>, List<String>, int) computePromptMetadata(
    List<PromptEntry> allPrompts) {
  final branchTimes = <String, DateTime>{};
  for (final p in allPrompts) {
    final t = branchTimes[p.branch];
    if (t == null || p.updatedAt.isAfter(t)) branchTimes[p.branch] = p.updatedAt;
  }
  final branches = branchTimes.keys.toList()
    ..sort((a, b) => branchTimes[b]!.compareTo(branchTimes[a]!));

  final pathTimes = <String, DateTime>{};
  for (final p in allPrompts) {
    if (p.projectPath.isEmpty) continue;
    final t = pathTimes[p.projectPath];
    if (t == null || p.updatedAt.isAfter(t))
      pathTimes[p.projectPath] = p.updatedAt;
  }
  final projectPaths = pathTimes.keys.toList()
    ..sort((a, b) => pathTimes[b]!.compareTo(pathTimes[a]!));

  final maxPriority = allPrompts.isEmpty
      ? 0
      : allPrompts.map((p) => p.priority).reduce((a, b) => a > b ? a : b);

  return (branches, projectPaths, maxPriority);
}

/// Narrows [src] to prompts that match the optional [projectFilter] and
/// [branchFilter]. Null filters are treated as "no restriction".
List<PromptEntry> applyProjectAndBranchFilter(
    List<PromptEntry> src, String? projectFilter, String? branchFilter) {
  var list = src;
  if (projectFilter != null)
    list = list.where((p) => p.projectPath == projectFilter).toList();
  if (branchFilter != null)
    list = list.where((p) => p.branch == branchFilter).toList();
  return list;
}

/// Applies project/branch filters, search [query], and status [filter]
/// to [src], then sorts the result by priority descending.
List<PromptEntry> applyPromptFilters(
    List<PromptEntry> src,
    String? projectFilter,
    String? branchFilter,
    String query,
    String filter) {
  var list = applyProjectAndBranchFilter(src, projectFilter, branchFilter);
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    list = list
        .where((p) =>
            p.content.toLowerCase().contains(q) ||
            p.branch.toLowerCase().contains(q))
        .toList();
  }
  if (filter == 'skipped') {
    list = list.where((p) => p.isSkipped).toList();
  } else if (filter != 'all') {
    list = list
        .where((p) => !p.isSkipped && p.status.name == filter)
        .toList();
  }
  list.sort((a, b) => b.priority.compareTo(a.priority));
  return list;
}

/// Counts prompts per status category for the filter-chip display.
Map<String, int> computePromptCounts(List<PromptEntry> src) {
  final counts = <String, int>{
    'all': 0,
    'pending': 0,
    'running': 0,
    'done': 0,
    'failed': 0,
    'skipped': 0,
  };
  for (final p in src) {
    counts['all'] = counts['all']! + 1;
    if (p.isSkipped) {
      counts['skipped'] = counts['skipped']! + 1;
    } else {
      counts[p.status.name] = (counts[p.status.name] ?? 0) + 1;
    }
  }
  return counts;
}
