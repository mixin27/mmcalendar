import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsConsentManager with ChangeNotifier {
  ConsentStatus? status;

  bool get hasConsent =>
      status == ConsentStatus.obtained || status == ConsentStatus.notRequired;

  AdsConsentManager() {
    ConsentInformation.instance.getConsentStatus().then((status) {
      status = status;
      notifyListeners();
    });
  }

  void updateConsent() {
    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyDisabled,
      ),
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadForm();
        }
      },
      (FormError error) {},
    );
  }

  void _loadForm() {
    ConsentForm.loadConsentForm(
      (consentForm) async {
        status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (formError) => _loadForm(),
          );
        }
      },
      (formError) {},
    );
  }

  Future<void> debugReset() async {
    await ConsentInformation.instance.reset();
  }
}

/// Helper variable to determine if the privacy options entry point is required.
Future<bool> isPrivacyOptionsRequired() async {
  return await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;
}
