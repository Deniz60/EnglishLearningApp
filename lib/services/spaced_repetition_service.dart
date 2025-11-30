import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// SM-2 Spaced Repetition algoritması
/// Leitner Box sistemine benzer, bilimsel temelli tekrar sistemi
/// 
/// Kurallar:
/// - Doğru cevap: Sonraki tekrar süresi artar
/// - Yanlış cevap: En başa döner
/// - Easiness factor (EF): Kelimenin ne kadar kolay olduğu (1.3 - 2.5)
class SpacedRepetitionService extends ChangeNotifier {
  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  static const String _boxName = 'spaced_repetition';
  late Box _srBox;
  bool _isInitialized = false;

  // Minimum easiness factor
  static const double _minEF = 1.3;
  static const double _maxEF = 2.5;
  static const double _defaultEF = 2.5;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _srBox = await Hive.openBox(_boxName);
    _isInitialized = true;
    print('📚 SpacedRepetitionService initialized');
  }

  /// Kullanıcı bazlı key oluştur
  String _getUserKey(String wordId) {
    final userId = AuthService().currentUser?.id;
    final isGuest = StorageService().isGuestMode();
    
    if (isGuest) {
      return 'sr_guest_$wordId';
    }
    return userId != null ? 'sr_${userId}_$wordId' : 'sr_$wordId';
  }

  /// Kelime için SR verisi al
  WordSRData getWordData(String wordId) {
    final key = _getUserKey(wordId);
    final json = _srBox.get(key);
    
    if (json != null) {
      return WordSRData.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
    }
    
    return WordSRData(
      wordId: wordId,
      easinessFactor: _defaultEF,
      repetitions: 0,
      interval: 0,
      nextReview: DateTime.now(),
      lastReview: null,
    );
  }

  /// Cevabı kaydet ve SR verisini güncelle
  /// quality: 0-5 arası (0: tamamen yanlış, 5: mükemmel)
  Future<WordSRData> recordAnswer(String wordId, int quality) async {
    if (!_isInitialized) await init();
    
    final data = getWordData(wordId);
    final newData = _calculateSM2(data, quality);
    
    // Kaydet
    final key = _getUserKey(wordId);
    await _srBox.put(key, jsonEncode(newData.toJson()));
    
    notifyListeners();
    print('📝 SR updated: $wordId, quality: $quality, next: ${newData.nextReview}');
    
    return newData;
  }

  /// SM-2 algoritması
  WordSRData _calculateSM2(WordSRData data, int quality) {
    // quality: 0-5
    // 0 - Complete blackout
    // 1 - Incorrect, but recognized
    // 2 - Incorrect, but easy to recall
    // 3 - Correct with difficulty
    // 4 - Correct with hesitation
    // 5 - Perfect response
    
    double ef = data.easinessFactor;
    int repetitions = data.repetitions;
    int interval = data.interval;
    
    // EF hesapla
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ef < _minEF) ef = _minEF;
    if (ef > _maxEF) ef = _maxEF;
    
    if (quality < 3) {
      // Yanlış cevap - başa dön
      repetitions = 0;
      interval = 1;
    } else {
      // Doğru cevap
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
      repetitions++;
    }
    
    // Interval limiti
    if (interval > 365) interval = 365;
    
    return WordSRData(
      wordId: data.wordId,
      easinessFactor: ef,
      repetitions: repetitions,
      interval: interval,
      nextReview: DateTime.now().add(Duration(days: interval)),
      lastReview: DateTime.now(),
      totalReviews: data.totalReviews + 1,
      correctCount: quality >= 3 ? data.correctCount + 1 : data.correctCount,
    );
  }

  /// Bugün tekrar edilecek kelimeleri getir
  List<String> getDueWords({int limit = 20}) {
    if (!_isInitialized) return [];
    
    final now = DateTime.now();
    final dueWords = <String>[];
    
    for (final key in _srBox.keys) {
      if (key.toString().startsWith('sr_')) {
        final json = _srBox.get(key);
        if (json != null) {
          final data = WordSRData.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
          if (data.nextReview.isBefore(now) || data.nextReview.isAtSameMomentAs(now)) {
            dueWords.add(data.wordId);
          }
        }
      }
    }
    
    // Önce en eski olanlar
    dueWords.sort((a, b) {
      final dataA = getWordData(a);
      final dataB = getWordData(b);
      return dataA.nextReview.compareTo(dataB.nextReview);
    });
    
    return dueWords.take(limit).toList();
  }

  /// Toplam tekrar edilecek kelime sayısı
  int getDueWordsCount() {
    if (!_isInitialized) return 0;
    
    final now = DateTime.now();
    int count = 0;
    
    for (final key in _srBox.keys) {
      if (key.toString().startsWith('sr_')) {
        final json = _srBox.get(key);
        if (json != null) {
          final data = WordSRData.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
          if (data.nextReview.isBefore(now) || data.nextReview.isAtSameMomentAs(now)) {
            count++;
          }
        }
      }
    }
    
    return count;
  }

  /// Kelimeyi SR sistemine ekle
  Future<void> addWord(String wordId) async {
    if (!_isInitialized) await init();
    
    final key = _getUserKey(wordId);
    if (_srBox.containsKey(key)) return; // Zaten var
    
    final data = WordSRData(
      wordId: wordId,
      easinessFactor: _defaultEF,
      repetitions: 0,
      interval: 0,
      nextReview: DateTime.now(),
      lastReview: null,
    );
    
    await _srBox.put(key, jsonEncode(data.toJson()));
    notifyListeners();
  }

  /// Birden fazla kelimeyi ekle
  Future<void> addWords(List<String> wordIds) async {
    for (final wordId in wordIds) {
      await addWord(wordId);
    }
  }

  /// Kelimeyi SR sisteminden kaldır
  Future<void> removeWord(String wordId) async {
    if (!_isInitialized) await init();
    
    final key = _getUserKey(wordId);
    await _srBox.delete(key);
    notifyListeners();
  }

  /// Tüm SR verilerini temizle
  Future<void> clearAll() async {
    if (!_isInitialized) await init();
    await _srBox.clear();
    notifyListeners();
  }

  /// İstatistikleri getir
  SRStatistics getStatistics() {
    if (!_isInitialized) {
      return SRStatistics(
        totalWords: 0,
        dueToday: 0,
        mastered: 0,
        learning: 0,
        newWords: 0,
        averageEF: 0,
      );
    }
    
    int totalWords = 0;
    int dueToday = 0;
    int mastered = 0;
    int learning = 0;
    int newWords = 0;
    double totalEF = 0;
    
    final now = DateTime.now();
    
    for (final key in _srBox.keys) {
      if (key.toString().startsWith('sr_')) {
        final json = _srBox.get(key);
        if (json != null) {
          final data = WordSRData.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
          totalWords++;
          totalEF += data.easinessFactor;
          
          if (data.nextReview.isBefore(now) || data.nextReview.isAtSameMomentAs(now)) {
            dueToday++;
          }
          
          if (data.repetitions == 0) {
            newWords++;
          } else if (data.interval >= 30) {
            mastered++;
          } else {
            learning++;
          }
        }
      }
    }
    
    return SRStatistics(
      totalWords: totalWords,
      dueToday: dueToday,
      mastered: mastered,
      learning: learning,
      newWords: newWords,
      averageEF: totalWords > 0 ? totalEF / totalWords : 0,
    );
  }

  /// Kelime durumunu getir
  WordStatus getWordStatus(String wordId) {
    final data = getWordData(wordId);
    
    if (data.repetitions == 0) {
      return WordStatus.newWord;
    } else if (data.interval >= 30) {
      return WordStatus.mastered;
    } else if (data.interval >= 7) {
      return WordStatus.reviewing;
    } else {
      return WordStatus.learning;
    }
  }

  /// Kelime için önerilen kalite puanı hesapla (cevap süresine göre)
  int calculateQuality({
    required bool isCorrect,
    required Duration responseTime,
  }) {
    if (!isCorrect) {
      // Yanlış cevap
      if (responseTime.inSeconds < 3) {
        return 1; // Hızlı ama yanlış
      }
      return 0; // Yavaş ve yanlış
    }
    
    // Doğru cevap
    if (responseTime.inSeconds < 2) {
      return 5; // Mükemmel
    } else if (responseTime.inSeconds < 5) {
      return 4; // Hızlı
    } else if (responseTime.inSeconds < 10) {
      return 3; // Normal
    } else {
      return 3; // Yavaş ama doğru
    }
  }
}

