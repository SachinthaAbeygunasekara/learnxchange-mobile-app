# LearnXchange - Peer-to-Peer Skill Sharing Platform

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square)
![Firebase](https://img.shields.io/badge/Firebase-Backend-039BE5?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-4caf50?style=flat-square)

> **Tech Stack:** Flutter (Frontend) • Firebase (Backend) • Dart (Language)

**LearnXchange** is a cross-platform mobile application developed using Flutter, designed to facilitate the exchange of skills between users without any monetary transactions. It acts as a peer-to-peer learning marketplace where users can register their teachable skills and discovery skills they wish to learn, creating a mutually beneficial knowledge exchange.

---

## 🚀 Key Features

### 🔍 Advanced Search & Discovery
- **Keyword Search**: Find users by name or specific skill sets.
- **Category Filtering**: Browse through popular domains like Coding, Design, Music, and Photography.
- **Rating Filters**: Filter potential partners based on community reputation.

### 🧠 Refined Matching Algorithm
- **Compatibility Scoring**: A weighted system that ranks users based on:
  - Mutual skill overlap (10x weight).
  - Shared categories (5x weight).
  - User reputation/rating bonus.
- **Perfect Matches**: Instantly find users who have exactly what you want and want exactly what you have.

### 📊 Learning Dashboard & Analytics
- **Live Statistics**: Real-time tracking of Completed Sessions, Upcoming Sessions, and Pending Requests.
- **Reputation Management**: Visualization of average ratings and total reviews received.
- **Skill Inventory**: Breakdown of skills offered vs. skills desired.

### 📅 Session & History Management
- **Categorized History**: Organize your learning journey into Upcoming, Completed, and Cancelled sessions.
- **Calendar Integration**: One-tap "Add to Calendar" functionality to sync scheduled sessions with native device calendars.
- **Searchable History**: Quickly find past exchanges using a dedicated history search.

### 🛡️ Admin Management Panel
- **Global Overview**: High-level visibility into all Users, Sessions, Requests, and Reviews.
- **User Moderation**: Ability to suspend or reactivate accounts to maintain community safety.
- **Audit Trails**: Monitor all exchange activities across the platform.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart) with Material Design 3.
- **Backend**: Firebase (Authentication, Firestore, Cloud Storage).
- **Authentication**: Firebase Email/Password, Forgot Password, and **Google Sign-In**.
- **Local Integration**: `add_2_calendar` for device synchronization.
- **State Management**: Stream-based reactive UI architecture.

---

## 📐 High-Level Architecture

LearnXchange follows a three-tier architecture:
- **Presentation Layer**: Flutter mobile app utilizing standard UI patterns.
- **Business Logic Layer**: Specialized Dart services (`UserService`, `MatchingService`, `SessionService`) for clean separation of concerns.
- **Data Layer**: Firebase Firestore (NoSQL) for real-time data persistence and Firebase Storage for media.

---

## ⚙️ Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/learnxchange.git
   cd learnxchange
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps and download `google-services.json` and `GoogleService-Info.plist`.
   - Place `google-services.json` in `android/app/`.
   - Place `GoogleService-Info.plist` in `ios/Runner/`.
   - Enable **Email/Password** and **Google** auth providers.
   - Create a Firestore Database and enable **Collection Group Index** for `reviews` (field: `timestamp`, scope: `Collection Group`).

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📌 Author
- **Sachintha Abeygunasekara** - *Initial Work & Final Project Development*

---

## 🎯 Conclusion
LearnXchange democratizes education by making knowledge free and accessible through community-driven barter. Built with scalability and security in mind, it serves as a robust demonstration of modern mobile application development practices.
