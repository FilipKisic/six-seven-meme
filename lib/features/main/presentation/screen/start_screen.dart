import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:six_seven/core/constants/app_assets.dart';
import 'package:six_seven/features/main/services/ad_service.dart';
import 'package:six_seven/features/main/services/start_sound_player.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final StartSoundPlayer _soundPlayer = StartSoundPlayer();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 680))..value = 0.5;
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    // Start loading.
    bannerAd.load();
  }

  Future<void> _startMemeMotion() async {
    if (_controller.isAnimating) {
      return;
    }

    unawaited(_playTapSound());
    _controller.repeat(reverse: true);
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    _controller
      ..stop()
      ..value = 0.5;
  }

  Future<void> _playTapSound() async {
    try {
      await _soundPlayer.play();
    } on Object {
      debugPrint('Failed to play sound');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111616),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startMemeMotion,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _SixSevenBackground(),
              Center(child: _AnimatedHands(animation: _controller)),
              const Align(alignment: Alignment(0, 0.63), child: _BottomPrompt()),
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_soundPlayer.dispose());
    _bannerAd?.dispose();
    super.dispose();
  }
}

class _SixSevenBackground extends StatelessWidget {
  const _SixSevenBackground();

  static const _words = ['SIX', 'SEVEN'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final fontSize = shortestSide < 500 ? 94.0 : 132.0;
        final rowHeight = fontSize * 0.98;
        final rowCount = (constraints.maxHeight / rowHeight).ceil() + 2;

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(rowCount, (rowIndex) {
              final word = _words[rowIndex.isEven ? 0 : 1];
              final color = rowIndex.isEven ? const Color(0xFF383E3E) : const Color(0xFF00565B);

              return Positioned(
                top: rowIndex * rowHeight,
                left: 0,
                right: 0,
                height: rowHeight,
                child: _RepeatedWordRow(word: word, color: color, fontSize: fontSize, shifted: rowIndex.isOdd),
              );
            }),
          ),
        );
      },
    );
  }
}

class _RepeatedWordRow extends StatelessWidget {
  const _RepeatedWordRow({required this.word, required this.color, required this.fontSize, required this.shifted});

  final String word;
  final Color color;
  final double fontSize;
  final bool shifted;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w900, height: 0.96, letterSpacing: 0);

    return Transform.translate(
      offset: Offset(shifted ? -fontSize * 0.54 : -fontSize * 0.06, 0),
      child: Text(word * 12, maxLines: 1, overflow: TextOverflow.visible, softWrap: false, style: textStyle),
    );
  }
}

class _AnimatedHands extends StatelessWidget {
  const _AnimatedHands({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final imageWidth = math.min(screenWidth * 0.45, 185.0);
        final overlap = math.min(screenWidth * 0.05, 20.0);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final eased = Curves.easeInOut.transform(animation.value);
            final offset = (eased - 0.5) * 32;

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -offset),
                  child: Image.asset(AppAssets.leftHand, width: imageWidth, filterQuality: FilterQuality.high),
                ),
                Transform.translate(
                  offset: Offset(-overlap, offset),
                  child: Image.asset(AppAssets.rightHand, width: imageWidth, filterQuality: FilterQuality.high),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BottomPrompt extends StatelessWidget {
  const _BottomPrompt();

  @override
  Widget build(BuildContext context) {
    const text = 'Tap for meme';
    const fillStyle = TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1, letterSpacing: 0);

    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fillStyle.fontSize,
            fontWeight: fillStyle.fontWeight,
            height: fillStyle.height,
            letterSpacing: fillStyle.letterSpacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.black,
          ),
        ),
        const Text(text, style: fillStyle),
      ],
    );
  }
}
