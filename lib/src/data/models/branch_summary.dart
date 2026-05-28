import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';

class BranchSummary {
  const BranchSummary({
    required this.name,
    required this.prompts,
  });

  final String name;
  final List<PromptEntry> prompts;

  int get totalCount => prompts.length;

  int get pendingCount => prompts
      .where((p) => p.status == PromptStatus.pending && !p.isSkipped)
      .length;

  int get doneCount =>
      prompts.where((p) => p.status == PromptStatus.done).length;

  int get failedCount =>
      prompts.where((p) => p.status == PromptStatus.failed).length;

  int get skippedCount => prompts.where((p) => p.isSkipped).length;
}
