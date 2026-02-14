/// ============================================
/// SignAI - Signaling Servisi
/// ============================================
/// Socket.IO üzerinden signaling server'a bağlanır.
/// WebRTC Offer/Answer/ICE mesajlarını iletir.
/// ============================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

/// Signaling mesaj tipleri
enum SignalingState {
  connected,
  disconnected,
  error,
}

/// Gelen arama bilgisi
class IncomingCall {
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final dynamic offer;
  final String callId;

  IncomingCall({
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.offer,
    required this.callId,
  });
}

class SignalingService {
  io.Socket? _socket;
  SignalingState _state = SignalingState.disconnected;

  // Callback'ler
  Function(IncomingCall)? onIncomingCall;
  Function(dynamic)? onCallAnswered;
  Function(dynamic)? onCallRejected;
  Function(dynamic)? onCallEnded;
  Function(dynamic)? onIceCandidate;
  Function(String, String)? onSubtitle; // text, fromUserId
  Function(Map<String, dynamic>)? onUserOnline;
  Function(Map<String, dynamic>)? onUserOffline;
  Function(List<Map<String, dynamic>>)? onOnlineUsers;
  Function(SignalingState)? onStateChanged;
  Function()? _onReconnectCallback;

  SignalingState get state => _state;
  bool get isConnected => _state == SignalingState.connected;

  // Kullanıcı bilgileri
  String? _userId;
  String? _username;

  /// Signaling Server'a bağlan (JWT token ile)
  Future<void> connect({String? token, String? userId, String? username}) async {
    _userId = userId;
    _username = username;
    try {
      final optionBuilder = io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(AppConstants.maxReconnectAttempts)
          .setReconnectionDelay(2000);

      // JWT token varsa auth olarak gönder
      if (token != null) {
        optionBuilder.setAuth({'token': token});
      }

      _socket = io.io(
        AppConstants.signalingServerUrl,
        optionBuilder.build(),
      );

      _setupListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Signaling bağlantı hatası: $e');
      _updateState(SignalingState.error);
    }
  }

  /// Dinleyicileri kur
  void _setupListeners() {
    final socket = _socket!;

    // Bağlantı durumları
    socket.onConnect((_) {
      debugPrint('🟢 Signaling Server\'a bağlanıldı');
      _updateState(SignalingState.connected);
      
      // Kullanıcıyı server'a kaydet
      if (_userId != null && _username != null) {
        _registerUser(_userId!, _username!);
      }
    });

    socket.onDisconnect((_) {
      debugPrint('🔴 Signaling bağlantısı kesildi');
      _updateState(SignalingState.disconnected);
    });

    socket.onConnectError((error) {
      debugPrint('❌ Bağlantı hatası: $error');
      _updateState(SignalingState.error);
    });

    socket.onReconnect((_) {
      debugPrint('🔄 Yeniden bağlanıldı');
      _updateState(SignalingState.connected);
      // Yeniden bağlandıktan sonra kullanıcıyı tekrar kaydet
      if (_userId != null && _username != null) {
        _registerUser(_userId!, _username!);
      }
      _onReconnectCallback?.call();
    });

    // Gelen arama
    socket.on('incoming-call', (data) {
      debugPrint('📞 Gelen arama: ${data['callerName']}');
      onIncomingCall?.call(IncomingCall(
        callerId: data['callerId'],
        callerName: data['callerName'],
        callerPhoto: data['callerPhoto'],
        offer: data['offer'],
        callId: data['callId'],
      ));
    });

    // Arama kabul edildi
    socket.on('call-answered', (data) {
      debugPrint('✅ Arama kabul edildi');
      onCallAnswered?.call(data['answer']);
    });

    // Arama reddedildi
    socket.on('call-rejected', (data) {
      debugPrint('❌ Arama reddedildi');
      onCallRejected?.call(data);
    });

    // Arama sonlandı
    socket.on('call-ended', (data) {
      debugPrint('📴 Arama sonlandı');
      onCallEnded?.call(data);
    });

    // ICE Candidate
    socket.on('ice-candidate', (data) {
      onIceCandidate?.call(data['candidate']);
    });

    // Altyazı
    socket.on('subtitle', (data) {
      onSubtitle?.call(data['text'], data['from']);
    });

    // Kullanıcı online/offline
    socket.on('user-online', (data) {
      onUserOnline?.call(Map<String, dynamic>.from(data));
    });

    socket.on('user-offline', (data) {
      onUserOffline?.call(Map<String, dynamic>.from(data));
    });

    // Mevcut online kullanıcılar
    socket.on('online-users', (data) {
      final users = (data['users'] as List)
          .map((u) => Map<String, dynamic>.from(u))
          .toList();
      onOnlineUsers?.call(users);
    });

    // Hata
    socket.on('call-error', (data) {
      debugPrint('⚠️ Arama hatası: ${data['message']}');
    });
  }

  /// Kullanıcı kaydı
  void register(String userId, String username) {
    _socket?.emit('register', {
      'userId': userId,
      'username': username,
    });
    debugPrint('👤 Kayıt gönderildi: $username');

    // Reconnect olduğunda aynı bilgilerle yeniden kayıt ol
    _onReconnectCallback = () {
      _socket?.emit('register', {
        'userId': userId,
        'username': username,
      });
      debugPrint('🔄 Yeniden kayıt gönderildi: $username');
    };
  }

  /// Arama başlat (Offer gönder)
  void callUser(String targetUserId, dynamic offer, Map<String, dynamic> callerInfo) {
    _socket?.emit('call-user', {
      'targetUserId': targetUserId,
      'offer': offer,
      'callerInfo': callerInfo,
    });
  }

  /// Aramayı kabul et (Answer gönder)
  void answerCall(String targetUserId, dynamic answer) {
    _socket?.emit('answer-call', {
      'targetUserId': targetUserId,
      'answer': answer,
    });
  }

  /// Aramayı reddet
  void rejectCall(String targetUserId) {
    _socket?.emit('reject-call', {
      'targetUserId': targetUserId,
    });
  }

  /// ICE Candidate gönder
  void sendIceCandidate(String targetUserId, dynamic candidate) {
    _socket?.emit('ice-candidate', {
      'targetUserId': targetUserId,
      'candidate': candidate,
    });
  }

  /// Aramayı sonlandır
  void endCall(String targetUserId) {
    _socket?.emit('end-call', {
      'targetUserId': targetUserId,
    });
  }

  /// Altyazı gönder
  void sendSubtitle(String targetUserId, String text, {String language = 'tr'}) {
    _socket?.emit('subtitle', {
      'targetUserId': targetUserId,
      'text': text,
      'language': language,
    });
  }

  /// Kullanıcıyı server'a kaydet
  void _registerUser(String userId, String username) {
    debugPrint("👤 Server'a kaydolunuyor: $username ($userId)");
    _socket?.emit('register', {
      'userId': userId,
      'username': username,
    });
  }

  /// Durumu güncelle
  void _updateState(SignalingState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }

  /// Bağlantıyı kes
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(SignalingState.disconnected);
  }
}
