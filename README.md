# GameBoo - Flutter Mobile Game App

A comprehensive gamified mobile application featuring multiple mini-games, character system, and glassmorphism UI design.

## 🎮 Features

### Core Games

- **Card Shooter** - Shoot cards at moving targets with increasing difficulty
- **Ball Blaster** - Break bricks and targets with bouncing balls
- **Racing Rush** - 2D racing game with obstacles and time constraints
- **Puzzle Mania** - Classic logic puzzles including match-3 and tile swap
- **Drone Flight** - Control drone through obstacles and checkpoints

### Character System

- **5 Unique Characters** with special abilities:
  - **Nova** - Futuristic pilot (Default starter)
  - **Blitz** - Cool racer with fast reflexes (Unlock: Level 5)
  - **Zink** - Puzzle-solving robot (Unlock: 500 XP)
  - **Karma** - Mystical card master (Unlock: 5 badges)
  - **Rokk** - Powerful destroyer (Unlock: 10 wins)

### Gamification

- **XP & Level System** - Earn experience and level up
- **Badges & Achievements** - Bronze, Silver, Gold, and Diamond badges
- **Daily Challenges** - Complete challenges for bonus XP
- **Streak System** - Consecutive play bonuses
- **Global Leaderboards** - Compete with players worldwide

### UI/UX

- **Glassmorphism Theme** - Modern frosted glass design
- **Light/Dark Mode** - Automatic theme switching
- **Responsive Design** - Optimized for all screen sizes
- **Smooth Animations** - Staggered animations and transitions

## 🛠️ Technical Stack

- **Flutter** - Cross-platform mobile development
- **Firebase** - Backend services (Auth, Firestore, Analytics, Crashlytics)
- **BLoC/Cubit** - State management
- **Flame** - Game engine for mini-games
- **Clean Architecture** - Domain, Data, and Presentation layers

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase CLI
- Android Studio / VS Code

### Installation

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   ├── characters/
│   ├── games/
│   ├── home/
│   └── profile/
├── shared/
│   └── widgets/
└── main.dart
```

## 🎯 Key Features Implementation

### Glassmorphism UI

- Custom glass containers with backdrop blur
- Gradient backgrounds and borders
- Transparent navigation bars
- Frosted glass effects throughout the app

### Character System

- Unlockable characters with unique abilities
- Character progression and leveling
- Special abilities that affect gameplay

### Game Engine

- Flame-based game rendering
- Modular game architecture
- Score calculation and XP systems

### Gamification

- Comprehensive XP and leveling system
- Achievement and badge system
- Daily challenges with rewards

---

**GameX** - Where gaming meets innovation! 🎮✨
# gameboo
