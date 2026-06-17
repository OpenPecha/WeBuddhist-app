import 'dart:io';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mala_sync_manager_test.mocks.dart';

@GenerateMocks([CreateUserAccumulatorUseCase, UpdateUserAccumulatorUseCase])
void main() {
  provideDummy<Either<Failure, MalaCount>>(
    const Left(UnknownFailure('dummy')),
  );

  late Directory tempDir;
  late MalaLocalDataSource local;
  late MockCreateUserAccumulatorUseCase create;
  late MockUpdateUserAccumulatorUseCase update;

  const userA = 'user-a';
  const userB = 'user-b';
  const presetId = 'chenrezig';

  MalaSyncManager buildManager({
    bool loggedIn = true,
    String? userId = userA,
  }) {
    return MalaSyncManager(
      local: local,
      createAccumulator: create,
      updateAccumulator: update,
      isLoggedIn: () => loggedIn,
      currentUserId: () => userId,
    );
  }

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_sync_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    create = MockCreateUserAccumulatorUseCase();
    update = MockUpdateUserAccumulatorUseCase();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('flush updates an existing accumulator with the absolute total', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(
        total: 50,
        syncedTotal: 40,
        accumulatorId: 'acc-1',
        name: 'Chenrezig',
        mantraId: 'm1',
      ),
    );
    when(update(any)).thenAnswer(
      (_) async => Right(MalaCount(accumulatorId: 'acc-1', total: 50)),
    );

    await buildManager().flush(SyncReason.debounce);

    final captured =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(captured.accumulatorId, 'acc-1');
    expect(captured.currentCount, 50); // absolute total, not a delta
    verifyNever(create(any));

    final after = local.read(userA, presetId);
    expect(after.syncedTotal, 50);
    expect(after.isDirty, isFalse);
  });

  test('flush lazily creates an accumulator on first sync', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(
        total: 12,
        syncedTotal: 0,
        name: 'Chenrezig',
        mantraId: 'm1',
      ),
    );
    when(create(any)).thenAnswer(
      (_) async => Right(MalaCount(accumulatorId: 'new-acc', total: 12)),
    );

    await buildManager().flush(SyncReason.launch);

    final captured =
        verify(create(captureAny)).captured.single as CreateUserAccumulatorParams;
    expect(captured.name, 'Chenrezig');
    expect(captured.mantraId, 'm1');
    expect(captured.currentCount, 12);

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, 'new-acc'); // id stored for future PUTs
    expect(after.syncedTotal, 12);
  });

  test('server ahead is adopted via max() into total and syncedTotal', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(
        total: 30,
        syncedTotal: 20,
        accumulatorId: 'acc-1',
      ),
    );
    // Another device pushed the server to 100.
    when(update(any)).thenAnswer(
      (_) async => Right(MalaCount(accumulatorId: 'acc-1', total: 100)),
    );

    await buildManager().flush(SyncReason.reconnect);

    final after = local.read(userA, presetId);
    expect(after.total, 100); // bumped up to reflect cross-device progress
    expect(after.syncedTotal, 100);
  });

  test('failed flush keeps the entry dirty for retry', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Left(NetworkFailure('offline')),
    );

    await buildManager().flush(SyncReason.debounce);

    final after = local.read(userA, presetId);
    expect(after.syncedTotal, 0);
    expect(after.isDirty, isTrue);
  });

  test('does nothing when not logged in', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );

    await buildManager(loggedIn: false).flush(SyncReason.launch);

    verifyNever(update(any));
    verifyNever(create(any));
  });

  test('only flushes the current user\'s entries (namespacing)', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-a'),
    );
    await local.write(
      userB,
      presetId,
      const LocalMalaState(total: 9, syncedTotal: 0, accumulatorId: 'acc-b'),
    );
    when(update(any)).thenAnswer(
      (_) async => Right(MalaCount(accumulatorId: 'acc-a', total: 5)),
    );

    await buildManager(userId: userA).flush(SyncReason.launch);

    final captured =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(captured.accumulatorId, 'acc-a'); // never touches user B
    expect(local.read(userB, presetId).isDirty, isTrue);
  });
}
