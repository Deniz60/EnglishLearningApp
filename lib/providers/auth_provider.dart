import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../models/user_profile.dart';
import '../utils/exceptions.dart' as app_exceptions;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _isGuest;
  bool get isGuest => _isGuest;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    }

    // Auth state değişikliklerini dinle
    _authService.authStateChanges.listen((AuthState data) {
      final session = data.session;
      _currentUser = session?.user;
      
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Profile load error: $e');
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      
      // Kullanıcı profilini ve rolünü yükle
      await _loadUserProfile();
      
      // Gerçek kullanıcı girişi yapıldı, misafir modunu kapat ve misafir verilerini sil
      _isGuest = false;
      await _storage.saveGuestMode(false);
      await _storage.clearGuestProgress();
      await _storage.clearGuestFavorites();
      
      // Bekleyen senkronizasyonları çalıştır
      await SyncService().syncPendingActions();
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      // Hata tipine göre kullanıcı dostu mesaj
      final authError = app_exceptions.AuthException.fromSupabase(e);
      _errorMessage = authError.userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String? fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      // Gerçek kullanıcı kayıdı yapıldı, misafir modunu kapat ve misafir verilerini sil
      _isGuest = false;
      await _storage.saveGuestMode(false);
      await _storage.clearGuestProgress();
      await _storage.clearGuestFavorites();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Hata tipine göre kullanıcı dostu mesaj
      final authError = app_exceptions.AuthException.fromSupabase(e);
      _errorMessage = authError.userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
      _isGuest = false;
      await _storage.saveGuestMode(false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _authService.updateUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Misafir girişi
  Future<void> guestLogin() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Önce Supabase'den çıkış yap (eğer giriş yapılmışsa)
      if (_currentUser != null) {
        await _authService.signOut();
        _currentUser = null;
      }
      
      // Eski misafir verilerini sil (temiz başlangıç için)
      await _storage.clearGuestProgress();
      await _storage.clearGuestFavorites();
      
      // Misafir olarak işaretle
      _isGuest = true;
      await _storage.saveGuestMode(true);
      
      // Misafir profil oluştur
      _userProfile = UserProfile(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'misafir@kullanici.com',
        fullName: 'Misafir Kullanıcı',
        isPremium: false,
      );
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Misafir modundan gerçek hesaba geçiş
  Future<void> convertGuestToUser(String email, String password, String fullName) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Yeni hesap oluştur
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      // Misafir modunu kapat
      _isGuest = false;
      await _storage.saveGuestMode(false);
      
      // Kullanıcı bilgilerini yükle
      await _loadUserProfile();
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Misafir kontrolü (uygulama başlangıcında)
  Future<void> checkGuestMode() async {
    final isGuestMode = await _storage.isGuestMode();
    if (isGuestMode) {
      _isGuest = true;
      _userProfile = UserProfile(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'misafir@kullanici.com',
        fullName: 'Misafir Kullanıcı',
        isPremium: false,
      );
      notifyListeners();
    }
  }
}
