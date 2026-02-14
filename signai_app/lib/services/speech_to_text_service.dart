/// ============================================
/// SignAI - Konuşmadan Metne Çevirme Servisi
/// ============================================
/// YEREL mikrofonu dinleyerek bu cihazdaki
/// kullanıcının sesini yazıya çevirir.
/// Yazıya çevrilen metin signaling üzerinden
/// karşı tarafa altyazı olarak gönderilir.
///
/// NOT: WebRTC remote audio stream'ini doğrudan
/// STT'ye beslemek mümkün olmadığından, her iki
/// tarafta da yerel mikrofon dinlenir ve altyazı
/// karşılıklı paylaşılır.
/// ============================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Konuşma tanıma durumları
enum SpeechState {
  notInitialized,
  ready,
  listening,
  paused,
  error,
}

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Durum
  SpeechState _state = SpeechState.notInitialized;
  bool _isInitialized = false;
  String _currentText = '';
  String _lastFinalText = '';
  String _selectedLocale = 'tr_TR'; // Varsayılan Türkçe

  // Tüm konuşma geçmişi
  final List<String> _transcriptHistory = [];

  // Callback'ler
  Function(String text, bool isFinal)? onTextRecognized;
  Function(SpeechState)? onStateChanged;
  Function(String)? onError;

  // Getter'lar
  SpeechState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get isListening => _state == SpeechState.listening;
  String get currentText => _currentText;
  String get lastFinalText => _lastFinalText;
  List<String> get transcriptHistory => List.unmodifiable(_transcriptHistory);
  String get selectedLocale => _selectedLocale;

  /// Servisi başlat
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        _updateState(SpeechState.ready);
        debugPrint('🎙️ Speech-to-Text servisi başlatıldı');

        // Mevcut dilleri listele
        final locales = await _speech.locales();
        debugPrint('🌍 Mevcut diller: ${locales.map((l) => l.localeId).join(', ')}');

        // Türkçe varsa seç
        final turkishLocale = locales.firstWhere(
          (l) => l.localeId.startsWith('tr'),
          orElse: () => locales.first,
        );
        _selectedLocale = turkishLocale.localeId;
        debugPrint('🌍 Seçilen dil: $_selectedLocale');
      } else {
        _updateState(SpeechState.error);
        debugPrint('❌ Speech-to-Text başlatılamadı');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Speech-to-Text başlatma hatası: $e');
      _updateState(SpeechState.error);
      return false;
    }
  }

  /// Dinlemeye başla
  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Speech servisi başlatılmamış');
      return;
    }

    if (_state == SpeechState.listening) {
      debugPrint('⚠️ Zaten dinleniyor');
      return;
    }

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: _selectedLocale,
        listenMode: stt.ListenMode.dictation, // Sürekli dinleme modu
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 30), // 30 saniye dinle, sonra yeniden başla
      );

      _updateState(SpeechState.listening);
      debugPrint('🎙️ Dinleme başladı');
    } catch (e) {
      debugPrint('❌ Dinleme başlatma hatası: $e');
      _updateState(SpeechState.error);
    }
  }

  /// Dinlemeyi durdur
  Future<void> stopListening() async {
    if (_state != SpeechState.listening) return;

    try {
      await _speech.stop();
      _updateState(SpeechState.ready);
      debugPrint('🎙️ Dinleme durduruldu');
    } catch (e) {
      debugPrint('❌ Dinleme durdurma hatası: $e');
    }
  }

  /// Dinlemeyi aç/kapa
  Future<void> toggleListening() async {
    if (_state == SpeechState.listening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Dili değiştir
  void setLocale(String localeId) {
    _selectedLocale = localeId;
    debugPrint('🌍 Dil değiştirildi: $localeId');

    // Eğer dinliyorsa, yeniden başlat
    if (_state == SpeechState.listening) {
      stopListening().then((_) => startListening());
    }
  }

  /// Mevcut dilleri getir
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) return [];
    return _speech.locales();
  }

  /// Konuşma tanıma sonucu
  void _onResult(SpeechRecognitionResult result) {
    _currentText = result.recognizedWords;

    if (result.finalResult) {
      // Kesinleşmiş sonuç
      _lastFinalText = _currentText;
      if (_currentText.isNotEmpty) {
        _transcriptHistory.add(_currentText);
      }
      onTextRecognized?.call(_currentText, true);
      debugPrint('📝 Kesin metin: $_currentText');

      // Otomatik yeniden dinlemeye başla
      _autoRestart();
    } else {
      // Geçici sonuç (henüz konuşma devam ediyor)
      onTextRecognized?.call(_currentText, false);
    }
  }

  /// Dinleme otomatik yeniden başlatma
  int _restartCount = 0;
  static const int _maxAutoRestarts = 100; // Sonsuz döngüyü engelle

  Future<void> _autoRestart() async {
    if (_restartCount >= _maxAutoRestarts) {
      debugPrint('⚠️ Maksimum otomatik yeniden başlatma sayısına ulaşıldı');
      _restartCount = 0;
      return;
    }

    // Kısa bir bekleme sonrası yeniden başla
    await Future.delayed(const Duration(milliseconds: 500));
    if (_state == SpeechState.listening || _state == SpeechState.ready) {
      _restartCount++;
      await startListening();
    }
  }

  /// Durum değişikliği
  void _onStatus(String status) {
    debugPrint('🎙️ Speech durumu: $status');

    switch (status) {
      case 'listening':
        _updateState(SpeechState.listening);
        break;
      case 'notListening':
        if (_state != SpeechState.error) {
          _updateState(SpeechState.ready);
        }
        break;
      case 'done':
        _updateState(SpeechState.ready);
        break;
    }
  }

  /// Hata
  void _onError(SpeechRecognitionError error) {
    debugPrint('❌ Speech hatası: ${error.errorMsg} (${error.permanent})');

    if (error.permanent) {
      _updateState(SpeechState.error);
    }

    onError?.call(error.errorMsg);
  }

  /// Durumu güncelle
  void _updateState(SpeechState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  /// Geçmişi temizle
  void clearHistory() {
    _transcriptHistory.clear();
    _currentText = '';
    _lastFinalText = '';
  }

  /// Tüm geçmişi birleştir
  String getFullTranscript() {
    return _transcriptHistory.join('. ');
  }

  /// Servisi kapat
  Future<void> dispose() async {
    await _speech.stop();
    await _speech.cancel();
    _isInitialized = false;
    _updateState(SpeechState.notInitialized);
    debugPrint('🎙️ Speech-to-Text servisi kapatıldı');
  }
}
