# MediMinder Xcode Setup Guide
## Mac Lab — Complete Step-by-Step Instructions

> **Estimated time: ~2.5–3 hours total**
> Code is already written. You just need to: create the Xcode project, build the UI in Interface Builder, wire outlets, and install dependencies.

---

## PHASE 1 — Project Setup (15 min)

### Step 1: Get the code onto the Mac
```bash
git clone https://github.com/YOUR_REPO/mediminder_pillreminder.git
# OR copy via USB — the folder you want is:
# mediminder_pillreminder/MediMinderObjC/
```

### Step 2: Open Xcode → Create New Project
1. **File → New → Project**
2. Choose **iOS → App**
3. Fill in:
   - **Product Name:** `MediMinder`
   - **Team:** None (for simulator)
   - **Organization ID:** `com.student.mediminder`
   - **Interface:** **Storyboard** ← IMPORTANT
   - **Language:** **Objective-C** ← IMPORTANT
   - **Uncheck** "Include Tests"
4. Save it **inside** the `MediMinderObjC/` folder

### Step 3: Delete the auto-generated ViewController files
Xcode creates a `ViewController.h` and `ViewController.m`. **Delete them** (move to trash).

### Step 4: Add all the .h and .m files from this repo
Drag ALL files from `MediMinderObjC/MediMinder/` into your Xcode project:
- `main.m`
- `AppDelegate.h` / `AppDelegate.m`
- `Medicine.h` / `Medicine.m`
- `DoseRecord.h` / `DoseRecord.m`
- `FirestoreService.h` / `FirestoreService.m`
- `LoginViewController.h` / `LoginViewController.m`
- `SignupViewController.h` / `SignupViewController.m`
- `MainTabBarController.h` / `MainTabBarController.m`
- `TodayViewController.h` / `TodayViewController.m`
- `MedicinesViewController.h` / `MedicinesViewController.m`
- `AddMedicineViewController.h` / `AddMedicineViewController.m`
- `ProfileViewController.h` / `ProfileViewController.m`

When the dialog appears, check **"Copy items if needed"**.

### Step 5: Add GoogleService-Info.plist
1. Go to **Firebase Console → Project Settings → Your iOS App**
2. Download `GoogleService-Info.plist`
3. Drag it into your Xcode project root (same level as `AppDelegate.m`)
4. Check **"Copy items if needed"**

---

## PHASE 2 — Install Firebase via CocoaPods (10 min)

### Step 6: Run CocoaPods
Open Terminal, navigate to `MediMinderObjC/`:
```bash
cd path/to/mediminder_pillreminder/MediMinderObjC
pod install
```
If CocoaPods isn't installed:
```bash
sudo gem install cocoapods
pod install
```

### Step 7: Open the .xcworkspace (NOT .xcodeproj)
After pod install, Xcode creates a `.xcworkspace` file.
**Always open `MediMinder.xcworkspace`** from now on, not `.xcodeproj`.

---

## PHASE 3 — Build the Storyboard UI (1.5–2 hours)
> This is the part you do by hand in Interface Builder.

Open `Main.storyboard`. Delete the default empty view controller.

---

### 🔲 SCENE 1: LoginViewController

**Drag a View Controller** onto the canvas.
- Set **Storyboard ID:** `LoginViewController`
- Set **Custom Class:** `LoginViewController`
- Check **"Is Initial View Controller"** in Attributes Inspector

**Add these UI components:**
| Component | Type | Config |
|---|---|---|
| `emailTextField` | UITextField | Placeholder: "Email", Keyboard: Email Address |
| `passwordTextField` | UITextField | Placeholder: "Password", Secure Text Entry: ✓ |
| `signInButton` | UIButton | Title: "Sign In", Background: blue |
| `signUpButton` | UIButton | Title: "Don't have an account? Sign Up" |
| `activityIndicator` | UIActivityIndicatorView | Style: Medium, Hides When Stopped: ✓ |
| `errorLabel` | UILabel | Text: (empty), Text Color: red, Hidden: ✓ |

**Wire Outlets:** Ctrl+drag from each component → LoginViewController
**Wire Actions:**
- `signInButton` → `signInTapped:` (Touch Up Inside)
- `signUpButton` → `signUpTapped:` (Touch Up Inside)

**Add Segue to SignupViewController:**
- Ctrl+drag from `signUpButton` to the SignupViewController scene
- Choose **Show** segue
- Set segue **Identifier:** `ShowSignup`

---

### 🔲 SCENE 2: SignupViewController

**Drag a View Controller** onto the canvas.
- Set **Storyboard ID:** `SignupViewController`
- Set **Custom Class:** `SignupViewController`

