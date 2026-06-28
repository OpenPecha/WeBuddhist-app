/// Maps ASCII digits to Tibetan Unicode digits (U+0F20–U+0F29).
const Map<String, String> englishToTibetanDigit = {
  '0': '༠',
  '1': '༡',
  '2': '༢',
  '3': '༣',
  '4': '༤',
  '5': '༥',
  '6': '༦',
  '7': '༧',
  '8': '༨',
  '9': '༩',
};

/// Reverse map: Tibetan digit → ASCII digit.
final Map<String, String> tibetanToEnglishDigit = {
  for (final entry in englishToTibetanDigit.entries) entry.value: entry.key,
};

/// Converts each ASCII digit in [value] to its Tibetan counterpart.
///
/// Non-digit characters (e.g. `.`, `k`, spaces) are preserved as-is.
String toTibetanDigits(Object value) {
  return value.toString().split('').map((char) {
    return englishToTibetanDigit[char] ?? char;
  }).join();
}
