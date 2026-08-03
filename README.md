# TrustHire — Flutter UI/UX Prototype

This is a **UI-only prototype**: 14 screens across Onboarding, Job Seeker,
Employer, and Admin flows, wired together with navigation and mock data.
There's no backend, Firebase, or real payment integration yet — it's meant
to let you *see and click through* the design before you build the real
thing.

## What's inside
```
lib/
  main.dart                     -> app entry + routes
  theme.dart                    -> colors, fonts, ThemeData
  widgets.dart                  -> TrustRing, badges, cards, buttons
  screens/
    root_menu_screen.dart       -> storyboard menu (start here)
    onboarding_screens.dart     -> splash, role select, KYC, trust intro
    seeker_screens.dart         -> job feed, job details, chat, rate
    employer_screens.dart       -> post job, applicants, escrow, release
    admin_screens.dart          -> fraud monitoring, verification/disputes
```

## How to run it

### 1. Install Flutter (one-time setup)
If you don't already have Flutter installed:
- Download it from https://docs.flutter.dev/get-started/install
- Run `flutter doctor` afterward and fix anything it flags (Android
  Studio / Xcode / device setup).

### 2. Get the project onto your machine
Unzip the project folder you downloaded, then open a terminal inside it
(the folder containing `pubspec.yaml`).

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Run it
Easiest option — a Chrome browser window:
```bash
flutter run -d chrome
```

Or on an Android emulator / physical phone:
```bash
flutter devices        # lists available emulators/phones
flutter run             # runs on whichever device is connected
```

If you use **Android Studio** or **VS Code** instead: just open this
folder as a project, pick a device from the device dropdown, and press
the green ▶️ Run button.

### 5. Using the app
It opens on a **storyboard menu** with four cards — tap any one to walk
through that flow screen by screen. Every "Continue / Apply / Submit"
button pushes to the next screen in that flow; use the phone's back
button (or the ← in the app bar) to go back.

## Next steps to make it real
- Replace mock lists (`jobs`, `applicants`) with data from Firebase/Firestore
- Wire the KYC upload boxes to `image_picker` + your verification API
- Replace the escrow screen with real Razorpay Sandbox checkout
- Add the AI fraud-check card's live result from your Python service
- Add state management (Provider/Riverpod/Bloc) once screens need shared state
