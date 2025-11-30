import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/exceptions.dart';

/// Çevrimdışı senkronizasyon için pending action türleri
enum SyncActionType {
  saveProgress,
  addFavorite,
  removeFavorite,
  updateFavoriteCategory,
  saveQuizResult,
}

/// Bekleyen senkronizasyon aksiyonu
class PendingAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  PendingAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
        id: json['id'] as String,
        type: SyncActionType.values[json['type'] as int],
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );

  PendingAction copyWithRetry() => PendingAction(
        id: id,
        type: type,
        data: data,
        createdAt: createdAt,
        retryCount: retryCount + 1,
      );
}

/// Çevrimdışı senkronizasyon servisi
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _syncBoxName = 'sync_queue';
  static const String _pendingActionsKey = 'pending_actions';
  static const int _maxRetries = 3;
  static const Duration _syncInterval = Duration(minutes: 5);

  late Box _syncBox;
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isOnline = true;

  // Stream controllers
  final _onlineStatusController = StreamController<bool>.broadcast();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<bool> get onlineStatus => _onlineStatusController.stream;
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _getPendingActions().length;

  /// Servisi başlat
  Future<void> init() async {
    if (_isInitialized) return;

    _syncBox = await Hive.openBox(_syncBoxName);
    _isInitialized = true;

    // Bağlantı durumunu kontrol et
    await _checkConnectivity();

    // Periyodik senkronizasyon başlat
    _startPeriodicSync();

    // Varsa bekleyen aksiyonları senkronize et
    if (_isOnline && pendingCount > 0) {
      await syncPendingActions();
    }

    print('✅ SyncService initialized - Pending: $pendingCount, Online: $_isOnline');
  }

  /// Bağlantı durumunu kontrol et
  Future<void> _checkConnectivity() async {
    try {
      // Supabase'e basit bir istek at
      await Supabase.instance.client
          .from('user_settings')
          .select('user_id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      _setOnlineStatus(true);
    } catch (e) {
      _setOnlineStatus(false);
    }
  }

  void _setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _onlineStatusController.add(isOnline);
      notifyListeners();
      print(isOnline ? '🌐 Online' : '📴 Offline');
    }
  }

  /// Periyodik senkronizasyon başlat
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await _checkConnectivity();
      if (_isOnline && pendingCount > 0) {
        await syncPendingActions();
      }
    });
  }

  /// Pending action ekle
  Future<void> addPendingAction(SyncActionType type, Map<String, dynamic> data) async {
    final action = PendingAction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${type.name}',
      type: type,
      data: data,
    );

    final actions = _getPendingActions();
    
    // Aynı tip ve aynı key için olanı güncelle (duplicate önleme)
    final existingIndex = actions.indexWhere((a) => 
      a.type == type && _isSameAction(a, action));
    
    if (existingIndex != -1) {
      actions[existingIndex] = action;
    } else {
      actions.add(action);
    }

    await _savePendingActions(actions);
    notifyListeners();

    print('📝 Pending action added: ${type.name} (Total: ${actions.length})');

    // Hemen senkronize etmeyi dene
    if (_isOnline) {
      await syncPendingActions();
    }
  }

  bool _isSameAction(PendingAction a, PendingAction b) {
    switch (a.type) {
      case SyncActionType.saveProgress:
        return true; // Progress her zaman tek
      case SyncActionType.addFavorite:
      case SyncActionType.removeFavorite:
      case SyncActionType.updateFavoriteCategory:
        return a.data['wordId'] == b.data['wordId'];
      case SyncActionType.saveQuizResult:
        return a.data['lessonId'] == b.data['lessonId'];
    }
  }

  /// Tüm bekleyen aksiyonları senkronize et
  Future<SyncResult> syncPendingActions() async {
    if (_isSyncing) {
      return SyncResult(success: 0, failed: 0, pending: pendingCount);
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    notifyListeners();

    final actions = _getPendingActions();
    int successCount = 0;
    int failedCount = 0;
    final remainingActions = <PendingAction>[];

    print('🔄 Syncing ${actions.length} pending actions...');

    for (final action in actions) {
      try {
        await _executeAction(action);
        successCount++;
        print('✅ Synced: ${action.type.name}');
      } catch (e) {
        print('❌ Sync failed: ${action.type.name} - $e');
        
        if (action.retryCount < _maxRetries) {
          remainingActions.add(action.copyWithRetry());
        } else {
          failedCount++;
          print('🚫 Max retries reached for: ${action.type.name}');
        }
      }
    }

    await _savePendingActions(remainingActions);

    _isSyncing = false;
    _syncStatusController.add(
      remainingActions.isEmpty ? SyncStatus.completed : SyncStatus.partiallyCompleted,
    );
    notifyListeners();

    print('📊 Sync result: $successCount success, $failedCount failed, ${remainingActions.length} pending');

    return SyncResult(
      success: successCount,
      failed: failedCount,
      pending: remainingActions.length,
    );
  }

  /// Tek bir aksiyonu çalıştır
  Future<void> _executeAction(PendingAction action) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      throw SyncException.uploadFailed('User not authenticated');
    }

    switch (action.type) {
      case SyncActionType.saveProgress:
        await supabase.from('user_settings').upsert({
          'user_id': userId,
          'lesson_progress': action.data['lesson_progress'],
          'lives': action.data['lives'],
          'total_score': action.data['total_score'],
          'streak': action.data['streak'],
          'updated_at': DateTime.now().toIso8601String(),
        });
        break;

      case SyncActionType.addFavorite:
        await supabase.from('favorites').upsert({
          'user_id': userId,
          'word_id': action.data['wordId'],
          'category': action.data['category'] ?? 'all',
          'created_at': DateTime.now().toIso8601String(),
        });
        break;

      case SyncActionType.removeFavorite:
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('word_id', action.data['wordId']);
        break;

      case SyncActionType.updateFavoriteCategory:
        await supabase
            .from('favorites')
            .update({'category': action.data['category']})
            .eq('user_id', userId)
            .eq('word_id', action.data['wordId']);
        break;

      case SyncActionType.saveQuizResult:
        // Quiz sonuçlarını kaydet (opsiyonel tablo)
        print('📊 Quiz result synced: ${action.data}');
        break;
    }
  }

  /// Pending actions'ları al
  List<PendingAction> _getPendingActions() {
    final jsonList = _syncBox.get(_pendingActionsKey, defaultValue: <String>[]) as List;
    return jsonList
        .map((json) => PendingAction.fromJson(
            Map<String, dynamic>.from(jsonDecode(json as String) as Map)))
        .toList();
  }

  /// Pending actions'ları kaydet
  Future<void> _savePendingActions(List<PendingAction> actions) async {
    final jsonList = actions.map((a) => jsonEncode(a.toJson())).toList();
    await _syncBox.put(_pendingActionsKey, jsonList);
  }

  /// Tüm pending actions'ları temizle
  Future<void> clearPendingActions() async {
    await _syncBox.delete(_pendingActionsKey);
    notifyListeners();
    print('🗑️ Pending actions cleared');
  }

  /// Bağlantı durumunu manuel kontrol et
  Future<void> checkConnection() async {
    await _checkConnectivity();
    if (_isOnline && pendingCount > 0) {
      await syncPendingActions();
    }
  }

  /// Servisi kapat
  @override
  void dispose() {
    _syncTimer?.cancel();
    _onlineStatusController.close();
    _syncStatusController.close();
    super.dispose();
  }
}

