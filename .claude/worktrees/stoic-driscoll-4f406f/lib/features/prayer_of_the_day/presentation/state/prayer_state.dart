import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/prayer_of_the_day/domain/entities/prayer.dart';

/// Base state for prayer feature.
abstract class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class PrayerInitial extends PrayerState {
  const PrayerInitial();
}

/// Loading state.
class PrayerLoading extends PrayerState {
  const PrayerLoading();
}

/// Loaded state with prayer data.
class PrayerLoaded extends PrayerState {
  final Prayer prayer;

  const PrayerLoaded(this.prayer);

  @override
  List<Object?> get props => [prayer];
}

/// Error state.
class PrayerError extends PrayerState {
  final String message;

  const PrayerError(this.message);

  @override
  List<Object?> get props => [message];
}
