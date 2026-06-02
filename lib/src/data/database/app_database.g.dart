// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PromptsTable extends Prompts with TableInfo<$PromptsTable, PromptEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PromptStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<PromptStatus>($PromptsTable.$converterstatus);
  static const VerificationMeta _isSkippedMeta = const VerificationMeta(
    'isSkipped',
  );
  @override
  late final GeneratedColumn<bool> isSkipped = GeneratedColumn<bool>(
    'is_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _outputMeta = const VerificationMeta('output');
  @override
  late final GeneratedColumn<String> output = GeneratedColumn<String>(
    'output',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectPathMeta = const VerificationMeta(
    'projectPath',
  );
  @override
  late final GeneratedColumn<String> projectPath = GeneratedColumn<String>(
    'project_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _claudeSessionIdMeta = const VerificationMeta(
    'claudeSessionId',
  );
  @override
  late final GeneratedColumn<String> claudeSessionId = GeneratedColumn<String>(
    'claude_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _claudeModelMeta = const VerificationMeta(
    'claudeModel',
  );
  @override
  late final GeneratedColumn<String> claudeModel = GeneratedColumn<String>(
    'claude_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _commitAfterRunMeta = const VerificationMeta(
    'commitAfterRun',
  );
  @override
  late final GeneratedColumn<bool> commitAfterRun = GeneratedColumn<bool>(
    'commit_after_run',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("commit_after_run" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    branch,
    priority,
    status,
    isSkipped,
    output,
    projectPath,
    sessionId,
    claudeSessionId,
    claudeModel,
    imagePaths,
    commitAfterRun,
    startedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PromptEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    } else if (isInserting) {
      context.missing(_branchMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_skipped')) {
      context.handle(
        _isSkippedMeta,
        isSkipped.isAcceptableOrUnknown(data['is_skipped']!, _isSkippedMeta),
      );
    }
    if (data.containsKey('output')) {
      context.handle(
        _outputMeta,
        output.isAcceptableOrUnknown(data['output']!, _outputMeta),
      );
    }
    if (data.containsKey('project_path')) {
      context.handle(
        _projectPathMeta,
        projectPath.isAcceptableOrUnknown(
          data['project_path']!,
          _projectPathMeta,
        ),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('claude_session_id')) {
      context.handle(
        _claudeSessionIdMeta,
        claudeSessionId.isAcceptableOrUnknown(
          data['claude_session_id']!,
          _claudeSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('claude_model')) {
      context.handle(
        _claudeModelMeta,
        claudeModel.isAcceptableOrUnknown(
          data['claude_model']!,
          _claudeModelMeta,
        ),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('commit_after_run')) {
      context.handle(
        _commitAfterRunMeta,
        commitAfterRun.isAcceptableOrUnknown(
          data['commit_after_run']!,
          _commitAfterRunMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PromptEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PromptEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      status: $PromptsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      isSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_skipped'],
      )!,
      output: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output'],
      ),
      projectPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_path'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      claudeSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claude_session_id'],
      )!,
      claudeModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claude_model'],
      )!,
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      )!,
      commitAfterRun: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}commit_after_run'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PromptsTable createAlias(String alias) {
    return $PromptsTable(attachedDatabase, alias);
  }

  static TypeConverter<PromptStatus, String> $converterstatus =
      const PromptStatusConverter();
}

class $ImageGenRecordsTable extends ImageGenRecords
    with TableInfo<$ImageGenRecordsTable, ImageGenRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageGenRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _negativePromptMeta = const VerificationMeta(
    'negativePrompt',
  );
  @override
  late final GeneratedColumn<String> negativePrompt = GeneratedColumn<String>(
    'negative_prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(512),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(512),
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _generationTimeMsMeta = const VerificationMeta(
    'generationTimeMs',
  );
  @override
  late final GeneratedColumn<int> generationTimeMs = GeneratedColumn<int>(
    'generation_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('success'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iterationMeta = const VerificationMeta(
    'iteration',
  );
  @override
  late final GeneratedColumn<int> iteration = GeneratedColumn<int>(
    'iteration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prompt,
    negativePrompt,
    model,
    width,
    height,
    seed,
    steps,
    generationTimeMs,
    startedAt,
    finishedAt,
    imagePath,
    status,
    errorMessage,
    iteration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_gen_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageGenRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('negative_prompt')) {
      context.handle(
        _negativePromptMeta,
        negativePrompt.isAcceptableOrUnknown(
          data['negative_prompt']!,
          _negativePromptMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('generation_time_ms')) {
      context.handle(
        _generationTimeMsMeta,
        generationTimeMs.isAcceptableOrUnknown(
          data['generation_time_ms']!,
          _generationTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('iteration')) {
      context.handle(
        _iterationMeta,
        iteration.isAcceptableOrUnknown(data['iteration']!, _iterationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageGenRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageGenRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      negativePrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}negative_prompt'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      ),
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      generationTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generation_time_ms'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      iteration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iteration'],
      )!,
    );
  }

  @override
  $ImageGenRecordsTable createAlias(String alias) {
    return $ImageGenRecordsTable(attachedDatabase, alias);
  }
}

class PromptEntry extends DataClass implements Insertable<PromptEntry> {
  final String id;
  final String content;
  final String branch;
  final int priority;
  final PromptStatus status;
  final bool isSkipped;
  final String? output;
  final String projectPath;
  final String sessionId;
  final String claudeSessionId;
  final String claudeModel;
  final String imagePaths;
  final bool commitAfterRun;
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PromptEntry({
    required this.id,
    required this.content,
    required this.branch,
    required this.priority,
    required this.status,
    required this.isSkipped,
    this.output,
    required this.projectPath,
    required this.sessionId,
    required this.claudeSessionId,
    required this.claudeModel,
    required this.imagePaths,
    required this.commitAfterRun,
    this.startedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['branch'] = Variable<String>(branch);
    map['priority'] = Variable<int>(priority);
    {
      map['status'] = Variable<String>(
        $PromptsTable.$converterstatus.toSql(status),
      );
    }
    map['is_skipped'] = Variable<bool>(isSkipped);
    if (!nullToAbsent || output != null) {
      map['output'] = Variable<String>(output);
    }
    map['project_path'] = Variable<String>(projectPath);
    map['session_id'] = Variable<String>(sessionId);
    map['claude_session_id'] = Variable<String>(claudeSessionId);
    map['claude_model'] = Variable<String>(claudeModel);
    map['image_paths'] = Variable<String>(imagePaths);
    map['commit_after_run'] = Variable<bool>(commitAfterRun);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PromptsCompanion toCompanion(bool nullToAbsent) {
    return PromptsCompanion(
      id: Value(id),
      content: Value(content),
      branch: Value(branch),
      priority: Value(priority),
      status: Value(status),
      isSkipped: Value(isSkipped),
      output: output == null && nullToAbsent
          ? const Value.absent()
          : Value(output),
      projectPath: Value(projectPath),
      sessionId: Value(sessionId),
      claudeSessionId: Value(claudeSessionId),
      claudeModel: Value(claudeModel),
      imagePaths: Value(imagePaths),
      commitAfterRun: Value(commitAfterRun),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PromptEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PromptEntry(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      branch: serializer.fromJson<String>(json['branch']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<PromptStatus>(json['status']),
      isSkipped: serializer.fromJson<bool>(json['isSkipped']),
      output: serializer.fromJson<String?>(json['output']),
      projectPath: serializer.fromJson<String>(json['projectPath']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      claudeSessionId: serializer.fromJson<String>(json['claudeSessionId']),
      claudeModel: serializer.fromJson<String>(json['claudeModel']),
      imagePaths: serializer.fromJson<String>(json['imagePaths']),
      commitAfterRun: serializer.fromJson<bool>(json['commitAfterRun']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'branch': serializer.toJson<String>(branch),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<PromptStatus>(status),
      'isSkipped': serializer.toJson<bool>(isSkipped),
      'output': serializer.toJson<String?>(output),
      'projectPath': serializer.toJson<String>(projectPath),
      'sessionId': serializer.toJson<String>(sessionId),
      'claudeSessionId': serializer.toJson<String>(claudeSessionId),
      'claudeModel': serializer.toJson<String>(claudeModel),
      'imagePaths': serializer.toJson<String>(imagePaths),
      'commitAfterRun': serializer.toJson<bool>(commitAfterRun),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PromptEntry copyWith({
    String? id,
    String? content,
    String? branch,
    int? priority,
    PromptStatus? status,
    bool? isSkipped,
    Value<String?> output = const Value.absent(),
    String? projectPath,
    String? sessionId,
    String? claudeSessionId,
    String? claudeModel,
    String? imagePaths,
    bool? commitAfterRun,
    Value<DateTime?> startedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PromptEntry(
    id: id ?? this.id,
    content: content ?? this.content,
    branch: branch ?? this.branch,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    isSkipped: isSkipped ?? this.isSkipped,
    output: output.present ? output.value : this.output,
    projectPath: projectPath ?? this.projectPath,
    sessionId: sessionId ?? this.sessionId,
    claudeSessionId: claudeSessionId ?? this.claudeSessionId,
    claudeModel: claudeModel ?? this.claudeModel,
    imagePaths: imagePaths ?? this.imagePaths,
    commitAfterRun: commitAfterRun ?? this.commitAfterRun,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PromptEntry copyWithCompanion(PromptsCompanion data) {
    return PromptEntry(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      branch: data.branch.present ? data.branch.value : this.branch,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      isSkipped: data.isSkipped.present ? data.isSkipped.value : this.isSkipped,
      output: data.output.present ? data.output.value : this.output,
      projectPath: data.projectPath.present
          ? data.projectPath.value
          : this.projectPath,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      claudeSessionId: data.claudeSessionId.present
          ? data.claudeSessionId.value
          : this.claudeSessionId,
      claudeModel: data.claudeModel.present
          ? data.claudeModel.value
          : this.claudeModel,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      commitAfterRun: data.commitAfterRun.present
          ? data.commitAfterRun.value
          : this.commitAfterRun,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PromptEntry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('branch: $branch, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('output: $output, ')
          ..write('projectPath: $projectPath, ')
          ..write('sessionId: $sessionId, ')
          ..write('claudeSessionId: $claudeSessionId, ')
          ..write('claudeModel: $claudeModel, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('commitAfterRun: $commitAfterRun, ')
          ..write('startedAt: $startedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    branch,
    priority,
    status,
    isSkipped,
    output,
    projectPath,
    sessionId,
    claudeSessionId,
    claudeModel,
    imagePaths,
    commitAfterRun,
    startedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PromptEntry &&
          other.id == this.id &&
          other.content == this.content &&
          other.branch == this.branch &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.isSkipped == this.isSkipped &&
          other.output == this.output &&
          other.projectPath == this.projectPath &&
          other.sessionId == this.sessionId &&
          other.claudeSessionId == this.claudeSessionId &&
          other.claudeModel == this.claudeModel &&
          other.imagePaths == this.imagePaths &&
          other.commitAfterRun == this.commitAfterRun &&
          other.startedAt == this.startedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ImageGenRecord extends DataClass implements Insertable<ImageGenRecord> {
  final String id;
  final String prompt;
  final String negativePrompt;
  final String model;
  final int width;
  final int height;
  final int? seed;
  final int steps;
  final int generationTimeMs;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String? imagePath;
  final String status;
  final String? errorMessage;
  final int iteration;
  const ImageGenRecord({
    required this.id,
    required this.prompt,
    required this.negativePrompt,
    required this.model,
    required this.width,
    required this.height,
    this.seed,
    required this.steps,
    required this.generationTimeMs,
    required this.startedAt,
    required this.finishedAt,
    this.imagePath,
    required this.status,
    this.errorMessage,
    required this.iteration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['prompt'] = Variable<String>(prompt);
    map['negative_prompt'] = Variable<String>(negativePrompt);
    map['model'] = Variable<String>(model);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || seed != null) {
      map['seed'] = Variable<int>(seed);
    }
    map['steps'] = Variable<int>(steps);
    map['generation_time_ms'] = Variable<int>(generationTimeMs);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['iteration'] = Variable<int>(iteration);
    return map;
  }

  ImageGenRecordsCompanion toCompanion(bool nullToAbsent) {
    return ImageGenRecordsCompanion(
      id: Value(id),
      prompt: Value(prompt),
      negativePrompt: Value(negativePrompt),
      model: Value(model),
      width: Value(width),
      height: Value(height),
      seed: seed == null && nullToAbsent ? const Value.absent() : Value(seed),
      steps: Value(steps),
      generationTimeMs: Value(generationTimeMs),
      startedAt: Value(startedAt),
      finishedAt: Value(finishedAt),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      iteration: Value(iteration),
    );
  }

  factory ImageGenRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageGenRecord(
      id: serializer.fromJson<String>(json['id']),
      prompt: serializer.fromJson<String>(json['prompt']),
      negativePrompt: serializer.fromJson<String>(json['negativePrompt']),
      model: serializer.fromJson<String>(json['model']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      seed: serializer.fromJson<int?>(json['seed']),
      steps: serializer.fromJson<int>(json['steps']),
      generationTimeMs: serializer.fromJson<int>(json['generationTimeMs']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      iteration: serializer.fromJson<int>(json['iteration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prompt': serializer.toJson<String>(prompt),
      'negativePrompt': serializer.toJson<String>(negativePrompt),
      'model': serializer.toJson<String>(model),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'seed': serializer.toJson<int?>(seed),
      'steps': serializer.toJson<int>(steps),
      'generationTimeMs': serializer.toJson<int>(generationTimeMs),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
      'imagePath': serializer.toJson<String?>(imagePath),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'iteration': serializer.toJson<int>(iteration),
    };
  }

  ImageGenRecord copyWith({
    String? id,
    String? prompt,
    String? negativePrompt,
    String? model,
    int? width,
    int? height,
    Value<int?> seed = const Value.absent(),
    int? steps,
    int? generationTimeMs,
    DateTime? startedAt,
    DateTime? finishedAt,
    Value<String?> imagePath = const Value.absent(),
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    int? iteration,
  }) => ImageGenRecord(
    id: id ?? this.id,
    prompt: prompt ?? this.prompt,
    negativePrompt: negativePrompt ?? this.negativePrompt,
    model: model ?? this.model,
    width: width ?? this.width,
    height: height ?? this.height,
    seed: seed.present ? seed.value : this.seed,
    steps: steps ?? this.steps,
    generationTimeMs: generationTimeMs ?? this.generationTimeMs,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    iteration: iteration ?? this.iteration,
  );
  ImageGenRecord copyWithCompanion(ImageGenRecordsCompanion data) {
    return ImageGenRecord(
      id: data.id.present ? data.id.value : this.id,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      negativePrompt: data.negativePrompt.present
          ? data.negativePrompt.value
          : this.negativePrompt,
      model: data.model.present ? data.model.value : this.model,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      seed: data.seed.present ? data.seed.value : this.seed,
      steps: data.steps.present ? data.steps.value : this.steps,
      generationTimeMs: data.generationTimeMs.present
          ? data.generationTimeMs.value
          : this.generationTimeMs,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      iteration: data.iteration.present ? data.iteration.value : this.iteration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageGenRecord(')
          ..write('id: $id, ')
          ..write('prompt: $prompt, ')
          ..write('negativePrompt: $negativePrompt, ')
          ..write('model: $model, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('seed: $seed, ')
          ..write('steps: $steps, ')
          ..write('generationTimeMs: $generationTimeMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('iteration: $iteration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prompt,
    negativePrompt,
    model,
    width,
    height,
    seed,
    steps,
    generationTimeMs,
    startedAt,
    finishedAt,
    imagePath,
    status,
    errorMessage,
    iteration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageGenRecord &&
          other.id == this.id &&
          other.prompt == this.prompt &&
          other.negativePrompt == this.negativePrompt &&
          other.model == this.model &&
          other.width == this.width &&
          other.height == this.height &&
          other.seed == this.seed &&
          other.steps == this.steps &&
          other.generationTimeMs == this.generationTimeMs &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.imagePath == this.imagePath &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.iteration == this.iteration);
}

class PromptsCompanion extends UpdateCompanion<PromptEntry> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> branch;
  final Value<int> priority;
  final Value<PromptStatus> status;
  final Value<bool> isSkipped;
  final Value<String?> output;
  final Value<String> projectPath;
  final Value<String> sessionId;
  final Value<String> claudeSessionId;
  final Value<String> claudeModel;
  final Value<String> imagePaths;
  final Value<bool> commitAfterRun;
  final Value<DateTime?> startedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PromptsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.branch = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.output = const Value.absent(),
    this.projectPath = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.claudeSessionId = const Value.absent(),
    this.claudeModel = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.commitAfterRun = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromptsCompanion.insert({
    required String id,
    required String content,
    required String branch,
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.output = const Value.absent(),
    this.projectPath = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.claudeSessionId = const Value.absent(),
    this.claudeModel = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.commitAfterRun = const Value.absent(),
    this.startedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       branch = Value(branch),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PromptEntry> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? branch,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<bool>? isSkipped,
    Expression<String>? output,
    Expression<String>? projectPath,
    Expression<String>? sessionId,
    Expression<String>? claudeSessionId,
    Expression<String>? claudeModel,
    Expression<String>? imagePaths,
    Expression<bool>? commitAfterRun,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (branch != null) 'branch': branch,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (isSkipped != null) 'is_skipped': isSkipped,
      if (output != null) 'output': output,
      if (projectPath != null) 'project_path': projectPath,
      if (sessionId != null) 'session_id': sessionId,
      if (claudeSessionId != null) 'claude_session_id': claudeSessionId,
      if (claudeModel != null) 'claude_model': claudeModel,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (commitAfterRun != null) 'commit_after_run': commitAfterRun,
      if (startedAt != null) 'started_at': startedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromptsCompanion copyWith({
    Value<String>? id,
    Value<String>? content,
    Value<String>? branch,
    Value<int>? priority,
    Value<PromptStatus>? status,
    Value<bool>? isSkipped,
    Value<String?>? output,
    Value<String>? projectPath,
    Value<String>? sessionId,
    Value<String>? claudeSessionId,
    Value<String>? claudeModel,
    Value<String>? imagePaths,
    Value<bool>? commitAfterRun,
    Value<DateTime?>? startedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PromptsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      branch: branch ?? this.branch,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isSkipped: isSkipped ?? this.isSkipped,
      output: output ?? this.output,
      projectPath: projectPath ?? this.projectPath,
      sessionId: sessionId ?? this.sessionId,
      claudeSessionId: claudeSessionId ?? this.claudeSessionId,
      claudeModel: claudeModel ?? this.claudeModel,
      imagePaths: imagePaths ?? this.imagePaths,
      commitAfterRun: commitAfterRun ?? this.commitAfterRun,
      startedAt: startedAt ?? this.startedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PromptsTable.$converterstatus.toSql(status.value),
      );
    }
    if (isSkipped.present) {
      map['is_skipped'] = Variable<bool>(isSkipped.value);
    }
    if (output.present) {
      map['output'] = Variable<String>(output.value);
    }
    if (projectPath.present) {
      map['project_path'] = Variable<String>(projectPath.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (claudeSessionId.present) {
      map['claude_session_id'] = Variable<String>(claudeSessionId.value);
    }
    if (claudeModel.present) {
      map['claude_model'] = Variable<String>(claudeModel.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (commitAfterRun.present) {
      map['commit_after_run'] = Variable<bool>(commitAfterRun.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('branch: $branch, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('output: $output, ')
          ..write('projectPath: $projectPath, ')
          ..write('sessionId: $sessionId, ')
          ..write('claudeSessionId: $claudeSessionId, ')
          ..write('claudeModel: $claudeModel, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('commitAfterRun: $commitAfterRun, ')
          ..write('startedAt: $startedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ImageGenRecordsCompanion extends UpdateCompanion<ImageGenRecord> {
  final Value<String> id;
  final Value<String> prompt;
  final Value<String> negativePrompt;
  final Value<String> model;
  final Value<int> width;
  final Value<int> height;
  final Value<int?> seed;
  final Value<int> steps;
  final Value<int> generationTimeMs;
  final Value<DateTime> startedAt;
  final Value<DateTime> finishedAt;
  final Value<String?> imagePath;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int> iteration;
  final Value<int> rowid;
  const ImageGenRecordsCompanion({
    this.id = const Value.absent(),
    this.prompt = const Value.absent(),
    this.negativePrompt = const Value.absent(),
    this.model = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.seed = const Value.absent(),
    this.steps = const Value.absent(),
    this.generationTimeMs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.iteration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageGenRecordsCompanion.insert({
    required String id,
    required String prompt,
    this.negativePrompt = const Value.absent(),
    this.model = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.seed = const Value.absent(),
    this.steps = const Value.absent(),
    this.generationTimeMs = const Value.absent(),
    required DateTime startedAt,
    required DateTime finishedAt,
    this.imagePath = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.iteration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       prompt = Value(prompt),
       startedAt = Value(startedAt),
       finishedAt = Value(finishedAt);
  static Insertable<ImageGenRecord> custom({
    Expression<String>? id,
    Expression<String>? prompt,
    Expression<String>? negativePrompt,
    Expression<String>? model,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? seed,
    Expression<int>? steps,
    Expression<int>? generationTimeMs,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? imagePath,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? iteration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prompt != null) 'prompt': prompt,
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
      if (model != null) 'model': model,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (seed != null) 'seed': seed,
      if (steps != null) 'steps': steps,
      if (generationTimeMs != null) 'generation_time_ms': generationTimeMs,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (imagePath != null) 'image_path': imagePath,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (iteration != null) 'iteration': iteration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageGenRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? prompt,
    Value<String>? negativePrompt,
    Value<String>? model,
    Value<int>? width,
    Value<int>? height,
    Value<int?>? seed,
    Value<int>? steps,
    Value<int>? generationTimeMs,
    Value<DateTime>? startedAt,
    Value<DateTime>? finishedAt,
    Value<String?>? imagePath,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<int>? iteration,
    Value<int>? rowid,
  }) {
    return ImageGenRecordsCompanion(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      model: model ?? this.model,
      width: width ?? this.width,
      height: height ?? this.height,
      seed: seed ?? this.seed,
      steps: steps ?? this.steps,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      iteration: iteration ?? this.iteration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) map['id'] = Variable<String>(id.value);
    if (prompt.present) map['prompt'] = Variable<String>(prompt.value);
    if (negativePrompt.present)
      map['negative_prompt'] = Variable<String>(negativePrompt.value);
    if (model.present) map['model'] = Variable<String>(model.value);
    if (width.present) map['width'] = Variable<int>(width.value);
    if (height.present) map['height'] = Variable<int>(height.value);
    if (seed.present) map['seed'] = Variable<int>(seed.value);
    if (steps.present) map['steps'] = Variable<int>(steps.value);
    if (generationTimeMs.present)
      map['generation_time_ms'] = Variable<int>(generationTimeMs.value);
    if (startedAt.present)
      map['started_at'] = Variable<DateTime>(startedAt.value);
    if (finishedAt.present)
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    if (imagePath.present)
      map['image_path'] = Variable<String>(imagePath.value);
    if (status.present) map['status'] = Variable<String>(status.value);
    if (errorMessage.present)
      map['error_message'] = Variable<String>(errorMessage.value);
    if (iteration.present) map['iteration'] = Variable<int>(iteration.value);
    if (rowid.present) map['rowid'] = Variable<int>(rowid.value);
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageGenRecordsCompanion(')
          ..write('id: $id, ')
          ..write('prompt: $prompt, ')
          ..write('negativePrompt: $negativePrompt, ')
          ..write('model: $model, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('seed: $seed, ')
          ..write('steps: $steps, ')
          ..write('generationTimeMs: $generationTimeMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('iteration: $iteration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PromptsTable prompts = $PromptsTable(this);
  late final $ImageGenRecordsTable imageGenRecords = $ImageGenRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    prompts,
    imageGenRecords,
  ];
}

typedef $$PromptsTableCreateCompanionBuilder =
    PromptsCompanion Function({
      required String id,
      required String content,
      required String branch,
      Value<int> priority,
      Value<PromptStatus> status,
      Value<bool> isSkipped,
      Value<String?> output,
      Value<String> projectPath,
      Value<String> sessionId,
      Value<String> claudeSessionId,
      Value<String> claudeModel,
      Value<String> imagePaths,
      Value<bool> commitAfterRun,
      Value<DateTime?> startedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PromptsTableUpdateCompanionBuilder =
    PromptsCompanion Function({
      Value<String> id,
      Value<String> content,
      Value<String> branch,
      Value<int> priority,
      Value<PromptStatus> status,
      Value<bool> isSkipped,
      Value<String?> output,
      Value<String> projectPath,
      Value<String> sessionId,
      Value<String> claudeSessionId,
      Value<String> claudeModel,
      Value<String> imagePaths,
      Value<bool> commitAfterRun,
      Value<DateTime?> startedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PromptsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PromptStatus, PromptStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get output => $composableBuilder(
    column: $table.output,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claudeSessionId => $composableBuilder(
    column: $table.claudeSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claudeModel => $composableBuilder(
    column: $table.claudeModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get commitAfterRun => $composableBuilder(
    column: $table.commitAfterRun,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get output => $composableBuilder(
    column: $table.output,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claudeSessionId => $composableBuilder(
    column: $table.claudeSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claudeModel => $composableBuilder(
    column: $table.claudeModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get commitAfterRun => $composableBuilder(
    column: $table.commitAfterRun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PromptStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSkipped =>
      $composableBuilder(column: $table.isSkipped, builder: (column) => column);

  GeneratedColumn<String> get output =>
      $composableBuilder(column: $table.output, builder: (column) => column);

  GeneratedColumn<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get claudeSessionId => $composableBuilder(
    column: $table.claudeSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claudeModel => $composableBuilder(
    column: $table.claudeModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get commitAfterRun => $composableBuilder(
    column: $table.commitAfterRun,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptsTable,
          PromptEntry,
          $$PromptsTableFilterComposer,
          $$PromptsTableOrderingComposer,
          $$PromptsTableAnnotationComposer,
          $$PromptsTableCreateCompanionBuilder,
          $$PromptsTableUpdateCompanionBuilder,
          (
            PromptEntry,
            BaseReferences<_$AppDatabase, $PromptsTable, PromptEntry>,
          ),
          PromptEntry,
          PrefetchHooks Function()
        > {
  $$PromptsTableTableManager(_$AppDatabase db, $PromptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<PromptStatus> status = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<String?> output = const Value.absent(),
                Value<String> projectPath = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> claudeSessionId = const Value.absent(),
                Value<String> claudeModel = const Value.absent(),
                Value<String> imagePaths = const Value.absent(),
                Value<bool> commitAfterRun = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromptsCompanion(
                id: id,
                content: content,
                branch: branch,
                priority: priority,
                status: status,
                isSkipped: isSkipped,
                output: output,
                projectPath: projectPath,
                sessionId: sessionId,
                claudeSessionId: claudeSessionId,
                claudeModel: claudeModel,
                imagePaths: imagePaths,
                commitAfterRun: commitAfterRun,
                startedAt: startedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String content,
                required String branch,
                Value<int> priority = const Value.absent(),
                Value<PromptStatus> status = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<String?> output = const Value.absent(),
                Value<String> projectPath = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> claudeSessionId = const Value.absent(),
                Value<String> claudeModel = const Value.absent(),
                Value<String> imagePaths = const Value.absent(),
                Value<bool> commitAfterRun = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PromptsCompanion.insert(
                id: id,
                content: content,
                branch: branch,
                priority: priority,
                status: status,
                isSkipped: isSkipped,
                output: output,
                projectPath: projectPath,
                sessionId: sessionId,
                claudeSessionId: claudeSessionId,
                claudeModel: claudeModel,
                imagePaths: imagePaths,
                commitAfterRun: commitAfterRun,
                startedAt: startedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptsTable,
      PromptEntry,
      $$PromptsTableFilterComposer,
      $$PromptsTableOrderingComposer,
      $$PromptsTableAnnotationComposer,
      $$PromptsTableCreateCompanionBuilder,
      $$PromptsTableUpdateCompanionBuilder,
      (PromptEntry, BaseReferences<_$AppDatabase, $PromptsTable, PromptEntry>),
      PromptEntry,
      PrefetchHooks Function()
    >;

typedef $$ImageGenRecordsTableCreateCompanionBuilder =
    ImageGenRecordsCompanion Function({
      required String id,
      required String prompt,
      Value<String> negativePrompt,
      Value<String> model,
      Value<int> width,
      Value<int> height,
      Value<int?> seed,
      Value<int> steps,
      Value<int> generationTimeMs,
      required DateTime startedAt,
      required DateTime finishedAt,
      Value<String?> imagePath,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> iteration,
      Value<int> rowid,
    });
typedef $$ImageGenRecordsTableUpdateCompanionBuilder =
    ImageGenRecordsCompanion Function({
      Value<String> id,
      Value<String> prompt,
      Value<String> negativePrompt,
      Value<String> model,
      Value<int> width,
      Value<int> height,
      Value<int?> seed,
      Value<int> steps,
      Value<int> generationTimeMs,
      Value<DateTime> startedAt,
      Value<DateTime> finishedAt,
      Value<String?> imagePath,
      Value<String> status,
      Value<String?> errorMessage,
      Value<int> iteration,
      Value<int> rowid,
    });

class $$ImageGenRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageGenRecordsTable> {
  $$ImageGenRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get generationTimeMs => $composableBuilder(
    column: $table.generationTimeMs,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
  ColumnFilters<int> get iteration => $composableBuilder(
    column: $table.iteration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImageGenRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageGenRecordsTable> {
  $$ImageGenRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get generationTimeMs => $composableBuilder(
    column: $table.generationTimeMs,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
  ColumnOrderings<int> get iteration => $composableBuilder(
    column: $table.iteration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImageGenRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageGenRecordsTable> {
  $$ImageGenRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);
  GeneratedColumn<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => column,
  );
  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);
  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);
  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);
  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);
  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);
  GeneratedColumn<int> get generationTimeMs => $composableBuilder(
    column: $table.generationTimeMs,
    builder: (column) => column,
  );
  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
  GeneratedColumn<int> get iteration =>
      $composableBuilder(column: $table.iteration, builder: (column) => column);
}

class $$ImageGenRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageGenRecordsTable,
          ImageGenRecord,
          $$ImageGenRecordsTableFilterComposer,
          $$ImageGenRecordsTableOrderingComposer,
          $$ImageGenRecordsTableAnnotationComposer,
          $$ImageGenRecordsTableCreateCompanionBuilder,
          $$ImageGenRecordsTableUpdateCompanionBuilder,
          (
            ImageGenRecord,
            BaseReferences<
              _$AppDatabase,
              $ImageGenRecordsTable,
              ImageGenRecord
            >,
          ),
          ImageGenRecord,
          PrefetchHooks Function()
        > {
  $$ImageGenRecordsTableTableManager(
    _$AppDatabase db,
    $ImageGenRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageGenRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageGenRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageGenRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> negativePrompt = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> generationTimeMs = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> finishedAt = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> iteration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageGenRecordsCompanion(
                id: id,
                prompt: prompt,
                negativePrompt: negativePrompt,
                model: model,
                width: width,
                height: height,
                seed: seed,
                steps: steps,
                generationTimeMs: generationTimeMs,
                startedAt: startedAt,
                finishedAt: finishedAt,
                imagePath: imagePath,
                status: status,
                errorMessage: errorMessage,
                iteration: iteration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String prompt,
                Value<String> negativePrompt = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int> generationTimeMs = const Value.absent(),
                required DateTime startedAt,
                required DateTime finishedAt,
                Value<String?> imagePath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> iteration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageGenRecordsCompanion.insert(
                id: id,
                prompt: prompt,
                negativePrompt: negativePrompt,
                model: model,
                width: width,
                height: height,
                seed: seed,
                steps: steps,
                generationTimeMs: generationTimeMs,
                startedAt: startedAt,
                finishedAt: finishedAt,
                imagePath: imagePath,
                status: status,
                errorMessage: errorMessage,
                iteration: iteration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImageGenRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageGenRecordsTable,
      ImageGenRecord,
      $$ImageGenRecordsTableFilterComposer,
      $$ImageGenRecordsTableOrderingComposer,
      $$ImageGenRecordsTableAnnotationComposer,
      $$ImageGenRecordsTableCreateCompanionBuilder,
      $$ImageGenRecordsTableUpdateCompanionBuilder,
      (
        ImageGenRecord,
        BaseReferences<_$AppDatabase, $ImageGenRecordsTable, ImageGenRecord>,
      ),
      ImageGenRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db, _db.prompts);
  $$ImageGenRecordsTableTableManager get imageGenRecords =>
      $$ImageGenRecordsTableTableManager(_db, _db.imageGenRecords);
}
