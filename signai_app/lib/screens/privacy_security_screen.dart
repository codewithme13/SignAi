import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  bool _twoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1D1F33) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB0B0C3) : const Color(0xFF6B6B80);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gizlilik ve Güvenlik', style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Gizlilik Bölümü
            Text(
              'GİZLİLİK',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _buildSwitchTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.circle,
              title: 'Çevrimiçi Durumunu Göster',
              subtitle: 'Diğer kullanıcılar seni çevrimiçi görebilir',
              value: _showOnlineStatus,
              onChanged: (v) => setState(() => _showOnlineStatus = v),
            ),
            _buildSwitchTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.done_all,
              title: 'Okundu Bilgisi',
              subtitle: 'Mesajların okunduğunu göster',
              value: _readReceipts,
              onChanged: (v) => setState(() => _readReceipts = v),
            ),

            const SizedBox(height: 30),

            // Güvenlik Bölümü
            Text(
              'GÜVENLİK',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _buildSwitchTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.security,
              title: 'İki Faktörlü Doğrulama',
              subtitle: 'Hesabını ekstra güvenlikle koru',
              value: _twoFactorAuth,
              onChanged: (v) => setState(() => _twoFactorAuth = v),
            ),
            _buildActionTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.lock_reset,
              title: 'Şifre Değiştir',
              subtitle: 'Hesap şifreni güncelle',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre değiştirme yakında eklenecek')),
                );
              },
            ),
            _buildActionTile(
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.devices,
              title: 'Aktif Oturumlar',
              subtitle: 'Hesabına bağlı cihazları yönet',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cihaz yönetimi yakında eklenecek')),
                );
              },
            ),

            const SizedBox(height: 30),

            // Bilgi Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFF6C63FF), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uçtan Uca Şifreli',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tüm görüntülü aramalarınız WebRTC ile uçtan uca şifrelidir.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF8B85FF)),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
        value: value,
        activeColor: const Color(0xFF6C63FF),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B85FF)),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }
}
