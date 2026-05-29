// Mirrors the EN/ZH string map from the prototype's data.jsx
class AppStrings {
  const AppStrings({
    required this.prompts,
    required this.branches,
    required this.settings,
    required this.logs,
    required this.newPrompt,
    required this.newShort,
    required this.search,
    required this.filterAll,
    required this.filterPending,
    required this.filterRunning,
    required this.filterDone,
    required this.filterFailed,
    required this.filterSkipped,
    required this.edit,
    required this.skip,
    required this.unskip,
    required this.delete,
    required this.cancel,
    required this.save,
    required this.create,
    required this.promptContent,
    required this.promptPlaceholder,
    required this.branch,
    required this.branchPlaceholder,
    required this.priority,
    required this.skipThis,
    required this.skipHint,
    required this.createPrompt,
    required this.editPrompt,
    required this.priorityHint,
    required this.start,
    required this.pause,
    required this.resume,
    required this.stop,
    required this.idle,
    required this.progress,
    required this.of,
    required this.nowRunning,
    required this.queueEmpty,
    required this.pending,
    required this.completed,
    required this.failed,
    required this.skipped,
    required this.statusPending,
    required this.statusRunning,
    required this.statusDone,
    required this.statusFailed,
    required this.statusSkipped,
    required this.noSelection,
    required this.noLogs,
    required this.detailContent,
    required this.detailMeta,
    required this.detailLogs,
    required this.confirmDelete,
    required this.deleted,
    required this.created,
    required this.saved,
    required this.skippedToast,
    required this.unskippedToast,
    required this.reordered,
    required this.runStarted,
    required this.runPaused,
    required this.runResumed,
    required this.runStopped,
    required this.branchEmpty,
    required this.cli,
    required this.cliDesc,
    required this.workdir,
    required this.workdirDesc,
    required this.autoCheckout,
    required this.autoCheckoutDesc,
    required this.pauseOnFail,
    required this.pauseOnFailDesc,
    required this.appearance,
    required this.language,
    required this.languageDesc,
    required this.theme,
    required this.themeDesc,
    required this.connected,
    required this.reorderHint,
    required this.branchesSection,
    required this.allBranches,
    required this.reset,
    required this.resetToast,
    required this.projectPath,
    required this.projectPathPlaceholder,
    required this.pickFolder,
    required this.projectsSection,
    required this.allProjects,
    required this.sessionId,
    required this.sessionIdPlaceholder,
    required this.sessionIdHint,
    required this.generateId,
    required this.commitAfterPrompt,
    required this.commitAfterPromptDesc,
    required this.closeWhileRunning,
    required this.closeWhileRunningMsg,
    required this.closeAnyway,
    required this.commitHistory,
    required this.tabPrompts,
    required this.noCommits,
    required this.batchCreate,
    required this.batchCreateTitle,
    required this.batchInputHint,
    required this.batchEmpty,
    required this.batchCreateBtn,
    required this.commitAfterAgent,
    required this.claudeQuestion,
    required this.typeYourAnswer,
    required this.submitAnswer,
    required this.modelMode,
    required this.modelModeDesc,
    required this.modelModeClaude,
    required this.modelModeLocal,
    required this.localModelName,
    required this.localModelNameDesc,
    required this.localModelNamePlaceholder,
    required this.claudeModelSelect,
    required this.claudeModelDefault,
    required this.schedule,
    required this.timerStartTitle,
    required this.timerModeTime,
    required this.timerModeCountdown,
    required this.timerSet,
    required this.dataManagement,
    required this.dataManagementDesc,
    required this.exportData,
    required this.exportDataDesc,
    required this.importData,
    required this.importDataDesc,
    required this.exportDialogTitle,
    required this.exportSelectProjects,
    required this.selectAll,
    required this.deselectAll,
    required this.exportBtn,
    required this.exportSuccess,
    required this.importBtn,
    required this.importFailed,
    required this.unassignedProject,
    required this.exportFormat,
    required this.attachImages,
    required this.noImages,
    required this.createAndStart,
    required this.envOverrides,
    required this.envOverridesDesc,
    required this.envOverridesTitle,
    required this.envOverridesDs4Btn,
    required this.envOverridesNone,
    required this.envOverridesClearAll,
    required this.envOverridesUnsetApiKey,
    required this.cliTool,
    required this.cliToolDesc,
    required this.cliToolClaudeCode,
    required this.cliToolAider,
    required this.aiderPath,
    required this.aiderPathDesc,
    required this.connectSettings,
    required this.connectSettingsDesc,
    required this.connectModeClaudeDesc,
    required this.connectModeLocalDesc,
    required this.connectModeAiderDesc,
    required this.optionalOverride,
    required this.toolFound,
    required this.toolNotFound,
    required this.duplicate,
    required this.duplicated,
    required this.promptTab,
    required this.imageGenTab,
    required this.imageGenPrompt,
    required this.imageGenPromptPlaceholder,
    required this.imageGenNegative,
    required this.imageGenNegativePlaceholder,
    required this.imageGenGenerate,
    required this.imageGenGenerating,
    required this.imageGenSave,
    required this.imageGenAttach,
    required this.imageGenIdle,
    required this.imageGenFailed,
    required this.imageGenSettings,
    required this.imageGenSettingsDesc,
    required this.imageGenApiUrl,
    required this.imageGenApiUrlDesc,
    required this.imageGenApiUrlPlaceholder,
    required this.imageGenModel,
    required this.imageGenModelDesc,
    required this.imageGenRefreshModels,
    required this.imageGenDownloadModels,
    required this.imageGenDownloadModelsDesc,
    required this.imageGenSize,
    required this.imageGenAddPrompt,
    required this.imageGenPresetModels,
  });

