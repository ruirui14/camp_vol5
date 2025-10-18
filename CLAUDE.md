# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **real-time heartbeat monitoring app with social features**, consisting of:
- **iOS App** (`camp_vol5_ios/`): SwiftUI + Firebase using Clean Architecture + MVVM
- **Apple Watch App** (`crazy_love Watch App/`): HealthKit integration for heart rate monitoring
- **Firebase Backend** (`functions/`): Cloud Functions for push notifications
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

# Run local emulator
npm run serve

# Deploy functions to Firebase
npm run deploy

# View function logs
npm run logs

# Open Firebase Functions shell
npm run shell

# Delete all Firebase Auth users (development only)
# After deploying, access via HTTPS:
curl "https://asia-southeast1-heart-beat-23158.cloudfunctions.net/deleteAllAuthUsers?secret=delete-all-users-2024"

# Delete Realtime Database heartbeats
firebase database:remove /live_heartbeats --project heart-beat-23158 --confirm
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
- **Repository Pattern**: Protocol-based data access (`UserRepositoryProtocol`, `HeartbeatRepositoryProtocol`)
- **ViewModelFactory Pattern**: Centralized dependency injection for ViewModels
- **BaseViewModel**: Shared error handling, loading states, Combine subscription management
- **Protocol-Based Services**: All services use protocols for testability
- **Reactive Programming**: Combine framework throughout for data flow
- **@EnvironmentObject**: AuthenticationManager and ViewModelFactory injected from app root
- **@StateObject**: ViewModels always declared with @StateObject in Views, never @State

### Layer Responsibilities

**Models** (`Models/`):
- Pure data structures with no business logic
- `User.swift`: User profile with social connections
- `Heartbeat.swift`: Real-time heart rate data (5-minute validity)
- `HeartUser.swift`: Apple Watch data exchange model

**Repositories** (`Repositories/`):
- Data access abstraction with protocol-based design
- `FirestoreUserRepository.swift`: User CRUD operations, follow relationships, QR code discovery
  - Uses `setData(merge: true)` for `private/metadata` updates (backward compatible)
  - Stores timestamps in separate `private/metadata` subcollection
- `FirebaseHeartbeatRepository.swift`: Real-time heartbeat data access
- Handle all Firebase ↔ Model data transformation

**Services** (`Services/`):
- Business logic layer that uses Repositories
- Return Combine publishers for reactive data flow
- Core services:
  - `AuthenticationManager.swift`: Firebase Auth + Google Sign-In + Email/Password, anonymous auth for guests
  - `UserService.swift`: User management, follow/unfollow operations via Repository
  - `HeartbeatService.swift`: Real-time monitoring, 5-minute data validity
  - `ViewModelFactory.swift`: Centralized ViewModel creation with DI
  - `ConnectivityManager.swift`: Apple Watch communication via WatchConnectivity
  - `WatchHeartRateService.swift`: Watch heart rate integration

**ViewModels** (`ViewModels/`):
- All extend `BaseViewModel` for shared functionality
- UI state management with Combine
- Created via ViewModelFactory for proper dependency injection
- Always use @StateObject in Views

**Views** (`Views/`):
- SwiftUI components with reactive bindings
- Main views: `ListHeartBeatsView`, `HeartbeatDetailView`
- Auth flow: `AuthView`, `EmailAuthView`, `UserNameInputView`
- Social: `FollowUserView`, `QRScannerSheet`, `QRCodeShareView`
- Reusable components in `Components/`

### Firebase Backend Architecture

**Cloud Functions** (`functions/index.js`):
- **onHeartbeatUpdate**: Triggered on `live_heartbeats/{userId}` writes
  - Rate limiting: 5-minute cooldown between notifications
  - Fetches follower list from Firestore
  - Sends push notifications to followers with `notificationEnabled: true`
  - Updates `lastNotificationSent` timestamp in Realtime Database
- **deleteAllAuthUsers**: HTTPS-triggered admin function (region: asia-southeast1)
  - Deletes all Firebase Authentication users
  - Requires secret key `?secret=delete-all-users-2024`
  - Used for testing/development data cleanup

**Data Structure**:

Realtime Database:
```
live_heartbeats/
  {userId}/
    bpm: number
    timestamp: number (milliseconds)
    lastNotificationSent: number (milliseconds)
```

Firestore:
```
users/
  {userId}/
    id: string
    name: string
    inviteCode: string (UUID)
    allowQRRegistration: boolean
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

### Firebase Integration

**Dual Authentication**:
- Anonymous authentication for guest users
- Google Sign-In for full social features
- Email/Password authentication
- Account linking for seamless migration

**Firestore**: User profiles, follow relationships
**Realtime Database**: Live heartbeat streaming (5-minute validity window)

## Key Dependencies

**iOS App**:
- Swift Package Manager (SPM)
- Firebase iOS SDK v11.14.0 (Auth, Firestore, Realtime Database, Analytics)
- GoogleSignIn-iOS v8.0.0
- iOS 18.0+ minimum deployment
- Bundle ID: `com.rui.camp-vol5-ios-1950`

**Firebase Functions**:
- Node.js 18
- firebase-admin v12.0.0
- firebase-functions v5.0.0

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
npm run serve
```

Then trigger functions manually or use the Firebase emulator UI at `http://localhost:4000`

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
- **No notifications sent**: Verify `notificationEnabled: true` in follower documents
- **Rate limiting not working**: Check `lastNotificationSent` field in Realtime Database
- **"No document to update" error**: Fixed - Repository now uses `setData(merge: true)` for backward compatibility with existing users

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
- **Code Formatting**: Use swift-format for consistency

## Recent Refactoring Notes

The codebase recently underwent Clean Architecture refactoring:
- Repository layer introduced for data access abstraction
- Services now use Repositories instead of direct Firebase access
- ViewModelFactory pattern for centralized dependency injection
- BaseViewModel for shared functionality
- Protocol-based design throughout for testability
