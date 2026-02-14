/// SignAI Sabit Değerleri
class AppConstants {
  // Uygulama Bilgileri
  static const String appName = 'SignAI';
  static const String appTagline = 'İşaret Dili ile Engelsiz İletişim';
  static const String appVersion = '1.0.0';

  // Signaling Server URL'i
  // Geliştirme: localhost:3001, Prodüksiyon: Railway/Render URL'i  
  static const String signalingServerUrl = 'http://10.55.1.77:3001';
  // Emulator için: static const String signalingServerUrl = 'http://localhost:3001';
  // static const String signalingServerUrl = 'https://signai-server.railway.app';

  // WebRTC STUN/TURN Sunucuları
  // STUN: NAT arkasındaki gerçek IP'yi bulmak için
  // TURN: Doğrudan bağlantı kurulamadığında relay olarak kullanılır
  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      // Google STUN sunucuları (ücretsiz)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      
      // Open Relay Project (ücretsiz topluluk TURN sunucusu)
      // https://www.metered.ca/tools/openrelay/
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ]
  };

  // Video Kalite Ayarları
  static const Map<String, dynamic> mediaConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '24',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  // UI Ayarları
  static const Duration subtitleDisplayDuration = Duration(seconds: 3);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxReconnectAttempts = 5;
}
