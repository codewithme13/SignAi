/// ============================================
/// SignAI - Call Screen (Arama Ekranı)
/// ============================================
/// WebRTC görüntülü arama ekranı.
/// AI altyazı overlay'i burada gösterilir.
/// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/call_provider.dart';
import '../services/webrtc_service.dart';
import '../utils/theme.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/call_controls.dart';
import '../widgets/call_timer.dart';
import '../widgets/sign_animation_overlay.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _showControls = true;
  Timer? _controlsTimer;
  bool _isMinimized = false;
  bool _isSwapped = false; // Video swap (tam ekran değiştirme)

  @override
  void initState() {
    super.initState();
    // Ekranı açık tut
    WakelockPlus.enable();
    _startControlsTimer();

    // Arama durumu değişikliklerini dinle
    // WidgetsBinding.instance.addPostFrameCallback, build metodu tamamlandıktan
    // sonra çalışarak context'in güvenli bir şekilde kullanılmasını sağlar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider'a erişim için context'i burada güvenle kullanabiliriz.
      // `listen: false` ile provider'ı dinlemeden sadece bir referans alırız,
      // çünkü listener'ı kendimiz manuel olarak ekleyeceğiz.
      final callProvider = context.read<CallProvider>();
      callProvider.addListener(_onCallStateChanged);
    });
  }

  // CallProvider'daki değişiklikleri dinleyen metod
  void _onCallStateChanged() {
    // Widget'ın hala ekranda olduğundan emin ol
    if (!mounted) return;

    final callProvider = context.read<CallProvider>();
    final callState = callProvider.webrtc.callState;

    // Eğer arama durumu 'bitti' veya 'boşta' ise, ekranı kapat
    if (callState == CallState.ended || callState == CallState.idle) {
      // Listener'ı daha fazla işlem yapmaması için hemen kaldır
      callProvider.removeListener(_onCallStateChanged);
      // Güvenli bir şekilde bir önceki ekrana dön
      Navigator.of(context).pop();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startControlsTimer();
    });
  }

  void _toggleMinimize() {
    setState(() => _isMinimized = !_isMinimized);
  }

  void _swapVideos() {
    setState(() => _isSwapped = !_isSwapped);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    WakelockPlus.disable();
    // Widget yok edilirken listener'ı bellek sızıntısını önlemek için kaldır.
    // try-catch bloğu, provider'ın beklenmedik bir şekilde yok olması
    // gibi nadir durumlarda uygulamanın çökmesini engeller.
    try {
      context.read<CallProvider>().removeListener(_onCallStateChanged);
    } catch (_) {
      debugPrint("CallScreen dispose: Listener kaldırılamadı veya zaten yoktu.");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final callState = callProvider.webrtc.callState;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // === ARKA PLAN: Video (swap durumuna göre) ===
            Positioned.fill(
              child: _isSwapped
                  ? _buildLocalVideoFull(callProvider)
                  : _buildRemoteVideo(callProvider),
            ),

            // === ÖN PLAN: Küçük video penceresi ===
            _isSwapped
                ? _buildRemoteVideoSmall(callProvider)
                : _buildLocalVideo(callProvider),

            // === BAĞLANTI DURUMU ===
            if (callState != CallState.connected)
              _buildConnectingOverlay(callState, callProvider),

            // === ALTYAZILAR (AI) ===
            Positioned(
              left: 16,
              right: 16,
              bottom: 160,
              child: SubtitleOverlay(
                signSubtitle: callProvider.signSubtitle,
                speechSubtitle: callProvider.speechSubtitle,
              ),
            ),

            // === İŞARET DİLİ ANİMASYONU ===
            // Karşıdaki kişi konuştuğunda, işaret dili animasyonu göster
            SignAnimationOverlay(
              text: callProvider.speechSubtitle,
              size: 120,
            ),

            // === ÜST BAR ===
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(callProvider),
              ),

            // === ALT KONTROLLER ===
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CallControls(
                  isMicMuted: callProvider.webrtc.isMicMuted,
                  isCameraOff: callProvider.webrtc.isCameraOff,
                  isFrontCamera: callProvider.webrtc.isFrontCamera,
                  onToggleMic: callProvider.toggleMic,
                  onToggleCamera: callProvider.toggleCamera,
                  onSwitchCamera: callProvider.switchCamera,
                  onHangUp: () => _hangUp(callProvider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Karşı tarafın video görüntüsü
  Widget _buildRemoteVideo(CallProvider callProvider) {
    final remoteStream = callProvider.webrtc.remoteStream;

    if (remoteStream == null) {
      return Container(
        color: SignAITheme.bgDark,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 80,
                color: SignAITheme.textHint,
              ),
              SizedBox(height: 16),
              Text(
                'Video bekleniyor...',
                style: TextStyle(
                  color: SignAITheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RTCVideoView(
      callProvider.webrtc.remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  /// Swap modunda: yerel video tam ekran
  Widget _buildLocalVideoFull(CallProvider callProvider) {
    if (callProvider.webrtc.isCameraOff) {
      return Container(
        color: SignAITheme.bgDark,
        child: const Center(
          child: Icon(Icons.videocam_off, size: 80, color: SignAITheme.textHint),
        ),
      );
    }
    return RTCVideoView(
      callProvider.webrtc.localRenderer,
      mirror: callProvider.webrtc.isFrontCamera,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  /// Swap modunda: karşı video küçük pencere
  Widget _buildRemoteVideoSmall(CallProvider callProvider) {
    final double width = _isMinimized ? 100 : 130;
    final double height = _isMinimized ? 140 : 180;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      right: 16,
      child: GestureDetector(
        onTap: _toggleMinimize,
        onDoubleTap: _swapVideos,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: SignAITheme.bgDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SignAITheme.accentColor.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: callProvider.webrtc.remoteStream == null
              ? const Center(
                  child: Icon(Icons.videocam_off, color: SignAITheme.textHint, size: 30),
                )
              : RTCVideoView(
                  callProvider.webrtc.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
      ),
    );
  }

  /// Kendi küçük video penceren
  Widget _buildLocalVideo(CallProvider callProvider) {
    final double width = _isMinimized ? 100 : 130;
    final double height = _isMinimized ? 140 : 180;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      right: 16,
      child: GestureDetector(
        onTap: _toggleMinimize,
        onDoubleTap: _swapVideos,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: SignAITheme.bgDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SignAITheme.primaryColor.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: callProvider.webrtc.isCameraOff
              ? const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: SignAITheme.textHint,
                    size: 30,
                  ),
                )
              : RTCVideoView(
                  callProvider.webrtc.localRenderer,
                  mirror: callProvider.webrtc.isFrontCamera,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
      ),
    );
  }

  /// Bağlantı bekleme overlay'i
  Widget _buildConnectingOverlay(CallState state, CallProvider callProvider) {
    String message;
    IconData icon;

    switch (state) {
      case CallState.calling:
        message = '${callProvider.currentCallUserName ?? "Kullanıcı"} aranıyor...';
        icon = Icons.ring_volume;
        break;
      case CallState.connecting:
        message = 'Bağlantı kuruluyor...';
        icon = Icons.sync;
        break;
      case CallState.reconnecting:
        message = 'Yeniden bağlanılıyor...';
        icon = Icons.refresh;
        break;
      case CallState.ended:
        message = 'Arama sona erdi';
        icon = Icons.call_end;
        break;
      default:
        message = 'Hazırlanıyor...';
        icon = Icons.hourglass_empty;
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: SignAITheme.primaryColor),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              if (state != CallState.ended)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(SignAITheme.primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Üst bar
  Widget _buildTopBar(CallProvider callProvider) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Geri butonu
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _hangUp(callProvider),
          ),
          const SizedBox(width: 8),
          // Kullanıcı adı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                callProvider.currentCallUserName ?? 'Bilinmeyen',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: callProvider.webrtc.callState == CallState.connected
                        ? SignAITheme.accentGreen
                        : SignAITheme.warningOrange,
                  ),
                  const SizedBox(width: 4),
                  CallTimer(
                    isActive: callProvider.webrtc.callState == CallState.connected,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Şifreleme ikonu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SignAITheme.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 14, color: SignAITheme.accentGreen),
                SizedBox(width: 4),
                Text(
                  'P2P',
                  style: TextStyle(
                    color: SignAITheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // AI durumu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: callProvider.isAiRunning
                  ? SignAITheme.primaryColor.withOpacity(0.2)
                  : SignAITheme.textHint.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: callProvider.isAiRunning
                      ? SignAITheme.primaryColor
                      : SignAITheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    color: callProvider.isAiRunning
                        ? SignAITheme.primaryColor
                        : SignAITheme.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aramayı bitir
  Future<void> _hangUp(CallProvider callProvider) async {
    // endCall() içinde webrtc.hangUp() çağrılır → state ended olur
    // → _onCallStateChanged listener zaten Navigator.pop() yapar
    // Bu yüzden burada tekrar pop yapmıyoruz (double-pop → siyah ekran)
    await callProvider.endCall();
    // Listener tetiklenmezse (edge case) güvenlik için pop yap
    if (mounted && callProvider.webrtc.callState != CallState.ended) {
      Navigator.of(context).pop();
    }
  }
}
