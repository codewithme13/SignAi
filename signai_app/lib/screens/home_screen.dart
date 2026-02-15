/// SignAI - Home Screen (Ana Ekran)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../services/signaling_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'call_screen.dart';
import 'login_screen.dart';
import 'package:signai_app/screens/profile_screen.dart';

import '../widgets/incoming_call_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _userIdController = TextEditingController();
  bool _isInitialized = false;
  bool _isDialogShowing = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _profileImagePath = path);
    } else {
      if (mounted) setState(() => _profileImagePath = null);
    }
  }

  Future<void> _initializeServices() async {
    final auth = context.read<AuthProvider>();
    final callProvider = context.read<CallProvider>();

    // Servisleri başlat (JWT token, userId, username ile)
    await callProvider.initializeServices(
      token: auth.token,
      userId: auth.userId,
      username: auth.username,
    );

    // Gelen arama dinleyicisi — CallProvider'ı dinle, callback'i ezme
    callProvider.addListener(_handleIncomingCall);

    setState(() => _isInitialized = true);
  }

  void _handleIncomingCall() {
    if (!mounted) return;
    if (_isDialogShowing) return;
    final callProvider = context.read<CallProvider>();
    if (callProvider.hasIncomingCall && callProvider.incomingCall != null) {
      _showIncomingCallDialog(callProvider.incomingCall!);
    }
  }

  void _showIncomingCallDialog(IncomingCall call) {
    _isDialogShowing = true;
    // Dış context referanslarını dialog açılmadan önce yakala
    final outerContext = context;
    final callProvider = outerContext.read<CallProvider>();

    showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (dialogContext) => IncomingCallDialog(
        callerName: call.callerName,
        callerPhotoUrl: call.callerPhoto,
        onAccept: () {
          _isDialogShowing = false;
          Navigator.of(dialogContext).pop();
          callProvider.acceptCall().then((_) {
            if (mounted) {
              Navigator.push(
                outerContext,
                MaterialPageRoute(builder: (_) => const CallScreen()),
              );
            }
          });
        },
        onReject: () {
          _isDialogShowing = false;
          Navigator.of(dialogContext).pop();
          callProvider.rejectCall();
        },
      ),
    );
  }

  Future<void> _startCall(String targetUserId, {String? targetUsername}) async {
    final auth = context.read<AuthProvider>();
    final callProvider = context.read<CallProvider>();

    if (targetUserId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir kullanıcı ID gir')),
      );
      return;
    }

    try {
      await callProvider.startCall(
        targetUserId.trim(),
        targetUsername ?? 'Kullanıcı',
        auth.userId!,
        auth.username!,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallScreen()),
      );

      // CallScreen'den döndükten sonra hata varsa göster
      if (!mounted) return;
      final error = callProvider.lastError;
      if (error != null) {
        callProvider.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama hatası: $e')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final callProvider = context.read<CallProvider>();
    if (state == AppLifecycleState.paused) {
      debugPrint('📱 Uygulama arka plana alındı');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('📱 Uygulama ön plana geldi');
      // Bağlantı kopmuşsa yeniden bağlan
      if (!callProvider.signaling.isConnected) {
        _initializeServices();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Listener'ı temizle
    try {
      final cp = context.read<CallProvider>();
      cp.removeListener(_handleIncomingCall);
      cp.cleanup();
    } catch (_) {}
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final callProvider = context.watch<CallProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(auth),

              // Bağlantı durumu
              _buildConnectionStatus(callProvider),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kullanıcı bilgisi kartı
                      _buildUserCard(auth),
                      const SizedBox(height: 24),

                      // Arama başlat
                      _buildCallSection(),
                      const SizedBox(height: 24),

                      // Online kullanıcılar
                      _buildOnlineUsers(callProvider),
                      const SizedBox(height: 24),

                      // Özellikler bölümü kaldırıldı
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB0B0C3) : const Color(0xFF6B6B80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: SignAITheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sign_language, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'SignAI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.account_circle, color: subtitleColor, size: 28),
            tooltip: 'Profil',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadProfileImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(CallProvider callProvider) {
    final isConnected = callProvider.signaling.isConnected;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isConnected ? SignAITheme.accentGreen : SignAITheme.callRed)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? SignAITheme.accentGreen : SignAITheme.callRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Sunucuya Bağlı' : 'Bağlantı Bekleniyor...',
            style: TextStyle(
              color: isConnected ? SignAITheme.accentGreen : SignAITheme.callRed,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AuthProvider auth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SignAITheme.bgCard : Colors.white;
    final cardAltColor = isDark ? SignAITheme.bgCardLight : const Color(0xFFF0F0F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB0B0C3) : const Color(0xFF6B6B80);
    final hintColor = isDark ? SignAITheme.textHint : const Color(0xFF9999AA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SignAITheme.primaryColor.withOpacity(0.3)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          _profileImagePath != null
              ? Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SignAITheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ],
                    image: DecorationImage(
                      image: FileImage(File(_profileImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: SignAITheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SignAITheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (auth.username ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            auth.username ?? 'Bilinmeyen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // User ID (kopyalanabilir)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardAltColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, size: 16, color: SignAITheme.accentColor),
                const SizedBox(width: 8),
                Flexible(
                  child: SelectableText(
                    auth.userId ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID\'ni paylaşarak seni aramasını sağla',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCallSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SignAITheme.bgCard : Colors.white;
    final cardAltColor = isDark ? SignAITheme.bgCardLight : const Color(0xFFF0F0F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final hintColor = isDark ? SignAITheme.textHint : const Color(0xFF9999AA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: SignAITheme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Görüntülü Arama Başlat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _userIdController,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Karşı tarafın User ID\'sini gir',
              hintStyle: TextStyle(color: hintColor, fontSize: 13),
              prefixIcon: const Icon(Icons.person_search, color: SignAITheme.primaryLight),
              filled: true,
              fillColor: cardAltColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: SignAITheme.callButtonGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: SignAITheme.callGreen.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isInitialized ? () => _startCall(_userIdController.text) : null,
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text(
                'Ara',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsers(CallProvider callProvider) {
    final users = callProvider.onlineUsers;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SignAITheme.bgCard : Colors.white;
    final cardAltColor = isDark ? SignAITheme.bgCardLight : const Color(0xFFF0F0F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final hintColor = isDark ? SignAITheme.textHint : const Color(0xFF9999AA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: SignAITheme.accentGreen),
              const SizedBox(width: 8),
              Text(
                'Online Kullanıcılar (${users.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Henüz online kullanıcı yok 😴\nID\'ni paylaşarak arkadaşlarını davet et!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            ...users.map((user) => _buildUserTile(user)),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardAltColor = isDark ? SignAITheme.bgCardLight : const Color(0xFFF0F0F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final String? photoPath = user['photoUrl'];
    final String serverUrl = AppConstants.signalingServerUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Profil fotoğrafı veya baş harf
          photoPath != null && photoPath.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    '$serverUrl$photoPath',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialAvatar(user),
                  ),
                )
              : _buildInitialAvatar(user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? 'Bilinmeyen',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: SignAITheme.accentGreen),
                    SizedBox(width: 4),
                    Text(
                      'Çevrimiçi',
                      style: TextStyle(
                        color: SignAITheme.accentGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Arama butonu
          Container(
            decoration: const BoxDecoration(
              gradient: SignAITheme.callButtonGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white, size: 20),
              onPressed: _isInitialized ? () => _startCall(user['userId'], targetUsername: user['username']) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(Map<String, dynamic> user) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: SignAITheme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (user['username'] ?? '?')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
