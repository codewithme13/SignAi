/// SignAI - Gelen Arama Diyaloğu Widget'ı
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

String _getServerBaseUrl() {
  return AppConstants.signalingServerUrl;
}

class IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String? callerPhotoUrl;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    super.key,
    required this.callerName,
    this.callerPhotoUrl,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Titreşim başlat
    _startVibration();
  }

  /// Gelen arama titreşimi
  Future<void> _startVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Titreşim pattern'i: 500ms titreşim, 1000ms bekleme, tekrarla
      Vibration.vibrate(
        pattern: [0, 500, 1000, 500, 1000, 500],
        intensities: [0, 200, 0, 200, 0, 200],
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Titreşimi durdur
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: SignAITheme.bgCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: SignAITheme.callGreen.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: SignAITheme.callGreen.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titreşimli avatar
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: SignAITheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SignAITheme.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: widget.callerPhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              '${_getServerBaseUrl()}${widget.callerPhotoUrl}',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  widget.callerName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.callerName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // "Gelen Arama" başlığı
            const Text(
              '📞 Gelen Arama',
              style: TextStyle(
                color: SignAITheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Arayan ismi
            Text(
              widget.callerName,
              style: const TextStyle(
                color: SignAITheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Görüntülü arama',
              style: TextStyle(
                color: SignAITheme.textHint,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 32),

            // Kabul / Red butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reddet
                _CallActionButton(
                  icon: Icons.call_end,
                  label: 'Reddet',
                  color: SignAITheme.callRed,
                  onTap: widget.onReject,
                ),

                // Kabul et
                _CallActionButton(
                  icon: Icons.videocam,
                  label: 'Kabul Et',
                  color: SignAITheme.callGreen,
                  onTap: widget.onAccept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