  final String prompts;
  final String branches;
  final String settings;
  final String logs;
  final String newPrompt;
  final String newShort;
  final String search;
  final String filterAll;
  final String filterPending;
  final String filterRunning;
  final String filterDone;
  final String filterFailed;
  final String filterSkipped;
  final String edit;
  final String skip;
  final String unskip;
  final String delete;
  final String cancel;
  final String save;
  final String create;
  final String promptContent;
  final String promptPlaceholder;
  final String branch;
  final String branchPlaceholder;
  final String priority;
  final String skipThis;
  final String skipHint;
  final String createPrompt;
  final String editPrompt;
  final String priorityHint;
  final String start;
  final String pause;
  final String resume;
  final String stop;
  final String idle;
  final String progress;
  final String of;
  final String nowRunning;
  final String queueEmpty;
  final String pending;
  final String completed;
  final String failed;
  final String skipped;
  final String statusPending;
  final String statusRunning;
  final String statusDone;
  final String statusFailed;
  final String statusSkipped;
  final String noSelection;
  final String noLogs;
  final String detailContent;
  final String detailMeta;
  final String detailLogs;
  final String confirmDelete;
  final String deleted;
  final String created;
  final String saved;
  final String skippedToast;
  final String unskippedToast;
  final String reordered;
  final String runStarted;
  final String runPaused;
  final String runResumed;
  final String runStopped;
  final String branchEmpty;
  final String cli;
  final String cliDesc;
  final String workdir;
  final String workdirDesc;
  final String autoCheckout;
  final String autoCheckoutDesc;
  final String pauseOnFail;
  final String pauseOnFailDesc;
  final String appearance;
  final String language;
  final String languageDesc;
  final String theme;
  final String themeDesc;
  final String connected;
  final String reorderHint;
  final String branchesSection;
  final String allBranches;
  final String reset;
  final String resetToast;
  final String projectPath;
  final String projectPathPlaceholder;
  final String pickFolder;
  final String projectsSection;
  final String allProjects;
  final String sessionId;
  final String sessionIdPlaceholder;
  final String sessionIdHint;
  final String generateId;
  final String commitAfterPrompt;
  final String commitAfterPromptDesc;
  final String closeWhileRunning;
  final String closeWhileRunningMsg;
  final String closeAnyway;
  final String commitHistory;
  final String tabPrompts;
  final String noCommits;
  final String batchCreate;
  final String batchCreateTitle;
  final String batchInputHint;
  final String batchEmpty;
  final String batchCreateBtn;
  final String commitAfterAgent;
  final String claudeQuestion;
  final String typeYourAnswer;
  final String submitAnswer;
  final String modelMode;
  final String modelModeDesc;
  final String modelModeClaude;
  final String modelModeLocal;
  final String localModelName;
  final String localModelNameDesc;
  final String localModelNamePlaceholder;
  final String claudeModelSelect;
  final String claudeModelDefault;
  final String schedule;
  final String timerStartTitle;
  final String timerModeTime;
  final String timerModeCountdown;
  final String timerSet;
  final String dataManagement;
  final String dataManagementDesc;
  final String exportData;
  final String exportDataDesc;
  final String importData;
  final String importDataDesc;
  final String exportDialogTitle;
  final String exportSelectProjects;
  final String selectAll;
  final String deselectAll;
  final String exportBtn;
  final String exportSuccess;
  final String importBtn;
  final String importFailed;
  final String unassignedProject;
  final String exportFormat;
  final String attachImages;
  final String noImages;
  final String createAndStart;
  final String envOverrides;
  final String envOverridesDesc;
  final String envOverridesTitle;
  final String envOverridesDs4Btn;
  final String envOverridesNone;
  final String envOverridesClearAll;
  final String envOverridesUnsetApiKey;
  final String cliTool;
  final String cliToolDesc;
  final String cliToolClaudeCode;
  final String cliToolAider;
  final String aiderPath;
  final String aiderPathDesc;
  final String connectSettings;
  final String connectSettingsDesc;
  final String connectModeClaudeDesc;
  final String connectModeLocalDesc;
  final String connectModeAiderDesc;
  final String optionalOverride;
  final String toolFound;
  final String toolNotFound;
  final String duplicate;
  final String duplicated;
  final String promptTab;
  final String imageGenTab;
  final String imageGenPrompt;
  final String imageGenPromptPlaceholder;
  final String imageGenNegative;
  final String imageGenNegativePlaceholder;
  final String imageGenGenerate;
  final String imageGenGenerating;
  final String imageGenSave;
  final String imageGenAttach;
  final String imageGenIdle;
  final String imageGenFailed;
  final String imageGenSettings;
  final String imageGenSettingsDesc;
  final String imageGenApiUrl;
  final String imageGenApiUrlDesc;
  final String imageGenApiUrlPlaceholder;
  final String imageGenModel;
  final String imageGenModelDesc;
  final String imageGenRefreshModels;
  final String imageGenDownloadModels;
  final String imageGenDownloadModelsDesc;
  final String imageGenSize;
  final String imageGenAddPrompt;
  final String imageGenPresetModels;

