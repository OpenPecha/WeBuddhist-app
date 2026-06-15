import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetRoutineInfoUseCase extends UseCase<RoutineInfo, NoParams> {
  final Future<Either<Failure, RoutineInfo>> Function() _getRoutineInfo;

  GetRoutineInfoUseCase(this._getRoutineInfo);

  @override
  Future<Either<Failure, RoutineInfo>> call(NoParams params) async {
    return _getRoutineInfo();
  }
}
