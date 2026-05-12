# Product Specification: MediMinder

## 1. App Overview

* **Name:** MediMinder
* **Purpose:** A beginner-friendly, educational application for adding medications and setting local notification reminders for dosages.
* **Target Audience:** Personal/Self-use (Single profile).
* **Platform:** Built with Flutter (Android/iOS).

## 2. Technical Stack

* **Frontend:** Flutter (Dart) with Material Design 3 enabled (`useMaterial3: true`).
* **State Management:** Native Flutter `setState` (StatefulWidgets) and passing callbacks/state down the widget tree.
* **Backend/Database:** Firebase Firestore for persistent medicine storage.
* **Authentication:** Firebase Authentication (Email/Password & Google Sign-In).
* **Local Storage/Hardware:** `flutter_local_notifications` for device-level alarms.

## 3. Core Features & User Flows

### A. Authentication

* Users must log in to access the app.
* **Methods Supported:** Standard Email/Password and Google Sign-In.

### B. Medicine Data Entry

* Users can add a new medication via a streamlined form.
* **Required Fields:**
* Name (Text)
* Type of Medicine (Text/Dropdown)
* Dosage (Text/Number)
* Amount/Inventory (Number - total pills/ml on hand)
* Form (Dropdown/Radio: Pill, Liquid, Injection)


* **Optional Fields:**
* Instructions (Text area - e.g., "Take with food")



### C. Scheduling & Recurrences

* Users define when the medication should be taken.
* **Recurrence Options:**
* Every X hours (e.g., Every 8 hours).
* Specific days of the week (allows selecting multiple, distinct times for the chosen days).



### D. Inventory & Edge Cases

* The app tracks the "Amount" of medicine left.
* Each time a dose is marked as taken, the Amount decrements.
* **Zero Inventory Lock:** If the Amount reaches `0`, the UI prevents the user from taking the dose until the inventory is updated/refilled.

### E. Reminders & Notifications

* **System:** Standard local device notifications.
* **Missed Doses:** If a notification is ignored, the medication status becomes "Overdue" on the dashboard.
* **Resolution:** The user must manually "Dismiss" or "Mark as Taken" to clear an overdue medication.
* **Out of Scope:** Snooze logic, custom tones, and auto-rescheduling after device reboot.

---

## 4. UI/UX Design System: Material 3 (Flutter Native)

The app will utilize Flutter's built-in Material You capabilities to create a modern, tactile, and visually rich experience without requiring extensive custom CSS-like styling.

### A. Global Theme Setup

* **Theme Initialization:** Leverage `ColorScheme.fromSeed` using a Purple/Violet seed color (`Color(0xFF6750A4)`).
* **Backgrounds:** Pure white (`Colors.white`) is prohibited. The app will use `colorScheme.surface` for the main background and `colorScheme.surfaceContainer` for elevated areas.
* **Typography:** Google Fonts (**Roboto**).
* Dashboard Titles: `textTheme.headlineMedium` (Medium, 500 weight).
* Standard Text: `textTheme.bodyLarge` or `bodyMedium` (Regular, 400 weight).



### B. Component Mapping

* **Primary Buttons:** `FilledButton` (Pill-shaped, uses Primary color, native tactile ripple).
* **Secondary Buttons:** `FilledButton.tonal()` (Uses secondaryContainer color for a softer appearance).
* **Floating Action Button (FAB):** `FloatingActionButton.large()` positioned at the bottom right. Defaults to a rounded squircle with native elevation on tap.
* **Medicine Cards:** `Card` widget with custom `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))`. Use `surfaceContainer` for the card color with `elevation: 0` or `1`. Generous internal padding (e.g., `EdgeInsets.all(20)`).
* **Input Fields:** `TextFormField` utilizing `InputDecoration(filled: true)`. This automatically creates the MD3 filled style: rounded top corners (12px), flat bottom, and an active primary-colored bottom border.

### C. Atmospheric & Interactive Enhancements

* **Organic Blurs:** Utilize a `Stack` on the main Dashboard. Place a `Container` with `BoxShape.circle` and a heavy `BoxShadow` (`blurRadius: 100`, primary color with 20% opacity) positioned partially off-screen to create atmospheric depth behind the UI.
* **Tactile Feedback:** Wrap Medicine Cards in an `InkWell` (with `borderRadius` matching the card's 24px) to ensure users receive satisfying ripple feedback when tapping to view details or dismiss an overdue dose.
* **Empty States:** If the database returns 0 medications, center an icon (e.g., `Icons.medication` sized at 80px, colored in `secondaryContainer`) with a friendly text prompt.

---

## 5. Main Navigation Structure

* **Architecture:** `Scaffold` with a `BottomNavigationBar`.
* **Tabs:**
1. **Today:** Shows upcoming, taken, and overdue medications.
2. **My Medicines:** A list view of all active prescriptions and remaining inventory.
3. **Profile:** Basic account info and Sign Out functionality.


## 6. Constraints

"Prioritize readability over brevity." (This prevents "clever" one-liners that are hard to decipher).

"Use explicit if/else blocks." (This prevents deeply nested and confusing ternary operators like condition ? a : b ? c : d).

"Strictly use async/await." (This prevents messy .then().catchError() chaining when fetching from Firebase).

"Avoid advanced Dart features." (Explicitly ban things like Mixins, complex Streams, or heavy functional programming like .reduce() if a simple for loop works just as well).

"Extract large widget trees." (Instruct the AI to break down massive UI blocks into smaller, clearly named helper widgets so the code doesn't become a "pyramid of doom").