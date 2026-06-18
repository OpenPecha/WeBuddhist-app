import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/meditation_of_day/domain/entities/meditation.dart';

/// Base state for meditation feature.
abstract class MeditationState extends Equatable {
  const MeditationState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class MeditationInitial extends MeditationState {
  const MeditationInitial();
}

/// Loading state.
class MeditationLoading extends MeditationState {
  const MeditationLoading();
}

/// Loaded state with meditation data.
class MeditationLoaded extends MeditationState {
  final Meditation meditation;

  const MeditationLoaded(this.meditation);

  @override
  List<Object?> get props => [meditation];
}

/// Error state.
class MeditationError extends MeditationState {
  final String message;

  const MeditationError(this.message);

  @override
  List<Object?> get props => [message];
}
