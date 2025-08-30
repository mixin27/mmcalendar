class AdsConfig {
  final String appId;
  final Map<String, String> adUnitIds;

  AdsConfig({required this.appId, required this.adUnitIds});

  String? banner(String key) => adUnitIds['banner.$key'] ?? adUnitIds['banner'];

  String? interstitial(String key) =>
      adUnitIds['interstitial.$key'] ?? adUnitIds['interstitial'];

  String? rewarded(String key) =>
      adUnitIds['rewarded.$key'] ?? adUnitIds['rewarded'];

  String? appOpen(String key) =>
      adUnitIds['appopen.$key'] ?? adUnitIds['appopen'];

  String? native(String key) => adUnitIds['native.$key'] ?? adUnitIds['native'];
}
