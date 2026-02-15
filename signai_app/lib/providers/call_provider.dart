/// ============================================
/// SignAI - Call Provider (Arama Yönetimi)
/// ============================================
/// WebRTC + AI Pipeline + Signaling
///
/// KAMERA MİMARİSİ (v2 - Tek Kamera):
/// ┌─────────────┐      ┌───────────────────┐
/// │ WebRTC      │─────>│ Karşı tarafa video │  (P2P stream)
/// │ getUserMedia│      └───────────────────┘
/// └──────┬──────┘
///        │ (aynı stream üzerinden pose detection)
///        ▼
/// ┌───────────────────┐      ┌─────────┐
/// │ ML Kit Pose Det.  │─────>│ Subtitle│
/// │ (frame by frame)  │      │ overlay │
/// └───────────────────┘      └─────────┘
///
/// v2'de TEK kamera stream'i kullanılır.
/// Camera package kaldırıldı — çift kamera çakışması önlendi.
/// ============================================

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/webrtc_service.dart';
import '../services/signaling_service.dart';
import '../services/sign_language_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/permission_service.dart';

class CallProvider with ChangeNotifier {
  final WebRTCService webrtc = WebRTCService();
  final SignalingService signaling = SignalingService();
  final SignLanguageService signLanguage = SignLanguageService();
  final SpeechToTextService speechToText = SpeechToTextService();

  // AI pipeline durumu
  bool _isAiRunning = false;

  // Online kullanıcılar
  final List<Map<String, dynamic>> _onlineUsers = [];
  List<Map<String, dynamic>> get onlineUsers => List.unmodifiable(_onlineUsers);

  // Aktif arama bilgisi
  String? _currentCallUserId;
  String? _currentCallUserName;
  String? get currentCallUserId => _currentCallUserId;
  String? get currentCallUserName => _currentCallUserName;

  // Altyazılar
  String _signSubtitle = '';
  String _speechSubtitle = '';
  String get signSubtitle => _signSubtitle;
  String get speechSubtitle => _speechSubtitle;

  // Gelen arama
  IncomingCall? _incomingCall;
  IncomingCall? get incomingCall => _incomingCall;
  bool get hasIncomingCall => _incomingCall != null;

  // AI durumu
  bool get isAiRunning => _isAiRunning;

  // Hata mesajı
  String? _lastError;
  String? get lastError => _lastError;

  // Başlatılma durumu
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Tüm servisleri başlat
  Future<void> initializeServices({
    String? token,
    String? userId,
    String? username,
  }) async {
    try {
      // Önce izinleri kontrol et
      final permissions = await PermissionService.requestAllPermissions();
      if (permissions['camera'] != true || permissions['microphone'] != true) {
        _lastError = 'Kamera ve mikrofon izinleri gerekli';
        debugPrint('❌ $_lastError');
        notifyListeners();
        return;
      }

      await webrtc.initialize();
      await signLanguage.initialize();

      // Konuşma izni varsa STT'yi başlat, yoksa sadece uyar
      if (permissions['speech'] == true) {
        await speechToText.initialize();
      } else {
        debugPrint('⚠️ Konuşma tanıma izni yok, STT devre dışı');
      }

      await signaling.connect(
        token: token,
        userId: userId,
        username: username,
      );

      _setupCallbacks();
      _isInitialized = true;
      _lastError = null;
      debugPrint('✅ Tüm servisler başlatıldı');
      notifyListeners();
    } catch (e) {
      _lastError = 'Servis başlatma hatası: $e';
      debugPrint('❌ $_lastError');
      notifyListeners();
    }
  }

