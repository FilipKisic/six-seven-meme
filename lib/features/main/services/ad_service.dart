import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isDisposed = false;
  bool _isBannerLoading = false;
  bool _isInterstitialLoading = false;
  bool _isInterstitialShowing = false;

  BannerAd? get bannerAd => _bannerAd;

  void loadBanner({VoidCallback? onLoaded}) {
    if (_isDisposed || _isBannerLoading || _bannerAd != null) {
      return;
    }

    _isBannerLoading = true;
    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoading = false;

          if (_isDisposed) {
            ad.dispose();
            return;
          }

          _bannerAd = ad as BannerAd;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoading = false;
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    unawaited(_loadBanner(bannerAd));
  }

  Future<void> _loadBanner(BannerAd bannerAd) async {
    try {
      await bannerAd.load();
    } on Object catch (error) {
      _isBannerLoading = false;
      debugPrint('BannerAd load threw: $error');
      bannerAd.dispose();
    }
  }

  void loadInterstitial() {
    if (_isDisposed || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    unawaited(_loadInterstitial());
  }

  Future<void> _loadInterstitial() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isInterstitialLoading = false;

            if (_isDisposed) {
              ad.dispose();
              return;
            }

            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoading = false;
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    } on Object catch (error) {
      _isInterstitialLoading = false;
      debugPrint('InterstitialAd load threw: $error');
    }
  }

  Future<void> showInterstitial() async {
    if (_isDisposed || _isInterstitialShowing) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitial();
      return;
    }

    _interstitialAd = null;
    _isInterstitialShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialShowing = false;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _isInterstitialShowing = false;
        loadInterstitial();
      },
    );

    try {
      await ad.show();
    } on Object catch (error) {
      debugPrint('InterstitialAd show threw: $error');
      ad.dispose();
      _isInterstitialShowing = false;
      loadInterstitial();
    }
  }

  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
  }

  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
