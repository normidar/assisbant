import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/providers/prefs_provider.dart';

enum AppTab { prompts, branches, logs, settings }

enum ModelMode { claude, local }

// ─── Tab ─────────────────────────────────────────────────────────────────────

final currentTabProvider = NotifierProvider<CurrentTabNotifier, AppTab>(
  CurrentTabNotifier.new,
);

class CurrentTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.prompts;
  void set(AppTab tab) => state = tab;
}

// ─── Language ─────────────────────────────────────────────────────────────────

final langNotifierProvider = NotifierProvider<LangNotifier, String>(
  LangNotifier.new,
);

class LangNotifier extends Notifier<String> {
  @override
  String build() => 'en';
  void set(String lang) => state = lang;
  void toggle() => state = state == 'en' ? 'zh' : 'en';
}

// ─── Filter ───────────────────────────────────────────────────────────────────

final filterNotifierProvider = NotifierProvider<FilterNotifier, String>(
  FilterNotifier.new,
);

class FilterNotifier extends Notifier<String> {
  @override
  String build() => 'pending';
  void set(String filter) => state = filter;
}

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

// ─── Selected prompt ─────────────────────────────────────────────────────────

final selectedPromptIdProvider =
    NotifierProvider<SelectedPromptIdNotifier, String?>(
  SelectedPromptIdNotifier.new,
);

class SelectedPromptIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
  void toggle(String id) => state = state == id ? null : id;
}

// ─── Branch filter ────────────────────────────────────────────────────────────

final branchFilterProvider =
    NotifierProvider<BranchFilterNotifier, String?>(BranchFilterNotifier.new);

class BranchFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? branch) => state = branch;
}

// ─── Project filter ───────────────────────────────────────────────────────────

final projectFilterProvider =
    NotifierProvider<ProjectFilterNotifier, String?>(ProjectFilterNotifier.new);

class ProjectFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? path) => state = path;
}

// ─── New prompt draft ─────────────────────────────────────────────────────────

final newPromptDraftProvider =
    NotifierProvider<NewPromptDraftNotifier, NewPromptDraft>(
  NewPromptDraftNotifier.new,
);

class NewPromptDraft {
  const NewPromptDraft({
    this.content = '',
    this.branch = '',
    this.projectPath = '',
    this.sessionId = '',
    this.priority = '',
    this.isSkipped = false,
    this.commitAfterAgent = true,
    this.claudeModel = '',
    this.imagePaths = const [],
  });

  final String content;
  final String branch;
  final String projectPath;
  final String sessionId;
  final String priority;
  final bool isSkipped;
  final bool commitAfterAgent;
  final String claudeModel;
  final List<String> imagePaths;

  bool get isEmpty =>
      content.isEmpty &&
      branch.isEmpty &&
      projectPath.isEmpty &&
      sessionId.isEmpty;
}

class NewPromptDraftNotifier extends Notifier<NewPromptDraft> {
  @override
  NewPromptDraft build() => const NewPromptDraft();
  void save(NewPromptDraft draft) => state = draft;
  void clear() => state = const NewPromptDraft();
}

// ─── Settings ─────────────────────────────────────────────────────────────────

final settingsStateProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      cliPath: prefs.getString('cliPath') ?? '',
      workdir: prefs.getString('workdir') ?? '~/Code/assisbant',
      autoCheckout: prefs.getBool('autoCheckout') ?? true,
      pauseOnFail: prefs.getBool('pauseOnFail') ?? false,
      commitAfterPrompt: prefs.getBool('commitAfterPrompt') ?? true,
      modelMode: ModelMode.values.firstWhere(
        (m) => m.name == (prefs.getString('modelMode') ?? ''),
        orElse: () => ModelMode.claude,
      ),
      localModelName: prefs.getString('localModelName') ?? '',
    );
  }

  Future<void> update(AppSettings s) async {
    state = s;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('cliPath', s.cliPath);
    await prefs.setString('workdir', s.workdir);
    await prefs.setBool('autoCheckout', s.autoCheckout);
    await prefs.setBool('pauseOnFail', s.pauseOnFail);
    await prefs.setBool('commitAfterPrompt', s.commitAfterPrompt);
    await prefs.setString('modelMode', s.modelMode.name);
    await prefs.setString('localModelName', s.localModelName);
  }
}

class AppSettings {
  const AppSettings({
    this.cliPath = '',
    this.workdir = '~/Code/assisbant',
    this.autoCheckout = true,
    this.pauseOnFail = false,
    this.commitAfterPrompt = true,
    this.modelMode = ModelMode.claude,
    this.localModelName = '',
  });

  final String cliPath;
  final String workdir;
  final bool autoCheckout;
  final bool pauseOnFail;
  final bool commitAfterPrompt;
  final ModelMode modelMode;
  final String localModelName;

  AppSettings copyWith({
    String? cliPath,
    String? workdir,
    bool? autoCheckout,
    bool? pauseOnFail,
    bool? commitAfterPrompt,
    ModelMode? modelMode,
    String? localModelName,
  }) =>
      AppSettings(
        cliPath: cliPath ?? this.cliPath,
        workdir: workdir ?? this.workdir,
        autoCheckout: autoCheckout ?? this.autoCheckout,
        pauseOnFail: pauseOnFail ?? this.pauseOnFail,
        commitAfterPrompt: commitAfterPrompt ?? this.commitAfterPrompt,
        modelMode: modelMode ?? this.modelMode,
        localModelName: localModelName ?? this.localModelName,
      );
}
