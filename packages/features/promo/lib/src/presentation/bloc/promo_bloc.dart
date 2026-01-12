import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:promo_carousel/promo_carousel.dart';

import '../../domain/usecases/get_feature_announcements.dart';
import '../../domain/usecases/get_onboarding_slides.dart';

part 'promo_event.dart';
part 'promo_state.dart';

/// BLoC for managing promo state
class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final GetOnboardingSlides getOnboardingSlides;
  final GetFeatureAnnouncements getFeatureAnnouncements;

  PromoBloc({
    required this.getOnboardingSlides,
    required this.getFeatureAnnouncements,
  }) : super(PromoInitial()) {
    on<CheckOnboardingRequested>(_onCheckOnboardingRequested);
    on<CheckFeatureAnnouncementsRequested>(
      _onCheckFeatureAnnouncementsRequested,
    );
  }

  Future<void> _onCheckOnboardingRequested(
    CheckOnboardingRequested event,
    Emitter<PromoState> emit,
  ) async {
    emit(PromoLoading());

    try {
      final slides = await getOnboardingSlides();

      if (slides == null || slides.isEmpty) {
        emit(PromoNotAvailable());
      } else {
        emit(PromoAvailable(slides: slides, campaignId: 'onboarding_v1'));
      }
    } catch (e) {
      emit(PromoError(message: e.toString()));
    }
  }

  Future<void> _onCheckFeatureAnnouncementsRequested(
    CheckFeatureAnnouncementsRequested event,
    Emitter<PromoState> emit,
  ) async {
    emit(PromoLoading());

    try {
      final slides = await getFeatureAnnouncements(event.currentVersion);

      if (slides == null || slides.isEmpty) {
        emit(PromoNotAvailable());
      } else {
        emit(
          PromoAvailable(
            slides: slides,
            campaignId: 'feature_announcement_${event.currentVersion}',
          ),
        );
      }
    } catch (e) {
      emit(PromoError(message: e.toString()));
    }
  }
}
