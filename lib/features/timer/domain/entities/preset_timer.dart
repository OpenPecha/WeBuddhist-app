class PresetTimer {
  const PresetTimer({
    required this.id,
    required this.name,
    required this.durationMs,
    this.audioUrl,
  });

  final String id;
  final String name;
  final int durationMs;
  final String? audioUrl;

  int get durationMinutes => durationMs ~/ 60000;

  int get displayMinutes {
    return durationMinutes;
  }
}
