
---

# 🛡️ Guardian Network

**Your Community. Your Safety. In Real-Time.**

Guardian Network is a **community-driven safety application** built with Flutter. It provides real-time crime awareness, reporting, and prevention tools through crowdsourced data, AI-powered insights, and interactive mapping.

---

## 🚀 Features

* 🔥 **Crime Heatmap** – Dynamic visualization of crime density with time filters.
* 📢 **Live Crime Reporting (Flash Alert)** – One-tap SOS with auto video/audio recording + GPS capture.
* 📍 **Proximity Alerts** – Smart notifications for nearby risks with adjustable radius.
* 📰 **Community Watch Feed** – Real-time reports, corroborated by the community.
* ✨ **Innovations** – AI-based crime prediction, safe route navigation, AR alerts, gamified engagement.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase or Node.js + Express + MongoDB
* **Mapping:** Google Maps SDK / Mapbox
* **AI/ML:** TensorFlow Lite, AWS SageMaker

---

## 📦 Project Structure

```
lib/
├── main.dart                    # App entry point & root widget
├── models/                      # Data models & state management
│   ├── crime_incident.dart      # Crime incident data model
│   └── crime_data_provider.dart # State management for crime data
├── screens/                     # App screens/pages
│   ├── main_screen.dart         # Navigation container
│   ├── map_screen.dart          # Interactive map + SOS
│   ├── alerts_screen.dart       # Proximity alerts
│   ├── reports_screen.dart      # Community reports list
│   └── profile_screen.dart      # User profile & settings
├── components/                  # Reusable UI components
│   ├── custom_navigation_bar.dart
│   ├── crime_marker.dart
│   ├── report_incident_sheet.dart
│   └── sos_button.dart
├── services/                    # External integrations
│   └── location_service.dart    # Geolocation wrapper
└── theme/                       # App styling
    └── app_theme.dart
```

---

## 📖 File Responsibilities

* **main.dart** → Root widget, theme setup, Provider initialization.
* **crime\_incident.dart** → Defines data model & enums (severity, filters).
* **crime\_data\_provider.dart** → State management, incident filtering, nearby threat calc.
* **map\_screen.dart** → Map rendering, markers, location tracking, SOS.
* **alerts\_screen.dart** → Proximity alerts & notifications (WIP).
* **reports\_screen.dart** → Chronological list of incidents w/ severity coloring.
* **profile\_screen.dart** → User info & settings (WIP).
* **custom\_navigation\_bar.dart** → Bottom navigation.
* **crime\_marker.dart** → Incident markers with severity-based styling.
* **report\_incident\_sheet.dart** → Bottom sheet for submitting new reports.
* **sos\_button.dart** → Emergency floating action button.
* **location\_service.dart** → Permission + geolocation provider.
* **app\_theme.dart** → Light/dark theme config, Material 3 colors.

---

## 🔄 Data Flow

1. **User Interaction** → Components → Screens
2. **Screens** → `CrimeDataProvider` (state change)
3. **Provider** → `notifyListeners()` → UI updates
4. **LocationService** → Feeds geolocation into MapScreen
5. **Theme** → Applied globally across widgets

---

## 🗺️ External Dependencies

* [`flutter_map`](https://pub.dev/packages/flutter_map) – Interactive maps
* [`latlong2`](https://pub.dev/packages/latlong2) – Coordinate utilities
* [`geolocator`](https://pub.dev/packages/geolocator) – Location services
* [`provider`](https://pub.dev/packages/provider) – State management

---

## ▶️ Getting Started

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* Android Studio or VS Code
* Google Maps API Key (enable Maps, Places, Geocoding, Directions APIs)

### Installation

```bash
git clone https://github.com/your-username/guardian_network.git
cd guardian_network
flutter pub get
flutter run
```

---

## ⚖️ Challenges & Mitigation

* **False reports** → Community corroboration & moderation
* **Privacy** → Encrypted storage & clear policies
* **Battery/data usage** → Optimized background services

---

## 📜 License

This project is licensed under the **MIT License**.

---
