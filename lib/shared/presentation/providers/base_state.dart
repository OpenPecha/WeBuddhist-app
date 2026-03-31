import 'package:equatable/equatable.dart';

/// Base state class for presentation layer state management.
///
/// All feature states should extend this class or one of its
/// predefined state classes (Loading, Loaded, Error).
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class InitialState extends BaseState {
  const InitialState();
}

/// Loading state while data is being fetched
class LoadingState extends BaseState {
  const LoadingState();
}

/// State when data has been successfully loaded
class LoadedState<T> extends BaseState {
  const LoadedState(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

/// State when an error has occurred
class ErrorState extends BaseState {
  const ErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
