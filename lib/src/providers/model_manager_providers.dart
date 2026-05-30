import 'package:assibant/src/data/services/model_manager_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final modelManagerServiceProvider = Provider<ModelManagerService>(
  (ref) => ModelManagerService(),
);

final modelsWatchProvider = StreamProvider<List<LocalModelInfo>>(
  (ref) => ref.watch(modelManagerServiceProvider).watchModels(),
);
