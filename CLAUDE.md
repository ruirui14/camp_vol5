# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **real-time heartbeat monitoring app with social features**, consisting of:
- **iOS App** (`camp_vol5_ios/`): SwiftUI + Firebase using Clean Architecture + MVVM
- **Apple Watch App** (`crazy_love Watch App/`): HealthKit integration for heart rate monitoring
- **Firebase Backend** (`functions/`): TypeScript Cloud Functions for push notifications and ranking system
- **Firebase Security Rules** (`firebase/`): Firestore and Realtime Database rules

## Build & Development Commands

### iOS App

**Working directory**: `/Users/fuuma/Dev/swift/camp_vol5/camp_vol5_ios/`

```bash
# Build the project
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios build

# Build and run on iOS Simulator (iPhone 16 is default)
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build folder
xcodebuild clean -project camp_vol5_ios.xcodeproj

# Run tests
xcodebuild test -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16'

# Resolve package dependencies
xcodebuild -resolvePackageDependencies -project camp_vol5_ios.xcodeproj

# Format Swift code
find . -name '*.swift' -print0 | xargs -0 swift-format format -i

# List available simulators
xcrun simctl list devices available
```

### Firebase Functions

**Working directory**: `/Users/fuuma/Dev/swift/camp_vol5/functions/`

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Type check without emitting
npm run typecheck

# Lint TypeScript code
npm run lint

# Format code with Prettier
npm run format

# Run local emulator
npm run serve

# Deploy functions to Firebase
npm run deploy

# View function logs
npm run logs

# Open Firebase Functions shell
npm run shell

# Delete Realtime Database heartbeats
firebase database:remove /live_heartbeats --project heart-beat-23158 --confirm

# Delete notification triggers
firebase database:remove /notification_triggers --project heart-beat-23158 --confirm
```

### Firebase Rules Deployment

**Working directory**: `/Users/fuuma/Dev/swift/camp_vol5/`

```bash
# Deploy Firestore rules only
firebase deploy --only firestore:rules

# Deploy Realtime Database rules only
firebase deploy --only database

# Deploy both rules
firebase deploy --only firestore:rules,database

# Deploy everything (functions + rules)
firebase deploy
```

## Architecture Overview

### iOS App Architecture

**Pattern**: Clean Architecture + MVVM with Repository Pattern

**Layer Structure**:
```
Views (SwiftUI) → ViewModels → Services → Repositories → Firebase
     ↑                ↑          ↑          ↑           ↓
     ├── @EnvironmentObject ─────┴──────────┴──────── Combine Publishers
     ├── AuthenticationManager (ObservableObject)
     └── ViewModelFactory (ObservableObject)
