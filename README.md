
---

# 🛡️ Guardian Network

**Your Community. Your Safety. In Real-Time.**

Guardian Network is a **community-driven safety application** built with Flutter. It provides real-time crime awareness, reporting, and prevention tools through crowdsourced data, AI-powered insights, and interactive mapping.

---

## 🚀 Features

* 🔥 **Crime Heatmap** – Dynamic visualization of crime density with time filters.
* 📢 **Live Crime Reporting (Flash Alert)** – One-tap SOS with auto video/audio recording + GPS capture.
* 📹 **Video Incident Reporting** – Record and submit video evidence with crime details.
* 💬 **Community Discussion System** – Comment, upvote/downvote, and discuss incidents.
* 📍 **Proximity Alerts** – Smart notifications for nearby risks with adjustable radius.
* 📰 **Community Watch Feed** – Real-time reports, corroborated by the community.
* 👥 **User Profiles & Reputation** – Verified users and contribution scoring.
* ✨ **Innovations** – AI-based crime prediction, safe route navigation, AR alerts, gamified engagement.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase or Node.js + Express + MongoDB
* **Mapping:** Google Maps SDK / Mapbox
* **AI/ML:** TensorFlow Lite, AWS SageMaker
* **Media Processing:** Camera, Video Recording, Image Processing

---

## 📦 Updated Project Structure

```
lib/
├── main.dart                    # App entry point & root widget
├── models/                      # Data models & state management
│   ├── crime_incident.dart      # Crime incident data model
│   ├── crime_data_provider.dart # State management for crime data
│   ├── incident_comment.dart    # Comment/discussion system model
│   └── app_user.dart            # User profile and reputation system
├── screens/                     # App screens/pages
│   ├── main_screen.dart         # Navigation container
│   ├── map_screen.dart          # Interactive map + SOS + Camera
│   ├── alerts_screen.dart       # Proximity alerts
│   ├── reports_screen.dart      # Community reports list
│   ├── community_screen.dart    # Community discussions & incidents (NEW)
│   ├── incident_detail_screen.dart # Incident discussion thread (NEW)
│   ├── video_report_screen.dart # Video recording & submission (NEW)
│   └── profile_screen.dart      # User profile & settings
├── components/                  # Reusable UI components
│   ├── custom_navigation_bar.dart
│   ├── crime_marker.dart
│   ├── report_incident_sheet.dart
│   ├── sos_button.dart
│   ├── incident_card.dart       # Incident listing card (NEW)
│   ├── comment_card.dart        # Comment display card (NEW)
│   └── comment_input.dart       # Comment input field (NEW)
├── services/                    # External integrations
│   └── location_service.dart    # Geolocation wrapper
└── theme/                       # App styling
    └── app_theme.dart
```

---

## 📖 File Responsibilities

* **main.dart** → Root widget, theme setup, Provider initialization.
* **crime_incident.dart** → Defines data model & enums (severity, filters).
* **crime_data_provider.dart** → State management, incident filtering, nearby threat calc, comment system.
* **incident_comment.dart** → Comment model with voting system and user engagement.
* **app_user.dart** → User profiles, verification status, and contribution scoring.
* **map_screen.dart** → Map rendering, markers, location tracking, SOS, Camera button.
* **alerts_screen.dart** → Proximity alerts & notifications.
* **reports_screen.dart** → Chronological list of incidents w/ severity coloring.
* **community_screen.dart** → Community tab with incidents and discussions.
* **incident_detail_screen.dart** → Full incident view with comment thread.
* **video_report_screen.dart** → Video recording and incident submission interface.
* **profile_screen.dart** → User info & settings.
* **custom_navigation_bar.dart** → Bottom navigation (updated with Community tab).
* **crime_marker.dart** → Incident markers with severity-based styling.
* **report_incident_sheet.dart** → Bottom sheet for submitting new reports.
* **sos_button.dart** → Emergency floating action button.
* **incident_card.dart** → Card widget for displaying incidents in lists.
* **comment_card.dart** → Card widget for displaying comments with voting.
* **comment_input.dart** → Input field for adding new comments.
* **location_service.dart** → Permission + geolocation provider.
* **app_theme.dart** → Light/dark theme config, Material 3 colors.

---

## 🔄 Enhanced Data Flow

1. **User Interaction** → Components → Screens
2. **Screens** → `CrimeDataProvider` (state change)
3. **Provider** → `notifyListeners()` → UI updates
4. **LocationService** → Feeds geolocation into MapScreen
5. **Camera Service** → Video recording and media capture
6. **Comment System** → User engagement and discussion threads
7. **Theme** → Applied globally across widgets

---

## 🆕 New Features Added

### 🎥 Video Reporting System
- Camera button positioned above SOS button on map screen
- Video recording interface with 30-60 second capture
- Crime type selection and description input
- GPS location attachment to video reports

### 💬 Community Discussion System
- New "Community" tab in navigation
- Two sub-tabs: Incidents and Discussions
- Commenting system with upvote/downvote functionality
- User reputation and verification system
- Real-time discussion threads for each incident

### 👤 User Engagement Features
- User profiles with contribution scores
- Verification system for trusted community members
- Gamified engagement through voting and commenting
- Anonymous user support for privacy

---

## 🗺️ External Dependencies

* [`flutter_map`](https://pub.dev/packages/flutter_map) – Interactive maps
* [`latlong2`](https://pub.dev/packages/latlong2) – Coordinate utilities
* [`geolocator`](https://pub.dev/packages/geolocator) – Location services
* [`provider`](https://pub.dev/packages/provider) – State management
* [`camera`](https://pub.dev/packages/camera) – Video recording capabilities
* [`video_player`](https://pub.dev/packages/video_player) – Video playback

---

## ▶️ Getting Started

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* Android Studio or VS Code
* Google Maps API Key (enable Maps, Places, Geocoding, Directions APIs)
* Camera permissions (for video reporting)

### Installation

```bash
git clone https://github.com/your-username/guardian_network.git
cd guardian_network
flutter pub get
flutter run
```

### Camera Setup (Android)

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Camera Setup (iOS)

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record video reports</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio with video</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save video reports</string>
```

---

## ⚖️ Challenges & Mitigation

* **False reports** → Community corroboration, voting system, and moderation
* **Privacy** → Encrypted storage, clear policies, and anonymous posting options
* **Battery/data usage** → Optimized background services and video compression
* **Content moderation** → Community voting and automated AI filtering
* **Video storage** → Cloud storage optimization and compression algorithms

---

## 🎯 Hackathon Demo Features

1. **Interactive Map** with live incident reporting
2. **SOS Emergency Button** with automatic recording
3. **Video Reporting** with camera integration
4. **Community Discussion System** with voting
5. **User Reputation System** with verification
6. **Real-time Notifications** for nearby incidents
7. **Time-based Filtering** of incident data

---

## 📜 License

This project is licensed under the **MIT License**.

---

## 🔮 Future Enhancements

* AI-powered crime prediction algorithms
* Safe route navigation with risk avoidance
* Augmented Reality alerts and directions
* Integration with local law enforcement APIs
* Multi-language support for diverse communities
* Offline functionality for areas with poor connectivity

---
