# Notes

A Flutter notes app supporting text, checklists, audio recordings, photos, videos, and freehand drawings.

## Features

- **Text notes** — rich text editor with title and body
- **Checklists** — items with checkboxes, reorderable via drag-and-drop, progress display
- **Audio notes** — record via microphone or attach existing audio files
- **Photo notes** — capture with camera or pick multiple from gallery, displayed in a 3-column grid
- **Video notes** — record with camera or pick from gallery
- **Drawing notes** — freehand canvas with 8 colours, adjustable stroke width, undo/clear
- **Search** — full-text search across note titles and content
- **Filter & sort** — filter by note type; sort by created date, updated date, or title (ascending/descending)

## Tech Stack

| Layer | Library |
|---|---|
| State management | [Riverpod](https://riverpod.dev) 2.6 + code generation |
| Database | [Drift](https://drift.simonbinder.eu) 2.20 (SQLite ORM) |
| Audio recording | [record](https://pub.dev/packages/record) 5.2 |
| Photo / video capture | [image_picker](https://pub.dev/packages/image_picker) 1.1 |
| File picking | [file_picker](https://pub.dev/packages/file_picker) 8.1 |
| Open attachments | [open_filex](https://pub.dev/packages/open_filex) 4.4 |

## Project Structure

```
lib/
├── main.dart
├── app/
│   └── app.dart                        # MaterialApp + theme
├── core/
│   ├── database/
│   │   ├── app_database.dart           # Drift database (SQLite)
│   │   ├── daos/notes_dao.dart         # Queries and mutations
│   │   └── tables/                     # Table definitions
│   └── providers/database_provider.dart
└── features/notes/
    ├── data/notes_repository.dart      # File staging + DB operations
    ├── domain/                         # Models and enums
    ├── providers/notes_providers.dart  # Riverpod notifiers
    └── presentation/
        ├── screens/
        │   ├── home_screen.dart
        │   ├── note_editor_screen.dart
        │   └── drawing_screen.dart
        └── widgets/                    # Per-type editor widgets
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.11
- Android SDK or Xcode (for iOS)

### Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Permissions

**Android** — declared in `AndroidManifest.xml`:
- `RECORD_AUDIO`, `CAMERA`
- `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`
- `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (legacy, SDK <= 32/29)

**iOS** — declared in `Info.plist`:
- `NSMicrophoneUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## Architecture

The app follows a feature-first clean architecture:

- **Domain** — pure Dart models and enums, no Flutter/framework dependencies
- **Data** — repository handles file staging (copy to `{appDocs}/attachments/` with UUID filenames) and all database transactions via Drift DAOs
- **Providers** — Riverpod `AsyncNotifier` family providers keyed by `noteId` (`null` = new note); editor state tracks staged attachments separately from persisted ones
- **Presentation** — `ConsumerStatefulWidget` screens and per-type editor widgets; each media editor auto-triggers its capture flow on first open via a route animation listener