```

**Key Architectural Patterns**:
- **Repository Pattern**: Protocol-based data access (`UserRepositoryProtocol`, `HeartbeatRepositoryProtocol`, `FollowerRepositoryProtocol`, etc.)
- **ViewModelFactory Pattern**: Centralized dependency injection for ViewModels
- **BaseViewModel**: Shared error handling, loading states, Combine subscription management
- **Protocol-Based Services**: All services use protocols for testability
- **Reactive Programming**: Combine framework throughout for data flow
- **@EnvironmentObject**: AuthenticationManager and ViewModelFactory injected from app root
- **@StateObject**: ViewModels always declared with @StateObject in Views, never @State
- **@MainActor Pattern**: Thread-safe UI state management (ViewModelFactory, AuthenticationManager, ColorThemeManager, etc.)
- **Singleton Pattern**: Shared instances for stateless services (`.shared` instances)

### Layer Responsibilities

**Models** (`Models/`):
- Pure data structures with no business logic
- `User.swift`: User profile with social connections and maxConnections for ranking
- `Heartbeat.swift`: Real-time heart rate data (5-minute validity)
- `HeartUser.swift`: Apple Watch data exchange model
- `Follower.swift`: Follower relationship with FCM token and notification settings
- `Following.swift`: Following relationship
- `CardImageTransformState.swift`: Background image transform state (scale, offset, opacity)
- `License.swift`: Open source license information

**Repositories** (`Repositories/`):
- Data access abstraction with protocol-based design
- User Data:
  - `FirestoreUserRepository.swift`: User CRUD operations, QR code discovery
    - Uses `setData(merge: true)` for `private/metadata` updates (backward compatible)
    - Stores timestamps in separate `private/metadata` subcollection
- Heartbeat Data:
  - `FirebaseHeartbeatRepository.swift`: Real-time heartbeat data access via Realtime Database
- Follow Relationships:
  - `FirestoreFollowerRepository.swift`: Follower data and FCM token management
  - `FirestoreFollowingRepository.swift`: Following relationship management
  - `FirestoreFollowRepository.swift`: Base follow/unfollow operations
- Ranking:
  - `RedisRankingRepository.swift`: Fetches rankings via Cloud Functions HTTPS callable
- All repositories implement protocol interfaces for testability and dependency injection

**Services** (`Services/`):
- Business logic layer that uses Repositories
- Return Combine publishers for reactive data flow
- Authentication & User Management:
  - `AuthenticationManager.swift`: Firebase Auth + Google Sign-In + Email/Password, anonymous auth (@MainActor)
  - `UserService.swift`: User operations, follow/unfollow, ranking retrieval (Singleton)
- Heartbeat & Watch:
  - `HeartbeatService.swift`: Real-time heartbeat monitoring, 5-minute data validity (Singleton)
  - `ConnectivityManager.swift`: Apple Watch communication via WatchConnectivity
  - `WatchHeartRateService.swift`: Watch heart rate integration
- UI State & Theming:
  - `AppStateManager.swift`: Splash screen and app initialization state (@MainActor)
  - `ColorThemeManager.swift`: Theme color persistence with UserDefaults (@MainActor, Singleton)
  - `BackgroundImageManager.swift`: Card background image management
  - `BackgroundImageCoordinator.swift`: Background image selection coordination (@MainActor)
  - `ImagePersistenceManager.swift`: Image compression and transform state storage
- Device & System:
  - `AutoLockManager.swift`: Prevents device auto-lock during active use
  - `DeviceOrientationManager.swift`: Device orientation state management
  - `VibrationService.swift`: Haptic feedback patterns (@MainActor, Singleton)
- Firebase Integration:
  - `NotificationService.swift`: FCM token management and push notification handling
  - `PerformanceMonitor.swift`: Firebase Performance Monitoring
  - `RemoteConfigManager.swift`: Firebase Remote Config for feature flags
  - `FirebaseLogger.swift`: Centralized Firebase logging
  - `FirebaseConfig.swift`: Firebase configuration management
- Utilities:
  - `ViewModelFactory.swift`: Centralized ViewModel creation with DI (@MainActor)
  - `PersistenceManager.swift`: Local data persistence
  - `YouTubeURLService.swift`: YouTube URL handling for streaming

**ViewModels** (`ViewModels/`):
- All extend `BaseViewModel` for shared functionality
- UI state management with Combine
- Created via ViewModelFactory for proper dependency injection
- Always use @StateObject in Views
- Key ViewModels:
  - `AuthViewModel`: Authentication flow state
  - `UserNameInputViewModel`: Username input validation
  - `FollowUserViewModel`: QR-based follow operations
  - `QRScannerViewModel`: QR code scanning state
  - `QRCodeShareViewModel`: QR code generation for sharing
  - `SettingsViewModel`: Settings screen state and operations
  - `ListHeartBeatsViewModel`: Heartbeat list with real-time updates
  - `HeartbeatDetailViewModel`: Individual heartbeat detail view
  - `UserHeartbeatCardViewModel`: User card presentation logic
  - `ConnectionsRankingViewModel`: Ranking list with pagination
  - `StreamViewModel`: Real-time streaming integration
  - `CardBackgroundEditViewModel`: Background image editing state
  - `HeartAnimationViewModel`: Heart animation parameters

**Views** (`Views/`):
- SwiftUI components with reactive bindings
- Main views: `ListHeartBeatsView`, `HeartbeatDetailView`, `ConnectionsRankingView`
- Auth flow: `AuthView`, `PasswordResetView`, `UserNameInputView`
- Social: `FollowUserView`, `QRScannerSheet`, `QRCodeShareView`
- Settings: `SettingsView`, `UserInfoSettingsView`, `UserNameEditView`, `AccountDeletionView`, `AutoLockSettingsView`
- Streaming: `StreamView`, `StreamUrlInputSheet`, `StreamWebViewWrapper`
- Background editing: `CardBackgroundEditView`, `TransformableCardImageView`, `GifPhotoPickerView`
- Reusable components in `Components/`: `BackgroundGradient`, `ErrorStateView`, `IconLabelButtonContent`
- View modifiers in `Modifiers/`: `GradientNavigationBarModifier`, `NavigationBarTransparentModifier`

### Firebase Backend Architecture

**Cloud Functions** (`functions/src/`, **TypeScript**):

All functions written in TypeScript with strict type checking. Entry point: `functions/src/index.ts`

**Notification System**:
- **onNotificationTrigger** (Realtime Database trigger):
  - Triggered on `notification_triggers/{userId}` writes (not `live_heartbeats`)
  - Fetches current heartbeat from `live_heartbeats/{userId}`
  - Retrieves follower list from Firestore `users/{userId}/followers`
  - Sends FCM push notifications to followers with `notificationEnabled: true`
  - Rate limiting handled at iOS app level (5-minute cooldown)
  - Cleans up trigger data after processing

**Ranking System** (Upstash Redis integration):
- **updateRankingScheduled** (Scheduled function, every 5 minutes):
  - Syncs `maxConnections` field from Firestore to Redis Sorted Set
  - Redis key: `user_ranking`, score = maxConnections
  - Enables fast ranking queries without Firestore reads
- **initialSyncRankingToRedis** (HTTPS callable):
  - One-time full sync of all users to Redis
  - Used for initial setup or manual re-sync
- **getRanking** (HTTPS callable):
  - Fetches top N users by maxConnections from Redis
  - On-memory cache (5-minute validity) to reduce Redis reads
  - Fallback to Firestore if Redis unavailable
  - Returns: `{ users: Array<{userId, name, maxConnections, rank}> }`

**Maintenance**:
- **cleanupOldHeartbeats** (Scheduled function, daily at 18:00 UTC / 03:00 JST):
  - Removes heartbeat data older than 1 hour from `live_heartbeats/`
  - Removes notification triggers older than 1 hour from `notification_triggers/`
  - Prevents database bloat from stale data

**Configuration**:
- Runtime: Node.js 20
- Region: asia-southeast1
- Dependencies: firebase-admin v12.0.0, firebase-functions v5.0.0, @upstash/redis v1.35.6
- Redis config: Set via `firebase functions:config:set upstash.redis_url="..." upstash.redis_token="..."`

**Data Structure**:

Realtime Database:
```
live_heartbeats/
  {userId}/
    bpm: number
    timestamp: number (milliseconds)

