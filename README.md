# AlertGuard — Mobile App

> Flutter mobile application for the AlertGuard emergency safety system.
> Available for Android and iOS.

---

## Overview

AlertGuard lets users send instant SOS alerts — with GPS location and
camera photos — to verified emergency contacts via Telegram.
Three hardware triggers work even when the app is in the background.

**Backend API:** `https://alertguard-api.onrender.com`  
**Backend Repository:** [alertguard-backend](https://github.com/YOUR_USERNAME/alertguard-backend)

---

## Tech Stack

| Layer            | Technology                    |
|------------------|-------------------------------|
| Framework        | Flutter 3.x                   |
| Language         | Dart                          |
| State Management | Riverpod 2.x                  |
| Navigation       | GoRouter                      |
| HTTP Client      | Dio (with JWT interceptor)    |
| Local Storage    | flutter_secure_storage        |
| Local Database   | SQLite (sqflite)              |
| GPS              | geolocator                    |
| Camera           | camera                        |
| Sensors          | sensors_plus                  |
| Notifications    | flutter_local_notifications   |
| Background       | flutter_background_service    |

---

## Features

### SOS Triggers
Three independent trigger methods — each can be enabled or disabled:

| Trigger | How It Works |
|---------|-------------|
| Volume Button | Triple press within 2 seconds |
| Shake | Shake phone firmly twice |
| Manual | Tap the SOS button in the app |

All triggers work when the app is in the background via a
foreground service with a persistent notification.

### Alert Flow
```
Trigger detected
    │
    ├── GPS coordinates captured
    ├── Front camera photo taken
    ├── Rear camera photo taken  (parallel with GPS)
    │
    ├── Internet available?
    │     ├── Yes → POST to backend immediately
    │     └── No  → Save to local SQLite queue
    │
    ├── Countdown (5 seconds) — can cancel
    │     └── Silent Mode → skip countdown, vibrate only
    │
    └── Alert sent → Telegram message to all verified contacts
```

### Offline Support
- Alerts stored locally when internet unavailable
- Automatic retry when connectivity restored
- Idempotency key prevents duplicate sends on retry

### Emergency Contacts
- Add up to 3 trusted contacts
- Share invite link (WhatsApp, SMS, any app)
- Contact verifies via Telegram bot
- Verification status shown in real time

### Test Mode
- Full SOS drill without notifying real contacts
- Requires user's own Telegram to be connected first
- Uses same invite-link verification flow as contacts

### Alert History
- Full list of past alerts
- Trigger type, timestamp, status per alert
- Google Maps link for location
- Front and rear photo thumbnails

### Settings
- Per-trigger enable/disable
- Silent mode toggle
- Test mode toggle (disabled until Telegram connected)
- Connect own Telegram for test mode

### Onboarding
- 6-slide onboarding on first launch
- Setup checklist as draggable bottom sheet
- Checklist disappears when all steps complete

---

## Architecture
```
lib/
├── core/
│   ├── network/
│   │   └── dio_client.dart          HTTP + JWT interceptor + auto-refresh
│   ├── storage/
│   │   └── secure_storage.dart      JWT token storage (Keychain / Keystore)
│   ├── router/
│   │   └── app_router.dart          GoRouter with auth + onboarding guard
│   ├── database/
│   │   └── local_database.dart      SQLite setup + migrations
│   └── services/
│       ├── trigger_service.dart     Volume + shake + manual detection
│       ├── alert_service.dart       Alert capture + send + queue
│       ├── location_service.dart    GPS with permission handling
│       ├── camera_service.dart      Dual camera capture
│       ├── connectivity_service.dart Real internet check
│       ├── queue_service.dart       SQLite offline queue
│       ├── queue_monitor.dart       Auto-retry on connectivity restore
│       ├── background_service.dart  Foreground service (Android)
│       └── permission_service.dart  Upfront permission requests
│
└── features/
    ├── auth/                        Login + Register screens
    ├── home/                        SOS tab + navigation
    ├── contacts/                    Contact management + invite links
    ├── history/                     Alert history + detail view
    ├── settings/                    All user preferences
    ├── profile/                     User profile data
    └── onboarding/                  First launch slides + checklist
```

---

## Setup

### Prerequisites
- Flutter 3.x
- Android Studio or Xcode
- A running AlertGuard backend (or use the live API)

### Installation
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/alertguard-mobile.git
cd alertguard-mobile

# Install dependencies
flutter pub get
```

### Configuration

By default the app connects to the production backend:
```
https://alertguard-api.onrender.com/api/v1
```

For local development:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/v1
```

### Run
```bash
# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

---

## Permissions

### Android
```xml
INTERNET
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
ACCESS_BACKGROUND_LOCATION
CAMERA
VIBRATE
FOREGROUND_SERVICE
RECEIVE_BOOT_COMPLETED
```

### iOS
```
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
NSCameraUsageDescription
```

---

## Key Technical Decisions

**Why Riverpod over BLoC or Provider?**
Riverpod's compile-time safety, `AsyncNotifier` pattern, and `ref.invalidate`
for cache busting made it the cleanest fit for this app's state patterns.

**Why SQLite for offline queue instead of SharedPreferences?**
Multiple queued alerts need structured storage with insert, query, update,
and delete operations. SharedPreferences is key-value only.

**Why two Dio instances?**
Alert uploads to Cloudinary take up to 30 seconds. Using a 60-second timeout
only on the alert endpoint prevents masking real hangs on auth and contact
endpoints which should respond in under 2 seconds.

**Why IndexedStack for navigation?**
The SOS trigger service must keep running when the user switches tabs.
IndexedStack keeps all tabs alive in memory. PageView disposes and recreates
tabs on switch which would kill the trigger listeners.

**Why capture GPS and photos before checking connectivity?**
GPS and camera take 1-3 seconds. If we checked connectivity first and
then captured, the network state could change during capture. Capturing
first guarantees data is ready whether we send immediately or queue.

---

## Sprint History

| Sprint | Feature |
|--------|---------|
| 1  | Django backend + JWT auth |
| 2  | Emergency contacts API |
| 3  | Alert API + Telegram dispatch |
| 3.5 | Telegram contact verification |
| 4  | Flutter setup + auth screens |
| 5  | Hardware triggers + background service |
| 5.5 | Contacts UI + invite link sharing |
| 6  | GPS + dual camera capture |
| 7  | Offline queue + auto retry |
| 8  | Alert history screen |
| 9  | Test mode + settings screen |
| 10 | Production deployment |
| 11 | README + portfolio polish |

---

## Known Limitations

| Limitation | Notes |
|------------|-------|
| Telegram only | SMS/WhatsApp planned for future |
| Background triggers on iOS | iOS background restrictions limit reliability |
| Cold start on free Render tier | First request after inactivity takes ~30s |

---
