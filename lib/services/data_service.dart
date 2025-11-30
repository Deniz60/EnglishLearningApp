import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Lesson> _allLessons = [];
  bool _isLoaded = false;
  bool _useSupabase = true;
  
  // Cache ayarları
  static const String _cacheBoxName = 'lessons_cache';
  static const String _cacheKey = 'lessons_data';
  static const String _cacheTimeKey = 'cache_timestamp';
  static const String _cacheVersionKey = 'cache_version';
  static const String _currentVersion = '1.0.0'; // Version değiştiğinde cache silinir
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const int _minLessonCount = 3000;
  
  Box? _cacheBox;

  Future<void> loadData() async {
    print('📥 loadData çağrıldı - _isLoaded: $_isLoaded');
    if (_isLoaded && _allLessons.isNotEmpty) {
      print('✅ Veriler zaten yüklü, tekrar yüklenmiyor');
      return;
    }

    // Cache box'ı aç
    await _initCache();

    try {
      // 1. Önce cache'den kontrol et
      if (_isCacheValid() && _hasSufficientData()) {
        print('⚡ Cache\'den yükleniyor...');
        _loadFromCache();
        _isLoaded = true;
        
        // Arka planda güncelleme
        _refreshInBackground();
        return;
      }

      // 2. Cache geçersiz veya yok, Supabase'den yükle
      if (_useSupabase) {
        await _loadFromSupabase();
      } else {
        await _loadFromJson();
      }
      _isLoaded = true;
      print('✅ Veriler yüklendi: ${_allLessons.length} kelime');
    } catch (e) {
      print('❌ Supabase hatası, JSON\'a geçiliyor: $e');
      _useSupabase = false;
      await _loadFromJson();
      _isLoaded = true;
    }
  }

  Future<void> _initCache() async {
    if (_cacheBox == null) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      
      // Version kontrolü - versiyon değiştiyse cache'i temizle
      final cachedVersion = _cacheBox?.get(_cacheVersionKey);
      if (cachedVersion != _currentVersion) {
        print('🔄 Yeni versiyon, cache temizleniyor...');
        await _cacheBox?.clear();
        await _cacheBox?.put(_cacheVersionKey, _currentVersion);
      }
    }
  }

  bool _isCacheValid() {
    final cacheTime = _cacheBox?.get(_cacheTimeKey);
    if (cacheTime == null) return false;
    
    try {
      final lastUpdate = DateTime.parse(cacheTime as String);
      final isValid = DateTime.now().difference(lastUpdate) < _cacheValidDuration;
      if (isValid) {
        print('✅ Cache geçerli (${DateTime.now().difference(lastUpdate).inHours} saat önce)');
      }
      return isValid;
    } catch (e) {
      return false;
    }
  }

  bool _hasSufficientData() {
    if (_allLessons.isEmpty) {
      _loadFromCache();
    }
    return _allLessons.length >= _minLessonCount;
  }

  void _loadFromCache() {
    final cachedData = _cacheBox?.get(_cacheKey);
    if (cachedData != null && cachedData is List) {
      _allLessons = cachedData.map((e) {
        return Lesson.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList();
      print('⚡ Cache\'den ${_allLessons.length} kelime yüklendi');
      notifyListeners();
    }
  }

  Future<void> _refreshInBackground() async {
    print('🔄 Arka planda güncelleme kontrol ediliyor...');
    try {
      await _loadFromSupabase();
    } catch (e) {
      print('⚠️ Arka plan güncellemesi başarısız: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      // Validasyon
      if (_allLessons.length < _minLessonCount) {
        print('⚠️ Eksik veri (${_allLessons.length}/$_minLessonCount), cache\'e yazılmadı');
        return;
      }

      // Cache'e kaydet
      final lessonMaps = _allLessons.map((lesson) => {
        'id': lesson.id,
        'english': lesson.english,
        'turkish': lesson.turkish,
        'level': lesson.level,
      }).toList();

      await _cacheBox?.put(_cacheKey, lessonMaps);
      await _cacheBox?.put(_cacheTimeKey, DateTime.now().toIso8601String());
      print('💾 ${_allLessons.length} kelime cache\'e kaydedildi');
    } catch (e) {
      print('❌ Cache kaydetme hatası: $e');
    }
  }

  // Manuel yenileme (kullanıcı isterse)
  Future<void> forceRefresh() async {
    print('🔄 Manuel yenileme başlatıldı...');
    _isLoaded = false;
    await _cacheBox?.delete(_cacheTimeKey);
    await loadData();
  }

  Future<void> _loadFromSupabase() async {
    print('📡 Supabase\'den veriler yükleniyor...');
    
    // Supabase'in default limiti 1000, pagination ile tüm veriyi çekelim
    List<Lesson> allLessons = [];
    int offset = 0;
    const int batchSize = 1000;
    bool hasMore = true;
    
    while (hasMore) {
      final response = await Supabase.instance.client
          .from('lessons')
          .select()
          .order('word_order', ascending: true)
          .range(offset, offset + batchSize - 1);
      
      final batch = (response as List).map((json) {
        return Lesson.fromJson({
          'id': json['id'],
          'english': json['english'],
          'turkish': json['turkish'],
          'level': json['level'],
        });
      }).toList();
      
      allLessons.addAll(batch);
      
      if (batch.length < batchSize) {
        hasMore = false;
      } else {
        offset += batchSize;
      }
      
      print('  ↓ ${allLessons.length} kelime yüklendi...');
    }
    
    _allLessons = allLessons;
    print('✅ Supabase\'den ${_allLessons.length} kelime yüklendi');
    
    // Cache'e kaydet
    await _saveToCache();
    notifyListeners();
  }

  Future<void> _loadFromJson() async {
    print('📁 JSON dosyalarından veriler yükleniyor...');
    
    final levels = ['a1', 'a2', 'b1', 'b2'];
    List<Lesson> allLessons = [];

    for (String level in levels) {
      try {
        final String jsonString = await rootBundle.loadString('assets/data/${level}Json.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        
        final lessons = jsonList.map((json) {
          json['level'] = level.toUpperCase();
          json['id'] = '${level}_${json['id'] ?? allLessons.length}';
          return Lesson.fromJson(json);
        }).toList();

        allLessons.addAll(lessons);
      } catch (e) {
        print('Error loading $level: $e');
      }
    }

    _allLessons = allLessons;
    notifyListeners();
  }

  // Lazy initialization metodu - login ekranından çağrılacak
  Future<void> ensureInitialized() async {
    print('🔍 ensureInitialized çağrıldı - _isLoaded: $_isLoaded, Kelime sayısı: ${_allLessons.length}');
    if (_isLoaded && _allLessons.isNotEmpty) {
      print('✅ Veriler zaten yüklü');
      return;
    }
    print('🔄 Veriler yükleniyor...');
    await _initCache();
    await loadData();
    print('✅ ensureInitialized tamamlandı - Kelime sayısı: ${_allLessons.length}');
  }

  List<Lesson> getAllLessons() => _allLessons;

  List<Lesson> getLessonsByLevel(String level) {
    return _allLessons.where((lesson) => lesson.level == level.toUpperCase()).toList();
  }

  Lesson? getLessonById(String id) {
    try {
      return _allLessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Lesson> getRandomLessons(String level, int count) {
    final levelLessons = getLessonsByLevel(level);
    levelLessons.shuffle();
    return levelLessons.take(count).toList();
  }

  // Yeni metodlar: Oyun türü bazlı sabit dersler

  // Bir seviyede kaç ders grubu var? (Oyun türüne göre)
  int getLessonGroupCount(String level, {String gameType = 'multiple_choice'}) {
    final lessons = getLessonsByLevel(level);
    final wordsPerLesson = gameType == 'word_matching' ? 6 : 10;
    return (lessons.length / wordsPerLesson).ceil();
  }

  // Belirli bir ders grubunun kelimelerini getir (sabit, tekrar etmez)
  List<Lesson> getLessonGroup(String level, int groupIndex, {String gameType = 'multiple_choice'}) {
    final lessons = getLessonsByLevel(level);
    final wordsPerLesson = gameType == 'word_matching' ? 6 : 10;
    final startIndex = groupIndex * wordsPerLesson;
    final endIndex = (startIndex + wordsPerLesson).clamp(0, lessons.length);
    
    if (startIndex >= lessons.length) return [];
    
    // Sabit sıralama - her zaman aynı kelimeler
    return lessons.sublist(startIndex, endIndex);
  }

  // Ders grubu anahtarı oluştur (yeni format)
  String getLessonGroupKey(String level, int groupIndex, String gameType) {
    return '${level}_${groupIndex}_$gameType';
  }
}
