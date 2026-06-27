/// A Buddhist observance or festival happening today.
class TodayEvent {
  final String id;
  final String name;
  final String? description;

  const TodayEvent({required this.id, required this.name, this.description});
}
