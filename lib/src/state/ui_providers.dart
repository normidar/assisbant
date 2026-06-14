import 'dart:async';
import 'dart:convert';

import 'package:assibant/src/providers/prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 表示言語を SharedPreferences に永続化する Notifier。
/// 対応言語は en / zh / ja。未保存・未対応の値は en にフォールバックする。
class LangNotifier extends Notifier<String> {
  static const _prefsKey = 'appLang';
  static const _supported = {'en', 'zh', 'ja'};

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_prefsKey) ?? 'en';
    return _supported.contains(saved) ? saved : 'en';
  }

  void set(String lang) {
    if (!_supported.contains(lang) || lang == state) return;
    state = lang;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(_prefsKey, lang),
    );
  }

  void toggle() => set(state == 'en' ? 'zh' : 'en');
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

final branchFilterProvider = NotifierProvider<BranchFilterNotifier, String?>(
  BranchFilterNotifier.new,
);

class BranchFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? branch) => state = branch;
}

// ─── Project filter ───────────────────────────────────────────────────────────

final projectFilterProvider = NotifierProvider<ProjectFilterNotifier, String?>(
  ProjectFilterNotifier.new,
);

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

/// 新規プロンプト作成フォームの一時的な入力状態。
///
/// モーダルが閉じられた（キャンセル）際に [NewPromptDraftNotifier.save] で保存し、
/// 再度開いたときに復元することで入力内容を失わないようにする。
/// フォーム送信後は [NewPromptDraftNotifier.clear] でリセットする。
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

  NewPromptDraft copyWith({
    String? content,
    String? branch,
    String? projectPath,
    String? sessionId,
    String? priority,
    bool? isSkipped,
    bool? commitAfterAgent,
    String? claudeModel,
    List<String>? imagePaths,
  }) => NewPromptDraft(
    content: content ?? this.content,
    branch: branch ?? this.branch,
    projectPath: projectPath ?? this.projectPath,
    sessionId: sessionId ?? this.sessionId,
    priority: priority ?? this.priority,
    isSkipped: isSkipped ?? this.isSkipped,
    commitAfterAgent: commitAfterAgent ?? this.commitAfterAgent,
    claudeModel: claudeModel ?? this.claudeModel,
    imagePaths: imagePaths ?? this.imagePaths,
  );
}

class NewPromptDraftNotifier extends Notifier<NewPromptDraft> {
  @override
  NewPromptDraft build() => const NewPromptDraft();
  void save(NewPromptDraft draft) => state = draft;
  void clear() => state = const NewPromptDraft();
}

// ─── Settings ─────────────────────────────────────────────────────────────────

final settingsStateProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

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
      imageGenApiUrl:
          prefs.getString('imageGenApiUrl') ?? 'http://localhost:7860',
      imageGenModel: prefs.getString('imageGenModel') ?? '',
      sdLocalMode: prefs.getBool('sdLocalMode') ?? false,
      sdDylibPath: prefs.getString('sdDylibPath') ?? '',
      sdModelPath: prefs.getString('sdModelPath') ?? '',
      sdVaePath: prefs.getString('sdVaePath') ?? '',
      comfyuiEnabled: prefs.getBool('comfyuiEnabled') ?? false,
      comfyuiUrl: prefs.getString('comfyuiUrl') ?? 'http://127.0.0.1:8188',
      comfyuiUnetName:
          prefs.getString('comfyuiUnetName') ??
          'z_image_turbo_bf16.safetensors',
      comfyuiClipName:
          prefs.getString('comfyuiClipName') ?? 'qwen_3_4b.safetensors',
      comfyuiVaeName: prefs.getString('comfyuiVaeName') ?? 'ae.safetensors',
      mlxModelDir: prefs.getString('mlxModelDir') ?? '',
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
    await prefs.setString('imageGenApiUrl', s.imageGenApiUrl);
    await prefs.setString('imageGenModel', s.imageGenModel);
    await prefs.setBool('sdLocalMode', s.sdLocalMode);
    await prefs.setString('sdDylibPath', s.sdDylibPath);
    await prefs.setString('sdModelPath', s.sdModelPath);
    await prefs.setString('sdVaePath', s.sdVaePath);
    await prefs.setBool('comfyuiEnabled', s.comfyuiEnabled);
    await prefs.setString('comfyuiUrl', s.comfyuiUrl);
    await prefs.setString('comfyuiUnetName', s.comfyuiUnetName);
    await prefs.setString('comfyuiClipName', s.comfyuiClipName);
    await prefs.setString('comfyuiVaeName', s.comfyuiVaeName);
    await prefs.setString('mlxModelDir', s.mlxModelDir);
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
    this.imageGenApiUrl = 'http://localhost:7860',
    this.imageGenModel = '',
    this.sdLocalMode = false,
    this.sdDylibPath = '',
    this.sdModelPath = '',
    this.sdVaePath = '',
    this.comfyuiEnabled = false,
    this.comfyuiUrl = 'http://127.0.0.1:8188',
    this.comfyuiUnetName = 'z_image_turbo_bf16.safetensors',
    this.comfyuiClipName = 'qwen_3_4b.safetensors',
    this.comfyuiVaeName = 'ae.safetensors',
    this.mlxModelDir = '',
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
  final String imageGenApiUrl; // 画像生成 API のエンドポイント（Automatic1111）
  final String imageGenModel; // 選択された画像生成モデル名
  final bool sdLocalMode; // true = stable-diffusion.cpp dylib、false = Web API
  final String sdDylibPath; // libstable-diffusion.dylib のパス
  final String sdModelPath; // .safetensors モデルのパス
  final String sdVaePath; // VAE .safetensors のパス（省略可）
  final bool comfyuiEnabled; // true = ComfyUI API モード
  final String comfyuiUrl; // ComfyUI サーバー URL
  final String comfyuiUnetName; // UNet モデルファイル名
  final String comfyuiClipName; // CLIP テキストエンコーダーファイル名
  final String comfyuiVaeName; // VAE ファイル名
  final String mlxModelDir; // MLXモデルディレクトリのパス（safetensors + config）

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
    String? imageGenApiUrl,
    String? imageGenModel,
    bool? sdLocalMode,
    String? sdDylibPath,
    String? sdModelPath,
    String? sdVaePath,
    bool? comfyuiEnabled,
    String? comfyuiUrl,
    String? comfyuiUnetName,
    String? comfyuiClipName,
    String? comfyuiVaeName,
    String? mlxModelDir,
  }) => AppSettings(
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
    imageGenApiUrl: imageGenApiUrl ?? this.imageGenApiUrl,
    imageGenModel: imageGenModel ?? this.imageGenModel,
    sdLocalMode: sdLocalMode ?? this.sdLocalMode,
    sdDylibPath: sdDylibPath ?? this.sdDylibPath,
    sdModelPath: sdModelPath ?? this.sdModelPath,
    sdVaePath: sdVaePath ?? this.sdVaePath,
    comfyuiEnabled: comfyuiEnabled ?? this.comfyuiEnabled,
    comfyuiUrl: comfyuiUrl ?? this.comfyuiUrl,
    comfyuiUnetName: comfyuiUnetName ?? this.comfyuiUnetName,
    comfyuiClipName: comfyuiClipName ?? this.comfyuiClipName,
    comfyuiVaeName: comfyuiVaeName ?? this.comfyuiVaeName,
    mlxModelDir: mlxModelDir ?? this.mlxModelDir,
  );
}
