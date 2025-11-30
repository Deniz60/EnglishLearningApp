import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı bilgisi
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Supabase'i başlat
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: kDebugMode,
    );
  }

  // Kayıt ol
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        if (kDebugMode) {
          print('✅ Kullanıcı kaydedildi: ${response.user!.email}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Kayıt hatası: $e');
      }
      rethrow;
    }
  }

  // Giriş yap
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (kDebugMode) {
          print('✅ Giriş başarılı: ${response.user!.email}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Giriş hatası: $e');
      }
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) {
        print('✅ Çıkış yapıldı');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Çıkış hatası: $e');
      }
      rethrow;
    }
  }

  // Şifre sıfırlama emaili gönder
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (kDebugMode) {
        print('✅ Şifre sıfırlama emaili gönderildi: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Şifre sıfırlama hatası: $e');
      }
      rethrow;
    }
  }

  // Kullanıcı profilini getir
  Future<UserProfile?> getUserProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profil getirme hatası: $e');
      }
      return null;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);

      if (kDebugMode) {
        print('✅ Profil güncellendi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profil güncelleme hatası: $e');
      }
      rethrow;
    }
  }

  // Email doğrulandı mı kontrol et
  bool get isEmailConfirmed {
    return currentUser?.emailConfirmedAt != null;
  }

  // Doğrulama emaili tekrar gönder
  Future<void> resendConfirmationEmail() async {
    try {
      final email = currentUser?.email;
      if (email == null) throw Exception('Kullanıcı bulunamadı');

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (kDebugMode) {
        print('✅ Doğrulama emaili tekrar gönderildi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email gönderme hatası: $e');
      }
      rethrow;
    }
  }

  // Kullanıcı emailini değiştir
  Future<void> updateEmail(String newEmail) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (kDebugMode) {
        print('✅ Email güncellendi: $newEmail');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email güncelleme hatası: $e');
      }
      rethrow;
    }
  }

  // Şifreyi değiştir
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (kDebugMode) {
        print('✅ Şifre güncellendi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Şifre güncelleme hatası: $e');
      }
      rethrow;
    }
  }

  // Hesabı sil
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      // Supabase auth kullanıcısını sil (cascade delete ile tüm veriler silinir)
      await _supabase.rpc('delete_user');

      if (kDebugMode) {
        print('✅ Hesap silindi');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Hesap silme hatası: $e');
      }
      rethrow;
    }
  }
}
