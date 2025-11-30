import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/exceptions.dart';
import '../utils/constants.dart';

/// Uygulama genelinde hata yönetimi için merkezi servis
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Global error stream for listening to errors
  final _errorController = StreamController<AppException>.broadcast();
  Stream<AppException> get errorStream => _errorController.stream;

  // Son hata (UI'da göstermek için)
  AppException? _lastError;
  AppException? get lastError => _lastError;

  /// Exception'ı yakala ve işle
  Future<T?> handle<T>({
    required Future<T> Function() action,
    T? fallback,
    bool showError = true,
    BuildContext? context,
    String? customMessage,
  }) async {
    try {
      return await action();
    } on NetworkException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } on AuthException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } on DataException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } on StorageException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } on SyncException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } on GameException catch (e) {
      _handleError(e, context, showError, customMessage);
      return fallback;
    } catch (e, stackTrace) {
      // Bilinmeyen hatalar
      final exception = DataException(
        e.toString(),
        userMessage: customMessage ?? 'Beklenmeyen bir hata oluştu',
        originalError: e,
        stackTrace: stackTrace,
      );
      _handleError(exception, context, showError, customMessage);
      return fallback;
    }
  }

  /// Sync operasyonu için özel handler (offline queue'ya ekler)
  Future<T?> handleSync<T>({
    required Future<T> Function() action,
    required Future<void> Function() onOffline,
    T? fallback,
    BuildContext? context,
  }) async {
    try {
      return await action();
    } on NetworkException {
      // Offline durumda queue'ya ekle
      await onOffline();
      _showInfo(context, 'Çevrimdışı mod: Veriler senkronize edilecek');
      return fallback;
    } catch (e) {
      await onOffline();
      return fallback;
    }
  }

  void _handleError(
    AppException error,
    BuildContext? context,
    bool showError,
    String? customMessage,
  ) {
    _lastError = error;
    _errorController.add(error);

    // Log error
    _logError(error);

    // UI'da göster
    if (showError && context != null && context.mounted) {
      showErrorSnackBar(
        context,
        customMessage ?? error.userMessage ?? error.message,
        error: error,
      );
    }
  }

  void _logError(AppException error) {
    print('❌ [${error.runtimeType}] ${error.message}');
    if (error.originalError != null) {
      print('   Original: ${error.originalError}');
    }
    if (error.stackTrace != null) {
      print('   Stack: ${error.stackTrace}');
    }
  }

  /// Hata SnackBar'ı göster
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    AppException? error,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Tekrar Dene',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Başarı SnackBar'ı göster
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Bilgi SnackBar'ı göster
  static void _showInfo(BuildContext? context, String message) {
    if (context == null || !context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Uyarı SnackBar'ı göster
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Senkronizasyon durumu göster
  static void showSyncStatus(BuildContext context, {required bool isOnline}) {
    if (!context.mounted) return;
    
    final message = isOnline 
        ? 'Çevrimiçi - Veriler senkronize ediliyor'
        : 'Çevrimdışı - Veriler yerel olarak kaydedildi';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isOnline ? AppColors.success : AppColors.warning,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Loading dialog göster
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Yükleniyor...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading dialog'u kapat
  static void hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Stream'i kapat (uygulama kapanırken)
  void dispose() {
    _errorController.close();
  }
}

/// Result wrapper - hata veya başarı durumunu tutar
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(AppException error) => Result._(error: error, isSuccess: false);

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error ?? DataException('Unknown error'));
  }
}
