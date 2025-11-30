import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

/// Gelişmiş Text-to-Speech servisi
/// İngilizce kelimelerin telaffuzunu destekler
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isAvailable = true;
  TtsState _ttsState = TtsState.stopped;
  
  // Ayarlar
  double _speechRate = 0.5;  // 0.0 - 1.0
  double _volume = 1.0;      // 0.0 - 1.0
  double _pitch = 1.0;       // 0.5 - 2.0
  String _language = 'en-US';
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPlaying => _ttsState == TtsState.playing;
  TtsState get state => _ttsState;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb || 
          defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        _flutterTts = FlutterTts();
        
        // Event listeners
        _flutterTts?.setStartHandler(() {
          _ttsState = TtsState.playing;
          notifyListeners();
        });
        
        _flutterTts?.setCompletionHandler(() {
          _ttsState = TtsState.stopped;
          notifyListeners();
        });
        
        _flutterTts?.setCancelHandler(() {
          _ttsState = TtsState.stopped;
          notifyListeners();
        });
        
        _flutterTts?.setErrorHandler((msg) {
          _ttsState = TtsState.stopped;
          if (kDebugMode) print('TTS Error: $msg');
          notifyListeners();
        });
        
        if (!kIsWeb) {
          await _flutterTts?.setLanguage(_language);
          await _flutterTts?.setSpeechRate(_speechRate);
          await _flutterTts?.setVolume(_volume);
          await _flutterTts?.setPitch(_pitch);
          
          // Android için engine ayarları
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _flutterTts?.setQueueMode(1); // Queue mode
          }
        }
        
        _isAvailable = true;
        print('🔊 TTS initialized successfully');
      } else {
        _isAvailable = false;
        print('⚠️ TTS not available on this platform');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TTS initialization error: $e');
      }
      _isAvailable = false;
    }

    _isInitialized = true;
  }

  /// Kelimeyi seslendir
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    
    if (!_isAvailable || _flutterTts == null) {
      if (kDebugMode) {
        print('🔇 TTS not available, would speak: $text');
      }
      return;
    }
    
    try {
      // Önceki seslendirmeyi durdur
      await stop();
      await _flutterTts?.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('❌ TTS speak error: $e');
      }
    }
  }

  /// Kelimeyi yavaş seslendir (öğrenme için)
  Future<void> speakSlow(String text) async {
    final originalRate = _speechRate;
    await setSpeechRate(0.3);
    await speak(text);
    // Biraz bekle ve eski hıza dön
    Future.delayed(const Duration(seconds: 2), () {
      setSpeechRate(originalRate);
    });
  }

  /// Kelimeyi hızlı seslendir
  Future<void> speakFast(String text) async {
    final originalRate = _speechRate;
    await setSpeechRate(0.7);
    await speak(text);
    Future.delayed(const Duration(seconds: 1), () {
      setSpeechRate(originalRate);
    });
  }

  /// Cümleyi seslendir (kelimeler arası doğal duraklama)
  Future<void> speakSentence(String sentence) async {
    if (!_isInitialized) await init();
    if (!_isAvailable || _flutterTts == null) return;
    
    try {
      // Cümle için normal hız kullan
      await _flutterTts?.setSpeechRate(0.45);
      await _flutterTts?.speak(sentence);
      // Sonra eski hıza dön
      await _flutterTts?.setSpeechRate(_speechRate);
    } catch (e) {
      if (kDebugMode) print('❌ TTS sentence error: $e');
    }
  }

  /// Seslendirmeyi durdur
  Future<void> stop() async {
    if (_isAvailable && _flutterTts != null) {
      try {
        await _flutterTts?.stop();
        _ttsState = TtsState.stopped;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('❌ TTS stop error: $e');
        }
      }
    }
  }

  /// Konuşma hızını ayarla (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_isAvailable && _flutterTts != null && !kIsWeb) {
      try {
        await _flutterTts?.setSpeechRate(_speechRate);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('❌ TTS setSpeechRate error: $e');
      }
    }
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isAvailable && _flutterTts != null && !kIsWeb) {
      try {
        await _flutterTts?.setVolume(_volume);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('❌ TTS setVolume error: $e');
      }
    }
  }

  /// Ses tonunu ayarla (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_isAvailable && _flutterTts != null && !kIsWeb) {
      try {
        await _flutterTts?.setPitch(_pitch);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('❌ TTS setPitch error: $e');
      }
    }
  }

  /// Dili değiştir
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_isAvailable && _flutterTts != null && !kIsWeb) {
      try {
        await _flutterTts?.setLanguage(_language);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('❌ TTS setLanguage error: $e');
      }
    }
  }

  /// Mevcut dilleri getir
  Future<List<String>> getLanguages() async {
    if (_isAvailable && _flutterTts != null) {
      try {
        final languages = await _flutterTts?.getLanguages;
        return List<String>.from(languages ?? []);
      } catch (e) {
        if (kDebugMode) print('❌ TTS getLanguages error: $e');
      }
    }
    return ['en-US', 'en-GB'];
  }

  /// Mevcut sesleri getir
  Future<List<Map<String, String>>> getVoices() async {
    if (_isAvailable && _flutterTts != null) {
      try {
        final voices = await _flutterTts?.getVoices;
        return List<Map<String, String>>.from(
          (voices as List?)?.map((v) => Map<String, String>.from(v)) ?? [],
        );
      } catch (e) {
        if (kDebugMode) print('❌ TTS getVoices error: $e');
      }
    }
    return [];
  }
}
