import 'package:equatable/equatable.dart';

class RoutineInfo extends Equatable {
  final int seriesCount;
  final int recitationCount;

  const RoutineInfo({required this.seriesCount, required this.recitationCount});

  @override
  List<Object?> get props => [seriesCount, recitationCount];
}
