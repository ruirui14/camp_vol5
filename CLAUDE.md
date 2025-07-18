# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Navigate to the iOS project directory
cd camp_vol5_ios

# Build the project
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios build

# Build and run on iOS Simulator (use iPhone 16 as default)
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16' build

# Alternative simulators: iPhone 15 Pro, iPhone 15 Pro Max, iPhone SE (3rd generation)
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Clean build folder
xcodebuild clean -project camp_vol5_ios.xcodeproj

# Run tests (if available)
xcodebuild test -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture Overview

This is a **SwiftUI + Firebase iOS app** using **MVVM architecture** for real-time heartbeat monitoring with social features.

### Key Architectural Patterns

- **MVVM Pattern**: Models → Services → ViewModels → Views
- **Reactive Programming**: Extensive use of Combine framework for data flow
- **EnvironmentObject Pattern**: AuthenticationManager injected through SwiftUI's dependency injection
- **@StateObject Pattern**: ViewModels declared with @StateObject in Views, not @State
- **Singleton Services**: UserService and HeartbeatService (AuthService replaced with EnvironmentObject)
- **Publisher-Subscriber**: Real-time data updates through Combine publishers

### Firebase Integration

The app uses **dual authentication modes**:
- **Anonymous Authentication**: Default for guest users
- **Google Sign-In**: Full social features with account linking
- **Firestore**: User profiles and follow relationships
- **Realtime Database**: Live heartbeat streaming (5-minute validity)

### Data Flow Architecture

```
Views (SwiftUI) → ViewModels → Services → Firebase
     ↑                ↑          ↑         ↓
     ├── @EnvironmentObject ──────┴─────────── Combine Publishers
     └── AuthenticationManager (ObservableObject)
```

**Authentication**: Uses `@EnvironmentObject` pattern for dependency injection  
**Services**: UserService and HeartbeatService remain as singletons  
**ViewModels**: Accept AuthenticationManager through constructor injection using @StateObject pattern

### Project Structure

This repository contains two main projects:
- `camp_vol5_ios/`: Main iOS application with SwiftUI
- `camp_vol5_watch/`: Apple Watch companion app

#### iOS App Structure (`camp_vol5_ios/`)

- **Models/**: Data structures (`Heartbeat`, `User`)
- **Services/**: Firebase integration and business logic
- **ViewModels/**: UI state management with Combine
- **Views/**: SwiftUI components with reactive binding
  - **Components/**: Reusable UI components
  - **Modifiers/**: Custom view modifiers for navigation

### Key Dependencies

- **Firebase iOS SDK v11.14.0**: Authentication, Firestore, Realtime Database
- **GoogleSignIn-iOS v8.0.0**: OAuth integration
- **iOS 18.0+**: Minimum deployment target

### Service Layer Architecture

**UserService.swift** - Firestore operations:
- `createUser()`, `getUser()`, `updateUser()` - User CRUD operations
- `findUserByInviteCode()` - QR code user discovery
- `followUser()`, `unfollowUser()` - Social relationship management
- All methods return Combine publishers for reactive programming

**HeartbeatService.swift** - Realtime Database operations:
- `getHeartbeatOnce()` - Single heartbeat fetch for list views
- `subscribeToHeartbeat()` - Real-time monitoring for detail views
- `sendHeartbeat()` - Heart rate data transmission
- 5-minute data validity window enforced
- `unsubscribeFromHeartbeat()` - Cleanup method to prevent memory leaks

**AuthenticationManager.swift** - Authentication state management:
- Combines Firebase Auth with Google Sign-In
- Anonymous authentication for guest users
- Account linking for seamless user experience
- Reactive state updates via @Published properties

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

**User Model** - Firestore document structure:
- `id: String` - Firebase UID
- `name: String` - Display name
- `inviteCode: String` - UUID for QR sharing
- `allowQRRegistration: Bool` - Privacy control
- `followingUserIds: [String]` - Social connections

**Heartbeat Model** - Realtime Database structure:
- `userId: String` - User identifier
- `bpm: Int` - Heart rate value
- `timestamp: Date` - Data validity (5-minute window)

### Configuration Requirements

- Firebase configuration requires `GoogleService-Info.plist`
- Google Sign-In requires URL scheme configuration in `Info.plist`
- Google Sign-In URL Scheme: `com.googleusercontent.apps.57453481062-r0n92cckbieo2s9kl334241bnntuehsv`
- Bundle ID: `com.rui.camp-vol5-ios-1950`

### Common Issues

- **"ユーザ情報が読み込み中..." stuck**: Check AuthenticationManager currentUser binding in ViewModels
- **Firebase Auth errors**: Verify GoogleService-Info.plist and URL scheme configuration
- **Real-time data not updating**: Ensure proper Combine subscription management in ViewModels
- **QR scanner not working**: Camera permission required in Info.plist
- **QR scanner page dismisses immediately**: Check shouldDismiss state management and Combine subscription lifecycle
- **Build fails with device not found**: Use iPhone 16 or iPhone 15 Pro instead of iPhone 15 (not available)

### Development Notes

- Code formatting handled by Xcode's built-in formatter
- SweetPad integration for external formatting support
- 各ファイルの冒頭には必ず日本語のコメントで仕様を記述すること
- 生成されたコードは、必ずコマンドを実行してビルドとテストを行うこと