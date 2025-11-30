import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class FavoritesProvider with ChangeNotifier {
  static const String _boxName = 'favorites';
  static const String _categoriesBoxName = 'favorite_categories';
  late Box<String> _favoritesBox;
  late Box<Map<dynamic, dynamic>> _categoriesBox;
  bool _isInitialized = false;
  final DatabaseService _database = DatabaseService();
  final StorageService _storage = StorageService();

  Set<String> get favorites => _favoritesBox.values.toSet();
  Map<String, String> _wordCategories = {}; // wordId -> categoryName
  bool get isInitialized => _isInitialized; // ✅ Public getter
  
  // Kategoriler
  List<String> get categories => ['Tümü', 'Zor Kelimeler', 'Çalışılacaklar', 'Önemli'];
  
  // Kullanıcıya özel box adı
  String _getUserBoxName(String baseName) {
    final isGuest = _storage.isGuestMode();
    if (isGuest) {
      print('🔑 Favorites Box: ${baseName}_guest (Misafir)');
      return '${baseName}_guest';
    } else {
      final userId = AuthService().currentUser?.id;
      if (userId != null) {
        print('🔑 Favorites Box: ${baseName}_$userId (User)');
        return '${baseName}_$userId';
      }
      return baseName;
    }
  }
  
  // Kategoriye göre favorileri getir
  Set<String> getFavoritesByCategory(String category) {
    if (category == 'Tümü') return favorites;
    return favorites.where((wordId) => _wordCategories[wordId] == category).toSet();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    
    final favBoxName = _getUserBoxName(_boxName);
    final catBoxName = _getUserBoxName(_categoriesBoxName);
    
    _favoritesBox = await Hive.openBox<String>(favBoxName);
    _categoriesBox = await Hive.openBox<Map>(catBoxName);
    
    // Kategorileri yükle
    _loadCategories();
    
    // Supabase'den favorileri senkronize et
    await _syncFromSupabase();
    
    _isInitialized = true;
    notifyListeners();
  }
  
  // Kullanıcı değiştiğinde yeniden yükle
  Future<void> reinitialize() async {
    _isInitialized = false;
    _wordCategories.clear();
    await init();
    print('🔄 FavoritesProvider yeniden yüklendi');
  }
  
  void _loadCategories() {
    for (var key in _categoriesBox.keys) {
      final data = _categoriesBox.get(key);
      if (data != null) {
        _wordCategories[key.toString()] = data['category'].toString();
      }
    }
  }
  
  // Supabase'den favorileri çek ve local ile birleştir
  Future<void> _syncFromSupabase() async {
    // Misafir modunda Supabase'den çekme
    if (_storage.isGuestMode()) {
      print('🚫 Misafir modu - Supabase\'den çekilmedi');
      return;
    }
    
    try {
      final remoteFavoritesWithCategories = await _database.getFavoritesWithCategories();
      
      // Remote'ta olup local'de olmayan favorileri ekle
      for (final entry in remoteFavoritesWithCategories) {
        final wordId = entry['word_id'] as String;
        final category = entry['category'] as String?;
        
        if (!_favoritesBox.containsKey(wordId)) {
          await _favoritesBox.put(wordId, wordId);
        }
        
        // Kategoriyi güncelle
        if (category != null && category != 'all') {
          _wordCategories[wordId] = category;
          await _categoriesBox.put(wordId, {'category': category});
        }
      }
      
      // Local'de olup remote'ta olmayan favorileri Supabase'e ekle
      final remoteWordIds = remoteFavoritesWithCategories.map((e) => e['word_id'] as String).toSet();
      for (final wordId in _favoritesBox.values) {
        if (!remoteWordIds.contains(wordId)) {
          try {
            final category = _wordCategories[wordId];
            await _database.addFavorite(wordId, category: category);
          } catch (e) {
            print('Favori ekleme hatası: $e');
          }
        }
      }
      
      print('✅ Favoriler senkronize edildi - Toplam: ${_favoritesBox.length}');
    } catch (e) {
      print('❌ Favori senkronizasyon hatası: $e');
    }
  }

  bool isFavorite(String lessonId) {
    return _favoritesBox.containsKey(lessonId);
  }

  Future<void> toggleFavorite(String lessonId, {String category = 'Tümü'}) async {
    if (isFavorite(lessonId)) {
      await _favoritesBox.delete(lessonId);
      _wordCategories.remove(lessonId);
      await _categoriesBox.delete(lessonId);
      
      // Supabase'den de sil (misafir değilse)
      if (!_storage.isGuestMode()) {
        try {
          await _database.removeFavorite(lessonId);
        } catch (e) {
          print('❌ Supabase favori silme hatası: $e');
        }
      }
    } else {
      await _favoritesBox.put(lessonId, lessonId);
      
      // Kategoriyi kaydet
      final actualCategory = category == 'Tümü' ? null : category;
      if (actualCategory != null) {
        _wordCategories[lessonId] = actualCategory;
        await _categoriesBox.put(lessonId, {'category': actualCategory});
      }
      
      // Supabase'e de ekle (misafir değilse)
      if (!_storage.isGuestMode()) {
        try {
          await _database.addFavorite(lessonId, category: actualCategory);
        } catch (e) {
          print('❌ Supabase favori ekleme hatası: $e');
        }
      }
    }
    notifyListeners();
  }
  
  // Kategorisini değiştir
  Future<void> setCategory(String wordId, String category) async {
    if (category == 'Tümü') {
      _wordCategories.remove(wordId);
      await _categoriesBox.delete(wordId);
      
      // Supabase'de kategorisini 'all' yap (misafir değilse)
      if (!_storage.isGuestMode()) {
        try {
          await _database.updateFavoriteCategory(wordId, 'all');
        } catch (e) {
          print('❌ Supabase kategori güncelleme hatası: $e');
        }
      }
    } else {
      _wordCategories[wordId] = category;
      await _categoriesBox.put(wordId, {'category': category});
      
      // Supabase'de kategorisini güncelle (misafir değilse)
      if (!_storage.isGuestMode()) {
        try {
          await _database.updateFavoriteCategory(wordId, category);
        } catch (e) {
          print('❌ Supabase kategori güncelleme hatası: $e');
        }
      }
    }
    notifyListeners();
  }
  
  String? getCategory(String wordId) {
    return _wordCategories[wordId];
  }

  Future<void> removeFavorite(String lessonId) async {
    await _favoritesBox.delete(lessonId);
    _wordCategories.remove(lessonId);
    await _categoriesBox.delete(lessonId);
    
    // Supabase'den de sil (misafir değilse)
    if (!_storage.isGuestMode()) {
      try {
        await _database.removeFavorite(lessonId);
      } catch (e) {
        print('❌ Supabase favori silme hatası: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> clearAll() async {
    // Local'i temizle
    final allFavorites = _favoritesBox.values.toList();
    await _favoritesBox.clear();
    await _categoriesBox.clear();
    _wordCategories.clear();
    
    // Supabase'den de temizle
    try {
      for (final wordId in allFavorites) {
        await _database.removeFavorite(wordId);
      }
    } catch (e) {
      print('❌ Supabase favorileri temizleme hatası: $e');
    }
    
    notifyListeners();
  }

  int get count => _favoritesBox.length;
}
