import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/get_group_profile_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final groupProfileRemoteDatasourceProvider =
    Provider<GroupProfileRemoteDatasource>((ref) {
  return GroupProfileRemoteDatasource(dio: ref.watch(dioProvider));
});

final groupProfileRepositoryProvider =
    Provider<GroupProfileRepositoryInterface>((ref) {
  return GroupProfileRepositoryImpl(
    remote: ref.watch(groupProfileRemoteDatasourceProvider),
  );
});

final getGroupProfileUseCaseProvider =
    Provider<GetGroupProfileUseCase>((ref) {
  final repository = ref.watch(groupProfileRepositoryProvider);
  return GetGroupProfileUseCase(repository.getGroupProfile);
});

final groupProfileProvider = FutureProvider.autoDispose
    .family<Either<Failure, GroupProfile>, String>((ref, groupId) async {
  final locale = ref.watch(localeProvider);
  final useCase = ref.watch(getGroupProfileUseCaseProvider);
  return useCase(
    GetGroupProfileParams(groupId: groupId, language: locale.languageCode),
  );
});
