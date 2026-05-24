# MediMinder SwiftUI — Setup Guide
## Open in Xcode 15, macOS Ventura → Build → Run. That's it.

> **Estimated time: ~5 minutes** (mostly waiting for Firebase to download)

---

## Step 1 — Get the code

```bash
git clone https://github.com/YOUR_REPO/mediminder_pillreminder.git
```

Or copy the folder via USB. The folder you want is:
```
mediminder_pillreminder/MediMinderSwiftUI/
```

---

## Step 2 — Open the project in Xcode

Double-click:
```
MediMinderSwiftUI/MediMinderSwiftUI.xcodeproj
```

Xcode opens and immediately shows **"Resolving Packages…"** in the status bar.

> ⏳ This downloads Firebase automatically (FirebaseAuth + FirebaseCore + FirebaseFirestore via Swift Package Manager). Takes **2–5 minutes** on first open. Just wait — do NOT close Xcode.

---

## Step 3 — Select a simulator and run

1. In the toolbar at the top, click the device selector (next to the ▶ button)
2. Choose any **iPhone** simulator (e.g. iPhone 15, iPhone 14, iPhone SE)
3. Press **⌘R** (or click ▶)

The app builds and launches in the simulator.

---

## That's the entire setup. ✅

No CocoaPods. No Terminal. No sudo. No Flutter SDK. No password required.

---

## What the app does

| Screen | Feature |
|--------|---------|
| **Login** | Email + password sign in |
| **Sign Up** | Create new account |
| **Today** | Shows today's doses (interval & weekly schedules), Mark Taken / Dismiss buttons, updates every minute |
| **My Medicines** | Real-time list, swipe left to Edit or Delete, + button to add new |
| **Add / Edit Medicine** | Full form: name, type, dosage, amount, form (Pill/Liquid/Injection), schedule type, interval slider, day picker, time picker |
| **Profile** | Shows account info, Sign Out button |

---

## Firebase

- The `GoogleService-Info.plist` is already inside the project folder — **you do NOT need to download it**.
- The app uses the **same Firebase project** as the Flutter version — all existing data is shared.
- Firestore data structure is unchanged:
  ```
  users/{userId}/medicines/{medicineId}
  users/{userId}/doseRecords/{recordId}
  ```

---

## Common Issues

| Issue | Fix |
|-------|-----|
| "Resolving Packages" stuck for 10+ min | Check internet. Try **File → Packages → Reset Package Caches** |
| Build error: module not found | Wait for package resolution to finish completely before building |
| App crashes on launch | Make sure `GoogleService-Info.plist` is in the Xcode project (check it appears in the left sidebar) |
| "No team" signing error | Go to **Target → Signing & Capabilities → Team** → choose **None** (simulator doesn't need a team) |
| Firebase Auth errors in console | These are normal debug logs — they don't affect functionality |

---

## File Structure

```
MediMinderSwiftUI/
├── MediMinderSwiftUI.xcodeproj/    ← Open this in Xcode
└── MediMinderSwiftUI/
    ├── MediMinderSwiftUIApp.swift   ← App entry + Firebase.configure()
    ├── ContentView.swift            ← Auth gate + Tab bar
    ├── GoogleService-Info.plist     ← Firebase config (already included)
    ├── Assets.xcassets/             ← App icon + accent color
    ├── Models/
    │   ├── Medicine.swift           ← Medicine data model
    │   └── DoseRecord.swift         ← Dose record model
    ├── Services/
    │   ├── AuthService.swift        ← Firebase Auth wrapper
    │   └── FirestoreService.swift   ← All Firestore read/write
    └── Views/
        ├── Auth/
        │   ├── LoginView.swift
        │   └── SignupView.swift
        ├── Today/
        │   └── TodayView.swift
        ├── Medicines/
        │   ├── MedicinesView.swift
        │   └── AddMedicineView.swift
        └── Profile/
            └── ProfileView.swift
```

> **Why SwiftUI instead of Storyboard?**
> SwiftUI declares the entire UI in code — so when you clone the repo, the UI is already there. The old ObjC version required manually dragging 50+ components in Interface Builder. SwiftUI eliminates that completely.
