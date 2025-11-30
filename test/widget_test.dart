// This is a basic Flutter widget test.
//
// English Learning App için temel widget testleri

import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/utils/constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('should have correct default values', () {
      expect(AppConstants.maxLives, 5);
      expect(AppConstants.premiumLives, 50);
      expect(AppConstants.wordsPerLesson, 10);
      expect(AppConstants.passScore, 7);
    });

    test('should have all level names', () {
      expect(AppConstants.levelNames.length, 4);
      expect(AppConstants.levelNames['A1'], 'Başlangıç');
      expect(AppConstants.levelNames['A2'], 'Temel');
      expect(AppConstants.levelNames['B1'], 'Orta');
      expect(AppConstants.levelNames['B2'], 'İleri');
    });

    test('should have all level colors', () {
      expect(AppConstants.levelColors.length, 4);
      expect(AppConstants.levelColors['A1'], AppColors.levelA1);
      expect(AppConstants.levelColors['A2'], AppColors.levelA2);
      expect(AppConstants.levelColors['B1'], AppColors.levelB1);
      expect(AppConstants.levelColors['B2'], AppColors.levelB2);
    });
  });

  group('AppColors Tests', () {
    test('should have primary colors', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.error, isNotNull);
    });

    test('should have level colors', () {
      expect(AppColors.levelA1, isNotNull);
      expect(AppColors.levelA2, isNotNull);
      expect(AppColors.levelB1, isNotNull);
      expect(AppColors.levelB2, isNotNull);
    });

    test('should have game colors', () {
      expect(AppColors.correct, isNotNull);
      expect(AppColors.incorrect, isNotNull);
      expect(AppColors.premium, isNotNull);
    });
  });
}
