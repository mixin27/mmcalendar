part of 'promo_bloc.dart';

/// Base class for promo states
abstract class PromoState extends Equatable {
  const PromoState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PromoInitial extends PromoState {}

/// Loading state
class PromoLoading extends PromoState {}

/// State when promo is available to show
class PromoAvailable extends PromoState {
  final List<PromoSlide> slides;
  final String campaignId;

  const PromoAvailable({required this.slides, required this.campaignId});

  @override
  List<Object?> get props => [slides, campaignId];
}

/// State when no promo is available
class PromoNotAvailable extends PromoState {}

/// Error state
class PromoError extends PromoState {
  final String message;

  const PromoError({required this.message});

  @override
  List<Object?> get props => [message];
}
