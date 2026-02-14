/// ============================================
/// SignAI - WebRTC Servisi
/// ============================================
/// P2P görüntülü arama bağlantısını yönetir.
/// Kamera, mikrofon ve veri kanalını kontrol eder.
/// ============================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/constants.dart';

/// Arama durumları
enum CallState {
  idle,        // Boşta
  calling,     // Arıyor
  ringing,     // Çalıyor (gelen arama)
  connecting,  // Bağlanıyor
  connected,   // Bağlandı
  reconnecting,// Yeniden bağlanıyor
  ended,       // Bitti
}

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Video renderer'ları
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // ICE Candidate kuyruğu (remoteDescription set edilmeden gelen adaylar)
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _remoteDescriptionSet = false;

  // Durum
  CallState _callState = CallState.idle;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isSpeakerOn = true;

  // Callback'ler
  Function(CallState)? onCallStateChanged;
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;
  Function(RTCSessionDescription)? onOffer;
  Function(RTCSessionDescription)? onAnswer;
  Function(MediaStream)? onLocalFrameAvailable; // AI işleme için
  Function(String)? onError; // Hata callback'i

  // Getter'lar
  CallState get callState => _callState;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isFrontCamera => _isFrontCamera;
  bool get isSpeakerOn => _isSpeakerOn;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  /// Renderer'ları başlat
  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    debugPrint('📹 WebRTC renderer\'ları hazır');
  }

  /// Kamera ve mikrofonu aç
  Future<MediaStream> openUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(
        AppConstants.mediaConstraints,
      );

      _localStream = stream;
      localRenderer.srcObject = stream;

      onLocalStream?.call(stream);
      debugPrint('📹 Kamera ve mikrofon açıldı');

      return stream;
    } catch (e) {
      debugPrint('❌ Kamera/mikrofon açma hatası: $e');
      onError?.call('Kamera veya mikrofon açılamadı: $e');
      rethrow;
    }
  }

  /// Peer Connection oluştur (WebRTC bağlantısı)
  Future<RTCPeerConnection> _createPeerConnection() async {
    final pc = await createPeerConnection(
      AppConstants.iceServers,
      {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      },
    );

    // Yerel medya akışını ekle
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // Karşıdan gelen video/ses akışını al
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
        debugPrint('📺 Karşı tarafın videosu alındı');
      }
    };

    // ICE Candidate bulunduğunda
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      onIceCandidate?.call(candidate);
    };

    // Bağlantı durumu değişikliği
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('🔗 ICE durumu: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _updateCallState(CallState.connected);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _updateCallState(CallState.reconnecting);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _updateCallState(CallState.ended);
          break;
        default:
          break;
      }
    };

    // Bağlantı durumu (genel)
    pc.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 Bağlantı durumu: $state');
    };

    return pc;
  }

  /// Arama başlat (Offer oluştur)
  Future<RTCSessionDescription> createOffer() async {
    try {
      _updateCallState(CallState.calling);
      _remoteDescriptionSet = false;
      _pendingIceCandidates.clear();

      _peerConnection = await _createPeerConnection();

      // Offer oluştur
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peerConnection!.setLocalDescription(offer);

      debugPrint('📤 Offer oluşturuldu');
      return offer;
    } catch (e) {
      debugPrint('❌ Offer oluşturma hatası: $e');
      _updateCallState(CallState.ended);
      onError?.call('Arama başlatılamadı: $e');
      rethrow;
    }
  }

  /// Gelen aramayı kabul et (Answer oluştur)
  Future<RTCSessionDescription> createAnswer(dynamic offer) async {
    try {
      _updateCallState(CallState.connecting);
      _remoteDescriptionSet = false;
      _pendingIceCandidates.clear();

      _peerConnection = await _createPeerConnection();

      // Karşıdan gelen offer'ı ayarla
      final remoteDescription = RTCSessionDescription(
        offer['sdp'],
        offer['type'],
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);
      _remoteDescriptionSet = true;

      // Bekleyen ICE adaylarını ekle
      await _drainPendingCandidates();

      // Answer oluştur
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peerConnection!.setLocalDescription(answer);

      debugPrint('📤 Answer oluşturuldu');
      return answer;
    } catch (e) {
      debugPrint('❌ Answer oluşturma hatası: $e');
      _updateCallState(CallState.ended);
      onError?.call('Arama kabul edilemedi: $e');
      rethrow;
    }
  }

  /// Karşıdan gelen Answer'ı işle
  Future<void> handleAnswer(dynamic answer) async {
    try {
      _updateCallState(CallState.connecting);

      final remoteDescription = RTCSessionDescription(
        answer['sdp'],
        answer['type'],
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);
      _remoteDescriptionSet = true;

      // Bekleyen ICE adaylarını ekle
      await _drainPendingCandidates();

      debugPrint('📥 Answer alındı ve ayarlandı');
    } catch (e) {
      debugPrint('❌ Answer işleme hatası: $e');
      onError?.call('Bağlantı kurulamadı: $e');
    }
  }

  /// ICE Candidate ekle (kuyruk destekli)
  Future<void> addIceCandidate(dynamic candidateData) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (_remoteDescriptionSet) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        // Remote description henüz set edilmemiş, kuyruğa ekle
        _pendingIceCandidates.add(candidate);
        debugPrint('🧊 ICE adayı kuyruğa eklendi (${_pendingIceCandidates.length} bekliyor)');
      }
    } catch (e) {
      debugPrint('⚠️ ICE candidate hatası: $e');
    }
  }

  /// Kuyrukta bekleyen ICE adaylarını ekle
  Future<void> _drainPendingCandidates() async {
    if (_pendingIceCandidates.isEmpty) return;

    debugPrint('🧊 ${_pendingIceCandidates.length} bekleyen ICE adayı ekleniyor...');
    for (final candidate in _pendingIceCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('⚠️ Bekleyen ICE candidate hatası: $e');
      }
    }
    _pendingIceCandidates.clear();
  }

  /// Mikrofonu aç/kapat
  void toggleMic() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !track.enabled;
      }
      _isMicMuted = !_isMicMuted;
      debugPrint('🎤 Mikrofon: ${_isMicMuted ? "Kapalı" : "Açık"}');
    }
  }

  /// Kamerayı aç/kapat
  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      for (var track in videoTracks) {
        track.enabled = !track.enabled;
      }
      _isCameraOff = !_isCameraOff;
      debugPrint('📹 Kamera: ${_isCameraOff ? "Kapalı" : "Açık"}');
    }
  }

  /// Ön/arka kamera değiştir
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        _isFrontCamera = !_isFrontCamera;
        debugPrint('📹 Kamera: ${_isFrontCamera ? "Ön" : "Arka"}');
      }
    }
  }

  /// Hoparlör/kulaklık değiştir
  void toggleSpeaker() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enableSpeakerphone(_isSpeakerOn ? false : true);
      }
      _isSpeakerOn = !_isSpeakerOn;
      debugPrint('🔊 Hoparlör: ${_isSpeakerOn ? "Açık" : "Kapalı"}');
    }
  }

  /// Arama durumunu güncelle
  void _updateCallState(CallState newState) {
    _callState = newState;
    onCallStateChanged?.call(newState);
  }

  /// Aramayı sonlandır
  Future<void> hangUp() async {
    try {
      // Yerel medya akışını kapat
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      // Uzak medya akışını kapat
      _remoteStream?.getTracks().forEach((track) => track.stop());
      _remoteStream?.dispose();
      _remoteStream = null;

      // Peer connection'ı kapat
      await _peerConnection?.close();
      _peerConnection = null;

      // Renderer'ları temizle
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      _updateCallState(CallState.ended);
      _isMicMuted = false;
      _isCameraOff = false;
      _remoteDescriptionSet = false;
      _pendingIceCandidates.clear();

      debugPrint('📴 Arama sonlandırıldı');
    } catch (e) {
      debugPrint('⚠️ Arama sonlandırma hatası: $e');
    }
  }

  /// Temizlik
  Future<void> dispose() async {
    await hangUp();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
