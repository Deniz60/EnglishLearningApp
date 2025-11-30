import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/services/error_handler.dart';
import 'package:english_learning_app/utils/exceptions.dart';

void main() {
  group('Result Tests', () {
    group('Success', () {
      test('should create success result with data', () {
        final result = Result.success('test data');
        expect(result.isSuccess, true);
        expect(result.data, 'test data');
        expect(result.error, isNull);
      });

      test('should handle fold for success', () {
        final result = Result.success(42);
        final value = result.fold(
          onSuccess: (data) => 'Success: $data',
          onFailure: (error) => 'Failed: ${error.message}',
        );
        expect(value, 'Success: 42');
      });
    });

    group('Failure', () {
      test('should create failure result with error', () {
        final error = DataException.loadFailed();
        final result = Result<String>.failure(error);
        expect(result.isSuccess, false);
        expect(result.data, isNull);
        expect(result.error, error);
      });

      test('should handle fold for failure', () {
        final error = NetworkException.noConnection();
        final result = Result<int>.failure(error);
        final value = result.fold(
          onSuccess: (data) => 'Success: $data',
          onFailure: (error) => 'Failed: ${error.userMessage}',
        );
        expect(value, contains('Failed'));
      });
    });
  });

  group('ErrorHandler Tests', () {
    test('should be singleton', () {
      final handler1 = ErrorHandler();
      final handler2 = ErrorHandler();
      expect(identical(handler1, handler2), true);
    });

    test('handle should return fallback on exception', () async {
      final handler = ErrorHandler();
      final result = await handler.handle<int>(
        action: () async => throw NetworkException.noConnection(),
        fallback: -1,
        showError: false,
      );
      expect(result, -1);
    });

    test('handle should return result on success', () async {
      final handler = ErrorHandler();
      final result = await handler.handle<int>(
        action: () async => 42,
        fallback: -1,
        showError: false,
      );
      expect(result, 42);
    });

    test('lastError should be updated after handling error', () async {
      final handler = ErrorHandler();
      final error = DataException.loadFailed();
      
      await handler.handle<void>(
        action: () async => throw error,
        showError: false,
      );
      
      expect(handler.lastError, isNotNull);
    });
  });
}
