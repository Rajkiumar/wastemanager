# WasteWise Connect

Community waste-management app with resident and truck-driver workflows, Firebase auth, live truck updates, reporting, collection schedules, and a gamified education hub.

## Core Features
- Dual login flows for residents and truck drivers (email/password, Google, password reset)
- Role-aware main shell with tabs for live truck tracker, collection schedule, issue reporting, and recycling education
- Firestore-backed truck status feed (drivers post updates, residents read in real time)
- Report form with photos (Firebase Storage) plus status timeline for the current user
- Calendar-based pickup schedule with notification opt-in stored per user
- Education hub with searchable sorting guide and Green Points gamification persisted in Firestore
- Push notifications scaffolded via FCM token registration and background handler

## Tech Stack
- Flutter (Material 3)
- Firebase: Auth, Firestore, Storage, Messaging
- Packages: google_sign_in, table_calendar, intl, image_picker, geolocator, google_maps_flutter (planned), fl_chart (analytics planned)

## Prerequisites
- Flutter SDK installed
- Firebase project with the following enabled: Email/Password auth, Google auth, Firestore, Storage, Cloud Messaging

## Setup
1) Install dependencies
```bash
flutter pub get
```
2) Configure Firebase (recommended: `firebase-tools` + `flutterfire`)
- Run `flutterfire configure` and select this app IDs/platforms, which will generate:
	- android/app/google-services.json
	- ios/Runner/GoogleService-Info.plist
	- macos/Runner/GoogleService-Info.plist (if building for macOS)
	- web/firebase-messaging-sw.js and web/index.html config for FCM (web)
- Ensure Android `applicationId` / iOS bundle IDs match your Firebase app registration.

3) Platform-specific steps
- Android: confirm `android/app/google-services.json` exists; Gradle plugins already included.
- iOS/macOS: add the plist files, then run `cd ios && pod install` (and similarly for macOS if used).
- Web: add your Firebase config snippet in `web/index.html` if not present; host `firebase-messaging-sw.js` for FCM.

4) Firestore/Storage rules (simple dev default)
```js
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		match /{document=**} { allow read, write: if request.auth != null; }
	}
}
service firebase.storage {
	match /b/{bucket}/o {
		match /{allPaths=**} { allow read, write: if request.auth != null; }
	}
}
```
Tighten for production (per-collection rules, validation, limits).

5) Run the app
```bash
flutter run
```

## Data Model Cheat Sheet
- `users/{uid}`: `greenPoints` (int), `notifications_enabled` (bool), `fcmToken`, `lastTokenUpdate`
- `trucks/{id}`: `neighborhood`, `status` (On Time/Early/Late), `eta`, `timestamp`
- `reports/{id}`: `issue`, `location`, `issueType`, `status` (Pending/In Progress/Resolved), `imageUrl`, `userId`, `userEmail`, `timestamp`

## Feature Notes
- Auth flows live in `lib/features/auth/login_screen.dart` (resident + driver login/register, Google sign-in, password reset)
- Main shell and tabs: tracker, schedule, report, education in `lib/main_shell.dart` and `lib/tabs/*`
- Notifications: token registration and listeners in `lib/services/notification_service.dart`; server-side sending is still needed
- Images: report photos uploaded to Firebase Storage and linked in Firestore
- Points: Education tab awards “Green Points” to the current user document via transactions

## Testing Pointers
- Create test users for both roles; verify email/password and Google sign-in
- Submit a report with and without images; confirm Firestore + Storage entries
- Post a truck update as driver; confirm it appears in the tracker list for residents
- Toggle notification preference in Schedule tab; ensure the flag updates in Firestore

## Implementation Roadmap

### Phase 1: User Profiles & Gamification (Features 6 + 3)
1. **User Profiles Service**
   - New Firestore collection: `userProfiles/{uid}` with stats, badges, preferences
   - Profile UI screen showing personal stats and achievements
   - Settings page for notification/theme preferences

2. **Community Leaderboard**
   - Leaderboard tab or bottom sheet with top users by Green Points
   - Weekly/monthly filters
   - User rank display on profile

### Phase 2: Advanced Analytics & Reports (Features 4 + 5)
3. **Dashboard Analytics**
   - Analytics tab with fl_chart visualizations
   - User stats: total points, reports submitted, items sorted
   - Community stats: most reported issues, collection trends
   - Date range filters

