import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'privacy_security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImagePath = path);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;

      // Fotoğrafı kalıcı olarak kaydet
      final dir = await getApplicationDocumentsDirectory();
      final savedPath = '${dir.path}/profile_photo.jpg';
      await File(image.path).copy(savedPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', savedPath);

      setState(() => _profileImagePath = savedPath);

      // Sunucuya da yükle (diğer kullanıcılar görsün)
      await _uploadPhotoToServer(savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
      );
    }
  }

  Future<void> _uploadPhotoToServer(String filePath) async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;

      final uri = Uri.parse('${AppConstants.signalingServerUrl}/api/profile/photo');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      final response = await request.send();
      if (response.statusCode == 200) {
        debugPrint('📸 Profil fotoğrafı sunucuya yüklendi');
      } else {
        debugPrint('⚠️ Fotoğraf yükleme hatası: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Fotoğraf sunucuya yüklenemedi: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profil Fotoğrafı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF)),
                  title: Text('Kamera', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF6C63FF)),
                  title: Text('Galeri', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImagePath != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: Text('Fotoğrafı Kaldır', style: TextStyle(color: textColor)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('profileImagePath');
                      setState(() => _profileImagePath = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1D1F33) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB0B0C3) : const Color(0xFF6B6B80);
    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ve Ayarlar', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        color: bgColor,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Profil Fotoğrafı & Bilgiler
            _buildProfileHeader(auth, textColor, subtitleColor),
            const SizedBox(height: 30),

            // Ayarlar
            Text(
              'AYARLAR',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),

            // Bildirimler Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Color(0xFF8B85FF)),
                title: Text('Bildirimler', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  themeProvider.notificationsEnabled ? 'Açık' : 'Kapalı',
                  style: TextStyle(color: subtitleColor),
                ),
                value: themeProvider.notificationsEnabled,
                activeColor: const Color(0xFF6C63FF),
                onChanged: (value) {
                  themeProvider.setNotifications(value);
                },
              ),
            ),

            // Tema Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF8B85FF),
                ),
                title: Text('Görünüm', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  isDark ? 'Koyu Tema' : 'Açık Tema',
                  style: TextStyle(color: subtitleColor),
                ),
                value: isDark,
                activeColor: const Color(0xFF6C63FF),
                onChanged: (value) {
                  themeProvider.setDarkMode(value);
                },
              ),
            ),

            // Gizlilik ve Güvenlik
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF8B85FF)),
                title: Text('Gizlilik ve Güvenlik', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Çıkış Butonu
            _buildLogoutButton(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth, Color textColor, Color subtitleColor) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: _profileImagePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(_profileImagePath!),
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1D1F33),
                          ),
                          child: Center(
                            child: Text(
                              (auth.username ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0A0E21), width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          auth.username ?? 'Bilinmeyen Kullanıcı',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          auth.userId ?? 'ID bulunamadı',
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        'Güvenli Çıkış',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF5252).withOpacity(0.8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: () async {
        await auth.logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
