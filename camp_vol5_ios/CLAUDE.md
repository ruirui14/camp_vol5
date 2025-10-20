# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**IMPORTANT**: All commands must be run from `/Users/fuuma/Dev/swift/camp_vol5/camp_vol5_ios/` (the repository root)

```bash
# Build the project
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios build

# Build and run on iOS Simulator (use iPhone 16 as default)
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16' build

# Alternative simulators: iPhone 15 Pro, iPhone 15 Pro Max, iPhone SE (3rd generation)
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Clean build folder
xcodebuild clean -project camp_vol5_ios.xcodeproj

# Run tests (currently no tests implemented)
xcodebuild test -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16'

# Package dependency resolution (if needed)
xcodebuild -resolvePackageDependencies -project camp_vol5_ios.xcodeproj

# Format all Swift files
find . -name '*.swift' -print0 | xargs -0 swift-format format -i

# List available simulators
xcrun simctl list devices available
```

## Architecture Overview

This is a **SwiftUI + Firebase iOS app** using **Clean Architecture + MVVM** for real-time heartbeat monitoring with social features.

### Key Architectural Patterns

- **Clean Architecture**: Models → Repositories → Services → ViewModels → Views
- **Repository Pattern**: Data access abstraction with protocol-based design (`UserRepositoryProtocol`, `FirestoreUserRepository`)
- **ViewModelFactory Pattern**: Centralized ViewModel creation with dependency injection
- **BaseViewModel**: Shared error handling, loading states, and Combine subscription management
- **Protocol-Based Services**: `UserServiceProtocol`, `HeartbeatServiceProtocol`, `VibrationServiceProtocol` for testability
- **Reactive Programming**: Extensive use of Combine framework for data flow
- **EnvironmentObject Pattern**: AuthenticationManager and ViewModelFactory injected through SwiftUI
- **@StateObject Pattern**: ViewModels declared with @StateObject in Views, not @State
- **Publisher-Subscriber**: Real-time data updates through Combine publishers

### Firebase Integration

The app uses **dual authentication modes**:
- **Anonymous Authentication**: Default for guest users
- **Google Sign-In**: Full social features with account linking
- **Firestore**: User profiles and follow relationships
- **Realtime Database**: Live heartbeat streaming (5-minute validity)

### Data Flow Architecture

```
Views (SwiftUI) → ViewModels → Services → Repositories → Firebase
     ↑                ↑          ↑          ↑           ↓
     ├── @EnvironmentObject ─────┴──────────┴──────── Combine Publishers
     ├── AuthenticationManager (ObservableObject)
     └── ViewModelFactory (ObservableObject)
```

**Dependency Injection**:
- `AuthenticationManager` and `ViewModelFactory` injected as `@EnvironmentObject` from app root
- `ViewModelFactory` creates all ViewModels with proper dependencies
- All ViewModels inherit from `BaseViewModel` for shared functionality

**Layer Responsibilities**:
- **Views**: SwiftUI components, declare ViewModels with `@StateObject`
- **ViewModels**: UI state management, business logic orchestration
- **Services**: Business logic, data transformation, Combine publishers
- **Repositories**: Data access abstraction, Firebase/database operations
- **Models**: Pure data structures (no logic)

### Project Structure

This repository contains two main projects:
- `camp_vol5_ios/`: Main iOS application with SwiftUI (fully implemented)
- `camp_vol5_watch/`: Apple Watch companion app (basic skeleton)

#### iOS App Structure (`camp_vol5_ios/`)

