# Best Practices Applied in Recitation Feature Refactoring

## 1. SOLID Principles

### Single Responsibility Principle (SRP)
Each class has one reason to change:

```dart
// ✅ GOOD: Each class has a single, clear purpose
class RecitationLanguageConfig {
  // Only responsible for language configuration
}

class RecitationSaveController {
  // Only responsible for save/unsave operations
}

class RecitationTextSection {
  // Only responsible for displaying text
}

// ❌ BAD: Old screen did everything
class _RecitationDetailScreenState {
  // - Built UI
  // - Handled language logic
  // - Managed save/unsave
  // - Processed text
  // - Handled errors
}
```

### Open/Closed Principle (OCP)
Open for extension, closed for modification:

```dart
// ✅ GOOD: Easy to add new languages without modifying existing code
static List<ContentType> getContentOrder(String languageCode) {
  switch (languageCode) {
    case tibetan: return [...];
    case english: return [...];
    case chinese: return [...];
    // Add new language here - no modification of existing cases
    default: return [...];
  }
}

// ✅ GOOD: Easy to add new content types
enum ContentType {
  recitation,
  translation,
  transliteration,
  adaptation,
  // Just add new type here
}
```

### Liskov Substitution Principle (LSP)
All widgets extend base classes correctly:

```dart
// ✅ All widgets properly extend StatelessWidget
class RecitationContent extends StatelessWidget { ... }
class RecitationSegment extends StatelessWidget { ... }
class RecitationTextSection extends StatelessWidget { ... }
```

### Interface Segregation Principle (ISP)
Components depend only on what they need:

```dart
// ✅ GOOD: RecitationSegment only receives what it needs
class RecitationSegment extends StatelessWidget {
  final RecitationSegmentModel segment;        // Only segment data
  final List<ContentType> contentOrder;         // Only display order
  final bool isFirstSegment;                    // Only position info
}

// ❌ BAD: Would be passing entire parent state
class RecitationSegment extends StatelessWidget {
  final RecitationDetailScreenState parentState; // Too much access!
}
```

### Dependency Inversion Principle (DIP)
Depend on abstractions, not concretions:

```dart
// ✅ GOOD: Controller receives dependencies through constructor
class RecitationSaveController {
  final WidgetRef ref;           // Abstract reference
  final BuildContext context;    // Abstract context

  RecitationSaveController({
    required this.ref,
    required this.context,
  });
}
```

## 2. Clean Code Principles

### Meaningful Names
```dart
// ✅ GOOD: Clear, descriptive names
class RecitationLanguageConfig { ... }
method getContentOrder() { ... }
variable contentOrder { ... }

// ❌ BAD: Vague or abbreviated names
class RLC { ... }
method get() { ... }
variable co { ... }
```

### Small Functions
```dart
// ✅ GOOD: Each method does one thing
List<Widget> _buildContentForType(ContentType contentType) {
  // 20 lines, one clear purpose
}

// ❌ BAD: 200-line method doing multiple things
Widget _buildSegment(...) {
  // 200+ lines with nested conditionals
}
```

### Don't Repeat Yourself (DRY)
```dart
// ✅ GOOD: Single source for language configuration
final params = RecitationLanguageConfig.getContentParams(lang, id);

// ❌ BAD: Repeated if-else blocks across multiple methods
if (lang == "bo") { ... }
else if (lang == "en") { ... }
// Repeated 4 times in different methods
```

### Comments and Documentation
```dart
// ✅ GOOD: Dartdoc comments explain "why" and "what"
/// Returns the display order of content types based on the user's language.
///
/// This determines the visual hierarchy of different content types:
/// - Tibetan users see: Recitation → Adaptation → Translation
/// - English users see: Translation → Recitation → Transliteration
static List<ContentType> getContentOrder(String languageCode) { ... }

// ❌ BAD: No comments or only "what" comments
// Get content order
List<ContentType> getContentOrder(String languageCode) { ... }
```

## 3. Flutter-Specific Best Practices

### Prefer StatelessWidget
```dart
// ✅ GOOD: Stateless when no state is needed
class RecitationDetailScreen extends ConsumerWidget {
  // No mutable state
}

// ❌ BAD: Stateful with empty initState
class _RecitationDetailScreenState extends ConsumerState {
  @override
  void initState() {
    super.initState();
    // Empty! No need for StatefulWidget
  }
}
```

### Use Const Constructors
```dart
// ✅ GOOD: Const constructors enable performance optimizations
class RecitationTextSection extends StatelessWidget {
  final String text;

  const RecitationTextSection({
    super.key,
    required this.text,
  });
}

// Usage
const RecitationTextSection(text: "...") // Can be cached
```

