/// ============================================
/// SignAI - İşaret Dili Animasyon Widget'ı
/// ============================================
/// Konuşma → İşaret Dili animasyonu gösterir
/// Karşıdaki kişi sadece işaret dili biliyorsa,
/// konuşulan kelimeler animasyonla gösterilir.
/// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Desteklenen kelimeler ve animasyon dosya yolları
const Map<String, String> _wordAnimationMap = {
  'merhaba': 'assets/animations/merhaba.json',
  'selam': 'assets/animations/merhaba.json',
  'yardım': 'assets/animations/yardim.json',
  'yardim': 'assets/animations/yardim.json',
  'imdat': 'assets/animations/yardim.json',
  'hoşçakal': 'assets/animations/hoscakal.json',
  'hoscakal': 'assets/animations/hoscakal.json',
  'güle güle': 'assets/animations/hoscakal.json',
  'hayır': 'assets/animations/hayir.json',
  'hayir': 'assets/animations/hayir.json',
  'yok': 'assets/animations/hayir.json',
  'teşekkür': 'assets/animations/tesekkurler.json',
  'teşekkürler': 'assets/animations/tesekkurler.json',
  'tesekkurler': 'assets/animations/tesekkurler.json',
  'sağol': 'assets/animations/tesekkurler.json',
  'evet': 'assets/animations/evet.json',
  'tamam': 'assets/animations/evet.json',
  'olur': 'assets/animations/evet.json',
  'yemek': 'assets/animations/yemek.json',
  'yemek yemek': 'assets/animations/yemek.json',
  'aç': 'assets/animations/yemek.json',
  'acıktım': 'assets/animations/yemek.json',
  'su': 'assets/animations/su.json',
  'su içmek': 'assets/animations/su.json',
  'susadım': 'assets/animations/su.json',
  'dur': 'assets/animations/dur.json',
  'durun': 'assets/animations/dur.json',
  'bekle': 'assets/animations/dur.json',
  'ben': 'assets/animations/ben.json',
  'benim': 'assets/animations/ben.json',
  'nasılsın': 'assets/animations/nasilsin.json',
  'nasilsin': 'assets/animations/nasilsin.json',
  'nasıl': 'assets/animations/nasilsin.json',
  'seni seviyorum': 'assets/animations/seni_seviyorum.json',
  'seviyorum': 'assets/animations/seni_seviyorum.json',
};

class SignAnimationOverlay extends StatefulWidget {
  /// Gösterilecek konuşma metni (null = gizle)
  final String? text;

  /// Animasyon boyutu
  final double size;

  /// Animasyon tamamlandığında callback
  final VoidCallback? onAnimationComplete;

  const SignAnimationOverlay({
    super.key,
    this.text,
    this.size = 150,
    this.onAnimationComplete,
  });

  @override
  State<SignAnimationOverlay> createState() => _SignAnimationOverlayState();
}

class _SignAnimationOverlayState extends State<SignAnimationOverlay>
    with TickerProviderStateMixin {
  String? _currentAnimation;
  String? _currentWord;
  Timer? _hideTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SignAnimationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != null) {
      _processText(widget.text!);
    }
  }

  /// Metni işle ve eşleşen kelimelerin animasyonunu göster
  void _processText(String text) {
    final lowerText = text.toLowerCase().trim();

    // Önce tam cümle eşleşmesi dene
    String? matchedAnimation = _wordAnimationMap[lowerText];
    String? matchedWord = matchedAnimation != null ? lowerText : null;

    // Eşleşme yoksa tek tek kelimelerde ara
    if (matchedAnimation == null) {
      final words = lowerText.split(' ');
      for (final word in words) {
        if (_wordAnimationMap.containsKey(word)) {
          matchedAnimation = _wordAnimationMap[word];
          matchedWord = word;
          break;
        }
      }
    }

    if (matchedAnimation != null && matchedWord != null) {
      _showAnimation(matchedAnimation, matchedWord);
    }
  }

  /// Animasyonu göster
  void _showAnimation(String animationPath, String word) {
    _hideTimer?.cancel();

    setState(() {
      _currentAnimation = animationPath;
      _currentWord = word;
    });

    _fadeController.forward();

    // Animasyon + kelime gösterimi için 3 saniye bekle
    _hideTimer = Timer(const Duration(seconds: 3), () {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentAnimation = null;
            _currentWord = null;
          });
          widget.onAnimationComplete?.call();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAnimation == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.deepPurple.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🤟',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'İşaret Dili',
                      style: TextStyle(
                        color: Colors.deepPurple[200],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lottie Animasyonu
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Lottie.asset(
                    _currentAnimation!,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),

                const SizedBox(height: 12),

                // Kelime gösterimi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentWord?.toUpperCase() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stateless versiyonu - basit kullanım için
class SignAnimationDisplay extends StatelessWidget {
  final String word;
  final double size;

  const SignAnimationDisplay({
    super.key,
    required this.word,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final animationPath = _wordAnimationMap[word.toLowerCase()];

    if (animationPath == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            animationPath,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          word.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
