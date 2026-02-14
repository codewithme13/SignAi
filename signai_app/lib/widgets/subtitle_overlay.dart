/// SignAI - Altyazı Overlay Widget'ı
/// Video üzerinde AI tarafından oluşturulan altyazıları gösterir.
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SubtitleOverlay extends StatelessWidget {
  final String signSubtitle;    // İşaret dilinden gelen metin
  final String speechSubtitle;  // Konuşmadan gelen metin

  const SubtitleOverlay({
    super.key,
    this.signSubtitle = '',
    this.speechSubtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final hasSign = signSubtitle.isNotEmpty;
    final hasSpeech = speechSubtitle.isNotEmpty;

    if (!hasSign && !hasSpeech) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İşaret dili altyazısı (karşı taraftan gelen)
        if (hasSign)
          _SubtitleBubble(
            text: signSubtitle,
            icon: Icons.sign_language,
            label: 'İşaret Dili',
            color: SignAITheme.primaryColor,
          ),

        if (hasSign && hasSpeech) const SizedBox(height: 8),

        // Konuşma altyazısı (ses tanımadan gelen)
        if (hasSpeech)
          _SubtitleBubble(
            text: speechSubtitle,
            icon: Icons.mic,
            label: 'Konuşma',
            color: SignAITheme.accentColor,
          ),
      ],
    );
  }
}

class _SubtitleBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  final String label;
  final Color color;

  const _SubtitleBubble({
    required this.text,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: text.isEmpty ? 0 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SignAITheme.subtitleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Etiket
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Metin
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.3,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
