import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase database işlemleri için basit wrapper
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Lesson Progress (user_settings tablosunda tutuluyor)
  Future<Map<String, dynamic>?> getLessonProgress() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      print('🔍 getLessonProgress - userId: $userId');
      if (userId == null) return null;

      final response = await _supabase
          .from('user_settings')
          .select('lesson_progress, lives, total_score, is_premium, streak, last_study_date, full_name')
          .eq('user_id', userId)
          .maybeSingle();

      print('📦 Supabase response: $response');
      
      if (response == null) {
        print('⚠️ user_settings tablosunda kayıt bulunamadı!');
        return null;
      }
      
      final result = {
        'lesson_progress': response['lesson_progress'] as Map<String, dynamic>?,
        'lives': response['lives'],
        'total_score': response['total_score'],
        'is_premium': response['is_premium'],
        'streak': response['streak'],
        'last_study_date': response['last_study_date'] != null 
            ? DateTime.tryParse(response['last_study_date'].toString())
            : null,
        'full_name': response['full_name'],
      };
      
      print('✅ Parsed result - total_score: ${result['total_score']}, streak: ${result['streak']}, lessons: ${(result['lesson_progress'] as Map?)?.length ?? 0}');
      return result;
    } catch (e) {
      print('❌ getLessonProgress error: $e');
      return null;
    }
  }

  Future<void> saveLessonProgress(
    Map<String, dynamic> progress, {
    int? lives,
    int? totalScore,
    bool? isPremium,
    int? streak,
    DateTime? lastStudyDate,
    String? fullName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'user_id': userId,
        'lesson_progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (lives != null) data['lives'] = lives;
      if (totalScore != null) data['total_score'] = totalScore;
      if (streak != null) data['streak'] = streak;
      if (lastStudyDate != null) data['last_study_date'] = lastStudyDate.toIso8601String();
      if (fullName != null) data['full_name'] = fullName;

      await _supabase.from('user_settings').upsert(data);
    } catch (e) {
      print('❌ saveLessonProgress error: $e');
    }
  }

  // Favorites
  Future<List<Map<String, dynamic>>> getFavoritesWithCategories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favorites')
          .select('word_id, category')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ getFavoritesWithCategories error: $e');
      return [];
    }
  }

  Future<void> addFavorite(String wordId, {String? category}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('favorites').upsert({
        'user_id': userId,
        'word_id': wordId,
        'category': category ?? 'all',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ addFavorite error: $e');
    }
  }

  Future<void> removeFavorite(String wordId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('word_id', wordId);
    } catch (e) {
      print('❌ removeFavorite error: $e');
    }
  }

  Future<void> updateFavoriteCategory(String wordId, String category) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('favorites')
          .update({'category': category})
          .eq('user_id', userId)
          .eq('word_id', wordId);
    } catch (e) {
      print('❌ updateFavoriteCategory error: $e');
    }
  }

  // Quiz Results (eğer gerekirse)
  Future<void> saveQuizResult({
    String? level,
    String? lessonId,
    int? score,
    int? totalQuestions,
    int? correctAnswers,
    int? pointsEarned,
    bool? passed,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Quiz sonuçlarını user_settings'e veya ayrı tabloya kaydedebiliriz
      // Şimdilik sadece log basalım
      print('📊 Quiz Result: ${level ?? lessonId} - $pointsEarned pts, $correctAnswers/$totalQuestions correct');
    } catch (e) {
      print('❌ saveQuizResult error: $e');
    }
  }
}
