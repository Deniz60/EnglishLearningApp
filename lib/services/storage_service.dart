import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_progress.dart';
import 'auth_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _progressBoxName = 'user_progress';
  static const String _progressKey = 'progress'; // Default key for migration
  static const String _settingsBoxName = 'settings';
  static const String _guestModeKey = 'is_guest';

  late Box<UserProgress> _progressBox;
  late Box _settingsBox;

  // Kullanıcıya özel key oluştur
  String _getUserProgressKey() {
    final isGuest = isGuestMode();
    if (isGuest) {
      print('🔑 Progress Key: progress_guest (Misafir)');
      return 'progress_guest';
    } else {
      final userId = AuthService().currentUser?.id;
      final key = userId != null ? 'progress_$userId' : _progressKey;
      print('🔑 Progress Key: $key (User ID: $userId)');
      return key;
    }
  }

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(LessonGroupProgressAdapter());
    
    _progressBox = await Hive.openBox<UserProgress>(_progressBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  UserProgress getProgress() {
    final key = _getUserProgressKey();
    return _progressBox.get(key) ?? UserProgress();
  }

  Future<void> saveProgress(UserProgress progress) async {
    final key = _getUserProgressKey();
    await _progressBox.put(key, progress);
  }

  Future<void> updateLives(int lives) async {
    final progress = getProgress();
    progress.lives = lives;
    progress.lastLifeUpdate = DateTime.now();
    await saveProgress(progress);
  }

  Future<void> setPremium(bool isPremium) async {
    final progress = getProgress();
    progress.isPremium = isPremium;
    if (isPremium) {
      progress.lives = 50; // Premium'da 50 can
    }
    await saveProgress(progress);
  }

  Future<void> addScore(int points) async {
    final progress = getProgress();
    progress.addScore(points);
    await saveProgress(progress);
  }

  Future<void> regenerateLives() async {
    final progress = getProgress();
    progress.regenerateLives();
    await saveProgress(progress);
  }

  Future<void> reset() async {
    final key = _getUserProgressKey();
    await _progressBox.delete(key);
  }

  // Misafir progress'ini sil
  Future<void> clearGuestProgress() async {
    await _progressBox.delete('progress_guest');
    print('🗑️ Misafir progress silindi');
  }

  // Misafir favorilerini sil
  Future<void> clearGuestFavorites() async {
    try {
      final favBox = await Hive.openBox<String>('favorites_guest');
      await favBox.clear();
      await favBox.close();
      print('🗑️ Misafir favorileri silindi');
    } catch (e) {
      print('⚠️ Misafir favorileri silme hatası: $e');
    }
    
    try {
      final catBox = await Hive.openBox<Map>('favorite_categories_guest');
      await catBox.clear();
      await catBox.close();
      print('🗑️ Misafir favori kategorileri silindi');
    } catch (e) {
      print('⚠️ Misafir favori kategorileri silme hatası: $e');
    }
  }

  // Guest mode methods
  Future<void> saveGuestMode(bool isGuest) async {
    await _settingsBox.put(_guestModeKey, isGuest);
  }

  bool isGuestMode() {
    return _settingsBox.get(_guestModeKey, defaultValue: false) as bool;
  }
}