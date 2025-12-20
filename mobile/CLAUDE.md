# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PocketMind is a Flutter mobile note management application that allows users to easily collect ideas from anywhere with AI enhancement capabilities (planned). The app supports cross-device synchronization via LAN and includes a share extension for quick note capture.

## Architecture

### Clean Architecture Pattern

The codebase follows a clean architecture approach with clear separation of concerns:

- **domain/**: Business entities and repository interfaces (pure Dart, no dependencies)
  - `entities/`: Domain models (NoteEntity, CategoryEntity)
  - `repositories/`: Abstract repository interfaces defining data operations

- **data/**: Data layer implementations
  - `repositories/`: Concrete repository implementations using Isar database
  - `mappers/`: Convert between domain entities and database models

- **model/**: Isar database models with code generation
  - `note.dart`, `category.dart`: Database schemas with `@collection` annotations
  - Generated files: `*.g.dart` (created by build_runner)

- **providers/**: Riverpod state management
  - Uses `riverpod_annotation` with code generation
  - Infrastructure providers (Isar, SharedPreferences, NotificationService)
  - Feature providers (notes, categories, navigation, app config)
  - Generated files: `*_providers.g.dart`

- **page/**: UI layer organized by feature
  - `home/`: Main app screens (HomeScreen, SettingsPage, NoteDetailPage)
  - `share/`: Share extension UI (EditNotePage, ShareSuccessPage)
  - `widget/`: Reusable UI components

- **service/**: Business logic services
  - `note_service.dart`: Note CRUD operations
  - `notification_service.dart`: Local notifications
  - `lan_sync/`: LAN synchronization system

- **api/**: External API integrations
  - HTTP client configuration
  - Link preview service

- **util/**: Utilities and helpers
  - Logging, theme data, image storage, URL parsing

### Dual Entry Points

The app has two separate entry points:

1. **main.dart**: Primary app entry point
   - Initializes Isar database with schemas: Note, Category, SyncLog
   - Runs UUID migration for legacy data
   - Sets up ProviderScope with overrides for Isar, SharedPreferences, NotificationService
   - Launches HomeScreen

2. **main_share.dart**: Share extension entry point (Android)
   - Separate Flutter engine for share functionality
   - Handles incoming shared content via MethodChannel
   - Provides quick note capture UI
   - Uses state machine: waiting → success → editing

### State Management

Uses **Riverpod 3.0** with code generation:
- Providers defined with `@riverpod` annotation
- Infrastructure providers are `keepAlive: true` singletons
- Feature providers use `Notifier` pattern for complex state
- Run `dart run build_runner build` to generate provider code

### Database

**Isar Community Edition** (NoSQL embedded database):
- Schemas: Note, Category, SyncLog
- Models in `model/` directory with `@collection` annotations
- Supports queries, indexes, and reactive streams
- Run `dart run build_runner build` to generate Isar schemas

### LAN Synchronization

Sophisticated peer-to-peer sync system in `lib/lan_sync/`:
- **UDP Discovery**: Broadcasts device presence on LAN
- **WebSocket Server/Client**: Bidirectional real-time sync
- **Conflict Resolution**: Last-write-wins with UUID-based tracking
- **Sync Engine**: Handles data merging and change detection
- **Deterministic Connection**: Uses device ID comparison to decide which peer initiates

Key components:
- `lan_sync_service.dart`: Main service coordinating all sync operations
- `sync_websocket_server.dart`: Accepts incoming connections
- `sync_websocket_client.dart`: Connects to remote peers
- `lan_sync_engine.dart`: Handles sync logic and conflict resolution
- `udp_lan_discovery.dart`: Peer discovery via UDP broadcasts

## Common Development Commands

### Code Generation

```bash
# Generate all code (Riverpod providers, Isar schemas, etc.)
dart run build_runner build

# Watch mode for continuous generation during development
dart run build_runner watch

# Clean generated files before rebuilding
dart run build_runner build --delete-conflicting-outputs
```

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/url_helper_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test test/integration_test.dart
```

### Building

```bash
# Build APK (Android)
flutter build apk

# Build app bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios

# Generate launcher icons
dart run flutter_launcher_icons
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

### Dependency Management

```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Key Technical Details

### UUID Migration

The app includes automatic UUID migration (`_migrateUuidsIfNeeded` in main.dart) that runs on startup to ensure all Notes and Categories have UUIDs for cross-device sync. This is a one-time migration for legacy data.

### Proxy Configuration

The app supports HTTP proxy configuration stored in SharedPreferences:
- `proxy_enabled`: Boolean flag
- `proxy_host`: Proxy server address
- `proxy_port`: Proxy server port
- Applied globally via `HttpOverrides.global` in main.dart

### Image Storage

Images are stored locally using `ImageStorageHelper`:
- Handles content URIs from Android share intents
- Converts and saves images to app's document directory
- Used by share extension for image attachments

### Responsive Design

Uses `flutter_screenutil` for responsive layouts:
- Desktop (>600px width): 1280x720 design size
- Mobile (≤600px width): 400x869 design size
- Adapts text sizes and layouts automatically

### Theme System

Two built-in themes in `util/theme_data.dart`:
- `calmBeigeTheme`: Light theme with warm beige tones
- `quietNightTheme`: Dark theme
- Follows system theme mode by default

### Notification System

Local notifications via `flutter_local_notifications`:
- Timezone-aware scheduling
- Initialized in main.dart
- Provided globally via `notificationServiceProvider`

## Important Patterns

### Repository Pattern

All data access goes through repository interfaces:
- Domain layer defines abstract interfaces
- Data layer provides Isar implementations
- Mappers convert between entities and models
- Services use repositories, never direct database access

### Provider Overrides

Infrastructure providers (Isar, SharedPreferences, NotificationService) are overridden in main() with actual instances. This allows for dependency injection and testing.

### Stream-based Reactivity

UI components use Riverpod's `watch` to reactively update when data changes. Repositories expose `Stream<T>` methods for real-time updates from Isar.

### Share Extension Architecture

The share extension uses a state machine pattern with three states:
- **waiting**: Transparent, waiting for share intent
- **success**: Shows success animation after saving
- **editing**: Full editor for adding details

Communication with native Android code via MethodChannel (`com.doublez.pocketmind/share`).

## Testing Notes

- Unit tests in `test/` directory
- Widget tests use `flutter_test` package
- Mock dependencies with `mockito` package
- Integration tests cover full user flows
- Test files mirror lib/ structure

## Code Generation Files

Never manually edit these generated files:
- `*.g.dart`: Generated by build_runner
- `*_providers.g.dart`: Generated by riverpod_generator
- `*.freezed.dart`: Generated by freezed
- Always regenerate after modifying source files with annotations

## Code Refactoring Tasks (2025-12-20)

This section tracks ongoing code quality improvements and refactoring tasks.

### Task List

#### Phase 1: Add Freezed Support (High Priority)
- [x] Task 1.1: Add Freezed dependencies to pubspec.yaml
- [x] Task 1.2: Migrate NoteEntity to use Freezed
- [x] Task 1.3: Migrate CategoryEntity to use Freezed
- [x] Task 1.4: Migrate AppConfigState to use Freezed
- [x] Task 1.5: Migrate LanSyncState to use Freezed

#### Phase 2: Improve Mappers (Medium Priority)
- [ ] Task 2.1: Convert NoteMapper to extension methods
- [ ] Task 2.2: Convert CategoryMapper to extension methods

#### Phase 3: Code Organization (Medium Priority)
- [ ] Task 3.1: Create unified constants file (lib/core/constants.dart)
- [ ] Task 3.2: Standardize provider file naming (use singular form)
- [ ] Task 3.3: Refactor LanSyncNotifier into smaller classes

#### Phase 4: Error Handling (Medium Priority)
- [ ] Task 4.1: Create Result/Either type for error handling
- [ ] Task 4.2: Update Repository methods to return Result type
- [ ] Task 4.3: Update Service methods to return Result type

#### Phase 5: Testing (Low Priority)
- [ ] Task 5.1: Add unit tests for NoteRepository
- [ ] Task 5.2: Add unit tests for CategoryRepository
- [ ] Task 5.3: Add unit tests for NoteService
- [ ] Task 5.4: Add unit tests for CategoryService

### Completed Tasks

#### 2025-12-20
- ✅ Task 1.1: Add Freezed dependencies to pubspec.yaml
  - Added `freezed_annotation ^3.1.0` to dependencies
  - Added `freezed ^3.0.0-0.0.dev` to dev_dependencies
  - Added `json_serializable ^6.8.0` for JSON support
  - Commit: `8fb119f` and `aa23490`

- ✅ Task 1.1b: Fix build.yaml to include lan_sync/model for Isar generation
  - Updated `build.yaml` to include `lib/lan_sync/model/**` path
  - Fixed SyncLog schema generation issue
  - All SyncLog-related errors resolved
  - Commit: `aa23490`

- ✅ Task 3.1: Create unified constants file (lib/core/constants.dart)
  - Created centralized constants file to eliminate magic numbers
  - Replaced hardcoded values throughout codebase:
    - `1` → `AppConstants.homeCategoryId`
    - `'home'` → `AppConstants.homeCategoryName`
    - `'pocket_images/'` → `AppConstants.localImagePathPrefix`
  - Updated 5 files with proper constant imports
  - All code still compiles without errors
  - Commit: `22b074d`

- ✅ Phase 1: Freezed 迁移完成 (Task 1.2-1.5)
  - 迁移 NoteEntity 到 Freezed 3.0（使用 abstract class）
  - 迁移 CategoryEntity 到 Freezed 3.0（使用 abstract class）
  - 迁移 AppConfigState 到 Freezed 3.0（保留自定义 getter）
  - 迁移 LanSyncState 到 Freezed 3.0（保留自定义 getter 和 factory 构造函数）
  - 创建 check-package-docs skill 用于查询第三方包文档
  - 所有代码通过 flutter analyze 验证
  - Commit: `53a3688`

- ✅ Phase 2: Mapper 扩展方法和 Lint 优化完成
  - 修复 5 个 info 级别警告（HTML 注释、library doc comment、PMlog 命名）
  - 优化 analysis_options.yaml 配置（添加额外的 lint 规则）
  - 将 NoteMapper 转换为扩展方法（NoteX/NoteEntityX）
  - 将 CategoryMapper 转换为扩展方法（CategoryX/CategoryEntityX）
  - 更新所有使用 Mapper 的代码（2 个 Repository 文件）
  - 代码更简洁：`NoteMapper.toDomain(note)` → `note.toDomain()`
  - 所有代码通过 flutter analyze 验证（0 issues）
  - Commit: `f49246d`

### Notes

- Each task should be tested with `flutter analyze` and `flutter run` before committing
- Commit format: `fix: <task description>`
- Run `dart run build_runner build --delete-conflicting-outputs` after adding Freezed annotations

### Known Issues

#### ~~Freezed 3.0 Compatibility Issue~~ (已解决)
- **解决方案**: Freezed 3.0 要求使用 `abstract` 或 `sealed` 关键字
- **实施**: 所有 Freezed 类已更新为 `abstract class`
- **状态**: ✅ 已完成迁移，所有代码正常编译
