# Recitation Feature Architecture

## Component Hierarchy

```
RecitationDetailScreen (91 lines)
├── AppBar
│   └── IconButton (Save/Unsave)
│       └── RecitationSaveController
│           ├── Checks authentication
│           ├── Performs save/unsave
│           └── Shows error feedback
│
└── Body
    ├── Loading State → CircularProgressIndicator
    ├── Error State → RecitationErrorState
    └── Success State → RecitationContent
                        ├── Title + Divider
                        └── List<RecitationSegment>
                            └── For each segment:
                                └── Renders content by ContentType order
                                    └── RecitationTextSection
                                        └── Formatted text
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    RecitationDetailScreen                       │
│  (Main orchestrator - manages state and configuration)          │
└────────────────┬───────────────────────────────┬────────────────┘
                 │                               │
                 ▼                               ▼
┌────────────────────────────┐   ┌──────────────────────────────┐
│ RecitationLanguageConfig   │   │   Riverpod Providers         │
│  (Configuration)           │   │  (Data fetching)             │
│                            │   │                              │
│ • getContentParams()       │   │ • authProvider               │
│ • getContentOrder()        │   │ • savedRecitationsProvider   │
│ • Language constants       │   │ • recitationContentProvider  │
└────────────────────────────┘   └──────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ContentType Enum                           │
│         (Type-safe content type definitions)                    │
│                                                                 │
│  • recitation                                                   │
│  • translation                                                  │
│  • transliteration                                              │
│  • adaptation                                                   │
└─────────────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Widgets                         │
└────────┬───────────────┬──────────────┬────────────────────┬────┘
         │               │              │                    │
         ▼               ▼              ▼                    ▼
┌────────────┐  ┌────────────┐  ┌─────────────┐  ┌──────────────┐
│ Recitation │  │ Recitation │  │ Recitation  │  │  Recitation  │
│  Content   │  │  Segment   │  │    Text     │  │ Error State  │
│            │  │            │  │   Section   │  │              │
│ (Layout)   │  │ (Logic)    │  │ (Display)   │  │ (Error UI)   │
└────────────┘  └────────────┘  └─────────────┘  └──────────────┘
```

## Language Configuration Flow

```
User Language: "en" (English)
         │
         ├─── getContentParams("en", textId) ──→ API Request Parameters
         │                                        {
         │                                          recitations: ["bo"],
         │                                          translations: ["en"],
         │                                          transliterations: ["en"]
         │                                        }
         │
         └─── getContentOrder("en") ─────────→ Display Order
                                               [
                                                 ContentType.translation,
                                                 ContentType.recitation,
                                                 ContentType.transliteration
                                               ]
```

## Before vs After Comparison

### Before (Monolithic)
```
RecitationDetailScreen (307 lines)
├── All language logic embedded
├── Duplicated rendering code
├── Save/unsave logic mixed in
├── Error handling inline
└── No reusable components
```

### After (Modular)
```
RecitationDetailScreen (91 lines)
├── Uses RecitationLanguageConfig
├── Delegates to RecitationContent
├── Uses RecitationSaveController
├── Uses RecitationErrorState
└── Composed of 7 reusable components
```

## Layer Responsibilities

### Domain Layer
```
┌─────────────────────────────────────────────┐
│  Business Logic & Configuration             │
│  • No UI dependencies                       │
│  • Pure Dart code                           │
│  • Easily testable                          │
│  • Language-agnostic                        │
└─────────────────────────────────────────────┘
```

### Presentation Layer - Controllers
```
┌─────────────────────────────────────────────┐
│  User Interaction Handlers                  │
│  • Coordinate between UI and data           │
│  • Handle side effects                      │
│  • Manage user feedback                     │
└─────────────────────────────────────────────┘
```

### Presentation Layer - Widgets
```
┌─────────────────────────────────────────────┐
│  Pure UI Components                         │
│  • Stateless when possible                  │
│  • Single responsibility                    │
│  • Highly reusable                          │
│  • Composable                               │
└─────────────────────────────────────────────┘
```

## Content Rendering Logic

