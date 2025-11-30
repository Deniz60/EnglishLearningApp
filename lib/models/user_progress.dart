import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 2)
class LessonGroupProgress {
  @HiveField(0)
  int bestScore; // En iyi skor (0-10)

  @HiveField(1)
  bool isUnlocked; // Bu ders açık mı?

  @HiveField(2)
  bool isCompleted; // 7/10 veya üzeri yapıldı mı?

  LessonGroupProgress({
    this.bestScore = 0,
    this.isUnlocked = false,
    this.isCompleted = false,
  });
}

@HiveType(typeId: 1)
class UserProgress {
  @HiveField(0)
  int lives;

  @HiveField(1)
  DateTime lastLifeUpdate;

  @HiveField(2)
  bool isPremium;

  @HiveField(3)
  int totalScore;

  @HiveField(4)
  Map<String, LessonGroupProgress> lessonProgress; // A1-0: {score: 8, unlocked: true}, A1-1: {score: 0, unlocked: false}

  @HiveField(5)
  int streak; // Günlük çalışma serisi

  @HiveField(6)
  DateTime? lastStudyDate;

  UserProgress({
    this.lives = 5,
    DateTime? lastLifeUpdate,
    this.isPremium = false,
    this.totalScore = 0,
    Map<String, LessonGroupProgress>? lessonProgress,
    this.streak = 0,
    this.lastStudyDate,
  })  : lastLifeUpdate = lastLifeUpdate ?? DateTime.now(),
        lessonProgress = lessonProgress ?? {};

  void decreaseLives() {
    if (!isPremium && lives > 0) {
      print('🔴 CAN AZALDI: $lives -> ${lives - 1}');
      lives--;
      lastLifeUpdate = DateTime.now();
    } else {
      print('⚠️ CAN AZALMADI - Premium: $isPremium, Lives: $lives');
    }
  }

  void regenerateLives() {
    if (isPremium) {
      lives = 50; // Premium'da 50 can
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(lastLifeUpdate);
    final hoursPassed = difference.inHours;

    if (hoursPassed > 0 && lives < 5) {
      lives = (lives + hoursPassed).clamp(0, 5);
      lastLifeUpdate = now;
    }
  }

  void updateStreak() {
    final now = DateTime.now();
    if (lastStudyDate == null) {
      streak = 1;
      lastStudyDate = now;
      return;
    }

    final daysDifference = now.difference(lastStudyDate!).inDays;
    
    if (daysDifference == 1) {
      streak++;
    } else if (daysDifference > 1) {
      streak = 1;
    }
    
    lastStudyDate = now;
  }

  void addScore(int points) {
    totalScore += points;
  }

  void completeLesson(String lessonGroupKey, int score) {
    // lessonGroupKey format: "A1_0_word_matching", "A1_1_multiple_choice", "B2_5_word_matching", etc.
    final progress = lessonProgress[lessonGroupKey] ?? LessonGroupProgress(isUnlocked: true);
    
    // Son aktivite tarihini güncelle
    lastStudyDate = DateTime.now();
    
    // Skoru güncelle
    if (score > progress.bestScore) {
      progress.bestScore = score;
    }
    
    // Kelime eşleştirme: 60/60 (her kelime 10 puan), Çoktan seçmeli: 7/10
    final isWordMatching = lessonGroupKey.contains('word_matching');
    final isCompleted = isWordMatching ? (score >= 60) : (score >= 7);
    
    if (isCompleted) {
      progress.isCompleted = true;
      
      // Sadece tamamlandığında sonraki dersi aç
      // "A1_0_word_matching" -> ["A1", "0", "word_matching"]
      final parts = lessonGroupKey.split('_');
      if (parts.length >= 2) {
        final level = parts[0];
        final index = int.tryParse(parts[1]) ?? 0;
        final gameType = parts.length >= 3 ? parts.sublist(2).join('_') : 'multiple_choice';
        final nextKey = '${level}_${index + 1}_$gameType';
        
        // Sonraki ders zaten varsa dokunma, yoksa oluştur ve aç
        if (!lessonProgress.containsKey(nextKey)) {
          lessonProgress[nextKey] = LessonGroupProgress(isUnlocked: true);
          print('🔓 Sonraki ders açıldı: $nextKey');
        }
      }
    }
    
    lessonProgress[lessonGroupKey] = progress;
    print('✅ Ders tamamlandı: $lessonGroupKey, Skor: $score/${progress.bestScore}, Tamamlandı: ${progress.isCompleted}');
  }

  // İlk dersleri aç (her oyun türü için her seviyenin ilk dersi)
  void initializeLessons() {
    if (lessonProgress.isEmpty) {
      // Her seviye ve oyun türü için ilk dersi aç
      final levels = ['A1', 'A2', 'B1', 'B2'];
      final gameTypes = ['multiple_choice', 'word_matching'];
      
      for (final level in levels) {
        for (final gameType in gameTypes) {
          final key = '${level}_0_$gameType';
          lessonProgress[key] = LessonGroupProgress(isUnlocked: true);
        }
      }
    }
  }

  // Bir seviyede kaç ders tamamlandı
  int getCompletedLessonsCount(String level) {
    return lessonProgress.entries
        .where((e) => e.key.startsWith(level) && e.value.isCompleted)
        .length;
  }

  // Toplam tamamlanan ders sayısı
  int get totalCompletedLessons {
    return lessonProgress.values.where((v) => v.isCompleted).length;
  }
}
