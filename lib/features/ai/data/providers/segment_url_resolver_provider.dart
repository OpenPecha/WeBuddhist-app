import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/ai/data/datasource/segment_url_resolver_datasource.dart';
import 'package:flutter_pecha/features/ai/data/repositories/segment_url_resolver_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for segment URL resolver datasource
final segmentUrlResolverDatasourceProvider = Provider<SegmentUrlResolverDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return SegmentUrlResolverDatasource(client: client);
});

/// Provider for segment URL resolver repository
final segmentUrlResolverRepositoryProvider = Provider<SegmentUrlResolverRepository>((ref) {
  final datasource = ref.watch(segmentUrlResolverDatasourceProvider);
  return SegmentUrlResolverRepository(datasource: datasource);
});
