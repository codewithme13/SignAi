/// ============================================
/// SignAI - İşaret Dili AI Servisi (v2)
/// ============================================
/// Kameradan gelen frame'leri gerçek zamanlı işler.
/// ML Kit Pose Detection ile vücut noktalarını algılar.
/// 10 temel Türk İşaret Dili hareketini tanır.
///
/// ALGILANAN 12 HAREKET:
/// ┌─────┬────────────────┬──────────────────────────────────────────┐
/// │  #  │   Hareket      │ Nasıl Yapılır                            │
/// ├─────┼────────────────┼──────────────────────────────────────────┤
/// │  1  │ Merhaba        │ Sağ el baş üstünde                      │
/// │  2  │ Teşekkürler    │ El çene civarı + aşağı hareket          │
/// │  3  │ Evet           │ El baş hizası + hafif aşağı hareket     │
/// │  4  │ Hayır          │ El yüz ortasında + sağa sola sallanma   │
/// │  5  │ Yardım         │ İki el omuz üstünde                     │
/// │  6  │ Yemek          │ El ağız hizasında + sabit               │
/// │  7  │ Su             │ El çene altında + sabit                 │
/// │  8  │ Dur            │ El göğüs hizası + kol açık              │
/// │  9  │ Hoşçakal       │ El yüz yanında + sallanma               │
/// │ 10  │ Ben            │ El göğüs hizası + vücuda yakın          │
/// │ 11  │ Nasılsın       │ İki el göğüs hizası + açık (ayrık)      │
/// │ 12  │ Seni Seviyorum │ İki el göğüs hizası + çapraz (yakın)    │
/// └─────┴────────────────┴──────────────────────────────────────────┘
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
  static const int _bufferSize = 8;
  static const int _minConsistentFrames = 3;

  // --- Cümle Oluşturma ---
  final List<String> _sentenceWords = [];
  String? _lastConfirmedWord;
  DateTime _lastWordTime = DateTime.now();
  static const Duration _wordCooldown = Duration(milliseconds: 1500);

  // --- Throttle ---
  DateTime _lastProcessTime = DateTime.now();
  static const Duration _processInterval = Duration(milliseconds: 150);

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
      debugPrint('🤖 İşaret Dili AI başlatıldı (12 hareket aktif)');
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
    // Gerekli landmark'ları çıkar (sadece bilek/dirsek/omuz — güvenilir noktalar)
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (nose == null || rShoulder == null || lShoulder == null) return null;

    final n = Point(nose.x, nose.y);
    final sw = _shoulderWidth; // Normalize referansı
    final midShoulderY = (rShoulder.y + lShoulder.y) / 2;
    final midShoulderX = (rShoulder.x + lShoulder.x) / 2;

    // ═══════════════════════════════════════════════════
    // GEVŞEK AMA AYIRT EDİCİ KURALLAR
    // Her hareketin TEK belirleyici özelliği var:
    //   Yardım       → İKİ el YUKARI (omuz üstü)
    //   Nasılsın     → İKİ el GÖĞÜS hizası + AYRIK
    //   Seni Seviyorum → İKİ el GÖĞÜS hizası + YAKIN
    //   Merhaba  → TEK el baş üstünde
    //   Hoşçakal → El yüz YANINDA + sallanma
    //   Hayır    → El yüz ORTASINDA + sallanma
    //   Teşekkür → El çene civarı + AŞAĞI hareket
    //   Evet     → El baş hizası + küçük aşağı hareket
    //   Yemek    → El AĞIZ seviyesinde
    //   Su       → El çene ALTINDA + hareketsiz
    //   Dur      → El göğüs hizası + kol AÇIK
    //   Ben      → El göğüs hizası + vücuda YAKIN
    // ═══════════════════════════════════════════════════

    // ═══ İKİ-EL HAREKETLERİ (önce kontrol — karışma riski yok) ═══

    // ── 1. YARDIM — İki kol birden baş üstünde 🆘 ──
    if (rWrist != null && lWrist != null) {
      final bothAboveShoulders = rWrist.y < midShoulderY && lWrist.y < midShoulderY;
      if (bothAboveShoulders) {
        return SignDetection(text: 'Yardım', confidence: 0.92, timestamp: DateTime.now());
      }
    }

    // ── 11. NASILSIN — İki el göğüs hizasında, birbirinden AYRIK 🤷 ──
    // Yardım'dan fark: eller AŞAĞIDA (göğüs hizası), yukarıda değil
    // Seni Seviyorum'dan fark: eller birbirinden UZAK
    if (rWrist != null && lWrist != null) {
      final bothAtChest = rWrist.y > midShoulderY && lWrist.y > midShoulderY &&
                          rWrist.y < midShoulderY + sw * 0.9 && lWrist.y < midShoulderY + sw * 0.9;
      final handsApart = (rWrist.x - lWrist.x).abs() > sw * 0.5;

      if (bothAtChest && handsApart) {
        return SignDetection(text: 'Nasılsın', confidence: 0.85, timestamp: DateTime.now());
      }
    }

    // ── 12. SENİ SEVİYORUM — İki el göğüs hizasında, birbirine YAKIN 💕 ──
    // Nasılsın'dan fark: eller birbirine YAKIN (kucaklama/kalp gibi)
    if (rWrist != null && lWrist != null) {
      final bothAtChest = rWrist.y > midShoulderY && lWrist.y > midShoulderY &&
                          rWrist.y < midShoulderY + sw * 0.9 && lWrist.y < midShoulderY + sw * 0.9;
      final handsTogether = (rWrist.x - lWrist.x).abs() < sw * 0.5;

      if (bothAtChest && handsTogether) {
        return SignDetection(text: 'Seni Seviyorum', confidence: 0.88, timestamp: DateTime.now());
      }
    }

    // ═══ TEK-EL HAREKETLERİ ═══

    // ── 2. MERHABA — Sağ el baş üstünde 👋 ──
    // Yardım'dan fark: sadece TEK el yukarıda
    if (rWrist != null) {
      final wristAboveHead = rWrist.y < n.y - sw * 0.15;
      final leftNotUp = lWrist == null || lWrist.y > midShoulderY + sw * 0.3;

      if (wristAboveHead && leftNotUp) {
        return SignDetection(text: 'Merhaba', confidence: 0.90, timestamp: DateTime.now());
      }
    }

    // ── 3. HOŞÇAKAL — El yüz hizasında, yüzün YANINDA, sallanıyor 👋 ──
    if (rWrist != null) {
      final atFaceLevel = rWrist.y > n.y - sw * 0.4 && rWrist.y < n.y + sw * 0.5;
      final toSide = (rWrist.x - n.x).abs() > sw * 0.25;
      final swing = _rightHandHorizontalSwing();
      final isSwinging = swing > sw * 0.15;

      if (atFaceLevel && toSide && isSwinging) {
        return SignDetection(text: 'Hoşçakal', confidence: 0.85, timestamp: DateTime.now());
      }
    }

    // ── 4. HAYIR — El yüz hizasında, ORTADA, sallanıyor ☝️ ──
    // Hoşçakal'dan fark: el yüzün yanında değil, ortasında
    if (rWrist != null) {
      final atFaceLevel = rWrist.y > n.y - sw * 0.4 && rWrist.y < n.y + sw * 0.5;
      final centered = (rWrist.x - n.x).abs() < sw * 0.35;
      final swing = _rightHandHorizontalSwing();
      final isSwinging = swing > sw * 0.12;

      if (atFaceLevel && centered && isSwinging) {
        return SignDetection(text: 'Hayır', confidence: 0.82, timestamp: DateTime.now());
      }
    }

    // ── 5. TEŞEKKÜRLER — El çene civarında + aşağı hareket 🙏 ──
    if (rWrist != null) {
      final nearChin = rWrist.y > n.y && rWrist.y < n.y + sw * 0.7;
      final centered = (rWrist.x - n.x).abs() < sw * 0.5;
      final movingDown = _rightHandVerticalMotion() > sw * 0.08;

      if (nearChin && centered && movingDown) {
        return SignDetection(text: 'Teşekkürler', confidence: 0.83, timestamp: DateTime.now());
      }
    }

    // ── 6. EVET — El baş hizasında, hafif aşağı hareket ✊ ──
    // Teşekkür'den fark: el daha YUKARI (burun civarı), hareket daha küçük
    if (rWrist != null) {
      final atHeadLevel = rWrist.y > n.y - sw * 0.25 && rWrist.y < n.y + sw * 0.35;
      final centered = (rWrist.x - n.x).abs() < sw * 0.4;
      final smallNod = _rightHandVerticalMotion() > sw * 0.05 && _rightHandVerticalMotion() < sw * 0.2;

      if (atHeadLevel && centered && smallNod) {
        return SignDetection(text: 'Evet', confidence: 0.80, timestamp: DateTime.now());
      }
    }

    // ── 7. YEMEK — El ağız hizasında, yüze yakın 🍽️ ──
    if (rWrist != null) {
      final atMouth = rWrist.y > n.y - sw * 0.1 && rWrist.y < n.y + sw * 0.45;
      final nearFace = (rWrist.x - n.x).abs() < sw * 0.35;
      final notSwinging = _rightHandHorizontalSwing() < sw * 0.15;
      final notMovingDown = _rightHandVerticalMotion().abs() < sw * 0.08;

      if (atMouth && nearFace && notSwinging && notMovingDown) {
        return SignDetection(text: 'Yemek', confidence: 0.81, timestamp: DateTime.now());
      }
    }

    // ── 8. SU — El çene altında, hareketsiz 💧 ──
    // Yemek'ten fark: el daha AŞAĞIDA (çene altı)
    if (rWrist != null) {
      final belowChin = rWrist.y > n.y + sw * 0.2 && rWrist.y < n.y + sw * 0.7;
      final centered = (rWrist.x - n.x).abs() < sw * 0.4;
      final isStill = _rightHandHorizontalSwing() < sw * 0.1 &&
                      _rightHandVerticalMotion().abs() < sw * 0.08;

      if (belowChin && centered && isStill) {
        return SignDetection(text: 'Su', confidence: 0.78, timestamp: DateTime.now());
      }
    }

    // ── 9. DUR — El göğüs hizasında, kol ileri uzanmış ✋ ──
    // Ben'den fark: el vücuttan UZAK (kol açık)
    if (rWrist != null) {
      final atChest = rWrist.y > midShoulderY && rWrist.y < midShoulderY + sw * 0.8;
      final armExtended = (rWrist.x - midShoulderX).abs() > sw * 0.3;
      final isStill = _rightHandHorizontalSwing() < sw * 0.12 &&
                      _rightHandVerticalMotion().abs() < sw * 0.1;

      if (atChest && armExtended && isStill) {
        return SignDetection(text: 'Dur', confidence: 0.77, timestamp: DateTime.now());
      }
    }

    // ── 10. BEN — El göğüs hizasında, vücuda yakın 👆 ──
    if (rWrist != null) {
      final atChest = rWrist.y > midShoulderY && rWrist.y < midShoulderY + sw * 0.7;
      final closeToBody = (rWrist.x - midShoulderX).abs() < sw * 0.3;
      final isStill = _rightHandHorizontalSwing() < sw * 0.1 &&
                      _rightHandVerticalMotion().abs() < sw * 0.08;

      if (atChest && closeToBody && isStill) {
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
