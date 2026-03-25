import 'package:flutter_pecha/features/creator_info/data/datasource/creator_info_local_datasource.dart';
import 'package:flutter_pecha/features/creator_info/data/repositories/creator_info_repository_impl.dart';
import 'package:flutter_pecha/features/creator_info/domain/repositories/creator_info_repository.dart';
import 'package:flutter_pecha/features/creator_info/domain/usecases/get_creator_info_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== Data Layer Providers ==========

/// Provider for CreatorInfoLocalDataSource.
final creatorInfoLocalDataSourceProvider = Provider<CreatorInfoLocalDataSource>((ref) {
  return CreatorInfoLocalDataSource();
});

/// Provider for CreatorInfo Repository.
final creatorInfoRepositoryProvider = Provider<CreatorInfoRepository>((ref) {
  final localDataSource = ref.watch(creatorInfoLocalDataSourceProvider);
  return CreatorInfoRepositoryImpl(localDataSource: localDataSource);
});

// ========== Use Case Providers ==========

/// Provider for GetCreatorInfoUseCase.
final getCreatorInfoUseCaseProvider = Provider<GetCreatorInfoUseCase>((ref) {
  final repository = ref.watch(creatorInfoRepositoryProvider);
  return GetCreatorInfoUseCase(repository);
});
