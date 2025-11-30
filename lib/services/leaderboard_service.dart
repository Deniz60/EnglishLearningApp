import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Leaderboard (Liderlik Tablosu) Servisi
class LeaderboardService extends ChangeNotifier {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  static const String _cacheBoxName = 'leaderboard_cache';
  
  Box? _cacheBox;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;
  String? _errorMessage;
  
  List<LeaderboardEntry> _dailyLeaderboard = [];
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  List<LeaderboardEntry> _allTimeLeaderboard = [];
  
  LeaderboardEntry? _currentUserEntry;
  int? _currentUserRank;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<LeaderboardEntry> get dailyLeaderboard => _dailyLeaderboard;
  List<LeaderboardEntry> get weeklyLeaderboard => _weeklyLeaderboard;
  List<LeaderboardEntry> get monthlyLeaderboard => _monthlyLeaderboard;
  List<LeaderboardEntry> get allTimeLeaderboard => _allTimeLeaderboard;
  LeaderboardEntry? get currentUserEntry => _currentUserEntry;
  int? get currentUserRank => _currentUserRank;

  Future<void> init({String? userId}) async {
    // userId verilmediyse AuthService'den al
    final effectiveUserId = userId ?? AuthService().currentUser?.id;
    
    if (_isInitialized && _currentUserId == effectiveUserId) return;
    
    _currentUserId = effectiveUserId;
    debugPrint('🏆 LeaderboardService init - userId: $_currentUserId');

    try {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _loadFromCache();
      _isInitialized = true;
      debugPrint('LeaderboardService initialized');
      
      await refresh();
    } catch (e) {
      debugPrint('LeaderboardService init error: $e');
      _isInitialized = true;
    }
  }
  
  /// Kullanıcı değiştiğinde çağır
  void setUserId(String? userId) {
    _currentUserId = userId;
    debugPrint('🏆 LeaderboardService userId updated: $_currentUserId');
  }

  void _loadFromCache() {
    try {
      final dailyCache = _cacheBox?.get('daily');
      final weeklyCache = _cacheBox?.get('weekly');
      final monthlyCache = _cacheBox?.get('monthly');
      final allTimeCache = _cacheBox?.get('allTime');

      if (dailyCache != null) {
        _dailyLeaderboard = _parseEntries(dailyCache);
      }
      if (weeklyCache != null) {
        _weeklyLeaderboard = _parseEntries(weeklyCache);
      }
      if (monthlyCache != null) {
        _monthlyLeaderboard = _parseEntries(monthlyCache);
      }
      if (allTimeCache != null) {
        _allTimeLeaderboard = _parseEntries(allTimeCache);
      }
    } catch (e) {
      debugPrint('Load from cache error: $e');
    }
  }

