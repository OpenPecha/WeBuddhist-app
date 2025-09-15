import 'package:flutter_pecha/core/network/http_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/mock_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/plans_repository.dart';
import '../datasource/plans_remote_datasource.dart';
import '../../models/plans_model.dart';

// Repository provider
final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(
    plansRemoteDatasource: PlansRemoteDatasource(
      client: ref.watch(httpClientProvider),
    ),
  );
});

// Get all plans provider
final plansFutureProvider = FutureProvider<List<PlansModel>>((ref) {
  return ref.watch(plansRepositoryProvider).getPlans();
  // return Future.value(mockPlans);
});

final planByIdFutureProvider = FutureProvider.family<PlansModel, String>((
  ref,
  id,
) {
  return ref.watch(plansRepositoryProvider).getPlanById(id);
});