```
RecitationSegment receives:
  • segment: RecitationSegmentModel (data)
  • contentOrder: List<ContentType> (configuration)

For each ContentType in contentOrder:
  ┌──────────────────────────────────────┐
  │ Switch on ContentType                │
  ├──────────────────────────────────────┤
  │ case recitation:                     │
  │   → Get segment.recitation map       │
  │                                      │
  │ case translation:                    │
  │   → Get segment.translations map     │
  │                                      │
  │ case transliteration:                │
  │   → Get segment.transliterations map │
  │                                      │
  │ case adaptation:                     │
  │   → Get segment.adaptations map      │
  └──────────────────────────────────────┘
         │
         ▼
  ┌──────────────────────────────────────┐
  │ For each entry in map:               │
  │   → Create RecitationTextSection     │
  │   → Add spacing between entries      │
  └──────────────────────────────────────┘
```

## State Management

```
┌──────────────────────────────────────────────────────────┐
│                    Riverpod Providers                     │
└───────────────┬──────────────────────────────────────────┘
                │
                ├── authProvider
                │   └── Tracks: isGuest
                │
                ├── savedRecitationsFutureProvider
                │   └── Returns: List<RecitationModel>
                │   └── Invalidated after: save/unsave
                │
                └── recitationContentProvider(params)
                    └── Input: RecitationContentParams
                    └── Returns: RecitationContentModel
                    └── States: loading | data | error
```

## Error Handling Flow

```
Error occurs in:
  ├── API call
  ├── Save/unsave operation
  └── Content loading

         │
         ▼
┌─────────────────────────────────────────┐
│  Is it a data loading error?            │
│  (recitationContentProvider)            │
└──────────┬──────────────────────────────┘
           │
    Yes    │    No
           │
           ▼                    ▼
┌──────────────────┐   ┌────────────────────┐
│ Show Error State │   │ Show SnackBar      │
│ (Full screen)    │   │ (Non-intrusive)    │
│                  │   │                    │
│ RecitationError  │   │ In Controller      │
│ State widget     │   │                    │
└──────────────────┘   └────────────────────┘
```

## Testing Strategy

```
Unit Tests
├── RecitationLanguageConfig
│   ├── Test getContentParams for each language
│   ├── Test getContentOrder for each language
│   └── Test isLanguageSupported
│
├── RecitationSaveController
│   ├── Test toggleSave for authenticated users
│   ├── Test toggleSave for guests (shows login)
│   └── Test error handling
│
└── ContentType enum
    └── Test enum values

Widget Tests
├── RecitationTextSection
│   ├── Test text rendering
│   └── Test HTML tag conversion
│
├── RecitationSegment
│   ├── Test content ordering
│   ├── Test divider display
│   └── Test empty content handling
│
├── RecitationContent
│   ├── Test title display
│   └── Test segment rendering
│
└── RecitationErrorState
    └── Test error display

Integration Tests
└── RecitationDetailScreen
    ├── Test full user flow
    ├── Test language switching
    ├── Test save/unsave
    └── Test error recovery
```

## Performance Considerations

### Optimizations Applied
- ✅ **ConsumerWidget instead of ConsumerStatefulWidget**: Reduced overhead
- ✅ **Const constructors**: Widgets can be cached by Flutter
- ✅ **Minimal rebuilds**: Clear provider watching
- ✅ **Lazy loading**: Content fetched only when needed

### Future Optimizations
- 🔄 **Memoization**: Cache content order calculations
- 🔄 **Pagination**: Load large recitations in chunks
- 🔄 **Image caching**: If images are added to content
- 🔄 **Offline mode**: Cache frequently accessed recitations

## Extensibility Points

### Adding New Language
```dart
// In RecitationLanguageConfig
static const String newLanguage = 'new';

// Update getContentParams
case newLanguage:
  return RecitationContentParams(
    textId: textId,
    // ... configure
  );

// Update getContentOrder
case newLanguage:
  return [
    // ... define order
  ];
```

### Adding New Content Type
```dart
// 1. Update ContentType enum
enum ContentType {
  // ...
  newType,
}

// 2. Update RecitationSegment switch
case ContentType.newType:
  contentMap = segment.newTypeField;
```

### Adding New Features
- **Share functionality**: Extend `RecitationDetailScreen` with share button
- **Audio playback**: Add new widget `RecitationAudioPlayer`
- **Favorites**: Extend `RecitationSaveController` with favorites logic
- **Notes**: Create `RecitationNotesWidget` component
