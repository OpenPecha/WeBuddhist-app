import 'dart:io';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_counter_notifier.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mala_counter_notifier_test.mocks.dart';

@GenerateMocks([GetAccumulatorDetailUseCase, MalaSyncManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  provideDummy<Either<Failure, MalaCount>>(
    const Left(UnknownFailure('dummy')),
  );

  late Directory tempDir;
  late MalaLocalDataSource local;
  late MockGetAccumulatorDetailUseCase getDetail;
  late MockMalaSyncManager sync;

  const userId = 'user-1';
  const mantra = Mantra(
    presetId: 'chenrezig',
    metadata: [AccumulatorMetadata(language: 'en', name: 'Chenrezig')],
    mantra: MantraText(id: 'm1', text: 'ༀ་མ་ཎི་པདྨེ་ཧཱུྃ', pronunciation: 'Om Mani Padme Hum'),
  );

  MalaCounterNotifier buildNotifier() => MalaCounterNotifier(
        mantra: mantra,
        local: local,
        getAccumulatorDetail: getDetail,
        sync: sync,
        currentUserId: () async => userId,
      );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_counter_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    getDetail = MockGetAccumulatorDetailUseCase();
    sync = MockMalaSyncManager();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('seed adopts the server total when the server is ahead', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 4212)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 4212);
    final s = local.read(userId, 'chenrezig');
    expect(s.syncedTotal, 4212);
    expect(s.accumulatorId, 'acc-1');
    notifier.dispose();
  });

  test('seed preserves local offline taps and pushes them', () async {
    // Local is ahead of the server (offline taps captured earlier).
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 20, syncedTotal: 10, accumulatorId: 'acc-1'),
    );
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 10)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 20); // local preserved
    verify(sync.flush(SyncReason.launch)).called(1); // tail pushed
    notifier.dispose();
  });

  test('incrementBead is a no-op while seeding', () {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 0)),
    );

    final notifier = buildNotifier(); // seed still pending (async)
    expect(notifier.state.isSeeding, isTrue);

    notifier.incrementBead();

    expect(notifier.state.total, 0);
    notifier.dispose();
  });

  test('incrementBead increments monotonically and notifies sync', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 0)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    notifier.incrementBead();
    notifier.incrementBead();
    notifier.incrementBead();

    expect(notifier.state.total, 3);
    expect(notifier.state.beadInRound, 3);
    expect(notifier.state.rounds, 0);
    expect(local.read(userId, 'chenrezig').total, 3);
    verify(sync.onTap(roundComplete: false)).called(3);
    notifier.dispose();
  });

  test('round completes at a multiple of beadsPerRound', () async {
    when(getDetail(any)).thenAnswer(
      (_) async =>
          const Right(MalaCount(accumulatorId: 'acc-1', total: kBeadsPerRound - 1)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, kBeadsPerRound - 1);
    notifier.incrementBead(); // lands on 108

    expect(notifier.state.total, kBeadsPerRound);
    expect(notifier.state.beadInRound, 0);
    expect(notifier.state.rounds, 1);
    verify(sync.onTap(roundComplete: true)).called(1);
    notifier.dispose();
  });

  test('fresh install with no accumulator seeds at 0', () async {
    // No user accumulator yet → detail returns count 0 with a null id.
    when(getDetail(any)).thenAnswer((_) async => const Right(MalaCount(total: 0)));

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 0);
    expect(notifier.state.isSeeding, isFalse);
    expect(local.read(userId, 'chenrezig').accumulatorId, isNull);
    // Nothing to push when local and server agree at 0.
    verifyNever(sync.flush(any));
    notifier.dispose();
  });
}