/// Senkronizasyon durumu
enum SyncStatus {
  idle,
  syncing,
  completed,
  partiallyCompleted,
  failed,
}

/// Senkronizasyon sonucu
class SyncResult {
  final int success;
  final int failed;
  final int pending;

  const SyncResult({
    required this.success,
    required this.failed,
    required this.pending,
  });

  bool get isFullyCompleted => failed == 0 && pending == 0;

  @override
  String toString() => 'SyncResult(success: $success, failed: $failed, pending: $pending)';
}

/// Connectivity mixin - Provider'larda kullanmak için
mixin ConnectivityAware {
  final SyncService _syncService = SyncService();

  bool get isOnline => _syncService.isOnline;
  int get pendingActionsCount => _syncService.pendingCount;

  /// Online olduğunda aksiyon yap, offline ise queue'ya ekle
  Future<void> executeWithSync({
    required Future<void> Function() onlineAction,
    required SyncActionType syncType,
    required Map<String, dynamic> syncData,
  }) async {
    try {
      if (_syncService.isOnline) {
        await onlineAction();
      } else {
        throw NetworkException.noConnection();
      }
    } on NetworkException {
      await _syncService.addPendingAction(syncType, syncData);
    } catch (e) {
      // Diğer hatalar için de queue'ya ekle
      await _syncService.addPendingAction(syncType, syncData);
      rethrow;
    }
  }
}