4. **Enhanced Reports**
   - Report filters (status, type, date range, user)
   - Comments section on reports (Firestore subcollection)
   - Admin approval workflow (status: Pending → Approved → In Progress → Resolved)
   - Evidence timeline with timestamps and photos

### Phase 3: Admin & Moderation (Feature 8)
5. **Admin Dashboard**
   - Admin role check on Firebase Custom Claims
   - Admin-only screen with:
     - User management (view, disable, promote to admin)
     - Report moderation queue
     - Driver performance metrics
     - System statistics

### Phase 4: UX/Accessibility & Advanced Features (Features 7 + 11)
6. **Advanced User Features**
   - Favorites: Save preferred pickup locations (Firestore: `userFavorites/{uid}`)
   - Calendar export: Add to device calendar (generate .ics files)
   - Dark mode theme toggle (persist in Firestore)
   - Multi-language support (i18n package + language selection)
   - Offline support: Cache reports and schedule data using sqflite

7. **Accessibility Improvements**
   - Text-to-speech for sorting guide items
   - Larger font size option
   - High contrast mode
   - Voice command basics (if time permits)
   - Better onboarding flow with skip option

### Phase 5: Backend Services (Feature 2)
8. **Cloud Functions for Notifications**
   - Schedule pickup reminders (9 PM night before collection)
   - "Truck nearby" alerts based on driver geolocation
   - Report status update notifications
   - Functions: `scheduleDayReminder`, `notifyTruckNearby`, `notifyReportStatus`

### Phase 6: Third-party Integrations (Feature 9)
9. **Integration Services**
   - Twilio SMS for backup alerts (optional phone number in profile)
   - Email summaries (monthly waste stats)
   - WhatsApp bot skeleton (ready for Twilio integration)

### Phase 7: AI/ML & Smart Features (Feature 10)
10. **ML Features**
    - Waste image classification: Integrate ML Kit or TensorFlow Lite
    - Smart suggestions for unrecognized items
    - Driver route optimization (basic: sort by neighborhood)
    - Predictive alerts (e.g., "Bin frequently full on Thursday")

### Phase 8: Location & Maps (Feature 1 - Final Touch)
11. **Real-time Location Tracking**
    - Driver geolocation tracking (background task)
    - Google Maps display with truck markers
    - ETA calculation based on distance
    - Resident proximity notifications
    - Truck history trail

---

## Implementation Priority & Effort Estimate

| Phase | Features | Est. Effort | Impact | Priority |
|-------|----------|-------------|--------|----------|
| 1 | User Profiles + Leaderboard | 1-2 weeks | High | **HIGH** |
| 2 | Analytics + Enhanced Reports | 2-3 weeks | High | **HIGH** |
| 3 | Admin Dashboard | 1-2 weeks | Medium | **MEDIUM** |
| 4 | UX/Accessibility | 1-2 weeks | Medium | **MEDIUM** |
| 5 | Cloud Functions | 1 week | High | **HIGH** |
| 6 | Integrations | 1 week | Low | LOW |
| 7 | AI/ML | 2-4 weeks | Medium | MEDIUM |
| 8 | Maps & Location | 1-2 weeks | High | **HIGH** |

---

## Suggested Start Order
1. **Start with Phase 1 (Profiles + Leaderboard)** - Foundation for gamification
2. **Then Phase 2 (Analytics + Reports)** - Heavy feature, good for engagement
3. **Phase 5 (Cloud Functions)** - Backend infrastructure for notifications
4. **Phase 4 (UX/Accessibility)** - Polish existing features
5. **Phase 3 (Admin)** - Moderation as app scales
6. **Phase 6 & 7 (Integrations & AI/ML)** - Nice-to-haves
7. **Phase 8 (Maps)** - Final polish

---

## New Packages Needed
```yaml
# Phase 4: Advanced features
sqflite: ^2.3.0          # Offline data caching
i18n_extension: ^7.0.0   # Multi-language support
flutter_local_notifications: ^16.0.0  # Scheduled notifications
uuid: ^4.0.0             # Unique IDs for favorites

# Phase 7: AI/ML
tflite_flutter: ^0.10.0  # TensorFlow Lite (optional)
google_mlkit_text_recognition: ^0.8.0  # Image recognition

# Phase 5: Cloud Functions
cloud_functions: ^5.0.0  # Direct function calls (optional)

# Phase 9: Integrations
twilio_flutter: ^0.0.8   # Twilio SMS
mailer: ^6.0.0           # Email sending
```