### Widget Composition Over Inheritance
```dart
// ✅ GOOD: Compose small widgets
class RecitationContent extends StatelessWidget {
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TitleWidget(),
          ...segments.map((s) => RecitationSegment(segment: s)),
        ],
      ),
    );
  }
}

// ❌ BAD: One giant widget with everything
```

### Extract Widgets
```dart
// ✅ GOOD: Extracted into separate widget file
class RecitationErrorState extends StatelessWidget { ... }

// ❌ BAD: Private method returning widget
Widget _buildErrorState() { ... }
// Problems:
// - Not reusable
// - Harder to test
// - Clutters main widget
```

### Use MediaQuery and Theme Correctly
```dart
// ✅ GOOD: Use theme for styling
Text(
  content.title,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
  ),
)

// ❌ BAD: Hardcoded values
Text(
  content.title,
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
)
```

## 4. Riverpod Best Practices

### Provider Scope
```dart
// ✅ GOOD: Watch only what's needed
final locale = ref.watch(localeProvider);
final languageCode = locale.languageCode;

// ✅ GOOD: Read for one-time access
final result = await ref.read(recitationsRepositoryProvider).save();

// ❌ BAD: Watching provider you only need to read
final repo = ref.watch(recitationsRepositoryProvider); // Unnecessary rebuild
```

### Provider Invalidation
```dart
// ✅ GOOD: Invalidate after mutation
await save();
ref.invalidate(savedRecitationsFutureProvider);

// ❌ BAD: Not invalidating (stale data)
await save();
// Forgot to invalidate!
```

### AsyncValue Handling
```dart
// ✅ GOOD: Handle all states
contentAsync.when(
  data: (content) => RecitationContent(content: content),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => RecitationErrorState(error: error),
)

// ❌ BAD: Only handling data state
contentAsync.value // Will throw on error/loading
```

## 5. Error Handling

### Graceful Degradation
```dart
// ✅ GOOD: Provide default value
final savedIds = savedRecitationsAsync.valueOrNull?.map(...).toList() ?? [];

// ✅ GOOD: Try-catch with user feedback
try {
  await save();
} catch (e) {
  showSnackBar('Failed to save');
}

// ❌ BAD: No error handling
final savedIds = savedRecitationsAsync.value.map(...).toList(); // Crash!
```

### User-Friendly Error Messages
```dart
// ✅ GOOD: Clear, actionable message
Text('Failed to load recitation')

// ❌ BAD: Technical jargon
Text('NetworkException: HTTP 500')
```

## 6. Accessibility

### Tooltips
```dart
// ✅ GOOD: Add tooltips for icon buttons
IconButton(
  onPressed: () => ...,
  icon: Icon(Icons.bookmark),
  tooltip: 'Save recitation', // Helps users understand
)

// ❌ BAD: No tooltip
IconButton(
  onPressed: () => ...,
  icon: Icon(Icons.bookmark),
)
```

### Semantic Labels (Future Enhancement)
```dart
// Future enhancement
Semantics(
  label: 'Save this recitation',
  child: IconButton(...),
)
```

## 7. Performance

### Avoid Unnecessary Rebuilds
```dart
// ✅ GOOD: Const widgets don't rebuild
const SizedBox(height: 8)
const Divider()

// ❌ BAD: Non-const creates new instance every rebuild
SizedBox(height: 8)
Divider()
```

### Efficient List Building
```dart
// ✅ GOOD: Use spread operator for dynamic lists
children: [
  if (condition) ...[
    Widget1(),
    Widget2(),
  ],
]

// ❌ BAD: Creating intermediate lists
children: condition
  ? [Widget1(), Widget2()]
  : []
..addAll(otherWidgets)
```

### Lazy Loading
```dart
// ✅ GOOD: Provider only fetches when watched
final contentAsync = ref.watch(recitationContentProvider(params));

// Data fetched on-demand, not preemptively
```

## 8. Code Organization

### File Structure
```dart
// ✅ GOOD: Clear, hierarchical structure
lib/
  features/
    recitation/
      domain/              // Business logic
      presentation/
        controllers/       // User interaction
        screens/          // Main pages
        widgets/          // Reusable components
      data/               // Data layer

// ❌ BAD: Flat structure
lib/
  recitation_detail.dart
  recitation_segment.dart
  recitation_config.dart
  // Hard to navigate
```

