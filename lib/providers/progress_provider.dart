import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_progress.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/leaderboard_service.dart';
import '../services/spaced_repetition_service.dart';
import '../utils/exceptions.dart';

class ProgressProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final DatabaseService _database = DatabaseService();
  final SyncService _syncService = SyncService();
  final NotificationService _notificationService = NotificationService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();
  UserProgress _progress = UserProgress();
  String? _fullName;
  String? _lastError;

  UserProgress get progress => _progress;
  int get lives => _progress.lives;
  bool get isPremium => _progress.isPremium;
  int get totalScore => _progress.totalScore;
  int get streak => _progress.streak;
  int get totalCompletedLessons => _progress.totalCompletedLessons;
  String? get fullName => _fullName;
  DateTime? get lastStudyDate => _progress.lastStudyDate;
  String? get lastError => _lastError;
  bool get isOnline => _syncService.isOnline;
  int get pendingSync => _syncService.pendingCount;

  Future<void> loadProgress() async {
    final isGuest = _storage.isGuestMode();
    
    // Önce local Hive'dan yükle (her kullanıcı için ayrı key kullanılıyor)
    _progress = _storage.getProgress();
    final localScore = _progress.totalScore;
    final localStreak = _progress.streak;
    final localLessons = _progress.lessonProgress.length;
    print('📱 Local progress: Puan=$localScore, Seri=$localStreak, Dersler=$localLessons');
    
    // Eğer kullanıcı giriş yapmışsa Supabase'den yükle (Misafir değilse)
    if (AuthService().currentUser != null && !isGuest) {
      await _loadFromSupabase();
      
      // Supabase'den yüklenen değerler 0 veya null ise VE local'da değer varsa, local'ı koru
      if (_progress.totalScore == 0 && localScore > 0) {
        print('⚠️ Supabase puan 0, local puan korunuyor: $localScore');
        _progress.totalScore = localScore;
      }
      if (_progress.streak == 0 && localStreak > 0) {
        print('⚠️ Supabase seri 0, local seri korunuyor: $localStreak');
        _progress.streak = localStreak;
      }
    }
    
    // Eğer hiç ders yoksa ilk dersleri aç (sadece boş ise)
    if (_progress.lessonProgress.isEmpty) {
      _progress.initializeLessons();
    }
    
    // SADECE canları yenile (puan, streak vs. korunacak)
    _regenerateLivesOnly();
    
    await _storage.saveProgress(_progress);
    print('🎯 ProgressProvider.loadProgress - Misafir: $isGuest, Can: ${_progress.lives}, Premium: ${_progress.isPremium}, Toplam Puan: ${_progress.totalScore}, Ders Sayısı: ${_progress.lessonProgress.length}');
    notifyListeners();
  }
  
  // Sadece canları yenile - diğer istatistikler korunur
  void _regenerateLivesOnly() {
    if (_progress.isPremium) {
      _progress.lives = 50;
      return;
    }
    
    final now = DateTime.now();
    final lastUpdate = _progress.lastLifeUpdate;
    final hoursPassed = now.difference(lastUpdate).inHours;
    
    // Sadece can ekle, diğer şeylere dokunma
    if (hoursPassed > 0 && _progress.lives < 5) {
      _progress.lives = (_progress.lives + hoursPassed).clamp(0, 5);
      _progress.lastLifeUpdate = now;
      print('💖 Canlar yenilendi: ${_progress.lives}/5');
    }
  }

  // Supabase'den TÜM progress bilgilerini yükle
  Future<void> _loadFromSupabase() async {
    try {
      print('🔍 Supabase\'den yükleme deniyor...');
      final data = await _database.getLessonProgress();
      
      if (data != null && data.isNotEmpty) {
        // Ders ilerlemesini yükle - SADECE boş değilse
        final remoteLessons = data['lesson_progress'] as Map<String, dynamic>?;
        if (remoteLessons != null && remoteLessons.isNotEmpty) {
          print('📥 Supabase\'den ${remoteLessons.length} ders ilerlemesi bulundu');
          final newProgress = <String, LessonGroupProgress>{};
          remoteLessons.forEach((key, value) {
            if (value is Map) {
              newProgress[key] = LessonGroupProgress(
                bestScore: value['bestScore'] ?? 0,
                isUnlocked: value['isUnlocked'] ?? false,
                isCompleted: value['isCompleted'] ?? false,
              );
            }
          });
          // Sadece Supabase'den gelen daha fazla veya eşit ders varsa güncelle
          if (newProgress.isNotEmpty) {
            _progress.lessonProgress = newProgress;
          }
        }
        
        // Can, puan, premium, streak bilgilerini yükle - SADECE 0'dan büyükse veya anlamlı değerse
        if (data['lives'] != null && (data['lives'] as int) > 0) {
          _progress.lives = data['lives'] as int;
          print('💖 Can yüklendi: ${_progress.lives}');
        }
        if (data['total_score'] != null && (data['total_score'] as int) > 0) {
          _progress.totalScore = data['total_score'] as int;
          print('🏆 Puan yüklendi: ${_progress.totalScore}');
        }
        if (data['is_premium'] != null) {
          _progress.isPremium = data['is_premium'] as bool;
          print('⭐ Premium yüklendi: ${_progress.isPremium}');
        }
        if (data['streak'] != null && (data['streak'] as int) > 0) {
          _progress.streak = data['streak'] as int;
          print('🔥 Seri yüklendi: ${_progress.streak}');
        }
        if (data['last_study_date'] != null) {
          _progress.lastStudyDate = data['last_study_date'] as DateTime;
          print('📅 Son çalışma tarihi yüklendi: ${_progress.lastStudyDate}');
        }
        if (data['full_name'] != null) {
          _fullName = data['full_name'] as String;
          print('👤 Ad-soyad yüklendi: $_fullName');
        }
        
        print('✅ Supabase\'den TÜM ilerleme yüklendi');
      } else {
        print('⚠️ Supabase\'de kayıtlı ilerleme bulunamadı (ilk giriş olabilir)');
      }
    } catch (e) {
      print('❌ Supabase yükleme hatası: $e');
    }
  }

  // Supabase'e TÜM progress bilgilerini kaydet (offline destekli)
  Future<void> _saveToSupabase() async {
    // Misafir modunda Supabase'e kaydetme
    if (_storage.isGuestMode()) {
      print('🚫 Misafir modu - Supabase\'e kaydedilmedi');
      return;
    }
    
    if (AuthService().currentUser == null) return;
    
    // Ders ilerlemesini Map'e çevir
    final progressMap = <String, dynamic>{};
    _progress.lessonProgress.forEach((key, value) {
      progressMap[key] = {
        'bestScore': value.bestScore,
        'isUnlocked': value.isUnlocked,
        'isCompleted': value.isCompleted,
      };
    });

    final syncData = {
      'lesson_progress': progressMap,
      'lives': _progress.lives,
      'total_score': _progress.totalScore,
      'streak': _progress.streak,
      'full_name': _fullName,
    };

    try {
      if (_syncService.isOnline) {
        print('💾 Supabase\'e kaydediliyor - ${progressMap.length} ders, Can: ${_progress.lives}, Puan: ${_progress.totalScore}, Seri: ${_progress.streak}');
        await _database.saveLessonProgress(
          progressMap,
          lives: _progress.lives,
          totalScore: _progress.totalScore,
          isPremium: _progress.isPremium,
          streak: _progress.streak,
          lastStudyDate: _progress.lastStudyDate,
          fullName: _fullName,
        );
        _lastError = null;
        print('📤 Supabase\'e TÜM ilerleme kaydedildi');
      } else {
        // Offline - queue'ya ekle
        throw NetworkException.noConnection();
      }
    } catch (e) {
      print('⚠️ Supabase kaydetme hatası: $e - Offline queue\'ya ekleniyor');
      _lastError = 'Veriler çevrimdışı kaydedildi';
      await _syncService.addPendingAction(SyncActionType.saveProgress, syncData);
    }
  }

  Future<void> decreaseLives() async {
    if (!_progress.isPremium) {
      print('📊 ProgressProvider - Önceki can: ${_progress.lives}');
      _progress.decreaseLives();
      print('📊 ProgressProvider - Yeni can: ${_progress.lives}');
      await _storage.saveProgress(_progress);
      await _saveToSupabase(); // Supabase'e de kaydet
      print('✅ ProgressProvider - Kaydedildi');
      notifyListeners();
    } else {
      print('⭐ ProgressProvider - Premium kullanıcı, can azalmadı');
    }
  }

  Future<void> setPremium(bool value) async {
    await _storage.setPremium(value);
    _progress = _storage.getProgress();
    notifyListeners();
  }

  Future<void> addScore(int points) async {
    await _storage.addScore(points);
    _progress = _storage.getProgress();
    await _saveToSupabase(); // Supabase'e de kaydet
    notifyListeners();
  }

  Future<void> completeLesson(String lessonKey, int score) async {
    // Önce mevcut puanı al
    final currentScore = _progress.totalScore;
    debugPrint('📊 completeLesson başladı - Mevcut puan: $currentScore, Eklenecek: $score');
    
    _progress.completeLesson(lessonKey, score);
    await _storage.saveProgress(_progress);
    
    // Progress'i yeniden yükle (addScore sonrası güncel değerleri al)
    _progress = _storage.getProgress();
    debugPrint('📊 completeLesson sonrası - Yeni puan: ${_progress.totalScore}');
    
    await _saveToSupabase(); // Supabase'e kaydet
    
    // Username al - önce fullName, yoksa profilden çek
    String? displayName = _fullName;
    if (displayName == null || displayName.isEmpty) {
      final user = AuthService().currentUser;
      if (user != null) {
        // Profilden ad-soyad çekmeyi dene
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .maybeSingle();
          if (profile != null && profile['full_name'] != null) {
            displayName = profile['full_name'] as String;
            _fullName = displayName; // Cache'le
          }
        } catch (e) {
          debugPrint('Profil çekme hatası: $e');
        }
        
        // Hala yoksa email kullan
        displayName ??= user.email?.split('@').first ?? 'Kullanici';
      }
    }
    
    // Leaderboard güncelle
    debugPrint('🏆 completeLesson -> Leaderboard güncelleniyor...');
    debugPrint('   Score: ${_progress.totalScore}, Words: ${_progress.totalCompletedLessons * 10}, Streak: ${_progress.streak}, Name: $displayName');
    
    try {
      await _leaderboardService.updateScore(
        score: _progress.totalScore,
        wordsLearned: _progress.totalCompletedLessons * 10, // Her derste 10 kelime
        streak: _progress.streak,
        username: displayName,
      );
      debugPrint('✅ Leaderboard güncelleme çağrısı tamamlandı');
    } catch (e) {
      debugPrint('❌ Leaderboard güncelleme hatası: $e');
    }
    
    // Başarı bildirimi
    if (_progress.totalCompletedLessons % 5 == 0) {
      await _notificationService.sendAchievementNotification(
        '🎉 Tebrikler!',
        '${_progress.totalCompletedLessons} ders tamamladınız!',
      );
    }
    
    notifyListeners();
  }

  Future<void> updateStreak() async {
    _progress.updateStreak();
    await _storage.saveProgress(_progress);
    await _saveToSupabase(); // Supabase'e kaydet
    
    // Seri uyarısı
    if (_progress.streak > 0 && _progress.streak % 7 == 0) {
      await _notificationService.sendAchievementNotification(
        '🔥 ${_progress.streak} Günlük Seri!',
        'Harika gidiyorsun! Serini korumaya devam et!',
      );
    }
    
    notifyListeners();
  }

  /// Tekrar edilecek kelimeleri al (Spaced Repetition)
  Future<List<String>> getDueWords() async {
    return _srService.getDueWords();
  }
  
  /// Tekrar edilecek kelime sayısı
  int get dueWordsCount => _srService.getDueWordsCount();

  Future<void> resetProgress() async {
    await _storage.reset();
    _progress = _storage.getProgress();
    notifyListeners();
  }

  bool canPlay() {
    return _progress.isPremium || _progress.lives > 0;
  }

  String getNextLifeTime() {
    if (_progress.isPremium) return 'Sınırsız';
    if (_progress.lives >= 5) return 'Dolu';

    final nextLife = _progress.lastLifeUpdate.add(const Duration(hours: 1));
    final diff = nextLife.difference(DateTime.now());
    
    if (diff.isNegative) return 'Hazır';
    
    final minutes = diff.inMinutes % 60;
    return '${minutes}dk';
  }

  Future<void> updateFullName(String newName) async {
    _fullName = newName;
    await _saveToSupabase(); // Supabase'e kaydet
    notifyListeners();
  }
}
