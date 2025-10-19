.
├── camp_vol5_ios
│   ├── camp_vol5_ios
│   │   ├── Assets.xcassets
│   │   │   ├── AppIcon.appiconset
│   │   │   │   ├── Contents.json
│   │   │   │   ├── icon 1.png
│   │   │   │   ├── icon 2.png
│   │   │   │   └── icon.png
│   │   │   ├── Colors
│   │   │   │   ├── accent.colorset
│   │   │   │   │   └── Contents.json
│   │   │   │   ├── base.colorset
│   │   │   │   │   └── Contents.json
│   │   │   │   ├── main.colorset
│   │   │   │   │   └── Contents.json
│   │   │   │   ├── text.colorset
│   │   │   │   │   └── Contents.json
│   │   │   │   └── Contents.json
│   │   │   ├── GoogleLogo.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   ├── ios_neutral_sq_na@1x.png
│   │   │   │   ├── ios_neutral_sq_na@2x.png
│   │   │   │   └── ios_neutral_sq_na@3x.png
│   │   │   ├── heart_beat.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── 心臓.png
│   │   │   ├── heart.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── heart.svg
│   │   │   ├── kyouai.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── kyouai.png
│   │   │   └── Contents.json
│   │   ├── Constants
│   │   │   └── CardConstants.swift
│   │   ├── Extensions
│   │   │   ├── Color+Hex.swift
│   │   │   ├── Error+Localization.swift
│   │   │   └── Publisher+ErrorHandling.swift
│   │   ├── Models
│   │   │   ├── Follower.swift
│   │   │   ├── Following.swift
│   │   │   ├── Heartbeat.swift
│   │   │   ├── License.swift
│   │   │   └── User.swift
│   │   ├── Repositories
│   │   │   ├── FirebaseHeartbeatRepository.swift
│   │   │   ├── FirestoreFollowerRepository.swift
│   │   │   ├── FirestoreFollowingRepository.swift
│   │   │   ├── FirestoreFollowRepository.swift
│   │   │   ├── FirestoreUserRepository.swift
│   │   │   ├── FollowerRepositoryProtocol.swift
│   │   │   ├── FollowingRepositoryProtocol.swift
│   │   │   ├── FollowRepositoryProtocol.swift
│   │   │   ├── HeartbeatRepositoryProtocol.swift
│   │   │   └── UserRepositoryProtocol.swift
│   │   ├── Resources
│   │   │   ├── PRIVACY_POLICY.md
│   │   │   └── TERMS_OF_SERVICE.md
│   │   ├── Services
│   │   │   ├── Protocols
│   │   │   │   ├── HeartbeatServiceProtocol.swift
│   │   │   │   ├── NotificationServiceProtocol.swift
│   │   │   │   └── VibrationServiceProtocol.swift
│   │   │   ├── AppStateManager.swift
│   │   │   ├── AuthenticationManager.swift
│   │   │   ├── AutoLockManager.swift
│   │   │   ├── BackgroundImageCoordinator.swift
│   │   │   ├── BackgroundImageManager.swift
│   │   │   ├── ConnectivityManager.swift
│   │   │   ├── FirebaseConfig.swift
│   │   │   ├── FirebaseLogger.swift
│   │   │   ├── HeartbeatService.swift
│   │   │   ├── ImagePersistenceManager.swift
│   │   │   ├── NotificationService.swift
│   │   │   ├── PerformanceMonitor.swift
│   │   │   ├── PersistenceManager.swift
│   │   │   ├── UserService.swift
│   │   │   ├── VibrationService.swift
│   │   │   ├── ViewModelFactory.swift
│   │   │   └── WatchHeartRateService.swift
│   │   ├── ViewModels
│   │   │   ├── Base
│   │   │   │   └── BaseViewModel.swift
│   │   │   ├── AuthViewModel.swift
│   │   │   ├── CardBackgroundEditViewModel.swift
│   │   │   ├── EmailAuthViewModel.swift
│   │   │   ├── FollowUserViewModel.swift
│   │   │   ├── HeartAnimationViewModel.swift
│   │   │   ├── HeartbeatDetailViewModel.swift
│   │   │   ├── ListHeartBeatsViewModel.swift
│   │   │   ├── QRCodeShareViewModel.swift
│   │   │   ├── QRScannerViewModel.swift
│   │   │   ├── SettingsViewModel.swift
│   │   │   ├── UserHeartbeatCardViewModel.swift
│   │   │   └── UserNameInputViewModel.swift
│   │   ├── Views
│   │   │   ├── Components
│   │   │   │   ├── BackgroundGradient.swift
│   │   │   │   ├── CameraQRScannerView.swift
│   │   │   │   ├── EmptyFollowingUsersView.swift
│   │   │   │   ├── ErrorStateView.swift
│   │   │   │   ├── FollowingUsersListView.swift
│   │   │   │   ├── HeartAnimationView.swift
│   │   │   │   ├── HeartbeatDetailBackground.swift
│   │   │   │   ├── HeartbeatDetailStatusBar.swift
│   │   │   │   ├── HeartbeatDetailToolbar.swift
│   │   │   │   ├── HeartBeatsListToolbar.swift
│   │   │   │   ├── ModernTextFieldStyle.swift
│   │   │   │   ├── NavigationBarGradient.swift
│   │   │   │   ├── QRCodeCardGenerator.swift
│   │   │   │   ├── SettingRow.swift
│   │   │   │   ├── SettingsNavigationSection.swift
│   │   │   │   ├── SettingsSignOutSection.swift
│   │   │   │   ├── SettingsToolbar.swift
│   │   │   │   ├── UserHeartbeatCard.swift
│   │   │   │   └── WhiteCapsuleTitle.swift
│   │   │   ├── Modifiers
│   │   │   │   ├── GradientNavigationBarModifier.swift
│   │   │   │   ├── NavigationBarTitleColorModifier.swift
│   │   │   │   └── NavigationBarTransparentModifier.swift
│   │   │   ├── Resource
│   │   │   │   └── splash-logo.riv
│   │   │   ├── Settings
│   │   │   │   ├── AccountDeletionView.swift
│   │   │   │   ├── AutoLockSettingsView.swift
│   │   │   │   ├── HeartbeatSettingsView.swift
│   │   │   │   ├── LicenseDetailView.swift
│   │   │   │   ├── LicensesView.swift
│   │   │   │   ├── PrivacyPolicyView.swift
│   │   │   │   ├── TermsOfServiceView.swift
│   │   │   │   ├── UserInfoSettingsView.swift
│   │   │   │   └── UserNameEditView.swift
│   │   │   ├── AuthView.swift
│   │   │   ├── CardBackgroundEditView.swift
│   │   │   ├── EmailAuthView.swift
│   │   │   ├── FollowUserView.swift
│   │   │   ├── HeartbeatDetailView.swift
│   │   │   ├── ImageEditView.swift
│   │   │   ├── ListHeartBeatsView.swift
│   │   │   ├── PhotoPickerView.swift
│   │   │   ├── QRCodeShareView.swift
│   │   │   ├── QRScannerSheet.swift
│   │   │   ├── SettingView.swift
│   │   │   ├── SplashView.swift
│   │   │   └── UserNameInputView.swift
│   │   ├── camp_vol5_ios.entitlements
│   │   ├── camp_vol5_iosApp.swift
│   │   ├── ContentView.swift
│   │   └── GoogleService-Info.plist
│   ├── crazy_love Watch App
│   │   ├── Assets.xcassets
│   │   │   ├── AccentColor.colorset
│   │   │   │   └── Contents.json
│   │   │   ├── AppIcon.appiconset
│   │   │   │   └── Contents.json
│   │   │   ├── heart.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── heart.svg
│   │   │   └── Contents.json
│   │   ├── Managers
│   │   │   └── WatchHeartRateManager.swift
│   │   ├── Models
│   │   │   └── HeartUser.swift
│   │   ├── ViewModels
│   │   │   └── ContentViewModel.swift
│   │   ├── Views
│   │   │   └── ContentView.swift
│   │   ├── crazy_lave Watch App.entitlements
│   │   ├── crazy_laveApp.swift
│   │   └── crazy_love Watch App.entitlements
│   ├── Settings.bundle
│   ├── camp-vol5-ios-Info.plist
│   ├── CLAUDE.md
│   └── crazy-lave-Watch-App-Info.plist
├── docs
│   └── tree.md
├── firebase
│   ├── database.rules.json
│   ├── firestore.indexes.json
│   ├── firestore.rules
│   └── README.md
├── functions
│   ├── lib
│   │   ├── test
│   │   │   ├── firebase-mock.js
│   │   │   ├── firebase-mock.js.map
│   │   │   ├── helpers.js
│   │   │   └── helpers.js.map
│   │   ├── cleanupOldHeartbeats.d.ts
│   │   ├── cleanupOldHeartbeats.d.ts.map
│   │   ├── cleanupOldHeartbeats.js
│   │   ├── cleanupOldHeartbeats.js.map
│   │   ├── index.d.ts
│   │   ├── index.d.ts.map
│   │   ├── index.integration.test.js
│   │   ├── index.integration.test.js.map
│   │   ├── index.js
│   │   ├── index.js.map
│   │   ├── notificationTrigger.d.ts
│   │   ├── notificationTrigger.d.ts.map
│   │   ├── notificationTrigger.js
│   │   ├── notificationTrigger.js.map
│   │   ├── types.d.ts
│   │   ├── types.d.ts.map
│   │   ├── types.js
│   │   ├── types.js.map
│   │   ├── utils.js
│   │   ├── utils.js.map
│   │   ├── utils.test.js
│   │   └── utils.test.js.map
│   ├── src
│   │   ├── cleanupOldHeartbeats.ts
│   │   ├── index.ts
│   │   ├── notificationTrigger.ts
│   │   └── types.ts
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── README.md
│   └── tsconfig.json
├── script
│   ├── deleteAllUsers.js
│   ├── package.json
│   ├── pnpm-lock.yaml
│   └── serviceAccountKey.json
├── CLAUDE.md
├── firebase.json
├── lefthook.yml
└── Taskfile.yml

45 directories, 185 files
