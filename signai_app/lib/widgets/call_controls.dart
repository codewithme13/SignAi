/// SignAI - Arama Kontrol Butonları Widget'ı
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CallControls extends StatelessWidget {
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onHangUp;

  const CallControls({
    super.key,
    required this.isMicMuted,
    required this.isCameraOff,
    required this.isFrontCamera,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mikrofon
          _ControlButton(
            icon: isMicMuted ? Icons.mic_off : Icons.mic,
            label: isMicMuted ? 'Aç' : 'Sessiz',
            isActive: !isMicMuted,
            activeColor: Colors.white,
            inactiveColor: SignAITheme.callRed,
            onTap: onToggleMic,
          ),

          // Kamera
          _ControlButton(
            icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: isCameraOff ? 'Aç' : 'Kapat',
            isActive: !isCameraOff,
            activeColor: Colors.white,
            inactiveColor: SignAITheme.callRed,
            onTap: onToggleCamera,
          ),

          // Kamera değiştir
          _ControlButton(
            icon: Icons.cameraswitch,
            label: 'Çevir',
            isActive: true,
            activeColor: Colors.white,
            inactiveColor: Colors.white,
            onTap: onSwitchCamera,
          ),

          // Kapat (büyük kırmızı buton)
          GestureDetector(
            onTap: onHangUp,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: SignAITheme.callRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SignAITheme.callRed.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : inactiveColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.white.withOpacity(0.3)
                    : inactiveColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white70 : inactiveColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
