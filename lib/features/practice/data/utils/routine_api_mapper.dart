import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';

RoutineData routineDataFromApiResponse(RoutineResponse? response) {
  if (response == null) return const RoutineData();
  final blocks = response.timeBlocks.map(routineBlockFromDto).toList();
  return RoutineData(
    blocks: blocks,
    apiRoutineId: response.id,
  ).sortedByTime;
}

RoutineBlock routineBlockFromDto(TimeBlockDTO tb) {
  final sessions = List<SessionDTO>.from(tb.sessions)
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return RoutineBlock(
    id: tb.id,
    time: hhmmToTime(tb.timeInt),
    notificationEnabled: tb.notificationEnabled,
    apiTimeBlockId: tb.id,
    items: sessions.map(routineItemFromSessionDto).toList(),
  );
}

RoutineItem routineItemFromSessionDto(SessionDTO s) {
  return RoutineItem(
    id: s.sourceId,
    title: s.title,
    imageUrl: s.imageUrl,
    type: switch (s.sessionType) {
      SessionType.plan => RoutineItemType.plan,
      SessionType.recitation => RoutineItemType.recitation,
    },
  );
}

List<SessionRequest> _sessionsForBlock(RoutineBlock block) {
  final sessions = <SessionRequest>[];
  for (var i = 0; i < block.items.length; i++) {
    final item = block.items[i];
    sessions.add(
      SessionRequest(
        sessionType: item.type == RoutineItemType.plan
            ? SessionType.plan
            : SessionType.recitation,
        sourceId: item.id,
        displayOrder: i,
      ),
    );
  }
  return sessions;
}

CreateTimeBlockRequest routineBlockToCreateRequest(RoutineBlock block) {
  return CreateTimeBlockRequest(
    time: formatRoutineTime24h(block.time),
    timeInt: timeToHHMM(block.time),
    notificationEnabled: block.notificationEnabled,
    sessions: _sessionsForBlock(block),
  );
}

UpdateTimeBlockRequest routineBlockToUpdateRequest(RoutineBlock block) {
  return UpdateTimeBlockRequest(
    time: formatRoutineTime24h(block.time),
    timeInt: timeToHHMM(block.time),
    notificationEnabled: block.notificationEnabled,
    sessions: _sessionsForBlock(block),
  );
}
