import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class AppOpenAdService {
  static const _lastImpressionKey = 'app_open_ad_last_impression';
  static const _displayInterval = Duration(hours: 12);
  static const _loadTimeout = Duration(seconds: 8);

  AppOpenAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  DateTime? _lastImpressionAt;

  Future<void> showIfEligible() async {
    if (_isLoading || _isShowing || !await _isEligible()) return;

    final adUnitId = kDebugMode ? appOpenAdUnitIdTEST : appOpenAdUnitIdPROD;
    if (adUnitId.isEmpty) {
      debugPrint(
        'App open ad disabled: configure APP_OPEN_AD_UNIT_ID for release.',
      );
      return;
    }

    _isLoading = true;
    final loaded = Completer<AppOpenAd?>();
    AppOpenAd? ad;
    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (loadedAd) {
            if (!loaded.isCompleted) loaded.complete(loadedAd);
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open ad failed to load: ${error.message}');
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
      ad = await loaded.future.timeout(_loadTimeout);
    } on TimeoutException {
      debugPrint('App open ad load timed out.');
    } catch (error) {
      debugPrint('App open ad load error: $error');
    } finally {
      _isLoading = false;
    }
    if (ad == null || _isShowing || !await _isEligible()) {
      ad?.dispose();
      return;
    }

    _ad = ad;
    _isShowing = true;
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdImpression: (_) => unawaited(_recordImpression()),
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _clearAd();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('App open ad failed to show: ${error.message}');
        failedAd.dispose();
        _clearAd();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show();
      await dismissed.future;
    } catch (error) {
      debugPrint('App open ad show error: $error');
      ad.dispose();
      _clearAd();
    }
  }

  Future<bool> _isEligible() async {
    final inMemoryImpression = _lastImpressionAt;
    if (inMemoryImpression != null &&
        DateTime.now().difference(inMemoryImpression) < _displayInterval) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastImpressionMillis = prefs.getInt(_lastImpressionKey);
    if (lastImpressionMillis == null) return true;

    final lastImpression = DateTime.fromMillisecondsSinceEpoch(
      lastImpressionMillis,
    );
    return DateTime.now().difference(lastImpression) >= _displayInterval;
  }

  Future<void> _recordImpression() async {
    final impressionAt = DateTime.now();
    _lastImpressionAt = impressionAt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastImpressionKey, impressionAt.millisecondsSinceEpoch);
  }

  void _clearAd() {
    _ad = null;
    _isShowing = false;
  }

  void dispose() {
    _ad?.dispose();
    _clearAd();
  }
}
