import '../../domain/entities/promo_interaction.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/promo_local_datasource.dart';

/// Implementation of PromoRepository
class PromoRepositoryImpl implements PromoRepository {
  final PromoLocalDataSource localDataSource;

  const PromoRepositoryImpl(this.localDataSource);

  @override
  Future<bool> hasSeenCampaign(String campaignId) async {
    return localDataSource.hasSeenCampaign(campaignId);
  }

  @override
  Future<void> markCampaignAsSeen(String campaignId) async {
    await localDataSource.markCampaignAsSeen(campaignId);
  }

  @override
  Future<void> trackInteraction(PromoInteraction interaction) async {
    await localDataSource.trackInteraction(interaction);
  }

  @override
  Future<String?> getLastSeenVersion() async {
    return localDataSource.getLastSeenVersion();
  }

  @override
  Future<void> setLastSeenVersion(String version) async {
    await localDataSource.setLastSeenVersion(version);
  }

  @override
  Future<List<PromoInteraction>> getInteractionsForCampaign(
    String campaignId,
  ) async {
    return localDataSource.getInteractionsForCampaign(campaignId);
  }

  @override
  Future<void> clearAllData() async {
    await localDataSource.clearAllData();
  }
}