  String batchCreateCount(int n) {
    if (this == _zh) return '创建 $n 条 Prompt';
    if (this == _ja) return '$n 件のプロンプトを作成';
    return 'Create $n prompt${n == 1 ? '' : 's'}';
  }

  String imageGenGenerateAllCount(int n) {
    if (this == _zh) return '全部生成 ($n)';
    if (this == _ja) return 'すべて生成 ($n)';
    return 'Generate All ($n)';
  }

  String imageGenProgressOf(int current, int total) {
    if (this == _zh) return '生成中 $current/$total…';
    if (this == _ja) return '生成中 $current/$total…';
    return 'Generating $current/$total…';
  }

  String importSuccessCount(int n) {
    if (this == _zh) return '已导入 $n 条 Prompt';
    if (this == _ja) return '$n 件のプロンプトをインポートしました';
    return 'Imported $n prompt${n == 1 ? '' : 's'}';
  }

  String promptsCount(int n) {
    if (this == _zh) return '$n 条 prompt';
    if (this == _ja) return '$n 件のプロンプト';
    return '$n prompt${n == 1 ? '' : 's'}';
  }

  static AppStrings forLang(String lang) =>
      lang == 'zh' ? _zh : lang == 'ja' ? _ja : _en;

  static const _en = AppStrings(
    prompts: 'Prompts',
    branches: 'Branches',
    settings: 'Settings',
    logs: 'Execution Log',
    newPrompt: 'New Prompt',
    newShort: 'New',
    search: 'Search prompts…',
    filterAll: 'All',
    filterPending: 'Pending',
    filterRunning: 'Running',
    filterDone: 'Done',
    filterFailed: 'Failed',
    filterSkipped: 'Skipped',
    edit: 'Edit',
    skip: 'Skip',
    unskip: 'Unskip',
    delete: 'Delete',
    cancel: 'Cancel',
    save: 'Save',
    create: 'Create',
    promptContent: 'Prompt content',
    promptPlaceholder: 'Describe what Claude Code should do…',
    branch: 'Target branch',
    branchPlaceholder: 'feature/new-thing',
    priority: 'Priority',
    skipThis: 'Skip this prompt',
    skipHint: 'Skipped prompts are kept but excluded from execution.',
    createPrompt: 'Create prompt',
    editPrompt: 'Edit prompt',
    priorityHint: 'Lower number runs first.',
    start: 'Start',
    pause: 'Pause',
    resume: 'Resume',
    stop: 'Stop',
    idle: 'Idle',
    progress: 'Progress',
    of: 'of',
    nowRunning: 'Now running',
    queueEmpty: 'Queue is empty — create a prompt to begin.',
    pending: 'pending',
    completed: 'completed',
    failed: 'failed',
    skipped: 'skipped',
    statusPending: 'Pending',
    statusRunning: 'Running',
    statusDone: 'Done',
    statusFailed: 'Failed',
    statusSkipped: 'Skipped',
    noSelection: 'Select a prompt to see details.',
    noLogs: 'This prompt has not been run yet.',
    detailContent: 'Content',
    detailMeta: 'Details',
    detailLogs: 'Last run',
    confirmDelete: 'Delete this prompt? This cannot be undone.',
    deleted: 'Prompt deleted',
    created: 'Prompt created',
    saved: 'Changes saved',
    skippedToast: 'Marked as skipped',
    unskippedToast: 'Un-skipped',
    reordered: 'Reordered',
    runStarted: 'Execution started',
    runPaused: 'Execution paused',
    runResumed: 'Execution resumed',
    runStopped: 'Execution stopped',
    branchEmpty: 'No prompts on this branch yet.',
    cli: 'Claude CLI Path',
    cliDesc: 'Custom path to the claude executable. Leave empty to use PATH.',
    workdir: 'Working directory',
    workdirDesc: 'Git repository root where prompts are executed.',
    autoCheckout: 'Auto-checkout branch',
    autoCheckoutDesc: 'Run "git checkout <branch>" before each prompt.',
    pauseOnFail: 'Pause on failure',
    pauseOnFailDesc: 'Stop the queue when a prompt fails instead of continuing.',
    appearance: 'Appearance',
    language: 'Language',
    languageDesc: 'Interface language. Restart not required.',
    theme: 'Theme',
    themeDesc: 'Currently fixed to Light. Dark mode coming soon.',
    connected: 'connected',
    reorderHint: 'Use arrows to reorder. Lower position runs first.',
    branchesSection: 'Branches',
    allBranches: 'All branches',
    reset: 'Reset',
    resetToast: 'Reset to pending',
    projectPath: 'Project path',
    projectPathPlaceholder: '/path/to/project',
    pickFolder: 'Browse…',
    projectsSection: 'Projects',
    allProjects: 'All projects',
    sessionId: 'Session ID',
    sessionIdPlaceholder: 'e.g. feature-x',
    sessionIdHint:
        'Prompts sharing the same Session ID resume the same Claude conversation.',
    generateId: 'Generate',
    commitAfterPrompt: 'Commit after prompt',
    commitAfterPromptDesc: 'Stage all changes and commit with the prompt content as the message after each successful run.',
    closeWhileRunning: 'Execution in progress',
    closeWhileRunningMsg: 'A prompt is currently running. Close the window anyway?',
    closeAnyway: 'Close anyway',
    commitHistory: 'Commit History',
    tabPrompts: 'Prompts',
    noCommits: 'No commits found.',
    batchCreate: 'Batch Create',
    batchCreateTitle: 'Batch Create Prompts',
    batchInputHint: 'Type a prompt and press Enter, or paste multiple lines…',
    batchEmpty: 'No prompts added yet.',
    batchCreateBtn: 'Create All',
    commitAfterAgent: 'Commit after agent',
    claudeQuestion: 'Claude is asking a question',
    typeYourAnswer: 'Type your answer…',
    submitAnswer: 'Submit',
    modelMode: 'Model target',
    modelModeDesc: 'Choose between Anthropic Claude or a local model.',
    modelModeClaude: 'Claude',
    modelModeLocal: 'Local',
    localModelName: 'Local model name',
    localModelNameDesc: 'Model identifier passed via --model flag (e.g. ollama/llama3).',
    localModelNamePlaceholder: 'e.g. ollama/llama3',
    claudeModelSelect: 'Claude model',
    claudeModelDefault: 'Default',
    schedule: 'Schedule',
    timerStartTitle: 'Schedule Start',
    timerModeTime: 'Specific Time',
    timerModeCountdown: 'Countdown',
    timerSet: 'Set',
    dataManagement: 'Data Management',
    dataManagementDesc: 'Export and import prompt data as JSON files.',
    exportData: 'Export prompts',
    exportDataDesc: 'Save selected project prompts to a JSON file.',
    importData: 'Import prompts',
    importDataDesc: 'Load prompts from a previously exported JSON file.',
    exportDialogTitle: 'Export Prompts',
    exportSelectProjects: 'Select projects to export',
    selectAll: 'Select all',
    deselectAll: 'Deselect all',
    exportBtn: 'Export to file',
    exportSuccess: 'Exported successfully',
    importBtn: 'Import from file',
    importFailed: 'Import failed: invalid or unreadable file.',
    unassignedProject: '(Unassigned)',
    exportFormat: 'Export format',
    attachImages: 'Attach images',
    noImages: 'No images attached',
    createAndStart: 'Create & Start',
    envOverrides: 'Env Overrides',
    envOverridesDesc: 'Custom env vars injected before each CLI run.',
    envOverridesTitle: 'Environment Variables',
    envOverridesDs4Btn: 'Set DS4',
    envOverridesNone: 'None',
    envOverridesClearAll: 'Clear all',
    envOverridesUnsetApiKey: 'Unset ANTHROPIC_API_KEY',
    cliTool: 'AI Tool',
    cliToolDesc: 'Choose the AI coding tool used to run prompts.',
    cliToolClaudeCode: 'Claude Code',
    cliToolAider: 'Aider',
    aiderPath: 'Aider Path',
    aiderPathDesc: 'Custom path to the aider executable. Leave empty to use PATH.',
    connectSettings: 'Connect Settings',
    connectSettingsDesc: 'AI tool and model configuration',
    connectModeClaudeDesc: 'Use Anthropic Claude via the Claude Code CLI',
    connectModeLocalDesc: 'Use Claude Code with a local or custom model',
    connectModeAiderDesc: 'Use Aider with a local or custom model',
    optionalOverride: 'optional override',
    toolFound: 'Found',
    toolNotFound: 'Not found',
    duplicate: 'Duplicate',
    duplicated: 'Prompt duplicated',
    promptTab: 'Prompt',
    imageGenTab: 'Image Gen',
    imageGenPrompt: 'Image prompt',
    imageGenPromptPlaceholder: 'Describe the image to generate…',
    imageGenNegative: 'Negative prompt',
    imageGenNegativePlaceholder: 'What to exclude from the image…',
    imageGenGenerate: 'Generate',
    imageGenGenerating: 'Generating…',
    imageGenSave: 'Save image',
    imageGenAttach: 'Attach to prompt',
    imageGenIdle: 'Generated image will appear here.',
    imageGenFailed: 'Generation failed. Check the API URL in Settings.',
    imageGenSettings: 'Image Generation',
    imageGenSettingsDesc: 'Local Stable Diffusion API (Automatic1111 WebUI)',
    imageGenApiUrl: 'API URL',
    imageGenApiUrlDesc: 'Automatic1111 WebUI endpoint.',
    imageGenApiUrlPlaceholder: 'http://localhost:7860',
    imageGenModel: 'Model',
    imageGenModelDesc: 'Stable Diffusion model to use. Click Refresh to load available models.',
    imageGenRefreshModels: 'Refresh',
    imageGenDownloadModels: 'Download Models',
    imageGenDownloadModelsDesc: 'Open Civitai to browse and download SD models.',
    imageGenSize: 'Image size',
    imageGenAddPrompt: 'Add prompt',
    imageGenPresetModels: 'Popular models',
  );