  /// Callback'leri kur
  void _setupCallbacks() {
    // --- Signaling callback'leri ---
    signaling.onIncomingCall = (call) {
      _incomingCall = call;
      notifyListeners();
    };

    signaling.onCallAnswered = (answer) async {
      try {
        await webrtc.handleAnswer(answer);
      } catch (e) {
        debugPrint('❌ Answer işleme hatası: $e');
        _lastError = 'Bağlantı kurulamadı';
        notifyListeners();
      }
    };

    signaling.onCallRejected = (_) {
      _currentCallUserId = null;
      _currentCallUserName = null;
      webrtc.hangUp();
      notifyListeners();
    };

    signaling.onCallEnded = (_) {
      endCall(sendSignal: false);
    };

    signaling.onIceCandidate = (candidate) async {
      await webrtc.addIceCandidate(candidate);
    };

    signaling.onTypedSubtitle = (text, type, fromUserId) {
      if (type == 'sign') {
        _signSubtitle = text;
      } else {
        _speechSubtitle = text;
      }
      notifyListeners();
    };

    // Eski callback'i de tutuyoruz (uyumluluk için)
    signaling.onSubtitle = null;

    signaling.onUserOnline = (user) {
      if (!_onlineUsers.any((u) => u['userId'] == user['userId'])) {
        _onlineUsers.add(user);
        notifyListeners();
      }
    };

    signaling.onUserOffline = (user) {
      _onlineUsers.removeWhere((u) => u['userId'] == user['userId']);
      notifyListeners();
    };

    signaling.onOnlineUsers = (users) {
      _onlineUsers.clear();
      _onlineUsers.addAll(users);
      notifyListeners();
    };

    // Arama hatası (kullanıcı çevrimdışı, geçersiz ID vs.)
    signaling.onCallError = (message) {
      debugPrint('⚠️ Arama hatası: $message');
      _lastError = message;
      // Arama durumunu temizle
      _currentCallUserId = null;
      _currentCallUserName = null;
      webrtc.hangUp();
      notifyListeners();
    };

    // --- WebRTC callback'leri ---
    webrtc.onCallStateChanged = (state) {
      if (state == CallState.connected) {
        _startAiProcessing();
      } else if (state == CallState.ended) {
        _stopAiProcessing();
      }
      notifyListeners();
    };

    webrtc.onIceCandidate = (candidate) {
      if (_currentCallUserId != null) {
        signaling.sendIceCandidate(
          _currentCallUserId!,
          candidate.toMap(),
        );
      }
    };

    webrtc.onError = (errorMessage) {
      _lastError = errorMessage;
      notifyListeners();
    };

    // --- İşaret dili callback'leri ---
    signLanguage.onWordConfirmed = (word) {
      debugPrint('🤟 Kelime onaylandı: $word');
    };

    signLanguage.onSentenceFormed = (sentence) {
      _signSubtitle = sentence;
      if (_currentCallUserId != null) {
        signaling.sendSubtitle(_currentCallUserId!, sentence, type: 'sign');
      }
      notifyListeners();
    };

    // --- Konuşma tanıma callback'leri ---
    // NOT: speech_to_text YEREL mikrofonu dinler.
    // Bu cihazdaki kullanıcının sesini yazıya çevirir.
    // Yazıya çevrilen metin karşı tarafa altyazı olarak gönderilir.
    speechToText.onTextRecognized = (text, isFinal) {
      if (isFinal && text.isNotEmpty && _currentCallUserId != null) {
        signaling.sendSubtitle(_currentCallUserId!, text);
      }
      notifyListeners();
    };
  }

  // ============ AI İŞLEME ============

  Timer? _aiTimer;