notification_triggers/
  {userId}/
    trigger: boolean (always true, used to trigger function)
    timestamp: number (milliseconds)
```

Firestore:
```
users/
  {userId}/
    id: string
    name: string
    inviteCode: string (UUID)
    allowQRRegistration: boolean
    maxConnections: number (calculated field for ranking)
    private/
      metadata/
        created_at: timestamp (server timestamp)
        updated_at: timestamp (server timestamp)
    followers/
      {followerId}/
        followerId: string
        fcmToken: string
        notificationEnabled: boolean
        createdAt: timestamp
    following/
      {followingId}/
        followingId: string
        createdAt: timestamp
```

**Redis** (Upstash):
```
user_ranking (Sorted Set)
  member: userId
  score: maxConnections

Rankings cached in-memory for 5 minutes in getRanking function
```

### Firebase Integration

**Dual Authentication**:
- Anonymous authentication for guest users
- Google Sign-In for full social features
- Email/Password authentication
- Account linking for seamless migration

**Firestore**: User profiles, follow relationships, maxConnections for ranking
**Realtime Database**: Live heartbeat streaming (5-minute validity window), notification triggers
**Redis (Upstash)**: Ranking data cache for fast queries

## Key Dependencies

**iOS App**:
- Swift Package Manager (SPM)
- Firebase iOS SDK v11.14.0 (Auth, Firestore, Realtime Database, Analytics)
- GoogleSignIn-iOS v8.0.0
- iOS 18.0+ minimum deployment
- Bundle ID: `com.rui.camp-vol5-ios-1950`

**Firebase Functions**:
- Node.js 20
- firebase-admin v12.0.0
- firebase-functions v5.0.0
- @upstash/redis v1.35.6
- @google-cloud/functions-framework v4.0.0
- TypeScript v5.3.3

**Firebase Project**: `heart-beat-23158` (alias: `kyouai`)

## Configuration Requirements

**iOS App**:
- `GoogleService-Info.plist` in `camp_vol5_ios/camp_vol5_ios/`
- URL Scheme for Google Sign-In: `com.googleusercontent.apps.57453481062-r0n92cckbieo2s9kl334241bnntuehsv`
- Info.plist permissions:
  - `NSCameraUsageDescription`: QR code scanning
  - `NSPhotoLibraryUsageDescription`: Background image selection
  - HealthKit capabilities for Apple Watch integration

**Firebase**:
- App Check with Debug Provider (DEBUG) or App Attest (RELEASE)
- Crashlytics enabled for crash reporting
- WatchConnectivity framework for Apple Watch sync
- Firebase Performance Monitoring enabled
- Remote Config for feature flags

**Cloud Functions**:
- Upstash Redis credentials via Firebase Functions config:
  ```bash
  firebase functions:config:set upstash.redis_url="https://..." upstash.redis_token="..."
  ```

## Common Development Patterns

### Creating a New Feature

1. **Model**: Define pure data structure in `Models/`
2. **Repository**: Create protocol + implementation in `Repositories/`
3. **Service**: Create protocol + implementation in `Services/`, use Repository
4. **ViewModel**: Extend `BaseViewModel`, add factory method to `ViewModelFactory`
5. **View**: Create SwiftUI view, use `@StateObject` for ViewModel

### Dependency Injection

```swift
// In ViewModelFactory
func makeMyFeatureViewModel() -> MyFeatureViewModel {
    MyFeatureViewModel(
        myService: myService,  // Injected via protocol
        authManager: authenticationManager
    )
}

