import '../entities/promo_interaction.dart';
import '../repositories/promo_repository.dart';

/// Use case to track a promo interaction
class TrackPromoInteraction {
  final PromoRepository repository;

  const TrackPromoInteraction(this.repository);

  /// Execute the use case
  Future<void> call(PromoInteraction interaction) async {
    await repository.trackInteraction(interaction);
  }
}
