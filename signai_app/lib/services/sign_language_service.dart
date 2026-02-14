/// ============================================
/// SignAI - İşaret Dili AI Servisi (v2)
/// ============================================
/// Kameradan gelen frame'leri gerçek zamanlı işler.
/// ML Kit Pose Detection ile vücut noktalarını algılar.
/// 10 temel Türk İşaret Dili hareketini tanır.
///
/// ALGILANAN 10 HAREKET:
/// ┌─────┬──────────────┬────────────────────────────────────────┐
/// │  #  │   Hareket    │ Nasıl Yapılır                          │
/// ├─────┼──────────────┼────────────────────────────────────────┤
/// │  1  │ Merhaba      │ Sağ el baş üstünde, kol kalkık        │
/// │  2  │ Teşekkürler  │ Sağ el çeneden aşağı doğru iner       │
/// │  3  │ Evet         │ Baş + sağ yumruk aşağı iner           │
/// │  4  │ Hayır        │ Sağ işaret parmağı sağa sola sallanır  │
/// │  5  │ Yardım       │ İki el yukarı kalkık                  │
/// │  6  │ Yemek        │ Sağ el ağza doğru gelir               │
/// │  7  │ Su           │ Sağ el (C şekli) ağza doğru gelir     │
/// │  8  │ Dur / Tamam  │ Sağ el avuç ileri, göğüs hizası       │
/// │  9  │ Hoşçakal     │ Sağ el yüz hizasında, sağa sola       │
/// │ 10  │ Ben / Kendim │ İşaret parmağı göğsü gösterir         │
/// └─────┴──────────────┴────────────────────────────────────────┘
/// ============================================

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ============ VERİ MODELLERİ ============

/// Algılanan bir işaret
class SignDetection {
  final String text;
  final double confidence;
  final DateTime timestamp;

  SignDetection({
    required this.text,
    required this.confidence,
    required this.timestamp,
  });

  @override
  String toString() => '$text (${(confidence * 100).toStringAsFixed(0)}%)';
}

// ============ ANA SERVİS ============

class SignLanguageService {
  // ML Kit Pose Detector
  PoseDetector? _poseDetector;

  // Durum
  bool _isInitialized = false;
  bool _isProcessing = false;

  // --- Hareket Geçmişi (Motion Tracking) ---
  // Son birkaç frame'deki el pozisyonlarını saklar.
  // Böylece "hareket" algılanabilir (sadece pozisyon değil).
  final List<_FrameSnapshot> _motionHistory = [];
  static const int _motionHistorySize = 6;

  // --- Algılama Buffer (Tutarlılık) ---
  final List<SignDetection> _frameBuffer = [];
  static const int _bufferSize = 10;
  static const int _minConsistentFrames = 5;

  // --- Cümle Oluşturma ---
  final List<String> _sentenceWords = [];
  String? _lastConfirmedWord;
  DateTime _lastWordTime = DateTime.now();
  static const Duration _wordCooldown = Duration(seconds: 2);

  // --- Throttle ---
  DateTime _lastProcessTime = DateTime.now();
  static const Duration _processInterval = Duration(milliseconds: 180);

  // --- Vücut Referansı ---
  double _shoulderWidth = 200.0; // Normalize referansı

  // Callback'ler
  Function(SignDetection)? onSignDetected;
  Function(String)? onSentenceFormed;
  Function(String)? onWordConfirmed;

  // Getter'lar
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String get currentSentence => _sentenceWords.join(' ');

  // ============ BAŞLATMA ============