/// Kelime SR verisi
class WordSRData {
  final String wordId;
  final double easinessFactor;
  final int repetitions;
  final int interval; // gün cinsinden
  final DateTime nextReview;
  final DateTime? lastReview;
  final int totalReviews;
  final int correctCount;

  WordSRData({
    required this.wordId,
    required this.easinessFactor,
    required this.repetitions,
    required this.interval,
    required this.nextReview,
    this.lastReview,
    this.totalReviews = 0,
    this.correctCount = 0,
  });

  double get accuracy => totalReviews > 0 ? correctCount / totalReviews : 0;

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'easinessFactor': easinessFactor,
        'repetitions': repetitions,
        'interval': interval,
        'nextReview': nextReview.toIso8601String(),
        'lastReview': lastReview?.toIso8601String(),
        'totalReviews': totalReviews,
        'correctCount': correctCount,
      };

  factory WordSRData.fromJson(Map<String, dynamic> json) => WordSRData(
        wordId: json['wordId'] as String,
        easinessFactor: (json['easinessFactor'] as num).toDouble(),
        repetitions: json['repetitions'] as int,
        interval: json['interval'] as int,
        nextReview: DateTime.parse(json['nextReview'] as String),
        lastReview: json['lastReview'] != null
            ? DateTime.parse(json['lastReview'] as String)
            : null,
        totalReviews: json['totalReviews'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
      );
}

/// SR istatistikleri
class SRStatistics {
  final int totalWords;
  final int dueToday;
  final int mastered;
  final int learning;
  final int newWords;
  final double averageEF;

  SRStatistics({
    required this.totalWords,
    required this.dueToday,
    required this.mastered,
    required this.learning,
    required this.newWords,
    required this.averageEF,
  });
}

/// Kelime durumu
enum WordStatus {
  newWord,     // Hiç çalışılmamış
  learning,    // Öğreniliyor (interval < 7)
  reviewing,   // Tekrar ediliyor (interval 7-30)
  mastered,    // Öğrenildi (interval >= 30)
}
