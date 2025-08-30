class AdSizeConfig {
  final int width;
  final int height;

  const AdSizeConfig(this.width, this.height);

  static const banner = AdSizeConfig(320, 50);
  static const largeBanner = AdSizeConfig(320, 100);
  static const mediumRectangle = AdSizeConfig(300, 250);
  static const leaderboard = AdSizeConfig(728, 90);
}