// In View
@EnvironmentObject var viewModelFactory: ViewModelFactory
@StateObject var viewModel: MyFeatureViewModel

var body: some View {
    MyView()
        .onAppear {
            viewModel = viewModelFactory.makeMyFeatureViewModel()
        }
}
```

### Combine Subscriptions

```swift
// Always store in cancellables (from BaseViewModel)
service.publisher
    .sink { [weak self] value in
        self?.handleValue(value)
    }
    .store(in: &cancellables)
```

### Error Handling

```swift
// Use BaseViewModel's handleError
service.operation()
    .sink(
        receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
                self?.handleError(error)
            }
        },
        receiveValue: { value in
            // Handle success
        }
    )
    .store(in: &cancellables)
```

## Testing Firebase Functions Locally

```bash
cd functions
npm run serve  # Builds TypeScript and starts emulator
```

Then trigger functions manually or use the Firebase emulator UI at `http://localhost:4000`

**Note**: Scheduled functions won't automatically run in emulator. Trigger them manually via emulator UI or shell.

## Common Issues & Solutions

**iOS App**:
- **"ユーザ情報が読み込み中..." stuck**: Check AuthenticationManager currentUser binding
- **Firebase Auth errors**: Verify GoogleService-Info.plist and URL scheme
- **Real-time data not updating**: Ensure Combine subscriptions stored in `cancellables`
- **QR scanner dismisses immediately**: Check shouldDismiss state and subscription lifecycle
- **Memory leaks**: Always use `[weak self]` in Combine closures and store in `cancellables`
- **Apple Watch sync issues**: Check WCSession activation and reachability in ConnectivityManager
- **Stale heart rate data**: ConnectivityManager has 10-second timeout