  Future<void> initialize() async {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base, // base = hızlı, stream için ideal
        ),
      );
      _isInitialized = true;
      debugPrint('🤖 İşaret Dili AI başlatıldı (10 hareket aktif)');
    } catch (e) {
      debugPrint('❌ AI başlatma hatası: $e');
      _isInitialized = false;
    }
  }

  // ============ FRAME İŞLEME ============

  /// Kameradan gelen her frame burada işlenir.
  /// v2: InputImage doğrudan alınır (CameraImage yerine).
  /// WebRTC frame'leri veya platform kanalından InputImage üretilebilir.
  Future<SignDetection?> processFrame(InputImage inputImage) async {
    if (!_isInitialized || _isProcessing) return null;

    final now = DateTime.now();
    if (now.difference(_lastProcessTime) < _processInterval) return null;

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      // ML Kit Pose Detection
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) { _isProcessing = false; return null; }

      final pose = poses.first;

      // Referans ölçeğini güncelle
      _updateBodyScale(pose);

      // Anlık pozisyon kaydı (motion tracking için)
      _recordSnapshot(pose);

      // 10 hareketi kontrol et
      final detection = _detect(pose);

      // Buffer'a ekle, tutarlılığı kontrol et
      if (detection != null) {
        _addToBuffer(detection);
        onSignDetected?.call(detection);
        _checkConsistency();
      }

      _isProcessing = false;
      return detection;
    } catch (e) {
      debugPrint('⚠️ Frame hatası: $e');
      _isProcessing = false;
      return null;
    }
  }

  /// Ham byte verilerinden InputImage oluştur (yardımcı metod)
  /// WebRTC frame'lerini veya platform kanalından gelen verileri
  /// processFrame'e göndermek için kullanılabilir.
  static InputImage? createInputImageFromBytes({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required InputImageRotation rotation,
    required InputImageFormat format,
  }) {
    try {
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ============ VÜCUT ÖLÇEĞİ ============

  void _updateBodyScale(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (ls != null && rs != null && ls.likelihood > 0.5 && rs.likelihood > 0.5) {
      final w = (ls.x - rs.x).abs();
      if (w > 40) _shoulderWidth = w;
    }
  }

  // ============ MOTION TRACKING ============
  // Son N frame'deki el pozisyonlarını sakla.
  // Böylece "el yukarıdan aşağı indi" gibi hareketleri algılayabiliriz.

  void _recordSnapshot(Pose pose) {
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    _motionHistory.add(_FrameSnapshot(
      rightWrist: rw != null ? Point(rw.x, rw.y) : null,
      leftWrist: lw != null ? Point(lw.x, lw.y) : null,
      nose: nose != null ? Point(nose.x, nose.y) : null,
      time: DateTime.now(),
    ));

    if (_motionHistory.length > _motionHistorySize) {
      _motionHistory.removeAt(0);
    }
  }

  /// Sağ elin son N frame'deki dikey hareketi (pozitif = aşağı indi)
  double _rightHandVerticalMotion() {
    if (_motionHistory.length < 3) return 0;
    final first = _motionHistory.first.rightWrist;
    final last = _motionHistory.last.rightWrist;
    if (first == null || last == null) return 0;
    return last.y - first.y; // pozitif = aşağı, negatif = yukarı
  }

  /// Sağ elin son N frame'deki yatay hareketi (mutlak)
  double _rightHandHorizontalSwing() {
    if (_motionHistory.length < 3) return 0;
    double minX = double.infinity, maxX = double.negativeInfinity;
    for (final snap in _motionHistory) {
      if (snap.rightWrist != null) {
        if (snap.rightWrist!.x < minX) minX = snap.rightWrist!.x;
        if (snap.rightWrist!.x > maxX) maxX = snap.rightWrist!.x;
      }
    }
    if (minX == double.infinity) return 0;
    return maxX - minX;
  }

  // ============ 10 HAREKET ALGILAMA ============

  SignDetection? _detect(Pose pose) {
    // Gerekli landmark'ları çıkar
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rIndex = pose.landmarks[PoseLandmarkType.rightIndex];
    final rThumb = pose.landmarks[PoseLandmarkType.rightThumb];

    if (nose == null || rShoulder == null || lShoulder == null) return null;

    final n = Point(nose.x, nose.y);
    final sw = _shoulderWidth; // Normalize referansı
    final midShoulderY = (rShoulder.y + lShoulder.y) / 2;
    final midShoulderX = (rShoulder.x + lShoulder.x) / 2;

    // Her hareket için ayrı kontrol (öncelik sırasıyla)

    // ═══════════════════════════════════════════
    // 1. YARDIM — İki kol birden yukarıda 🆘
    // ═══════════════════════════════════════════
    // En belirgin hareket, önce kontrol et
    if (rWrist != null && lWrist != null && rElbow != null && lElbow != null) {
      final bothWristsAboveNose = rWrist.y < n.y && lWrist.y < n.y;
      final bothElbowsAboveShoulders = rElbow.y < rShoulder.y && lElbow.y < lShoulder.y;
      final wristsApart = (rWrist.x - lWrist.x).abs() > sw * 0.4;

      if (bothWristsAboveNose && bothElbowsAboveShoulders && wristsApart) {
        return SignDetection(text: 'Yardım', confidence: 0.92, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 2. MERHABA — Sağ el baş üstünde, kol kalkık 👋
    // ═══════════════════════════════════════════
    if (rWrist != null && rElbow != null) {
      final wristAboveHead = rWrist.y < n.y - sw * 0.3;
      final elbowAboveShoulder = rElbow.y < rShoulder.y;
      final elbowBentUp = rWrist.y < rElbow.y; // bilek dirsekten yukarıda
      // Sol el yukarıda DEĞİL (Yardım'dan ayırmak için)
      final leftDown = lWrist == null || lWrist.y > midShoulderY;

      if (wristAboveHead && elbowAboveShoulder && elbowBentUp && leftDown) {
        // Yatay sallanma varsa ekstra güven
        final swing = _rightHandHorizontalSwing();
        final conf = swing > sw * 0.15 ? 0.93 : 0.85;
        return SignDetection(text: 'Merhaba', confidence: conf, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 3. HOŞÇAKAL — Sağ el yüz hizasında, sağa sola sallanır 👋
    // ═══════════════════════════════════════════
    // Merhaba'dan farkı: el baş ÜSTÜNDE değil, yüz HİZASINDA
    if (rWrist != null && rElbow != null) {
      final atFaceLevel = (rWrist.y - n.y).abs() < sw * 0.35;
      final toSideOfFace = (rWrist.x - n.x).abs() > sw * 0.3;
      final swing = _rightHandHorizontalSwing();
      final isSwinging = swing > sw * 0.2;

      if (atFaceLevel && toSideOfFace && isSwinging) {
        return SignDetection(text: 'Hoşçakal', confidence: 0.84, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 4. HAYIR — Sağ işaret parmağı sağa sola, baş hizası ☝️
    // ═══════════════════════════════════════════
    if (rWrist != null && rIndex != null) {
      final indexAboveWrist = rIndex.y < rWrist.y; // parmak yukarı
      final atHeadLevel = (rIndex.y - n.y).abs() < sw * 0.4;
      final swing = _rightHandHorizontalSwing();
      final isSwinging = swing > sw * 0.15;
      // Parmak açık mı? (index ile wrist arasında mesafe)
      final fingerExtended = (rIndex.y - rWrist.y).abs() > sw * 0.15;

      if (indexAboveWrist && atHeadLevel && isSwinging && fingerExtended) {
        return SignDetection(text: 'Hayır', confidence: 0.82, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 5. TEŞEKKÜRLER — Sağ el çeneden aşağı iner 🙏
    // ═══════════════════════════════════════════
    if (rWrist != null) {
      final nearChin = rWrist.y > n.y && rWrist.y < n.y + sw * 0.6;
      final centered = (rWrist.x - n.x).abs() < sw * 0.4;
      final movingDown = _rightHandVerticalMotion() > sw * 0.1;

      if (nearChin && centered && movingDown) {
        return SignDetection(text: 'Teşekkürler', confidence: 0.83, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 6. EVET — Baş hizasında yumruk, aşağı iner ✊
    // ═══════════════════════════════════════════
    if (rWrist != null && rIndex != null && rThumb != null) {
      // Yumruk mu? (parmaklar bilege yakın)
      final fistClosed = (rIndex.y - rWrist.y).abs() < sw * 0.12 &&
                         (rThumb.y - rWrist.y).abs() < sw * 0.12;
      final atHeadLevel = rWrist.y > n.y - sw * 0.2 && rWrist.y < n.y + sw * 0.5;
      final centered = (rWrist.x - n.x).abs() < sw * 0.35;
      final noddingDown = _rightHandVerticalMotion() > sw * 0.08;

      if (fistClosed && atHeadLevel && centered && noddingDown) {
        return SignDetection(text: 'Evet', confidence: 0.80, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 7. YEMEK — Sağ el ağza gider gelir 🍽️
    // ═══════════════════════════════════════════
    if (rWrist != null) {
      // El ağız bölgesinde
      final atMouth = rWrist.y > n.y - sw * 0.05 && rWrist.y < n.y + sw * 0.35;
      final nearFace = (rWrist.x - n.x).abs() < sw * 0.3;
      // Dirsek aşağıda (el yukarı kalkmış)
      final elbowBelow = rElbow != null && rElbow.y > rWrist.y;

      if (atMouth && nearFace && elbowBelow) {
        return SignDetection(text: 'Yemek', confidence: 0.81, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 8. SU — Sağ el (C şekli) çeneye gelir 💧
    // ═══════════════════════════════════════════
    if (rWrist != null && rThumb != null && rIndex != null) {
      final belowChin = rWrist.y > n.y + sw * 0.1 && rWrist.y < n.y + sw * 0.5;
      final centered = (rWrist.x - n.x).abs() < sw * 0.3;
      // C şekli: başparmak ile işaret parmağı arasında boşluk
      final cShape = (rThumb.x - rIndex.x).abs() > sw * 0.05 &&
                     (rThumb.x - rIndex.x).abs() < sw * 0.25;
      final elbowBelow = rElbow != null && rElbow.y > rWrist.y;

      if (belowChin && centered && cShape && elbowBelow) {
        return SignDetection(text: 'Su', confidence: 0.78, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 9. DUR / TAMAM — Avuç ileri, göğüs hizası ✋
    // ═══════════════════════════════════════════
    if (rWrist != null && rIndex != null && rThumb != null) {
      final chestLevel = rWrist.y > midShoulderY && rWrist.y < midShoulderY + sw * 0.7;
      // Avuç açık: parmaklar bilekten uzakta
      final palmOpen = (rIndex.y - rWrist.y).abs() > sw * 0.15;
      // El vücudun önünde (yana doğru değil)
      final inFront = (rWrist.x - midShoulderX).abs() < sw * 0.5;
      // Hareket yok (sabit duruyor)
      final isStill = _rightHandHorizontalSwing() < sw * 0.1 &&
                      _rightHandVerticalMotion().abs() < sw * 0.08;

      if (chestLevel && palmOpen && inFront && isStill) {
        return SignDetection(text: 'Dur', confidence: 0.77, timestamp: DateTime.now());
      }
    }

    // ═══════════════════════════════════════════
    // 10. BEN — İşaret parmağı göğsü gösterir 👆
    // ═══════════════════════════════════════════
    if (rWrist != null && rIndex != null) {
      final chestLevel = rWrist.y > midShoulderY && rWrist.y < midShoulderY + sw * 0.6;
      final centered = (rWrist.x - midShoulderX).abs() < sw * 0.25;
      // İşaret parmağı aşağı (göğse doğru) bakıyor
      final pointingDown = rIndex.y > rWrist.y;
      // El vücuda yakın
      final closeToBody = (rWrist.x - midShoulderX).abs() < sw * 0.3;

      if (chestLevel && centered && pointingDown && closeToBody) {
        return SignDetection(text: 'Ben', confidence: 0.76, timestamp: DateTime.now());
      }
    }

    return null; // Hiçbir hareket eşleşmedi
  }

  // ============ BUFFER & TUTARLILIK ============

  void _addToBuffer(SignDetection detection) {
    _frameBuffer.add(detection);
    if (_frameBuffer.length > _bufferSize) {
      _frameBuffer.removeAt(0);
    }
  }

  /// Aynı kelime N/bufferSize frame'de algılandıysa onayla
  void _checkConsistency() {
    if (_frameBuffer.length < _minConsistentFrames) return;

    // Sayım
    final counts = <String, int>{};
    for (final d in _frameBuffer) {
      counts[d.text] = (counts[d.text] ?? 0) + 1;
    }

    // En çok tekrar eden
    String? best;
    int bestCount = 0;
    counts.forEach((word, count) {
      if (count > bestCount) { bestCount = count; best = word; }
    });

    if (best == null || bestCount < _minConsistentFrames) return;

    final now = DateTime.now();
    // Spam önleme
    if (best == _lastConfirmedWord && now.difference(_lastWordTime) < _wordCooldown) return;

    // ✅ Kelime onaylandı!
    _lastConfirmedWord = best;
    _lastWordTime = now;
    _frameBuffer.clear();
    _motionHistory.clear();

    _sentenceWords.add(best!);
    onWordConfirmed?.call(best!);
    onSentenceFormed?.call(currentSentence);

    debugPrint('✅ İşaret: $best (${bestCount}/${_bufferSize} frame)');
  }

  // ============ YARDIMCI ============

  void clearSentence() {
    _sentenceWords.clear();
    _frameBuffer.clear();
    _motionHistory.clear();
    _lastConfirmedWord = null;
  }

  void undoLastWord() {
    if (_sentenceWords.isNotEmpty) {
      _sentenceWords.removeLast();
      onSentenceFormed?.call(currentSentence);
    }
  }

  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
    _isInitialized = false;
    _frameBuffer.clear();
    _motionHistory.clear();
    _sentenceWords.clear();
    debugPrint('🤖 İşaret Dili AI kapatıldı');
  }
}

// ============ YARDIMCI SINIFLAR ============

/// Tek bir frame'deki el/baş pozisyon kaydı
class _FrameSnapshot {
  final Point<double>? rightWrist;
  final Point<double>? leftWrist;
  final Point<double>? nose;
  final DateTime time;

  _FrameSnapshot({this.rightWrist, this.leftWrist, this.nose, required this.time});
}