### Import Organization
```dart
// ✅ GOOD: Organized imports
// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports
import 'package:flutter_pecha/features/...';

// ❌ BAD: Random order
import 'package:flutter_pecha/features/...';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/...';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

## 9. Naming Conventions

### Files
```dart
// ✅ GOOD: snake_case
recitation_language_config.dart
recitation_text_section.dart

// ❌ BAD: Other cases
RecitationLanguageConfig.dart
recitation-language-config.dart
```

### Classes
```dart
// ✅ GOOD: PascalCase
class RecitationSaveController { ... }
class ContentType { ... }

// ❌ BAD: Other cases
class recitationSaveController { ... }
class content_type { ... }
```

### Variables and Methods
```dart
// ✅ GOOD: camelCase
final contentOrder = ...;
void handleSaveToggle() { ... }

// ❌ BAD: Other cases
final ContentOrder = ...;
void HandleSaveToggle() { ... }
```

### Constants
```dart
// ✅ GOOD: lowerCamelCase (Dart convention)
static const String tibetan = 'bo';
static const String english = 'en';

// Note: SCREAMING_SNAKE_CASE is valid but lowerCamelCase is preferred
```

## 10. Testing Considerations

### Testable Design
```dart
// ✅ GOOD: Pure functions are easily testable
static List<ContentType> getContentOrder(String languageCode) {
  // No side effects, no dependencies
  // Easy to test all branches
}

// ❌ BAD: Tightly coupled, hard to test
void _buildSegment() {
  final locale = ref.watch(...);  // Can't test without Riverpod
  final auth = ref.watch(...);    // Can't test without providers
}
```

### Dependency Injection
```dart
// ✅ GOOD: Dependencies injected
class RecitationSaveController {
  final WidgetRef ref;
  final BuildContext context;

  RecitationSaveController({
    required this.ref,
    required this.context,
  });
  // Can mock ref and context in tests
}

// ❌ BAD: Hard dependencies
class RecitationSaveController {
  void save() {
    final ref = ProviderContainer(); // Can't mock
  }
}
```

## 11. Immutability

### Immutable Widgets
```dart
// ✅ GOOD: All fields final
class RecitationSegment extends StatelessWidget {
  final RecitationSegmentModel segment;
  final List<ContentType> contentOrder;
  final bool isFirstSegment;

  const RecitationSegment({...});
}

// ❌ BAD: Mutable fields
class RecitationSegment extends StatelessWidget {
  RecitationSegmentModel segment; // Not final!
}
```

### Immutable Data
```dart
// ✅ GOOD: Use copyWith for modifications
final updated = recitation.copyWith(title: newTitle);

// ❌ BAD: Mutating existing objects
recitation.title = newTitle; // Don't do this!
```

## 12. Documentation

### Class Documentation
```dart
// ✅ GOOD: Complete dartdoc
/// A widget that displays a single segment of recitation content.
///
/// This widget handles the rendering of different content types
/// (recitation, translation, transliteration, adaptation) based on
/// the specified display order.
class RecitationSegment extends StatelessWidget { ... }
```

### Method Documentation
```dart
// ✅ GOOD: Document parameters and behavior
/// Builds the widgets for a specific content type.
///
/// Returns an empty list if the content type is not available
/// in this segment.
///
/// [contentType] - The type of content to build widgets for
List<Widget> _buildContentForType(ContentType contentType) { ... }
```

### Inline Comments
```dart
// ✅ GOOD: Explain "why", not "what"
// Add spacing between different entries (but not before the first one)
if (!isFirstEntry) {
  widgets.add(const SizedBox(height: 8));
}

// ❌ BAD: Obvious comments
// Check if first entry
if (!isFirstEntry) { ... }
```

## Summary Checklist

✅ **SOLID Principles**: All five applied
✅ **Clean Code**: Meaningful names, small functions, DRY
✅ **Flutter Best Practices**: StatelessWidget, const constructors, composition
✅ **Riverpod Best Practices**: Proper provider usage, invalidation
✅ **Error Handling**: Graceful degradation, user-friendly messages
✅ **Accessibility**: Tooltips, semantic structure
✅ **Performance**: Const widgets, efficient rebuilds
✅ **Code Organization**: Clear structure, organized imports
✅ **Naming Conventions**: Consistent Dart conventions
✅ **Testing**: Testable design, dependency injection
✅ **Immutability**: Final fields, immutable data
✅ **Documentation**: Comprehensive dartdoc comments

## Resources

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Documentation](https://riverpod.dev/docs/introduction/getting_started)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
