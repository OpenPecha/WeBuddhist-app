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

@GenerateMocks([
  CreateUserAccumulatorUseCase,
  UpdateUserAccumulatorUseCase,
  DeleteUserAccumulatorUseCase,
])
void main() {
  provideDummy<Either<Failure, MalaCount>>(const Left(UnknownFailure('dummy')));
  provideDummy<Either<Failure, Unit>>(const Left(UnknownFailure('dummy')));

  late Directory tempDir;
  late MalaLocalDataSource local;
  late MockCreateUserAccumulatorUseCase create;
  late MockUpdateUserAccumulatorUseCase update;
  late MockDeleteUserAccumulatorUseCase delete;

  const userA = 'user-a';
  const userB = 'user-b';
  const presetId = 'chenrezig';

  MalaSyncManager buildManager({bool loggedIn = true, String? userId = userA}) {
    return MalaSyncManager(
      local: local,
      createAccumulator: create,
      updateAccumulator: update,
      isLoggedIn: () => loggedIn,
      currentUserId: () async => userId,
    );
  }

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_sync_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    create = MockCreateUserAccumulatorUseCase();
    update = MockUpdateUserAccumulatorUseCase();
    delete = MockDeleteUserAccumulatorUseCase();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'existing accumulator updates with the absolute total (no create)',
    () async {
      await local.write(
        userA,
        presetId,
        const LocalMalaState(
          total: 50,
          syncedTotal: 40,
          accumulatorId: 'acc-1',
        ),
      );
      when(update(any)).thenAnswer(
        (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 50)),
      );

      await buildManager().flush(SyncReason.debounce);

      final captured =
          verify(update(captureAny)).captured.single
              as UpdateUserAccumulatorParams;
      expect(captured.accumulatorId, 'acc-1');
      expect(captured.currentCount, 50); // absolute total, not a delta
      verifyNever(create(any)); // never creates when an id already exists

      final after = local.read(userA, presetId);
      expect(after.syncedTotal, 50);
      expect(after.isDirty, isFalse);
    },
  );

  test(
    'first sync creates once (parent_id) then updates the absolute total',
    () async {
      await local.write(
        userA,
        presetId,
        const LocalMalaState(total: 12, syncedTotal: 0), // no accumulatorId yet
      );
      when(create(any)).thenAnswer(
        (_) async => const Right(MalaCount(accumulatorId: 'new-acc', total: 0)),
      );
      when(update(any)).thenAnswer(
        (_) async =>
            const Right(MalaCount(accumulatorId: 'new-acc', total: 12)),
      );

      await buildManager().flush(SyncReason.launch);

      // Created exactly once, with the preset id as parent_id.
      expect(verify(create(captureAny)).captured.single, presetId);
      // Then pushed the absolute total to the new id.
      final put =
          verify(update(captureAny)).captured.single
              as UpdateUserAccumulatorParams;
      expect(put.accumulatorId, 'new-acc');
      expect(put.currentCount, 12);

      final after = local.read(userA, presetId);
      expect(after.accumulatorId, 'new-acc'); // id stored for future PUTs
      expect(after.syncedTotal, 12);
    },
  );

  test('does not create again once an id is stored', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 5)),
    );

    await buildManager().flush(SyncReason.launch);

    verifyNever(create(any));
    verify(update(any)).called(1);
  });

  test(
    'server ahead is adopted via max() into total and syncedTotal',
    () async {
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
        (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 100)),
      );

      await buildManager().flush(SyncReason.reconnect);

      final after = local.read(userA, presetId);
      expect(after.total, 100); // bumped up to reflect cross-device progress
      expect(after.syncedTotal, 100);
    },
  );

  test('failed flush keeps the entry dirty for retry', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );
    when(
      update(any),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

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
      (_) async => const Right(MalaCount(accumulatorId: 'acc-a', total: 5)),
    );

    await buildManager(userId: userA).flush(SyncReason.launch);

    final captured =
        verify(update(captureAny)).captured.single
            as UpdateUserAccumulatorParams;
    expect(captured.accumulatorId, 'acc-a'); // never touches user B
    expect(local.read(userB, presetId).isDirty, isTrue);
  });

  test(
    'reset flushes dirty tail then soft-deletes the active accumulator',
    () async {
      await local.write(
        userA,
        presetId,
        const LocalMalaState(
          total: 50,
          syncedTotal: 40,
          accumulatorId: 'acc-old',
        ),
      );
      when(update(any)).thenAnswer(
        (_) async =>
            const Right(MalaCount(accumulatorId: 'acc-old', total: 50)),
      );
      when(delete(any)).thenAnswer((_) async => const Right(unit));

      await buildManager().resetAccumulator(
        presetId,
        deleteAccumulator: delete,
      );

      final put =
          verify(update(captureAny)).captured.single
              as UpdateUserAccumulatorParams;
      expect(put.accumulatorId, 'acc-old');
      expect(put.currentCount, 50);
      expect(verify(delete('acc-old')).callCount, 1);
      verifyNever(create(any));

      final after = local.read(userA, presetId);
      expect(after.accumulatorId, isNull);
      expect(after.total, 0);
      expect(after.syncedTotal, 0);
      expect(after.isDirty, isFalse);
    },
  );

  test(
    'reset skips PUT when fully synced then soft-deletes accumulator',
    () async {
      await local.write(
        userA,
        presetId,
        const LocalMalaState(
          total: 50,
          syncedTotal: 50,
          accumulatorId: 'acc-old',
        ),
      );
      when(delete(any)).thenAnswer((_) async => const Right(unit));

      await buildManager().resetAccumulator(
        presetId,
        deleteAccumulator: delete,
      );

      verifyNever(update(any));
      verify(delete('acc-old')).called(1);
      verifyNever(create(any));

      final after = local.read(userA, presetId);
      expect(after.accumulatorId, isNull);
      expect(after.total, 0);
      expect(after.syncedTotal, 0);
    },
  );

  test('reset with no server accumulator only clears local session', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 0, syncedTotal: 0),
    );

    await buildManager().resetAccumulator(presetId, deleteAccumulator: delete);

    verifyNever(update(any));
    verifyNever(delete(any));
    verifyNever(create(any));

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, isNull);
    expect(after.total, 0);
  });
}
