part of 'promo_bloc.dart';

/// Base class for promo events
abstract class PromoEvent extends Equatable {
  const PromoEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if onboarding should be shown
class CheckOnboardingRequested extends PromoEvent {
  const CheckOnboardingRequested();
}

/// Event to check if feature announcements should be shown
class CheckFeatureAnnouncementsRequested extends PromoEvent {
  final String currentVersion;

  const CheckFeatureAnnouncementsRequested(this.currentVersion);

  @override
  List<Object?> get props => [currentVersion];
}
