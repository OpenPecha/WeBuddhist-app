import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_page.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/domain/repositories/practice_items_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Fetches one page of practice items, filtered by [tab] and [language].
class GetPracticeItemsUseCase {
  final PracticeItemsRepository _repository;
  const GetPracticeItemsUseCase(this._repository);

  Future<Either<Failure, PracticeItemsPage>> call({
    required PracticeItemsTab tab,
    required String language,
    required int page,
    required int pageSize,
  }) {
    return _repository.getPracticeItems(
      tab: tab,
      language: language,
      page: page,
      pageSize: pageSize,
    );
  }
}
