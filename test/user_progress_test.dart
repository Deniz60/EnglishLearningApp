import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/models/user_progress.dart';

void main() {
  group('UserProgress Tests', () {
    late UserProgress progress;

    setUp(() {
      progress = UserProgress();
    });

    group('Initial State', () {
      test('should have default values', () {
        expect(progress.lives, 5);
        expect(progress.totalScore, 0);
        expect(progress.streak, 0);
        expect(progress.isPremium, false);
        expect(progress.lessonProgress, isEmpty);
      });
    });

    group('Lives Management', () {
      test('decreaseLives should decrease lives by 1', () {
        progress.lives = 5;
        progress.decreaseLives();
        expect(progress.lives, 4);
      });

      test('decreaseLives should not go below 0', () {
        progress.lives = 0;
        progress.decreaseLives();
        expect(progress.lives, 0);
      });

      test('regenerateLives should restore lives to max', () {
        progress.lives = 2;
        progress.lastLifeUpdate = DateTime.now().subtract(const Duration(hours: 10));
        progress.regenerateLives();
        expect(progress.lives, 5);
      });

      test('premium users should have 50 lives on regenerate', () {
        progress.isPremium = true;
        progress.regenerateLives();
        expect(progress.lives, 50);
      });
    });

    group('Score Management', () {
      test('addScore should add points to totalScore', () {
        progress.addScore(100);
        expect(progress.totalScore, 100);
      });

      test('addScore should accumulate points', () {
        progress.addScore(50);
        progress.addScore(30);
        expect(progress.totalScore, 80);
      });
    });

    group('Streak Management', () {
      test('updateStreak should start at 1 if no previous date', () {
        progress.lastStudyDate = null;
        progress.streak = 0;
        progress.updateStreak();
        expect(progress.streak, 1);
      });

      test('updateStreak should increase streak for consecutive days', () {
        progress.lastStudyDate = DateTime.now().subtract(const Duration(days: 1));
        progress.streak = 5;
        progress.updateStreak();
        expect(progress.streak, 6);
      });

      test('updateStreak should reset streak if more than 1 day gap', () {
        progress.lastStudyDate = DateTime.now().subtract(const Duration(days: 3));
        progress.streak = 5;
        progress.updateStreak();
        expect(progress.streak, 1);
      });
    });

    group('Lesson Progress', () {
      test('initializeLessons should create initial lessons for each level', () {
        progress.initializeLessons();
        expect(progress.lessonProgress.isNotEmpty, true);
        // Her seviyenin ilk dersi açık olmalı
        expect(progress.lessonProgress['A1_0_multiple_choice']?.isUnlocked, true);
        expect(progress.lessonProgress['A1_0_word_matching']?.isUnlocked, true);
        expect(progress.lessonProgress['B2_0_multiple_choice']?.isUnlocked, true);
      });

      test('completeLesson should mark lesson as completed with passing score', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_multiple_choice', 8);
        expect(progress.lessonProgress['A1_0_multiple_choice']?.isCompleted, true);
        expect(progress.lessonProgress['A1_0_multiple_choice']?.bestScore, 8);
      });

      test('completeLesson should unlock next lesson', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_multiple_choice', 7);
        // Sonraki ders açılmalı
        expect(progress.lessonProgress['A1_1_multiple_choice']?.isUnlocked, true);
      });

      test('completeLesson should update best score if higher', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_multiple_choice', 7);
        progress.completeLesson('A1_0_multiple_choice', 9);
        expect(progress.lessonProgress['A1_0_multiple_choice']?.bestScore, 9);
      });

      test('completeLesson should not update best score if lower', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_multiple_choice', 9);
        progress.completeLesson('A1_0_multiple_choice', 6);
        expect(progress.lessonProgress['A1_0_multiple_choice']?.bestScore, 9);
      });

      test('word_matching requires score of 60 to complete', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_word_matching', 50);
        expect(progress.lessonProgress['A1_0_word_matching']?.isCompleted, false);
        
        progress.completeLesson('A1_0_word_matching', 60);
        expect(progress.lessonProgress['A1_0_word_matching']?.isCompleted, true);
      });
    });

    group('Total Completed Lessons', () {
      test('totalCompletedLessons should count completed lessons', () {
        progress.initializeLessons();
        expect(progress.totalCompletedLessons, 0);
        
        progress.completeLesson('A1_0_multiple_choice', 8);
        expect(progress.totalCompletedLessons, 1);
        
        progress.completeLesson('A1_0_word_matching', 60);
        expect(progress.totalCompletedLessons, 2);
      });

      test('getCompletedLessonsCount should count by level', () {
        progress.initializeLessons();
        progress.completeLesson('A1_0_multiple_choice', 8);
        progress.completeLesson('A1_0_word_matching', 60);
        progress.completeLesson('B1_0_multiple_choice', 9);
        
        expect(progress.getCompletedLessonsCount('A1'), 2);
        expect(progress.getCompletedLessonsCount('B1'), 1);
        expect(progress.getCompletedLessonsCount('B2'), 0);
      });
    });
  });

  group('LessonGroupProgress Tests', () {
    test('should have correct default values', () {
      final lesson = LessonGroupProgress();
      expect(lesson.bestScore, 0);
      expect(lesson.isUnlocked, false);
      expect(lesson.isCompleted, false);
    });

    test('should allow setting values', () {
      final lesson = LessonGroupProgress(
        bestScore: 10,
        isUnlocked: true,
        isCompleted: true,
      );
      expect(lesson.bestScore, 10);
      expect(lesson.isUnlocked, true);
      expect(lesson.isCompleted, true);
    });
  });
}
