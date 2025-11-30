import 'package:flutter_test/flutter_test.dart';
import 'package:english_learning_app/utils/exceptions.dart';

void main() {
  group('AppException Tests', () {
    group('NetworkException', () {
      test('noConnection should have correct message', () {
        final exception = NetworkException.noConnection();
        expect(exception.message, 'No internet connection');
        expect(exception.userMessage, 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
      });

      test('timeout should have correct message', () {
        final exception = NetworkException.timeout();
        expect(exception.message, 'Connection timeout');
        expect(exception.userMessage, 'Bağlantı zaman aşımına uğradı. Tekrar deneyin.');
      });

      test('serverError should include original error', () {
        final originalError = Exception('Server 500');
        final exception = NetworkException.serverError(originalError);
        expect(exception.originalError, originalError);
        expect(exception.userMessage, 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.');
      });
    });

    group('AuthException', () {
      test('invalidCredentials should have correct type', () {
        final exception = AuthException.invalidCredentials();
        expect(exception.type, AuthErrorType.invalidCredentials);
        expect(exception.userMessage, 'E-posta veya şifre hatalı');
      });

      test('emailAlreadyExists should have correct type', () {
        final exception = AuthException.emailAlreadyExists();
        expect(exception.type, AuthErrorType.emailAlreadyExists);
        expect(exception.userMessage, 'Bu e-posta adresi zaten kullanılıyor');
      });

      test('weakPassword should have correct type', () {
        final exception = AuthException.weakPassword();
        expect(exception.type, AuthErrorType.weakPassword);
        expect(exception.userMessage, 'Şifre çok zayıf. En az 6 karakter kullanın');
      });

      test('fromSupabase should parse invalid credentials', () {
        final exception = AuthException.fromSupabase('Invalid login credentials');
        expect(exception.type, AuthErrorType.invalidCredentials);
      });

      test('fromSupabase should parse email already exists', () {
        final exception = AuthException.fromSupabase('User already registered');
        expect(exception.type, AuthErrorType.emailAlreadyExists);
      });

      test('fromSupabase should handle unknown errors', () {
        final exception = AuthException.fromSupabase('Some unknown error');
        expect(exception.type, AuthErrorType.unknown);
        expect(exception.userMessage, 'Giriş yapılamadı. Lütfen tekrar deneyin.');
      });
    });

    group('DataException', () {
      test('loadFailed should have correct type', () {
        final exception = DataException.loadFailed('Network error');
        expect(exception.type, DataErrorType.loadFailed);
        expect(exception.userMessage, 'Veriler yüklenemedi. Tekrar deneyin.');
      });

      test('saveFailed should have correct type', () {
        final exception = DataException.saveFailed();
        expect(exception.type, DataErrorType.saveFailed);
        expect(exception.userMessage, 'Veriler kaydedilemedi.');
      });

      test('notFound should have correct type', () {
        final exception = DataException.notFound();
        expect(exception.type, DataErrorType.notFound);
      });

      test('cacheExpired should have correct type', () {
        final exception = DataException.cacheExpired();
        expect(exception.type, DataErrorType.cacheExpired);
        expect(exception.userMessage, 'Önbellek süresi doldu. Veriler güncelleniyor...');
      });
    });

    group('StorageException', () {
      test('readFailed should have correct message', () {
        final exception = StorageException.readFailed('Box not found');
        expect(exception.userMessage, 'Veriler okunamadı.');
      });

      test('writeFailed should have correct message', () {
        final exception = StorageException.writeFailed();
        expect(exception.userMessage, 'Veriler kaydedilemedi.');
      });

      test('boxNotFound should include box name', () {
        final exception = StorageException.boxNotFound('user_progress');
        expect(exception.message, 'Box not found: user_progress');
      });
    });

    group('GameException', () {
      test('noLives should have correct message', () {
        final exception = GameException.noLives();
        expect(exception.message, 'No lives remaining');
        expect(exception.userMessage, 'Canınız kalmadı! Canlarınızın yenilenmesini bekleyin.');
      });

      test('lessonLocked should have correct message', () {
        final exception = GameException.lessonLocked();
        expect(exception.userMessage, 'Bu ders henüz açılmadı. Önceki dersi tamamlayın.');
      });
    });

    group('SyncException', () {
      test('uploadFailed should have correct type', () {
        final exception = SyncException.uploadFailed('Timeout');
        expect(exception.type, SyncErrorType.uploadFailed);
        expect(exception.userMessage, 'Senkronizasyon başarısız. Veriler yerel olarak kaydedildi.');
      });

      test('downloadFailed should have correct type', () {
        final exception = SyncException.downloadFailed();
        expect(exception.type, SyncErrorType.downloadFailed);
      });

      test('conflict should have correct type', () {
        final exception = SyncException.conflict();
        expect(exception.type, SyncErrorType.conflict);
        expect(exception.userMessage, 'Veri çakışması tespit edildi.');
      });
    });
  });

  group('Exception toString', () {
    test('AppException toString should include message', () {
      final exception = NetworkException.noConnection();
      expect(exception.toString(), contains('AppException'));
    });
  });
}