  static const _zh = AppStrings(
    prompts: 'Prompt',
    branches: '分支',
    settings: '设置',
    logs: '执行日志',
    newPrompt: '新建 Prompt',
    newShort: '新建',
    search: '搜索 prompt…',
    filterAll: '全部',
    filterPending: '待执行',
    filterRunning: '执行中',
    filterDone: '已完成',
    filterFailed: '失败',
    filterSkipped: '已跳过',
    edit: '编辑',
    skip: '跳过',
    unskip: '取消跳过',
    delete: '删除',
    cancel: '取消',
    save: '保存',
    create: '创建',
    promptContent: 'Prompt 内容',
    promptPlaceholder: '描述需要 Claude Code 执行的任务…',
    branch: '目标分支',
    branchPlaceholder: 'feature/new-thing',
    priority: '优先级',
    skipThis: '跳过此 Prompt',
    skipHint: '已跳过的 prompt 会保留但不会被执行。',
    createPrompt: '创建 Prompt',
    editPrompt: '编辑 Prompt',
    priorityHint: '数值越小越先执行。',
    start: '开始执行',
    pause: '暂停',
    resume: '继续',
    stop: '停止',
    idle: '空闲',
    progress: '进度',
    of: '/',
    nowRunning: '当前执行',
    queueEmpty: '队列为空 — 创建一条 prompt 开始。',
    pending: '待执行',
    completed: '已完成',
    failed: '失败',
    skipped: '已跳过',
    statusPending: '待执行',
    statusRunning: '执行中',
    statusDone: '已完成',
    statusFailed: '失败',
    statusSkipped: '已跳过',
    noSelection: '选择一条 prompt 查看详情。',
    noLogs: '此 prompt 尚未执行过。',
    detailContent: '内容',
    detailMeta: '详情',
    detailLogs: '最近执行',
    confirmDelete: '删除此 prompt？操作不可撤销。',
    deleted: 'Prompt 已删除',
    created: 'Prompt 已创建',
    saved: '已保存',
    skippedToast: '已标记为跳过',
    unskippedToast: '已取消跳过',
    reordered: '已重新排序',
    runStarted: '执行已开始',
    runPaused: '已暂停',
    runResumed: '已继续',
    runStopped: '已停止',
    branchEmpty: '此分支暂无 prompt。',
    cli: 'Claude CLI 路径',
    cliDesc: '自定义 claude 可执行文件路径，留空则使用 PATH。',
    workdir: '工作目录',
    workdirDesc: '执行 prompt 的 git 仓库根目录。',
    autoCheckout: '自动切换分支',
    autoCheckoutDesc: '每条 prompt 执行前自动 git checkout 目标分支。',
    pauseOnFail: '失败时暂停',
    pauseOnFailDesc: 'prompt 失败时暂停队列，而不是继续执行。',
    appearance: '外观',
    language: '语言',
    languageDesc: '界面语言，无需重启。',
    theme: '主题',
    themeDesc: '当前固定浅色，深色模式即将推出。',
    connected: '已连接',
    reorderHint: '通过箭头调整顺序，靠前的优先执行。',
    branchesSection: '分支',
    allBranches: '全部分支',
    reset: '重置',
    resetToast: '已重置为待执行',
    projectPath: '项目路径',
    projectPathPlaceholder: '/path/to/project',
    pickFolder: '选择文件夹…',
    projectsSection: '项目',
    allProjects: '全部项目',
    sessionId: 'Session ID',
    sessionIdPlaceholder: '例：feature-x',
    sessionIdHint: '相同 Session ID 的 prompt 将在同一个 Claude 对话中依次执行。',
    generateId: '生成',
    commitAfterPrompt: '执行后提交',
    commitAfterPromptDesc: '每次成功执行后，暂存所有变更并以 prompt 内容作为提交信息进行提交。',
    closeWhileRunning: '正在执行',
    closeWhileRunningMsg: '当前有 prompt 正在运行，确定关闭窗口？',
    closeAnyway: '强制关闭',
    commitHistory: '提交历史',
    tabPrompts: '提示词',
    noCommits: '未找到提交记录。',
    batchCreate: '批量创建',
    batchCreateTitle: '批量创建 Prompt',
    batchInputHint: '输入提示词并按 Enter，或粘贴多行文本…',
    batchEmpty: '还未添加任何提示词。',
    batchCreateBtn: '全部创建',
    commitAfterAgent: 'Agent完成后提交',
    claudeQuestion: 'Claude 正在提问',
    typeYourAnswer: '输入你的回答…',
    submitAnswer: '提交',
    modelMode: '模型目标',
    modelModeDesc: '选择 Anthropic Claude 或本地模型。',
    modelModeClaude: 'Claude',
    modelModeLocal: '本地',
    localModelName: '本地模型名称',
    localModelNameDesc: '通过 --model 参数传递的模型标识符（如 ollama/llama3）。',
    localModelNamePlaceholder: '例：ollama/llama3',
    claudeModelSelect: 'Claude 模型',
    claudeModelDefault: '默认',
    schedule: '定时',
    timerStartTitle: '定时开始',
    timerModeTime: '指定时间',
    timerModeCountdown: '倒计时',
    timerSet: '设置',
    dataManagement: '数据管理',
    dataManagementDesc: '将 Prompt 数据导出或导入为 JSON 文件。',
    exportData: '导出 Prompt',
    exportDataDesc: '将所选项目的 Prompt 保存到 JSON 文件。',
    importData: '导入 Prompt',
    importDataDesc: '从之前导出的 JSON 文件加载 Prompt。',
    exportDialogTitle: '导出 Prompt',
    exportSelectProjects: '选择要导出的项目',
    selectAll: '全选',
    deselectAll: '取消全选',
    exportBtn: '导出到文件',
    exportSuccess: '导出成功',
    importBtn: '从文件导入',
    importFailed: '导入失败：文件无效或无法读取。',
    unassignedProject: '（未分配）',
    exportFormat: '导出格式',
    attachImages: '附加图片',
    noImages: '未附加图片',
    createAndStart: '创建并开始',
    envOverrides: '环境变量覆盖',
    envOverridesDesc: '每次 CLI 调用前注入的自定义环境变量。',
    envOverridesTitle: '环境变量',
    envOverridesDs4Btn: '设置 DS4',
    envOverridesNone: '未设置',
    envOverridesClearAll: '清除全部',
    envOverridesUnsetApiKey: '取消 ANTHROPIC_API_KEY',
    cliTool: 'AI 工具',
    cliToolDesc: '选择用于执行 Prompt 的 AI 编码工具。',
    cliToolClaudeCode: 'Claude Code',
    cliToolAider: 'Aider',
    aiderPath: 'Aider 路径',
    aiderPathDesc: '自定义 aider 可执行文件路径，留空则使用 PATH。',
    connectSettings: '连接设置',
    connectSettingsDesc: 'AI 工具和模型配置',
    connectModeClaudeDesc: '通过 Claude Code CLI 使用 Anthropic Claude',
    connectModeLocalDesc: '使用 Claude Code 配合本地或自定义模型',
    connectModeAiderDesc: '使用 Aider 配合本地或自定义模型',
    optionalOverride: '可选覆盖',
    toolFound: '已找到',
    toolNotFound: '未找到',
    duplicate: '复制',
    duplicated: 'Prompt 已复制',
    promptTab: '提示词',
    imageGenTab: '图像生成',
    imageGenPrompt: '图像描述',
    imageGenPromptPlaceholder: '描述要生成的图像…',
    imageGenNegative: '负面提示词',
    imageGenNegativePlaceholder: '图像中要排除的内容…',
    imageGenGenerate: '生成',
    imageGenGenerating: '生成中…',
    imageGenSave: '保存图片',
    imageGenAttach: '附加到提示词',
    imageGenIdle: '生成的图像将显示在这里。',
    imageGenFailed: '生成失败，请检查设置中的 API 地址。',
    imageGenSettings: '图像生成',
    imageGenSettingsDesc: '本地 Stable Diffusion API（Automatic1111 WebUI）',
    imageGenApiUrl: 'API 地址',
    imageGenApiUrlDesc: 'Automatic1111 WebUI 端点。',
    imageGenApiUrlPlaceholder: 'http://localhost:7860',
    imageGenModel: '模型',
    imageGenModelDesc: '要使用的 Stable Diffusion 模型。点击"刷新"加载可用模型。',
    imageGenRefreshModels: '刷新',
    imageGenDownloadModels: '下载模型',
    imageGenDownloadModelsDesc: '打开 Civitai 浏览并下载 SD 模型。',
    imageGenSize: '图像尺寸',
    imageGenAddPrompt: '添加提示词',
    imageGenPresetModels: '热门模型',
  );

