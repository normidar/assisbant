// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

@ProviderFor(promptRepository)
const promptRepositoryProvider = PromptRepositoryProvider._();

final class PromptRepositoryProvider
    extends
        $FunctionalProvider<
          PromptRepository,
          PromptRepository,
          PromptRepository
        >
    with $Provider<PromptRepository> {
  const PromptRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promptRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promptRepositoryHash();

  @$internal
  @override
  $ProviderElement<PromptRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PromptRepository create(Ref ref) {
    return promptRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PromptRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PromptRepository>(value),
    );
  }
}

String _$promptRepositoryHash() => r'8c4c05978861cebce4c472bce9b8233111b880a8';

@ProviderFor(executionService)
const executionServiceProvider = ExecutionServiceProvider._();

final class ExecutionServiceProvider
    extends
        $FunctionalProvider<
          ExecutionService,
          ExecutionService,
          ExecutionService
        >
    with $Provider<ExecutionService> {
  const ExecutionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'executionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$executionServiceHash();

  @$internal
  @override
  $ProviderElement<ExecutionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExecutionService create(Ref ref) {
    return executionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExecutionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExecutionService>(value),
    );
  }
}

String _$executionServiceHash() => r'203873035e49af34fb2f296c3e74ac7603036469';
