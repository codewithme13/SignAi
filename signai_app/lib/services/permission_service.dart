/// ============================================
/// SignAI - İzin Yönetimi Servisi
/// ============================================
/// Kamera, mikrofon ve konuşma tanıma izinlerini
/// yönetir. İzinler verilmeden uygulama çalışmaz.
/// ============================================

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// İzin durumları
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class PermissionService {
  /// Tüm gerekli izinleri iste
  /// Dönen map: { 'camera': true, 'microphone': true, 'speech': true }
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    final camera = await requestCamera();
    results['camera'] = camera == PermissionResult.granted;

    final mic = await requestMicrophone();
    results['microphone'] = mic == PermissionResult.granted;

    final speech = await requestSpeechRecognition();
    results['speech'] = speech == PermissionResult.granted;

    debugPrint('🔐 İzin sonuçları: $results');
    return results;
  }

  /// Kamera izni iste
  static Future<PermissionResult> requestCamera() async {
    final status = await Permission.camera.request();
    return _mapStatus(status, 'Kamera');
  }

  /// Mikrofon izni iste
  static Future<PermissionResult> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return _mapStatus(status, 'Mikrofon');
  }

  /// Konuşma tanıma izni iste
  static Future<PermissionResult> requestSpeechRecognition() async {
    final status = await Permission.speech.request();
    return _mapStatus(status, 'Konuşma Tanıma');
  }

  /// Tüm izinler verilmiş mi kontrol et
  static Future<bool> areAllPermissionsGranted() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    final speech = await Permission.speech.isGranted;
    return camera && mic && speech;
  }

  /// Kamera ve mikrofon izni verilmiş mi
  static Future<bool> areCorePermissionsGranted() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    return camera && mic;
  }

  /// Kalıcı olarak reddedilen izinler varsa ayarlara yönlendir
  static Future<bool> openSettingsIfNeeded() async {
    final camera = await Permission.camera.isPermanentlyDenied;
    final mic = await Permission.microphone.isPermanentlyDenied;

    if (camera || mic) {
      debugPrint('⚠️ İzinler kalıcı olarak reddedilmiş, ayarlar açılıyor...');
      return openAppSettings();
    }
    return false;
  }

  /// PermissionStatus → PermissionResult dönüşümü
  static PermissionResult _mapStatus(PermissionStatus status, String label) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        debugPrint('✅ $label izni verildi');
        return PermissionResult.granted;
      case PermissionStatus.permanentlyDenied:
        debugPrint('🚫 $label izni kalıcı olarak reddedildi');
        return PermissionResult.permanentlyDenied;
      default:
        debugPrint('❌ $label izni reddedildi');
        return PermissionResult.denied;
    }
  }
}