**Firebase Functions**:
- **FCM token invalid**: Token may have expired, check Firebase console
- **No notifications sent**:
  - Verify `notificationEnabled: true` in follower documents
  - Check that `notification_triggers/{userId}` is being written (not `live_heartbeats`)
  - Verify follower's fcmToken exists in Firestore
- **Rate limiting not working**: Rate limiting is handled at iOS app level (5-minute cooldown)
- **"No document to update" error**: Fixed - Repository now uses `setData(merge: true)` for backward compatibility
- **Ranking not updating**:
  - Check `updateRankingScheduled` function logs (runs every 5 minutes)
  - Verify Upstash Redis credentials in Firebase Functions config
  - Manually trigger `initialSyncRankingToRedis` for full re-sync
- **TypeScript compilation errors**: Run `npm run typecheck` to verify types before deployment

## Code Standards

- **Japanese Comments**: 各ファイルの冒頭には必ず日本語のコメントで仕様を記述すること
- **Build Verification**: 生成されたコードは、必ずビルドとテストを実行して検証すること
- **Architecture**: Follow Clean Architecture + MVVM pattern strictly
  - Models: Pure data (no logic)
  - Repositories: Data access with protocols
  - Services: Business logic via Repositories, return Combine publishers
  - ViewModels: Extend BaseViewModel, use @StateObject in Views
  - Views: SwiftUI with reactive bindings
- **Dependency Injection**:
  - Use @EnvironmentObject for AuthenticationManager and ViewModelFactory
  - Create ViewModels via ViewModelFactory factory methods
  - Inject services through constructor (protocol types)
- **Combine**: Always store subscriptions in `cancellables`
- **Error Handling**: Use BaseViewModel.handleError() for consistency
- **Code Formatting**:
  - Swift: Use swift-format for consistency
  - TypeScript: Use Prettier (`npm run format` in functions/)
- **MainActor Pattern**: Use `@MainActor` for services managing UI state (AuthenticationManager, ColorThemeManager, etc.)
- **Singleton Pattern**: Use `.shared` for stateless service singletons (UserService, HeartbeatService, etc.)

## Development Tools & Configuration

**SwiftLint** (`.swiftlint.yml`):
- 20+ opt-in rules enabled for code quality
- Automatic linting enforced via git hooks

**Lefthook** (`lefthook.yml`):
- Pre-commit hooks for code formatting and linting
- Ensures code quality before commits

**Taskfile** (`Taskfile.yml`):
- Task automation for common development workflows

## Recent Refactoring Notes

The codebase recently underwent Clean Architecture refactoring:
- Repository layer introduced for data access abstraction
- Services now use Repositories instead of direct Firebase access
- ViewModelFactory pattern for centralized dependency injection
- BaseViewModel for shared functionality
- Protocol-based design throughout for testability

**New Features Since Refactoring**:
- **Ranking System**: Redis-backed ranking with scheduled sync (every 5 minutes)
- **Follower/Following Split**: Separate repositories for follower and following relationships
- **Background Image Editing**: Transform state persistence with compression
- **Streaming Integration**: YouTube URL handling for real-time streaming
- **Enhanced Settings**: Comprehensive settings with account deletion, auto-lock control
- **Cloud Functions Migration**: JavaScript → TypeScript with strict typing
- **Notification Architecture**: Separated trigger mechanism from heartbeat data