  /// WebRTC local stream'den periyodik frame yakalayıp ML Kit'e gönderir.
  /// flutter_webrtc doğrudan raw frame callback sunmaz, bu yüzden
  /// `MediaStreamTrack.captureFrame()` ile RGBA frame yakalar,
  /// ardından dosya tabanlı InputImage oluşturup pose detection yaparız.
  void _startAiProcessing() {
    if (_isAiRunning) return;
    _isAiRunning = true;
    debugPrint('🤖 AI işleme başlatıldı');
    notifyListeners();

    // Her 200ms'de bir frame yakala ve işle
    _aiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _captureAndProcessFrame();
    });
  }

  bool _isCapturing = false;

  Future<void> _captureAndProcessFrame() async {
    if (!_isAiRunning || !signLanguage.isInitialized) return;
    if (_isCapturing) return; // Önceki frame hâlâ işleniyorsa atla
    _isCapturing = true;

    final localStream = webrtc.localStream;
    if (localStream == null) { _isCapturing = false; return; }

    final videoTracks = localStream.getVideoTracks();
    if (videoTracks.isEmpty) { _isCapturing = false; return; }

    try {
      // flutter_webrtc captureFrame() → encoded image (PNG) ByteBuffer
      final buffer = await videoTracks.first.captureFrame();
      final pngBytes = buffer.asUint8List();

      // PNG’yi bellekte decode et (disk I/O’dan kaçın)
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final width = image.width;
      final height = image.height;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();

      if (byteData == null) return;

      final rawBytes = byteData.buffer.asUint8List();

      // RGBA → InputImage (ML Kit BGRA8888 formatında bekler,
      // ancak RGBA ile de çalışır — pose detection için renk sırası önemsiz)
      final inputImage = InputImage.fromBytes(
        bytes: rawBytes,
        metadata: InputImageMetadata(
          size: ui.Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      // ML Kit Pose Detection ile işle
      await signLanguage.processFrame(inputImage);
    } catch (e) {
      // Frame yakalama her zaman başarılı olmayabilir
      debugPrint('⚠️ AI frame hatası: $e');
    } finally {
      _isCapturing = false;
    }
  }

  void _stopAiProcessing() {
    if (!_isAiRunning) return;
    _aiTimer?.cancel();
    _aiTimer = null;
    _isAiRunning = false;
    debugPrint('🤖 AI işleme durduruldu');
  }

  // ============ KULLANICI İŞLEMLERİ ============

  void registerUser(String userId, String username) {
    signaling.register(userId, username);
  }

  /// Arama başlat
  Future<void> startCall(String targetUserId, String targetUserName,
      String myUserId, String myUsername) async {
    try {
      _currentCallUserId = targetUserId;
      _currentCallUserName = targetUserName;
      _lastError = null;

      await webrtc.openUserMedia();
      final offer = await webrtc.createOffer();

      signaling.callUser(targetUserId, offer.toMap(), {
        'userId': myUserId,
        'username': myUsername,
      });

      await speechToText.startListening();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Arama başlatma hatası: $e');
      _lastError = 'Arama başlatılamadı: $e';
      _currentCallUserId = null;
      _currentCallUserName = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Gelen aramayı kabul et
  Future<void> acceptCall() async {
    if (_incomingCall == null) return;

    try {
      _currentCallUserId = _incomingCall!.callerId;
      _currentCallUserName = _incomingCall!.callerName;
      _lastError = null;

      await webrtc.openUserMedia();
      final answer = await webrtc.createAnswer(_incomingCall!.offer);
      signaling.answerCall(_currentCallUserId!, answer.toMap());

      _incomingCall = null;
      await speechToText.startListening();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Arama kabul hatası: $e');
      _lastError = 'Arama kabul edilemedi: $e';
      _currentCallUserId = null;
      _currentCallUserName = null;
      _incomingCall = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Gelen aramayı reddet
  void rejectCall() {
    if (_incomingCall == null) return;
    signaling.rejectCall(_incomingCall!.callerId);
    _incomingCall = null;
    notifyListeners();
  }

  /// Aramayı sonlandır
  /// [sendSignal] false ise karşı tarafa sinyal göndermez (zaten karşı taraftan geldi)
  Future<void> endCall({bool sendSignal = true}) async {
    try {
      if (sendSignal && _currentCallUserId != null) {
        signaling.endCall(_currentCallUserId!);
      }

      _stopAiProcessing();
      await webrtc.hangUp();
      await speechToText.stopListening();
      signLanguage.clearSentence();

      _currentCallUserId = null;
      _currentCallUserName = null;
      _signSubtitle = '';
      _speechSubtitle = '';
      _incomingCall = null;

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Arama sonlandırma hatası: $e');
    }
  }

  void toggleMic() {
    webrtc.toggleMic();
    notifyListeners();
  }

  void toggleCamera() {
    webrtc.toggleCamera();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await webrtc.switchCamera();
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Kaynakları temizle (dispose öncesi çağır)
  Future<void> cleanup() async {
    _stopAiProcessing();
    await webrtc.hangUp();
    signaling.disconnect();
    await signLanguage.dispose();
    await speechToText.stopListening();
  }

  @override
  void dispose() {
    _stopAiProcessing();
    signaling.disconnect();
    // Async kaynaklar cleanup() ile önceden temizlenmiş olmalı
    // Burada sadece senkron temizlik yapılır
    super.dispose();
  }
}