**Add these UI components:**
| Component | Type | Config |
|---|---|---|
| `emailTextField` | UITextField | Placeholder: "Email", Keyboard: Email Address |
| `passwordTextField` | UITextField | Placeholder: "Password", Secure Text Entry: ✓ |
| `confirmTextField` | UITextField | Placeholder: "Confirm Password", Secure Text Entry: ✓ |
| `createAccountButton` | UIButton | Title: "Create Account" |
| `activityIndicator` | UIActivityIndicatorView | Hides When Stopped: ✓ |
| `errorLabel` | UILabel | Hidden: ✓, Text Color: red |

**Wire Outlets & Action:**
- Wire all 6 outlets to `SignupViewController`
- `createAccountButton` → `createAccountTapped:` (Touch Up Inside)

---

### 🔲 SCENE 3: MainTabBarController

**Drag a Tab Bar Controller** onto the canvas.
- Set **Storyboard ID:** `MainTabBarController`
- Set **Custom Class:** `MainTabBarController`
- Delete the 2 default View Controllers it creates (you'll add your own)

**Add 3 Navigation Controllers** (drag from Object Library):
Each one becomes a tab. Ctrl+drag from Tab Bar Controller → each Nav Controller, choose **Relationship Segue → view controllers**.

For each Navigation Controller, set its root view controller:
- Ctrl+drag from Nav Controller → View Controller, choose **Relationship Segue → root view controller**

| Tab | Nav Controller Root | Tab Bar Item Title | System Image |
|---|---|---|---|
| Tab 0 | TodayViewController | Today | clock.fill |
| Tab 1 | MedicinesViewController | Medicines | pills.fill |
| Tab 2 | ProfileViewController | Profile | person.fill |

---

### 🔲 SCENE 4: TodayViewController

The root view controller of Tab 0's Navigation Controller.
- Set **Custom Class:** `TodayViewController`

**Add these UI components:**
| Component | Type | Config |
|---|---|---|
| `tableView` | UITableView | Style: Plain, fills the view |
| `emptyStateView` | UIView | Centered, Hidden by default |
| `emptyLabel` | UILabel | Inside emptyStateView, text: "No doses scheduled for today." |
| `activityIndicator` | UIActivityIndicatorView | Hides When Stopped: ✓ |

**Add Prototype Cell to tableView:**
- Select `tableView` → Attributes Inspector → **Prototype Cells: 1**
- Select the prototype cell → set **Style: Subtitle**, **Identifier: `DoseCell`**

**Wire Outlets** to `TodayViewController`

---

### 🔲 SCENE 5: MedicinesViewController

The root view controller of Tab 1's Navigation Controller.
- Set **Custom Class:** `MedicinesViewController`

**Add these UI components:**
| Component | Type | Config |
|---|---|---|
| `tableView` | UITableView | Style: Plain, fills the view |
| `emptyStateView` | UIView | Centered, Hidden by default; add a UILabel inside: "No medicines yet. Tap + to add one." |
| `activityIndicator` | UIActivityIndicatorView | Hides When Stopped: ✓ |
| `addButton` | UIBarButtonItem | In the Navigation Item, set System Item: Add |

**Add Prototype Cell to tableView:**
- Prototype Cells: 1
- Style: **Subtitle**
- Identifier: `MedicineCell`
- Accessory: Disclosure Indicator

**Wire Outlets & Action:**
- Wire `tableView`, `emptyStateView`, `activityIndicator`
- Ctrl+drag `addButton` → `addMedicineTapped:` (Action)

---

### 🔲 SCENE 6: AddMedicineViewController

This is presented modally (NOT part of the tab bar).
- **Drag a View Controller** onto the canvas
- Set **Storyboard ID:** `AddMedicineViewController`
- Set **Custom Class:** `AddMedicineViewController`
- Embed in Navigation Controller (Editor → Embed In → Navigation Controller) — but **do NOT connect it** to the tab bar

**Add these UI components (in a UIScrollView):**

> TIP: Use a UIScrollView as the root, with a content UIView inside it. Place everything inside the content view.

| Component | Type | Config |
|---|---|---|
| `nameTextField` | UITextField | Placeholder: "Medicine Name *" |
| `dosageTextField` | UITextField | Placeholder: "e.g. 500mg" |
| `amountTextField` | UITextField | Placeholder: "e.g. 30", Keyboard: Number Pad |
| `instructionsTextView` | UITextView | Placeholder hint via text color |
| `typePickerView` | UIPickerView | Shows medicine types |
| `formSegmentedControl` | UISegmentedControl | Segments: Pill \| Liquid \| Injection |
| `scheduleSegmentControl` | UISegmentedControl | Segments: Every X Hours \| Days of Week |
| `intervalPanel` | UIView | Contains slider + label + time button |
| `intervalSlider` | UISlider | min: 1, max: 24 (inside intervalPanel) |
| `intervalLabel` | UILabel | "Every 8 hours" (inside intervalPanel) |
| `startTimeButton` | UIButton | "08:00" (inside intervalPanel) |
| `weeklyPanel` | UIView | Hidden by default; contains day buttons + timesStackView |
| `weekdayStackView` | UIStackView | Horizontal, 7 UIButtons: Mon(tag=0)..Sun(tag=6) |
| `addTimeButton` | UIButton | "+ Add Time" (inside weeklyPanel) |
| `timesStackView` | UIStackView | Vertical (inside weeklyPanel) |
| `saveButton` | UIButton | "Save Medicine" |
| `activityIndicator` | UIActivityIndicatorView | Hides When Stopped: ✓ |

**Wire ALL Outlets to AddMedicineViewController**

**Wire Actions:**
| Button/Control | Action |
|---|---|
| `scheduleSegmentControl` → Value Changed | `scheduleSegmentChanged:` |
| `intervalSlider` → Value Changed | `intervalSliderChanged:` |
| `startTimeButton` → Touch Up Inside | `startTimeButtonTapped:` |
| `addTimeButton` → Touch Up Inside | `addTimeTapped:` |
| Each weekday button (Mon–Sun) → Touch Up Inside | `weekdayButtonTapped:` |
| `saveButton` → Touch Up Inside | `saveTapped:` |
| Nav bar Cancel button → Touch Up Inside | `cancelTapped:` |

**IMPORTANT for weekday buttons:**
Set each UIButton's **Tag** in the Attributes Inspector:
Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6

---

### 🔲 SCENE 7: ProfileViewController

The root view controller of Tab 2's Navigation Controller.
- Set **Custom Class:** `ProfileViewController`

**Add these UI components:**
| Component | Type | Config |
|---|---|---|
| `avatarLabel` | UILabel | Width=80, Height=80, Center aligned, font size 36, background color: system blue, corner radius: 40 (set in .m) |
| `displayNameLabel` | UILabel | Font: Bold, size 20 |
| `emailLabel` | UILabel | Shows email, smaller font |
| `accountIdLabel` | UILabel | Shows truncated UID |
| `signOutButton` | UIButton | Title: "Sign Out", background: red or destructive tint |
| `activityIndicator` | UIActivityIndicatorView | Hides When Stopped: ✓ |

**Wire Outlets & Action:**
- Wire all 6 outlets
- `signOutButton` → `signOutTapped:` (Touch Up Inside)

---

## PHASE 4 — Final Steps (10 min)

### Step 8: Set bundle identifier
In Xcode → Target → General → Bundle Identifier:
```
com.student.mediminder
```
This must match what you used in Firebase Console when adding the iOS app.

### Step 9: Check Info.plist has NSFaceIDUsageDescription (if needed)
Firebase Auth may prompt for it. Add if build warns.

### Step 10: Build & Run
- Select the **iPhone Simulator** (e.g., iPhone 15)
- Press **⌘R** to build and run
- If errors: check all outlets are connected (no dangling IBOutlets)

---

## Common Errors & Fixes

| Error | Fix |
|---|---|
| `Unrecognized selector sent to instance` | An IBAction is connected in storyboard but spelled wrong. Disconnect & reconnect. |
| `Thread 1: EXC_BAD_ACCESS` | An IBOutlet is declared but not connected in IB. Check all outlets. |
| `Could not instantiate class named ...` | Custom class not set in Identity Inspector for that scene. |
| `Firebase: No GoogleService-Info.plist found` | Make sure the file is added to the Xcode target (check the file inspector). |
| `pod: command not found` | Run `sudo gem install cocoapods` first. |
| Build fails with Firebase headers not found | Open `.xcworkspace` not `.xcodeproj` |

---

## File Summary

```
MediMinderObjC/
├── Podfile                          ← Run `pod install` here
└── MediMinder/
    ├── main.m                       ← App entry point
    ├── AppDelegate.h/.m             ← Firebase init + initial screen routing
    ├── Medicine.h/.m                ← Medicine data model
    ├── DoseRecord.h/.m              ← Dose record data model
    ├── FirestoreService.h/.m        ← All Firestore reads & writes
    ├── LoginViewController.h/.m     ← Login screen
    ├── SignupViewController.h/.m    ← Sign up screen
    ├── MainTabBarController.h/.m    ← Tab bar (Today / Medicines / Profile)
    ├── TodayViewController.h/.m     ← Today's dose list
    ├── MedicinesViewController.h/.m ← Medicine list
    ├── AddMedicineViewController.h/.m ← Add / Edit medicine form
    └── ProfileViewController.h/.m  ← User profile + sign out
```

> [!NOTE]
> You do NOT write the storyboard as code. Interface Builder generates the XML automatically as you drag components. Your only job is to drag, set identifiers, and wire connections.