  static const _ja = AppStrings(
    prompts: 'プロンプト',
    branches: 'ブランチ',
    settings: '設定',
    logs: '実行ログ',
    newPrompt: '新規プロンプト',
    newShort: '新規',
    search: 'プロンプトを検索…',
    filterAll: 'すべて',
    filterPending: '待機中',
    filterRunning: '実行中',
    filterDone: '完了',
    filterFailed: '失敗',
    filterSkipped: 'スキップ済',
    edit: '編集',
    skip: 'スキップ',
    unskip: 'スキップ解除',
    delete: '削除',
    cancel: 'キャンセル',
    save: '保存',
    create: '作成',
    promptContent: 'プロンプト内容',
    promptPlaceholder: 'Claude Code に実行させるタスクを記述…',
    branch: 'ターゲットブランチ',
    branchPlaceholder: 'feature/new-thing',
    priority: '優先度',
    skipThis: 'このプロンプトをスキップ',
    skipHint: 'スキップされたプロンプトは保持されますが実行されません。',
    createPrompt: 'プロンプトを作成',
    editPrompt: 'プロンプトを編集',
    priorityHint: '数値が小さいほど先に実行されます。',
    start: '開始',
    pause: '一時停止',
    resume: '再開',
    stop: '停止',
    idle: 'アイドル',
    progress: '進捗',
    of: '/',
    nowRunning: '実行中',
    queueEmpty: 'キューが空です — プロンプトを作成してください。',
    pending: '待機中',
    completed: '完了',
    failed: '失敗',
    skipped: 'スキップ済',
    statusPending: '待機中',
    statusRunning: '実行中',
    statusDone: '完了',
    statusFailed: '失敗',
    statusSkipped: 'スキップ済',
    noSelection: 'プロンプトを選択して詳細を表示。',
    noLogs: 'このプロンプトはまだ実行されていません。',
    detailContent: '内容',
    detailMeta: '詳細',
    detailLogs: '最終実行',
    confirmDelete: 'このプロンプトを削除しますか？この操作は取り消せません。',
    deleted: 'プロンプトを削除しました',
    created: 'プロンプトを作成しました',
    saved: '変更を保存しました',
    skippedToast: 'スキップ済みにしました',
    unskippedToast: 'スキップを解除しました',
    reordered: '並び替えました',
    runStarted: '実行を開始しました',
    runPaused: '一時停止しました',
    runResumed: '再開しました',
    runStopped: '停止しました',
    branchEmpty: 'このブランチにはまだプロンプトがありません。',
    cli: 'Claude CLI パス',
    cliDesc: 'claude 実行ファイルのカスタムパス。空欄の場合は PATH を使用します。',
    workdir: '作業ディレクトリ',
    workdirDesc: 'プロンプトを実行する git リポジトリのルートディレクトリ。',
    autoCheckout: '自動ブランチ切り替え',
    autoCheckoutDesc: '各プロンプト実行前に git checkout を自動実行します。',
    pauseOnFail: '失敗時に一時停止',
    pauseOnFailDesc: 'プロンプトが失敗したとき、続行せずにキューを停止します。',
    appearance: '外観',
    language: '言語',
    languageDesc: 'インターフェース言語。再起動不要。',
    theme: 'テーマ',
    themeDesc: '現在はライトモード固定です。ダークモードは近日公開予定。',
    connected: '接続済み',
    reorderHint: '矢印で並び替え。上にあるものが先に実行されます。',
    branchesSection: 'ブランチ',
    allBranches: 'すべてのブランチ',
    reset: 'リセット',
    resetToast: '待機中にリセットしました',
    projectPath: 'プロジェクトパス',
    projectPathPlaceholder: '/path/to/project',
    pickFolder: '参照…',
    projectsSection: 'プロジェクト',
    allProjects: 'すべてのプロジェクト',
    sessionId: 'Session ID',
    sessionIdPlaceholder: '例：feature-x',
    sessionIdHint: '同じ Session ID のプロンプトは同一の Claude セッションで続けて実行されます。',
    generateId: '生成',
    commitAfterPrompt: '実行後にコミット',
    commitAfterPromptDesc: '成功した実行ごとに、すべての変更をステージングしてプロンプト内容をメッセージとしてコミットします。',
    closeWhileRunning: '実行中',
    closeWhileRunningMsg: '現在プロンプトが実行中です。ウィンドウを閉じてもよいですか？',
    closeAnyway: '閉じる',
    commitHistory: 'コミット履歴',
    tabPrompts: 'プロンプト',
    noCommits: 'コミットが見つかりません。',
    batchCreate: 'バッチで作成',
    batchCreateTitle: 'プロンプトを一括作成',
    batchInputHint: 'プロンプトを入力してEnterキーを押すか、複数行を貼り付け…',
    batchEmpty: 'プロンプトがまだ追加されていません。',
    batchCreateBtn: 'すべて作成',
    commitAfterAgent: 'エージェント完了後にコミット',
    claudeQuestion: 'Claude から質問があります',
    typeYourAnswer: '回答を入力…',
    submitAnswer: '送信',
    modelMode: 'モデル設定',
    modelModeDesc: 'Anthropic Claude またはローカルモデルを選択します。',
    modelModeClaude: 'Claude',
    modelModeLocal: 'ローカル',
    localModelName: 'ローカルモデル名',
    localModelNameDesc: '--model フラグで渡すモデル識別子（例：ollama/llama3）。',
    localModelNamePlaceholder: '例：ollama/llama3',
    claudeModelSelect: 'Claude モデル',
    claudeModelDefault: 'デフォルト',
    schedule: 'スケジュール',
    timerStartTitle: '開始時刻の設定',
    timerModeTime: '時刻指定',
    timerModeCountdown: 'カウントダウン',
    timerSet: '設定',
    dataManagement: 'データ管理',
    dataManagementDesc: 'プロンプトデータを JSON ファイルとしてエクスポート・インポートします。',
    exportData: 'プロンプトをエクスポート',
    exportDataDesc: '選択したプロジェクトのプロンプトを JSON ファイルに保存します。',
    importData: 'プロンプトをインポート',
    importDataDesc: '以前エクスポートした JSON ファイルからプロンプトを読み込みます。',
    exportDialogTitle: 'プロンプトをエクスポート',
    exportSelectProjects: 'エクスポートするプロジェクトを選択',
    selectAll: 'すべて選択',
    deselectAll: 'すべて解除',
    exportBtn: 'ファイルに保存',
    exportSuccess: 'エクスポートしました',
    importBtn: 'ファイルから読み込む',
    importFailed: 'インポートに失敗しました：ファイルが無効または読み込めません。',
    unassignedProject: '（未割り当て）',
    exportFormat: 'エクスポート形式',
    attachImages: '画像を添付',
    noImages: '画像なし',
    createAndStart: '作成して開始',
    envOverrides: '環境変数のオーバーライド',
    envOverridesDesc: 'CLI 実行前に注入するカスタム環境変数。',
    envOverridesTitle: '環境変数',
    envOverridesDs4Btn: 'DS4 を設定',
    envOverridesNone: '未設定',
    envOverridesClearAll: 'すべてクリア',
    envOverridesUnsetApiKey: 'ANTHROPIC_API_KEY を削除',
    cliTool: 'AI ツール',
    cliToolDesc: 'プロンプトを実行する AI コーディングツールを選択します。',
    cliToolClaudeCode: 'Claude Code',
    cliToolAider: 'Aider',
    aiderPath: 'Aider パス',
    aiderPathDesc: 'aider 実行ファイルのカスタムパス。空欄の場合は PATH を使用します。',
    connectSettings: '接続設定',
    connectSettingsDesc: 'AI ツールとモデルの設定',
    connectModeClaudeDesc: 'Claude Code CLI 経由で Anthropic Claude を使用',
    connectModeLocalDesc: 'Claude Code でローカルモデルを使用',
    connectModeAiderDesc: 'Aider でローカルモデルを使用',
    optionalOverride: '任意のカスタムパス',
    toolFound: '検出済み',
    toolNotFound: '未検出',
    duplicate: '複製',
    duplicated: 'プロンプトを複製しました',
    promptTab: 'プロンプト',
    imageGenTab: '画像生成',
    imageGenPrompt: '画像プロンプト',
    imageGenPromptPlaceholder: '生成する画像を説明してください…',
    imageGenNegative: 'ネガティブプロンプト',
    imageGenNegativePlaceholder: '画像から除外する要素…',
    imageGenGenerate: '生成',
    imageGenGenerating: '生成中…',
    imageGenSave: '画像を保存',
    imageGenAttach: 'プロンプトに添付',
    imageGenIdle: '生成された画像がここに表示されます。',
    imageGenFailed: '生成に失敗しました。設定の API URL を確認してください。',
    imageGenSettings: '画像生成',
    imageGenSettingsDesc: 'ローカル Stable Diffusion API（Automatic1111 WebUI）',
    imageGenApiUrl: 'API URL',
    imageGenApiUrlDesc: 'Automatic1111 WebUI のエンドポイント。',
    imageGenApiUrlPlaceholder: 'http://localhost:7860',
    imageGenModel: 'モデル',
    imageGenModelDesc: '使用する Stable Diffusion モデル。「更新」をクリックして利用可能なモデルを読み込みます。',
    imageGenRefreshModels: '更新',
    imageGenDownloadModels: 'モデルをダウンロード',
    imageGenDownloadModelsDesc: 'Civitai を開いて SD モデルを検索・ダウンロードします。',
    imageGenSize: '画像サイズ',
    imageGenAddPrompt: 'プロンプトを追加',
    imageGenPresetModels: '人気モデル',
  );
}