  List<LeaderboardEntry> _parseEntries(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      if (e is Map) {
        return LeaderboardEntry.fromMap(Map<String, dynamic>.from(e));
      }
      return null;
    }).whereType<LeaderboardEntry>().toList();
  }

  Future<void> _saveToCache() async {
    try {
      await _cacheBox?.put('daily', _dailyLeaderboard.map((e) => e.toMap()).toList());
      await _cacheBox?.put('weekly', _weeklyLeaderboard.map((e) => e.toMap()).toList());
      await _cacheBox?.put('monthly', _monthlyLeaderboard.map((e) => e.toMap()).toList());
      await _cacheBox?.put('allTime', _allTimeLeaderboard.map((e) => e.toMap()).toList());
      await _cacheBox?.put('lastUpdate', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Save to cache error: $e');
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchLeaderboard(LeaderboardPeriod.daily),
        _fetchLeaderboard(LeaderboardPeriod.weekly),
        _fetchLeaderboard(LeaderboardPeriod.monthly),
        _fetchLeaderboard(LeaderboardPeriod.allTime),
      ]);
      
      if (_currentUserId != null && !_currentUserId!.startsWith('guest_')) {
        await _fetchCurrentUserRank();
      }
      
      await _saveToCache();
    } catch (e) {
      debugPrint('Refresh leaderboard error: $e');
      _errorMessage = 'Liderlik tablosu güncellenemedi';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchLeaderboard(LeaderboardPeriod period) async {
    try {
      DateTime? startDate;
      final now = DateTime.now();
      
      switch (period) {
        case LeaderboardPeriod.daily:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case LeaderboardPeriod.weekly:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case LeaderboardPeriod.monthly:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case LeaderboardPeriod.allTime:
          startDate = null;
          break;
      }

      var query = Supabase.instance.client
          .from('leaderboard')
          .select('user_id, username, avatar_url, score, words_learned, streak, updated_at');
      
      if (startDate != null) {
        query = query.gte('updated_at', startDate.toIso8601String());
      }
      
      final response = await query
          .order('score', ascending: false)
          .limit(100);

      final entries = (response as List).asMap().entries.map((entry) {
        final data = entry.value as Map<String, dynamic>;
        return LeaderboardEntry(
          rank: entry.key + 1,
          userId: data['user_id'] ?? '',
          username: data['username'] ?? 'Anonim',
          avatarUrl: data['avatar_url'],
          score: data['score'] ?? 0,
          wordsLearned: data['words_learned'] ?? 0,
          streak: data['streak'] ?? 0,
          updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();

      switch (period) {
        case LeaderboardPeriod.daily:
          _dailyLeaderboard = entries;
          break;
        case LeaderboardPeriod.weekly:
          _weeklyLeaderboard = entries;
          break;
        case LeaderboardPeriod.monthly:
          _monthlyLeaderboard = entries;
          break;
        case LeaderboardPeriod.allTime:
          _allTimeLeaderboard = entries;
          break;
      }
    } catch (e) {
      debugPrint('Fetch leaderboard error ($period): $e');
    }
  }

  Future<void> _fetchCurrentUserRank() async {
    if (_currentUserId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('leaderboard')
          .select('user_id, username, avatar_url, score, words_learned, streak')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (response != null) {
        final userScore = response['score'] ?? 0;
        
        final rankResponse = await Supabase.instance.client
            .from('leaderboard')
            .select('user_id')
            .gt('score', userScore);
        
        _currentUserRank = (rankResponse as List).length + 1;
        
        _currentUserEntry = LeaderboardEntry(
          rank: _currentUserRank!,
          userId: _currentUserId!,
          username: response['username'] ?? 'Sen',
          avatarUrl: response['avatar_url'],
          score: userScore,
          wordsLearned: response['words_learned'] ?? 0,
          streak: response['streak'] ?? 0,
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Fetch current user rank error: $e');
    }
  }

  Future<void> updateScore({
    required int score,
    required int wordsLearned,
    required int streak,
    String? username,
    String? avatarUrl,
  }) async {
    // userId yoksa AuthService'den al
    _currentUserId ??= AuthService().currentUser?.id;
    
    debugPrint('🏆 updateScore called - userId: $_currentUserId, score: $score');
    
    if (_currentUserId == null) {
      debugPrint('❌ updateScore failed: userId is null');
      return;
    }
    
    if (_currentUserId!.startsWith('guest_')) {
      debugPrint('⚠️ updateScore skipped: guest user');
      return;
    }

    try {
      debugPrint('📤 Sending to Supabase leaderboard...');
      await Supabase.instance.client.from('leaderboard').upsert(
        {
          'user_id': _currentUserId,
          'username': username ?? 'Kullanici',
          'avatar_url': avatarUrl,
          'score': score,
          'words_learned': wordsLearned,
          'streak': streak,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      debugPrint('✅ Leaderboard updated successfully!');

      await _fetchCurrentUserRank();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Update score error: $e');
    }
  }

  Future<void> addToScore(int points) async {
    if (_currentUserEntry == null) return;
    
    await updateScore(
      score: _currentUserEntry!.score + points,
      wordsLearned: _currentUserEntry!.wordsLearned,
      streak: _currentUserEntry!.streak,
      username: _currentUserEntry!.username,
      avatarUrl: _currentUserEntry!.avatarUrl,
    );
  }

  List<LeaderboardEntry> getLeaderboard(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return _dailyLeaderboard;
      case LeaderboardPeriod.weekly:
        return _weeklyLeaderboard;
      case LeaderboardPeriod.monthly:
        return _monthlyLeaderboard;
      case LeaderboardPeriod.allTime:
        return _allTimeLeaderboard;
    }
  }

  bool isCurrentUser(String userId) {
    return _currentUserId == userId;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final int score;
  final int wordsLearned;
  final int streak;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.score,
    required this.wordsLearned,
    required this.streak,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      rank: map['rank'] ?? 0,
      userId: map['user_id'] ?? '',
      username: map['username'] ?? 'Anonim',
      avatarUrl: map['avatar_url'],
      score: map['score'] ?? 0,
      wordsLearned: map['words_learned'] ?? 0,
      streak: map['streak'] ?? 0,
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'score': score,
      'words_learned': wordsLearned,
      'streak': streak,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank.';
    }
  }

  String get formattedScore {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
