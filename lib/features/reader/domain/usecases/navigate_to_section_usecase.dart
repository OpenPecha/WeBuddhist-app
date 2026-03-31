import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/reader/domain/entities/text_content.dart';
import 'package:flutter_pecha/features/reader/domain/repositories/reader_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

/// Navigate to a specific section use case.
class NavigateToSectionUseCase extends UseCase<Section, NavigateToSectionParams> {
  final ReaderRepository _repository;

  NavigateToSectionUseCase(this._repository);

  @override
  Future<Either<Failure, Section>> call(NavigateToSectionParams params) async {
    if (params.sectionId.isEmpty) {
      return const Left(ValidationFailure('Section ID cannot be empty'));
    }
    return await _repository.navigateToSection(params.sectionId);
  }
}

/// Parameters for navigating to a section.
class NavigateToSectionParams {
  final String sectionId;

  const NavigateToSectionParams({required this.sectionId});
}
