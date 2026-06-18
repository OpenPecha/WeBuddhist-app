import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/creator_info/domain/entities/creator_info.dart';

/// Base state for creator info feature.
abstract class CreatorInfoState extends Equatable {
  const CreatorInfoState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class CreatorInfoInitial extends CreatorInfoState {
  const CreatorInfoInitial();
}

/// Loading state.
class CreatorInfoLoading extends CreatorInfoState {
  const CreatorInfoLoading();
}

/// Loaded state with creator info data.
class CreatorInfoLoaded extends CreatorInfoState {
  final CreatorInfo creatorInfo;

  const CreatorInfoLoaded(this.creatorInfo);

  @override
  List<Object?> get props => [creatorInfo];
}

/// Error state.
class CreatorInfoError extends CreatorInfoState {
  final String message;

  const CreatorInfoError(this.message);

  @override
  List<Object?> get props => [message];
}
