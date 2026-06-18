import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Extension methods on Either to simplify common operations
extension EitherX<L, R> on Either<L, R> {
  /// Maps the right side of the Either
  Either<L, R2> mapRight<R2>(R2 Function(R) fn) => fold(
        (l) => Left(l),
        (r) => Right(fn(r)),
      );

  /// Maps the left side of the Either
  Either<L2, R> mapLeft<L2>(L2 Function(L) fn) => fold(
        (l) => Left(fn(l)),
        (r) => Right(r),
      );

  /// Returns the right value or a default if left
  R getOrElse(R Function(L) defaultValue) => fold(defaultValue, (r) => r);

  /// Returns the right value or null if left
  R? get rightOrNull => fold((_) => null as R?, (r) => r);

  /// Returns the left value or null if right
  L? get leftOrNull => fold((l) => l, (_) => null as L?);

  /// Checks if this is a Right value
  bool get isRight => fold((_) => false, (_) => true);

  /// Checks if this is a Left value
  bool get isLeft => !isRight;

  /// Executes a side effect when Right
  Either<L, R> whenRight(void Function(R) fn) {
    if (isRight) {
      fn(getOrElse((l) => throw UnreachableError()));
    }
    return this;
  }

  /// Executes a side effect when Left
  Either<L, R> whenLeft(void Function(L) fn) {
    if (isLeft) {
      fn(leftOrNull as L);
    }
    return this;
  }
}

/// Widget helpers for Either types
extension EitherWidgetExtensions<L, R> on Either<L, R> {
  /// Build a widget based on the Either state
  Widget build({
    required Widget Function(R right) whenRight,
    required Widget Function(L left) whenLeft,
  }) {
    return fold(
      whenLeft,
      whenRight,
    );
  }
}

/// Specific extension for Either<Failure, T> for common UI operations
extension EitherFailureOr<T> on Either<Failure, T> {
  /// Build a widget with loading, data, and error states
  Widget buildWidget({
    required Widget Function(T data) onData,
    Widget Function(Failure failure)? onError,
    Widget? onLoading,
  }) {
    return build(
      whenRight: onData,
      whenLeft: onError ?? (failure) => _DefaultErrorWidget(failure: failure),
    );
  }
}

/// Default error widget for displaying failures
class _DefaultErrorWidget extends StatelessWidget {
  final Failure failure;

  const _DefaultErrorWidget({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class UnreachableError extends Error {
  final String message;
  UnreachableError([this.message = 'Unreachable code executed']);

  @override
  String toString() => 'UnreachableError: $message';
}
