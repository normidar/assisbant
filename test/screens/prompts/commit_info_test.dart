import 'package:assibant/src/data/database/app_database.dart';
import 'package:assibant/src/data/database/prompt_status.dart';
import 'package:assibant/src/screens/prompts/commit_history_view.dart';
import 'package:flutter_test/flutter_test.dart';

PromptEntry _entry({String id = 'id'}) => PromptEntry(
  id: id,
  content: 'content',
  branch: 'main',
  priority: 10,
  status: PromptStatus.pending,
  isSkipped: false,
  projectPath: '',
  sessionId: '',
  claudeSessionId: '',
  claudeModel: '',
  imagePaths: '',
  commitAfterRun: false,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('CommitInfo.shortHash', () {
    test('returns first 7 characters of a full SHA', () {
      final info = CommitInfo(
        hash: 'abc1234def5678',
        date: DateTime(2024),
        message: 'Fix bug',
      );
      expect(info.shortHash, 'abc1234');
    });

    test('returns exactly 7 characters when hash is exactly 7 long', () {
      final info = CommitInfo(
        hash: '1234567',
        date: DateTime(2024),
        message: 'Init',
      );
      expect(info.shortHash, '1234567');
    });

    test('returns the full hash when shorter than 7 characters', () {
      final info = CommitInfo(
        hash: 'abc',
        date: DateTime(2024),
        message: 'Short',
      );
      expect(info.shortHash, 'abc');
    });

    test('returns empty string for empty hash', () {
      final info = CommitInfo(
        hash: '',
        date: DateTime(2024),
        message: 'Empty',
      );
      expect(info.shortHash, '');
    });
  });

  group('CommitInfo.hasMatch', () {
    test('returns false when matchedPrompts is empty (default)', () {
      final info = CommitInfo(
        hash: 'abc1234',
        date: DateTime(2024),
        message: 'No match',
      );
      expect(info.hasMatch, isFalse);
    });

    test('returns true when at least one prompt is matched', () {
      final info = CommitInfo(
        hash: 'abc1234',
        date: DateTime(2024),
        message: 'Has match',
        matchedPrompts: [_entry()],
      );
      expect(info.hasMatch, isTrue);
    });

    test('returns true for multiple matched prompts', () {
      final info = CommitInfo(
        hash: 'abc1234',
        date: DateTime(2024),
        message: 'Many matches',
        matchedPrompts: [
          _entry(id: '1'),
          _entry(id: '2'),
        ],
      );
      expect(info.hasMatch, isTrue);
    });
  });
}