- **Models/**: Pure data structures (`User.swift`, `Heartbeat.swift`, `HeartUser.swift`)
- **Repositories/**: Data access layer with protocol-based design
  - `UserRepositoryProtocol.swift` - Repository interface
  - `FirestoreUserRepository.swift` - Firestore implementation with data transformation
  - `HeartbeatRepositoryProtocol.swift` - Heartbeat data access interface
  - `FirebaseHeartbeatRepository.swift` - Realtime Database implementation
- **Services/**: Business logic and Firebase integration
  - **Core Services**:
    - `AuthenticationManager.swift` - Authentication state (EnvironmentObject)
    - `UserService.swift` - User CRUD operations via Repository
    - `HeartbeatService.swift` - Real-time heartbeat monitoring
    - `ViewModelFactory.swift` - Centralized ViewModel creation with DI
  - **Supporting Services**:
    - `BackgroundImageManager.swift`, `ImagePersistenceManager.swift` - Image management
    - `AppStateManager.swift` - App lifecycle and splash screen control
    - `ConnectivityManager.swift` - Apple Watch communication via WatchConnectivity
    - `WatchHeartRateService.swift` - Watch heart rate data integration
    - `VibrationService.swift` - Haptic feedback
    - `AutoLockManager.swift` - Screen lock prevention
    - `FirebaseLogger.swift`, `FirebaseConfig.swift` - Firebase utilities
  - **Protocols/**: Service abstractions for testability
- **ViewModels/**: UI state management with Combine (all extend `BaseViewModel`)
  - `Base/BaseViewModel.swift` - Shared error handling, loading states, Combine management
  - Authentication: `AuthViewModel.swift`, `EmailAuthViewModel.swift`, `UserNameInputViewModel.swift`
  - Main features: `ListHeartBeatsViewModel.swift`, `HeartbeatDetailViewModel.swift`
  - Social features: `FollowUserViewModel.swift`, `QRScannerViewModel.swift`, `QRCodeShareViewModel.swift`
  - Settings: `SettingsViewModel.swift`
  - UI components: `CardBackgroundEditViewModel.swift`, `HeartAnimationViewModel.swift`, `UserHeartbeatCardViewModel.swift`
- **Views/**: SwiftUI components with reactive binding
  - **Root**: `ContentView.swift`, `SplashView.swift`
  - **Authentication**: `AuthView.swift`, `EmailAuthView.swift`, `UserNameInputView.swift`
  - **Main**: `ListHeartBeatsView.swift`, `HeartbeatDetailView.swift`
  - **Social**: `FollowUserView.swift`, `QRScannerSheet.swift`, `QRCodeShareView.swift`
  - **Settings**: `SettingView.swift`, `Settings/` folder with detailed settings views
  - **Components/**: Reusable UI components (cards, animations, toolbars, etc.)
  - **Modifiers/**: Custom view modifiers for navigation styling
- **Extensions/**: Swift extensions (`Color+Hex.swift`, `Publisher+ErrorHandling.swift`)
- **Constants/**: Shared constants (`CardConstants.swift`)
- **Assets.xcassets/**: App icons, images, and color sets

### Key Dependencies

**Package Manager**: Swift Package Manager (SPM) - dependencies managed through Xcode
- **Firebase iOS SDK v11.14.0**: Authentication, Firestore, Realtime Database, Analytics
- **GoogleSignIn-iOS v8.0.0**: OAuth integration for social login
- **iOS 18.0+**: Minimum deployment target
- **Swift 5.0**: Language version
- **Bundle ID**: `com.rui.camp-vol5-ios-1950`

### Service & Repository Layer Architecture

**Repository Layer** (protocol-based for testability):

`UserRepositoryProtocol` → `FirestoreUserRepository`:
- Handles all Firestore data access and model transformation
- `create()`, `fetch()`, `update()`, `delete()` - CRUD operations
- `findByInviteCode()` - QR code user discovery with privacy filter
- `fetchMultiple()` - Batch user retrieval for following lists
- Encapsulates Firestore ↔ Model data conversion logic

`HeartbeatRepositoryProtocol` → `FirebaseHeartbeatRepository`:
- Real-time Database access for heartbeat data
- Repository handles database-specific operations

**Service Layer** (business logic):

`UserService` (implements `UserServiceProtocol`):
- Business logic for user management via Repository
- `createUser()`, `getUser()`, `updateUser()`, `deleteUser()` - User operations
- `findUserByInviteCode()` - QR code discovery
- `followUser()`, `unfollowUser()`, `getFollowingUsers()` - Social features
- `generateNewInviteCode()`, `updateQRRegistrationSetting()` - Settings
- All methods return Combine publishers

`HeartbeatService` (implements `HeartbeatServiceProtocol`):
- Real-time heartbeat monitoring business logic
- `getHeartbeatOnce()` - Single fetch for list views
- `subscribeToHeartbeat()` - Real-time monitoring for detail views
- `sendHeartbeat()` - Heart rate data transmission
- 5-minute data validity window enforced
- `unsubscribeFromHeartbeat()` - Cleanup to prevent memory leaks

`AuthenticationManager`:
- Combines Firebase Auth with Google Sign-In and Email/Password
- Anonymous authentication for guest users
- Account linking for seamless user experience
- Reactive state updates via @Published properties
- Injected as @EnvironmentObject throughout app

`ViewModelFactory`:
- Centralized ViewModel creation with dependency injection
- Injected as @EnvironmentObject from app root
- Factory methods for all ViewModels with proper dependencies
- Ensures consistent dependency setup across the app

**Apple Watch Integration**:

`ConnectivityManager`:
- WatchConnectivity framework integration
- Receives heart rate data from Apple Watch
- Background task management for reliable data sync
- Timeout monitoring (10-second validity)
- Firebase Realtime Database persistence

`WatchHeartRateService`:
- ObservableObject wrapper for ConnectivityManager
- Publishes heart rate updates to UI
- Methods: `sendUserToWatch()`, `startHeartRateMonitoring()`, `stopHeartRateMonitoring()`

### Background Image Management System

**BackgroundImageManager.swift**: Core service for managing background images with persistent storage
**ImagePersistenceManager.swift**: Handles image processing, storage, and retrieval with advanced compression

**Key Features**:
- **Persistent Storage**: Images saved to Documents/BackgroundImages with UserDefaults metadata
- **Multi-Format Support**: Original, edited, and thumbnail versions automatically generated
- **Memory Management**: Downsampling and compression for performance
- **Transform System**: Normalized coordinate system for consistent positioning across devices
- **Reactive Updates**: @Published properties for real-time UI updates

### Data Models

**User Model** (`Models/User.swift`) - Pure data structure:
- `id: String` - Firebase UID
- `name: String` - Display name
- `inviteCode: String` - UUID for QR sharing
- `allowQRRegistration: Bool` - Privacy control
- `followingUserIds: [String]` - Social connections
- `createdAt: Date?`, `updatedAt: Date?` - Timestamps
- No business logic - data transformation handled by Repository layer

**Heartbeat Model** (`Models/Heartbeat.swift`) - Realtime Database structure:
- `userId: String` - User identifier
- `bpm: Int` - Heart rate value
- `timestamp: Date` - Data validity (5-minute window)

**HeartUser Model** (`Models/HeartUser.swift`):
- Used for Apple Watch data exchange
- Includes `userId` and `userName`

### Configuration Requirements

- **Firebase**: Requires `GoogleService-Info.plist` in project root
  - App Check configured with Debug Provider (DEBUG) or App Attest (RELEASE)
  - Crashlytics enabled for crash reporting
- **Google Sign-In**: Requires URL scheme in `Info.plist`
  - URL Scheme: `com.googleusercontent.apps.57453481062-r0n92cckbieo2s9kl334241bnntuehsv`
- **Apple Watch**: WatchConnectivity framework for heart rate data sync
- **Permissions**: Camera (QR scanning), Photo Library (background images), HealthKit (Apple Watch)
- **Info.plist Keys**:
  - `NSCameraUsageDescription`: QR code scanning
  - `NSPhotoLibraryUsageDescription`: Background image selection

### Common Issues

- **"ユーザ情報が読み込み中..." stuck**: Check AuthenticationManager currentUser binding in ViewModels
- **Firebase Auth errors**: Verify GoogleService-Info.plist and URL scheme configuration
- **Real-time data not updating**: Ensure proper Combine subscription management in ViewModels
- **QR scanner not working**: Camera permission required in Info.plist
- **QR scanner page dismisses immediately**: Check shouldDismiss state management and Combine subscription lifecycle
- **Build fails with device not found**: Use iPhone 16 or iPhone 15 Pro instead of iPhone 15 (not available)
- **Memory leaks in subscriptions**: Always store Combine subscriptions in `cancellables` (inherited from `BaseViewModel`)
- **Apple Watch heart rate not syncing**: Check WCSession activation state and reachability in ConnectivityManager
- **Heart rate shows stale data**: ConnectivityManager has 10-second timeout - check `lastHeartRateReceived`

### Development Notes

- **Code Formatting**: Use `find . -name '*.swift' -print0 | xargs -0 swift-format format -i` for consistency
- **Testing**: Currently no unit tests implemented - manual testing required
- **Watch App**: Located at `crazy_lave Watch App/` with basic heart rate monitoring functionality
  - Uses HealthKit for heart rate measurement
  - WatchConnectivity for data sync with iPhone
  - Models: `HeartUser.swift`, Managers: `WatchHeartRateManager.swift`
- **Recent Refactoring**: The codebase recently underwent Clean Architecture refactoring:
  - Repository layer introduced for data access abstraction
  - Services now use Repositories instead of direct Firebase access
  - ViewModelFactory pattern for centralized ViewModel creation
  - BaseViewModel for shared ViewModel functionality
  - Protocol-based service design for testability

### Code Standards

- **Japanese Comments**: 各ファイルの冒頭には必ず日本語のコメントで仕様を記述すること
- **Build Verification**: 生成されたコードは、必ずコマンドを実行してビルドとテストを行うこと
- **Architecture**: Follow Clean Architecture + MVVM pattern
  - Models: Pure data structures (no logic)
  - Repositories: Data access with protocol-based design
  - Services: Business logic via Repository layer, return Combine publishers
  - ViewModels: Extend `BaseViewModel`, use @StateObject in Views
  - Views: SwiftUI with reactive bindings
- **Dependencies**:
  - Use @EnvironmentObject for AuthenticationManager and ViewModelFactory
  - Create ViewModels via ViewModelFactory factory methods
  - Inject services through constructor parameters (protocol types)
- **Combine Subscriptions**: Always store in `cancellables` to prevent memory leaks
- **Error Handling**: Use `BaseViewModel.handleError()` for consistent error messages
