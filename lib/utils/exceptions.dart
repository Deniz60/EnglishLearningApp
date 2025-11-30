/// Uygulama genelinde kullanılan özel exception sınıfları
library;

/// Temel uygulama exception'ı
abstract class AppException implements Exception {
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Ağ bağlantısı hataları
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.userMessage = 'İnternet bağlantınızı kontrol edin',
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.noConnection() => const NetworkException(
        'No internet connection',
        userMessage: 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
      );

  factory NetworkException.timeout() => const NetworkException(
        'Connection timeout',
        userMessage: 'Bağlantı zaman aşımına uğradı. Tekrar deneyin.',
      );

  factory NetworkException.serverError([dynamic error]) => NetworkException(
        'Server error: $error',
        userMessage: 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.',
        originalError: error,
      );
}

/// Kimlik doğrulama hataları
class AuthException extends AppException {
  final AuthErrorType type;

  const AuthException(
    super.message, {
    this.type = AuthErrorType.unknown,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.invalidCredentials() => const AuthException(
        'Invalid credentials',
        type: AuthErrorType.invalidCredentials,
        userMessage: 'E-posta veya şifre hatalı',
      );

  factory AuthException.emailNotConfirmed() => const AuthException(
        'Email not confirmed',
        type: AuthErrorType.emailNotConfirmed,
        userMessage: 'E-posta adresinizi doğrulayın',
      );

  factory AuthException.userNotFound() => const AuthException(
        'User not found',
        type: AuthErrorType.userNotFound,
        userMessage: 'Kullanıcı bulunamadı',
      );

  factory AuthException.emailAlreadyExists() => const AuthException(
        'Email already exists',
        type: AuthErrorType.emailAlreadyExists,
        userMessage: 'Bu e-posta adresi zaten kullanılıyor',
      );

  factory AuthException.weakPassword() => const AuthException(
        'Weak password',
        type: AuthErrorType.weakPassword,
        userMessage: 'Şifre çok zayıf. En az 6 karakter kullanın',
      );

  factory AuthException.sessionExpired() => const AuthException(
        'Session expired',
        type: AuthErrorType.sessionExpired,
        userMessage: 'Oturum süresi doldu. Tekrar giriş yapın',
      );

  factory AuthException.fromSupabase(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('invalid login credentials') ||
        errorMessage.contains('invalid_credentials')) {
      return AuthException.invalidCredentials();
    }
    if (errorMessage.contains('email not confirmed')) {
      return AuthException.emailNotConfirmed();
    }
    if (errorMessage.contains('user not found')) {
      return AuthException.userNotFound();
    }
    if (errorMessage.contains('already registered') ||
        errorMessage.contains('already exists')) {
      return AuthException.emailAlreadyExists();
    }
    if (errorMessage.contains('weak password') ||
        errorMessage.contains('password')) {
      return AuthException.weakPassword();
    }

    return AuthException(
      error.toString(),
      userMessage: 'Giriş yapılamadı. Lütfen tekrar deneyin.',
      originalError: error,
    );
  }
}

enum AuthErrorType {
  invalidCredentials,
  emailNotConfirmed,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  sessionExpired,
  unknown,
}

/// Veri yükleme hataları
class DataException extends AppException {
  final DataErrorType type;

  const DataException(
    super.message, {
    this.type = DataErrorType.unknown,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  factory DataException.loadFailed([dynamic error]) => DataException(
        'Data load failed: $error',
        type: DataErrorType.loadFailed,
        userMessage: 'Veriler yüklenemedi. Tekrar deneyin.',
        originalError: error,
      );

  factory DataException.saveFailed([dynamic error]) => DataException(
        'Data save failed: $error',
        type: DataErrorType.saveFailed,
        userMessage: 'Veriler kaydedilemedi.',
        originalError: error,
      );

  factory DataException.notFound() => const DataException(
        'Data not found',
        type: DataErrorType.notFound,
        userMessage: 'Veri bulunamadı.',
      );

  factory DataException.corrupted() => const DataException(
        'Data corrupted',
        type: DataErrorType.corrupted,
        userMessage: 'Veri bozuk. Uygulama yeniden yüklenecek.',
      );

  factory DataException.cacheExpired() => const DataException(
        'Cache expired',
        type: DataErrorType.cacheExpired,
        userMessage: 'Önbellek süresi doldu. Veriler güncelleniyor...',
      );
}

enum DataErrorType {
  loadFailed,
  saveFailed,
  notFound,
  corrupted,
  cacheExpired,
  unknown,
}

/// Depolama hataları
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.userMessage = 'Depolama hatası oluştu',
    super.originalError,
    super.stackTrace,
  });

  factory StorageException.readFailed([dynamic error]) => StorageException(
        'Storage read failed: $error',
        userMessage: 'Veriler okunamadı.',
        originalError: error,
      );

  factory StorageException.writeFailed([dynamic error]) => StorageException(
        'Storage write failed: $error',
        userMessage: 'Veriler kaydedilemedi.',
        originalError: error,
      );

  factory StorageException.boxNotFound(String boxName) => StorageException(
        'Box not found: $boxName',
        userMessage: 'Veri kutusu bulunamadı.',
      );
}

/// Oyun/Quiz hataları
class GameException extends AppException {
  const GameException(
    super.message, {
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  factory GameException.noLives() => const GameException(
        'No lives remaining',
        userMessage: 'Canınız kalmadı! Canlarınızın yenilenmesini bekleyin.',
      );

  factory GameException.lessonLocked() => const GameException(
        'Lesson is locked',
        userMessage: 'Bu ders henüz açılmadı. Önceki dersi tamamlayın.',
      );

  factory GameException.invalidAnswer() => const GameException(
        'Invalid answer',
        userMessage: 'Geçersiz cevap.',
      );
}

/// Senkronizasyon hataları
class SyncException extends AppException {
  final SyncErrorType type;

  const SyncException(
    super.message, {
    this.type = SyncErrorType.unknown,
    super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  factory SyncException.uploadFailed([dynamic error]) => SyncException(
        'Upload failed: $error',
        type: SyncErrorType.uploadFailed,
        userMessage: 'Senkronizasyon başarısız. Veriler yerel olarak kaydedildi.',
        originalError: error,
      );

  factory SyncException.downloadFailed([dynamic error]) => SyncException(
        'Download failed: $error',
        type: SyncErrorType.downloadFailed,
        userMessage: 'Veriler indirilemiyor. Çevrimdışı mod kullanılıyor.',
        originalError: error,
      );

  factory SyncException.conflict() => const SyncException(
        'Sync conflict',
        type: SyncErrorType.conflict,
        userMessage: 'Veri çakışması tespit edildi.',
      );
}

enum SyncErrorType {
  uploadFailed,
  downloadFailed,
  conflict,
  unknown,
}
