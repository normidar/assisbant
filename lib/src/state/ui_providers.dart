import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterapptemp/src/providers/prefs_provider.dart';

enum AppTab { prompts, branches, logs, settings }

enum ModelMode { claude, local }

enum CliTool { claudeCode, aider }

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

/// アプリ設定を SharedPreferences に永続化する Notifier。
///
/// build() で SharedPreferences から初期値を読み込む。
/// sharedPreferencesProvider は normal_main.dart で ProviderScope.overrides に
/// 注入されるため、アプリ起動時に await して確実に初期化済みのインスタンスを渡す。
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
      envOverrides: _parseEnvOverrides(prefs.getString('envOverrides') ?? ''),
      cliTool: CliTool.values.firstWhere(
        (t) => t.name == (prefs.getString('cliTool') ?? ''),
        orElse: () => CliTool.claudeCode,
      ),
      aiderPath: prefs.getString('aiderPath') ?? '',
      remoteEnabled: prefs.getBool('remoteEnabled') ?? false,
      remotePort: prefs.getInt('remotePort') ?? 8765,
    );
  }

  /// state を即時更新してから SharedPreferences に書き込む。
  /// state を先に更新することで UI がちらつかない。
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
    await prefs.setString('envOverrides', jsonEncode(s.envOverrides));
    await prefs.setString('cliTool', s.cliTool.name);
    await prefs.setString('aiderPath', s.aiderPath);
    await prefs.setBool('remoteEnabled', s.remoteEnabled);
    await prefs.setInt('remotePort', s.remotePort);
  }

  static Map<String, String> _parseEnvOverrides(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return const {};
    }
  }
}

/// アプリ全体の設定値を保持するイミュータブルなデータクラス。
class AppSettings {
  const AppSettings({
    this.cliPath = '',
    this.workdir = '~/Code/assisbant',
    this.autoCheckout = true,
    this.pauseOnFail = false,
    this.commitAfterPrompt = true,
    this.modelMode = ModelMode.claude,
    this.localModelName = '',
    this.envOverrides = const {},
    this.cliTool = CliTool.claudeCode,
    this.aiderPath = '',
    this.remoteEnabled = false,
    this.remotePort = 8765,
  });

  final String cliPath; // claude CLI のパス。空の場合は PATH から検索
  final String workdir; // デフォルトの作業ディレクトリ（prompt.projectPath で上書き可能）
  final bool autoCheckout; // 実行前に git checkout を行うか
  final bool pauseOnFail; // プロンプト失敗時にキューを一時停止するか
  final bool commitAfterPrompt; // 成功後に自動で git commit するか（グローバル設定）
  final ModelMode modelMode; // claude モードか local モデルか（claudeCode 時のみ有効）
  final String localModelName; // local モード / Aider 時のモデル名
  // CLI 実行前に注入する環境変数。値が '__UNSET__' のキーは unset される。
  final Map<String, String> envOverrides;
  final CliTool cliTool; // 使用する AI ツール（Claude Code または Aider）
  final String aiderPath; // aider 実行ファイルのパス。空の場合は PATH から検索
  final bool remoteEnabled; // スマホからのリモート接続を受け付けるか
  final int remotePort; // WebSocket サーバーのポート番号

  AppSettings copyWith({
    String? cliPath,
    String? workdir,
    bool? autoCheckout,
    bool? pauseOnFail,
    bool? commitAfterPrompt,
    ModelMode? modelMode,
    String? localModelName,
    Map<String, String>? envOverrides,
    CliTool? cliTool,
    String? aiderPath,
    bool? remoteEnabled,
    int? remotePort,
  }) =>
      AppSettings(
        cliPath: cliPath ?? this.cliPath,
        workdir: workdir ?? this.workdir,
        autoCheckout: autoCheckout ?? this.autoCheckout,
        pauseOnFail: pauseOnFail ?? this.pauseOnFail,
        commitAfterPrompt: commitAfterPrompt ?? this.commitAfterPrompt,
        modelMode: modelMode ?? this.modelMode,
        localModelName: localModelName ?? this.localModelName,
        envOverrides: envOverrides ?? this.envOverrides,
        cliTool: cliTool ?? this.cliTool,
        aiderPath: aiderPath ?? this.aiderPath,
        remoteEnabled: remoteEnabled ?? this.remoteEnabled,
        remotePort: remotePort ?? this.remotePort,
      );
}
