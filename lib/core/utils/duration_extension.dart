extension DurationExtensions on Duration {
  /// Converts the duration into a readable string format: mm:ss or hh:mm:ss
  String toFormattedString() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    
    final hours = inHours;
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));
    
    if (hours > 0) {
      return "${twoDigits(hours)}:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }
}