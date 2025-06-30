# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios build

# Build and run on iOS Simulator
xcodebuild -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild clean -project camp_vol5_ios.xcodeproj

# Run tests (if available)
xcodebuild test -project camp_vol5_ios.xcodeproj -scheme camp_vol5_ios -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture Overview

This is a **SwiftUI + Firebase iOS app** using **MVVM architecture** for real-time heartbeat monitoring with social features.

### Key Architectural Patterns

- **MVVM Pattern**: Models → Services → ViewModels → Views
- **Reactive Programming**: Extensive use of Combine framework for data flow
- **Singleton Services**: Shared instances for Firebase interactions (`AuthService.shared`, `FirestoreService.shared`, `RealtimeService.shared`)
- **Publisher-Subscriber**: Real-time data updates through Combine publishers

### Firebase Integration

The app uses **dual authentication modes**:
- **Anonymous Authentication**: Default for guest users
- **Google Sign-In**: Full social features with account linking
- **Firestore**: User profiles and follow relationships
- **Realtime Database**: Live heartbeat streaming (5-minute validity)

### Data Flow Architecture

```
Views (SwiftUI) → ViewModels (@ObservedObject) → Services (Singletons) → Firebase
     ↑                           ↑                        ↑              ↓
     └───────────────────────────┴────────────────────────┴──── Combine Publishers
```

### Directory Structure Significance

- **Models/**: Data structures (`Heartbeat`, `User`)
- **Services/**: Firebase integration and business logic
- **ViewModels/**: UI state management with Combine
- **Views/**: SwiftUI components with reactive binding

### Key Dependencies

- **Firebase iOS SDK v11.14.0**: Authentication, Firestore, Realtime Database
- **GoogleSignIn-iOS v8.0.0**: OAuth integration
- **iOS 18.0+**: Minimum deployment target

### Development Notes

- Code formatting handled by Xcode's built-in formatter
- SweetPad integration for external formatting support
- Firebase configuration requires `GoogleService-Info.plist`
- Google Sign-In requires URL scheme configuration in `Info.plist`