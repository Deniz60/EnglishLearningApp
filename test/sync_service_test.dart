import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/services/sync_service.dart';

void main() {
  group('PendingAction Tests', () {
    test('should create with correct values', () {
      final action = PendingAction(
        id: 'test_1',
        type: SyncActionType.saveProgress,
        data: {'lives': 5, 'score': 100},
      );

      expect(action.id, 'test_1');
      expect(action.type, SyncActionType.saveProgress);
      expect(action.data['lives'], 5);
      expect(action.retryCount, 0);
    });

    test('toJson should serialize correctly', () {
      final action = PendingAction(
        id: 'test_1',
        type: SyncActionType.addFavorite,
        data: {'wordId': 'word_123'},
      );

      final json = action.toJson();
      expect(json['id'], 'test_1');
      expect(json['type'], SyncActionType.addFavorite.index);
      expect(json['data']['wordId'], 'word_123');
      expect(json['retryCount'], 0);
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'id': 'test_2',
        'type': SyncActionType.removeFavorite.index,
        'data': {'wordId': 'word_456'},
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 2,
      };

      final action = PendingAction.fromJson(json);
      expect(action.id, 'test_2');
      expect(action.type, SyncActionType.removeFavorite);
      expect(action.data['wordId'], 'word_456');
      expect(action.retryCount, 2);
    });

    test('copyWithRetry should increment retryCount', () {
      final action = PendingAction(
        id: 'test_1',
        type: SyncActionType.saveProgress,
        data: {},
        retryCount: 1,
      );

      final retried = action.copyWithRetry();
      expect(retried.retryCount, 2);
      expect(retried.id, action.id);
      expect(retried.type, action.type);
    });
  });

  group('SyncActionType Tests', () {
    test('should have all expected types', () {
      expect(SyncActionType.values.length, 5);
      expect(SyncActionType.values.contains(SyncActionType.saveProgress), true);
      expect(SyncActionType.values.contains(SyncActionType.addFavorite), true);
      expect(SyncActionType.values.contains(SyncActionType.removeFavorite), true);
      expect(SyncActionType.values.contains(SyncActionType.updateFavoriteCategory), true);
      expect(SyncActionType.values.contains(SyncActionType.saveQuizResult), true);
    });
  });

  group('SyncResult Tests', () {
    test('should report fully completed when no failures or pending', () {
      final result = SyncResult(success: 5, failed: 0, pending: 0);
      expect(result.isFullyCompleted, true);
    });

    test('should not report fully completed when there are failures', () {
      final result = SyncResult(success: 3, failed: 2, pending: 0);
      expect(result.isFullyCompleted, false);
    });

    test('should not report fully completed when there are pending', () {
      final result = SyncResult(success: 3, failed: 0, pending: 2);
      expect(result.isFullyCompleted, false);
    });

    test('toString should include all values', () {
      final result = SyncResult(success: 3, failed: 1, pending: 2);
      final str = result.toString();
      expect(str, contains('3'));
      expect(str, contains('1'));
      expect(str, contains('2'));
    });
  });

  group('SyncStatus Tests', () {
    test('should have all expected statuses', () {
      expect(SyncStatus.values.length, 5);
      expect(SyncStatus.values.contains(SyncStatus.idle), true);
      expect(SyncStatus.values.contains(SyncStatus.syncing), true);
      expect(SyncStatus.values.contains(SyncStatus.completed), true);
      expect(SyncStatus.values.contains(SyncStatus.partiallyCompleted), true);
      expect(SyncStatus.values.contains(SyncStatus.failed), true);
    });
  });
}
