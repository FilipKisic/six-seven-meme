import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  Future<bool> gatherConsentAndInitialize() async {
    try {
      await _requestConsentInfoUpdate();
      await _loadAndShowFormIfRequired();
    } on Object catch (error) {
      debugPrint('UMP consent gathering error: $error');
    }

    final canRequest = await ConsentInformation.instance.canRequestAds();
    if (canRequest) {
      await MobileAds.instance.initialize();
    }
    return canRequest;
  }

  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => completer.complete(),
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  Future<void> _loadAndShowFormIfRequired() async {
    if (!await ConsentInformation.instance.isConsentFormAvailable()) {
      return;
    }

    await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint('Consent form dismissed with error: ${error.message}');
      }
    });
  }
}
