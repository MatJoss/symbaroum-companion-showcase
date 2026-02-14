# 🎲 Symbaroum Companion

🇫🇷 *[Version française](README.md)*

> **Full-featured mobile campaign management app for the [Symbaroum](https://freeleaguepublishing.com/games/symbaroum/) tabletop RPG** — Interactive character sheets, real-time Firebase sync, and tools for Game Masters and Players.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase)](https://firebase.google.com/)
[![Platform](https://img.shields.io/badge/Platform-Android-green)]()
[![Play Store](https://img.shields.io/badge/Play%20Store-Closed%20testing-brightgreen?logo=googleplay)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚠️ Disclaimer & Intellectual Property

> **Symbaroum** is a tabletop RPG created by **Free League Publishing**. This application is an **unofficial fan-made project**, developed for personal and educational purposes. No proprietary game data (rule texts, illustrations, bestiary, etc.) is included in this repository.
>
> The app is currently in **closed testing on the Google Play Store**, in compliance with GDPR. Contact with the publisher is planned to discuss the project's future.

---

## 📱 Preview

<p align="center">
  <img src="screenshots/0_PlayStore.jpg" width="200" alt="Play Store"/>
  <img src="screenshots/1_Accueil.jpg" width="200" alt="Home screen"/>
  <img src="screenshots/2_ChoixRole.jpg" width="200" alt="Role selection"/>
</p>

### 🎩 Game Master View

<p align="center">
  <img src="screenshots/3_MJ_Campagnes.jpg" width="200" alt="Campaigns (GM)"/>
  <img src="screenshots/4_MJ_ListePerso.jpg" width="200" alt="Character list (GM)"/>
  <img src="screenshots/5_MJ_PersoCarac.jpg" width="200" alt="Attributes (GM)"/>
  <img src="screenshots/6_MJ_PersoInventaire.jpg" width="200" alt="Inventory (GM)"/>
  <img src="screenshots/7_MJ_PersoComp.jpg" width="200" alt="Abilities (GM)"/>
</p>

### 🗡️ Player View

<p align="center">
  <img src="screenshots/8_PJ_Campagnes.jpg" width="200" alt="Campaigns (Player)"/>
  <img src="screenshots/9_PJ_ListePerso.jpg" width="200" alt="Character list (Player)"/>
  <img src="screenshots/10_PJ_PersoCarac.jpg" width="200" alt="Attributes (Player)"/>
  <img src="screenshots/11_PJ_PersoComp.jpg" width="200" alt="Abilities (Player)"/>
</p>

---

## 🎯 Project Overview

**Symbaroum Companion** is a mobile app that enables Symbaroum tabletop RPG groups to digitally and collaboratively manage their campaigns, replacing paper character sheets with an interactive, real-time synchronized interface.

> **Note:** The app is currently entirely in French. English localization is planned.

### Two Roles

| 🎩 Game Master (GM) | 🗡️ Player (PC) |
|---|---|
| Creates and manages campaigns | Joins via QR code scan |
| Generates invitation QR codes | Interactive character sheet |
| Edits all characters in real time | Automatic synchronization |
| Deals damage, heals, awards XP | Inventory management |
| Oversees all characters | Browse talents & powers |

---

## 🏗️ Technical Architecture

### Tech Stack

```
┌──────────────────────────────────────────────────────────────┐
│                     SYMBAROUM COMPANION                      │
│                  Full Firebase Architecture                  │
└──────────────────────────────────────────────────────────────┘

┌───────────────────────┐          ┌───────────────────────────┐
│   FLUTTER APP (Client)│          │   FIREBASE (Backend)      │
│   ────────────────────│          │   ──────────────────────  │
│                       │          │                           │
│  • Riverpod (State)   │◄────────►│  • Firestore (NoSQL DB)   │
│  • Freezed (Models)   │  Realtime│  • Firebase Auth          │
│  • Material Design 3  │  Streams │  • Firebase Storage       │
│  • Responsive UI      │          │  • Cloud Functions        │
│  • QR Code Scanner    │          │  • App Check (Security)   │
│                       │          │                           │
└───────────────────────┘          └───────────────────────────┘
         │
         ▼
┌───────────────────────┐
│   Platforms           │
│   ─────────────       │
│  • Android (Play Store│
│    closed testing)    │
│  • Web (technically   │
│    ready, not deployed│
└───────────────────────┘
```

### Flutter Code Organization

```
flutter_app/lib/
├── config/                    # Firebase & App configuration
│   ├── app_config.dart        # URLs, constants, logging
│   ├── firebase_config.dart   # 🔒 Firebase keys (not included - see .example)
│   ├── firebase_initialization.dart
│   ├── routes.dart            # Named navigation
│   └── theme.dart             # Custom Material 3 theme
│
├── models/                    # Data models (Freezed + JSON)
│   ├── personnage.dart        # Full character model
│   ├── campagne.dart          # Campaign and its players
│   ├── talent.dart            # Talents (novice/adept/master)
│   ├── pouvoir.dart           # Mystical powers
│   ├── equipment.dart         # Weapons, armor, equipment
│   ├── inventaire.dart        # Inventory system
│   ├── caracteristiques.dart  # The 8 Symbaroum attributes
│   ├── trait.dart             # Character traits
│   ├── argent.dart            # Currency system (Thaler/Shilling/Orteg)
│   └── game_data.dart         # Game reference data
│
├── providers/                 # State Management (Riverpod)
│   ├── firebase_providers.dart # Real-time Firestore stream providers
│   └── providers.dart          # App-level providers
│
├── services/                  # Data access layer
│   ├── firestore_service.dart      # Generic Firestore CRUD
│   ├── firestore_adapter.dart      # Adapter pattern for Firestore
│   ├── firebase_auth_service.dart  # Authentication (Google, Email)
│   ├── firebase_storage_service.dart # Avatar uploads
│   ├── storage_service.dart        # Secure local storage
│   ├── notification_service.dart   # In-app notifications
│   └── permission_service.dart     # GM/Player role management
│
├── screens/                   # App screens
│   ├── firebase_login_screen.dart         # Login (Google / Email)
│   ├── role_selection_screen.dart          # GM or Player role selection
│   ├── welcome_screen.dart                # Welcome screen
│   │
│   ├── # --- GM Flow ---
│   ├── campagnes_list_screen.dart         # Campaign list
│   ├── create_campagne_screen.dart        # Campaign creation
│   ├── campagne_detail_screen.dart        # Campaign detail + players
│   ├── campagne_manage_screen.dart        # Advanced management
│   ├── qr_code_display_screen.dart        # Invitation QR code
│   ├── personnage_detail_screen.dart      # Character sheet (GM view)
│   │
│   ├── # --- Player Flow ---
│   ├── player_campagnes_screen.dart       # My campaigns (player)
│   ├── player_personnage_select_screen.dart # Character selection
│   ├── player_character_main_screen.dart  # Player main hub
│   ├── player_character_detail_screen.dart # My character sheet
│   ├── player_character_creation_screen.dart # Character creation
│   ├── qr_code_scan_screen.dart           # Invitation QR scanner
│   └── account_settings_screen.dart       # Account settings
│
├── widgets/                   # Reusable components
│   ├── combat_stats_widget.dart           # Computed combat stats
│   ├── capacite_selection_dialog.dart     # Talent/power selection
│   ├── description_dialog.dart            # Rich description display
│   ├── responsive_wrapper.dart            # Responsive design
│   └── background_setter.dart             # Symbaroum themed background
│
└── utils/                     # Utilities
    ├── combat_stats_calculator.dart       # Defense/protection/attack calculations
    ├── character_validator.dart            # Character validation
    └── avatar_utils.dart                  # Avatar handling
```

### Firebase Security

- **Firebase App Check** — Abuse protection (reCAPTCHA v3 / Play Integrity)
- **Firestore Security Rules** — Role-based access control (GM/Player) and ownership
- **Firebase Auth** — Google Sign-In + Email/Password
- **Cloud Functions** — Server-side sensitive operations (account deletion)
- **Storage Rules** — Avatar uploads restricted to authenticated users

---

## 🚀 Features

### ✅ Implemented

- [x] **Authentication** — Google Sign-In + Email/Password via Firebase Auth
- [x] **Campaign management** — Creation, editing, QR code invitations
- [x] **Full character sheets** — The 8 attributes, HP, corruption, XP
- [x] **Talents** — Novice/adept/master system with descriptions
- [x] **Mystical powers & Rituals** — Traditions, levels, descriptions
- [x] **Character traits** — Boons, burdens, racial traits
- [x] **Inventory** — Carried/stored item management
- [x] **Weapons & Armor** — With special qualities and automatic calculations
- [x] **Equipped item management** — Equipped items dynamically impact defense and protection stats
- [x] **Automatic calculations** — Defense, protection, attack, corruption threshold (recalculated in real time based on equipment)
- [x] **Real-time sync** — Firestore streams for instant updates
- [x] **Role system** — GM (full control) vs Player (own sheet only)
- [x] **GM actions** — Damage, healing, XP award in one click
- [x] **Avatars** — Upload and cropping with Firebase Storage
- [x] **Responsive** — Adapted for mobile and tablet
- [x] **Symbaroum theme** — Dark, atmospheric UI

### 🔄 In Progress

- [ ] Enhanced player interface (dedicated tabs)
- [ ] Combat: round and initiative management
- [ ] Shared campaign journal

### 📋 Roadmap

- [ ] **Real-time GM-Player chat** — *TODO: evaluate technology (Firestore subcollections? Firebase Realtime DB? Third-party solution?) for a responsive chat without breaking the existing architecture*
- [ ] **Advanced conditional bonuses/penalties** — *TODO: some bonuses depend on complex combinations (talent + talent level + equipped items). Database modeling challenge: hardcoding isn't clean, making them dynamic is a real architectural challenge*
- [ ] **Internationalization (i18n)** — *The app is currently entirely in French. English localization is planned*
- [ ] Marketplace: equipment buying/selling
- [ ] NPC / creature generator
- [ ] Character export/import (PDF / JSON)
- [ ] Offline mode with deferred sync
- [ ] Push notifications

---

## 💡 Project Journey

This project went through a **significant architectural evolution**:

### v1 — Python + Kivy + Flask + SQLite
Initial architecture with a Kivy desktop client, Flask REST + Socket.IO server, and SQLite database. Functional but limited in terms of mobile deployment and real-time capabilities.

### v2 — Flutter + Firebase (current architecture)
Full migration to Flutter for cross-platform support and Firebase for serverless backend. Major gains in real-time sync (Firestore streams), authentication (Firebase Auth), and deployability (Play Store + Web).

> The code in this repo reflects the **v2 (Flutter + Firebase)** architecture.

---

## 🛠️ Tech Stack

| Category | Technologies |
|---|---|
| **Frontend** | Flutter 3.x, Dart 3.10, Material Design 3 |
| **State Management** | Riverpod 3 + Riverpod Generator |
| **Models** | Freezed + JSON Serializable |
| **Backend** | Firebase (Firestore, Auth, Storage, Functions, App Check) |
| **Auth** | Google Sign-In, Email/Password |
| **CI/CD** | Google Play Console (Android) |
| **QR Codes** | qr_flutter (generation) + mobile_scanner (scanning) |
| **Media** | image_picker + image_cropper |
| **Former stack (v1)** | Python, Flask, Socket.IO, SQLAlchemy, SQLite, Kivy |

---

## 📦 Repository Structure

```
symbaroum-companion-showcase/
├── flutter_app/           # 📱 Flutter application (main source code)
│   ├── lib/               # Dart code
│   ├── android/           # Android configuration
│   ├── assets/            # Images and visual resources
│   └── pubspec.yaml       # Flutter dependencies
│
├── functions/             # ☁️ Firebase Cloud Functions (Node.js)
│   └── index.js           # Secure account deletion
│
├── screenshots/           # 📸 Application screenshots
│
├── firebase.json          # Firebase configuration
└── storage.rules          # Storage security rules
```

> **Note:** Firebase configuration files (API keys, `google-services.json`) are not included in this repository for security reasons. `.example` files are provided for easy setup. Proprietary game data (rule texts, bestiary, etc.) belonging to Free League Publishing is not included.

---

## 🔧 Setup (for developers)

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x+
- [Firebase CLI](https://firebase.google.com/docs/cli)
- A configured Firebase project
- Android Studio or VS Code

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/MatJoss/symbaroum-companion-showcase.git
   cd symbaroum-companion-showcase
   ```

2. **Configure Firebase**
   ```bash
   # Copy the example configuration files
   cp flutter_app/lib/config/firebase_config.dart.example flutter_app/lib/config/firebase_config.dart
   cp flutter_app/android/app/google-services.json.example flutter_app/android/app/google-services.json
   ```
   Then replace the `YOUR_*` values with your actual Firebase keys in the copied files.

3. **Install dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

4. **Generate code (Freezed, Riverpod, JSON)**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔍 Notable Technical Aspects

- Flutter/Dart application deployed on Android (Play Store, closed testing), with Web capability
- State management via Riverpod, models generated with Freezed + JSON Serializable
- Full Firebase backend: Firestore (real-time), Auth (Google + Email), Storage, Cloud Functions, App Check
- GM/Player role system with ownership-based Firestore security rules
- Nested data modeling (character → inventory → equipment → qualities)
- Dynamic combat stat calculations based on equipped items
- Full migration from a v1 Python/Kivy/Flask/SQLite stack

---

## 📜 License

The source code of this project is licensed under the [MIT License](LICENSE).

> **Important:** This license covers only the application's source code. The Symbaroum tabletop RPG, its rules, illustrations, and universe are the property of **Free League Publishing AB**. This project is not affiliated with Free League Publishing.

---

## 📬 Contact

**MatJoss** — [GitHub](https://github.com/MatJoss)

*Fan-made project developed with passion for the Symbaroum community* 🎲🌲
