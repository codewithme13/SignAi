/// SignAI - Auth Provider (Kullanıcı Yönetimi)
/// JWT tabanlı kimlik doğrulama ile sunucu kayıt desteği.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  String? _username;
  String? _token;
  bool _isLoggedIn = false;
  String? _error;

  String? get userId => _userId;
  String? get username => _username;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  /// JWT token'ın süresinin dolup dolmadığını kontrol et
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // JWT payload'u decode et (base64url)
      String payload = parts[1];
      // Base64 padding ekle
      final remainder = payload.length % 4;
      if (remainder > 0) payload += '=' * (4 - remainder);

      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = data['exp'] as int?;
      if (exp == null) return true;

      // Şu anki zaman exp'den büyükse token süresi dolmuş
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true; // Parse edilemiyorsa süresi dolmuş say
    }
  }

  /// Kayıtlı kullanıcıyı yükle
  Future<bool> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _token = prefs.getString('token');

    if (_userId != null && _username != null && _token != null) {
      // Token süresi dolmuşsa oturumu temizle
      if (_isTokenExpired(_token!)) {
        debugPrint('⏰ Token süresi dolmuş, yeniden giriş gerekli');
        await logout();
        return false;
      }
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Kayıt ol - yeni kullanıcı oluştur
  Future<void> register(String username, String password) async {
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.signalingServerUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _userId = data['userId'];
        _username = data['username'];
        _token = data['token'];
        _isLoggedIn = true;

        // Yerel kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _userId!);
        await prefs.setString('username', _username!);
        await prefs.setString('token', _token!);

        notifyListeners();
        debugPrint('👤 Kullanıcı kaydedildi: $_username ($_userId)');
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Kayıt başarısız';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      if (_error == null) {
        _error = 'Sunucuya bağlanılamadı: $e';
        notifyListeners();
      }
      debugPrint('❌ Register hatası: $e');
      rethrow;
    }
  }

  /// Giriş yap - mevcut kullanıcıyla şifreli giriş
  Future<void> login(String username, String password) async {
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.signalingServerUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userId = data['userId'];
        _username = data['username'];
        _token = data['token'];
        _isLoggedIn = true;

        // Yerel kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _userId!);
        await prefs.setString('username', _username!);
        await prefs.setString('token', _token!);

        notifyListeners();
        debugPrint('👤 Giriş yapıldı: $_username ($_userId)');
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Giriş başarısız';
        notifyListeners();
        throw Exception(_error);
      }
    } catch (e) {
      if (_error == null) {
        _error = 'Sunucuya bağlanılamadı: $e';
        notifyListeners();
      }
      debugPrint('❌ Login hatası: $e');
      rethrow;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    _userId = null;
    _username = null;
    _token = null;
    _isLoggedIn = false;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('token');

    notifyListeners();
  }
}
