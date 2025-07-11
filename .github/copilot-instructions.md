<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# GameX Flutter App - Copilot Instructions

This is a Flutter mobile application called GameX featuring:

## Core Features

- Multiple mini-games (Card Shooter, Ball Blaster, Racing Rush, Puzzle Mania, Drone Flight)
- Character system with 5 unique characters (Nova, Blitz, Zink, Karma, Rokk)
- Glassmorphism theme with light/dark mode support
- User profile system with XP, levels, and badges
- Global leaderboards and social sharing
- Gamification elements (daily challenges, streaks)

## Technical Stack

- Flutter with Clean Architecture
- State Management: BLoC/Cubit pattern
- Firebase: Auth, Firestore, Analytics, Crashlytics
- Game Engine: Flame for game rendering
- UI: Glassmorphism design with custom themes

## Code Guidelines

- Use Clean Architecture with Domain, Data, and Presentation layers
- Implement proper error handling and offline support
- Follow Flutter best practices for performance
- Use proper dependency injection
- Implement responsive design with flutter_screenutil
- Use proper asset management and optimization

## Character System

Each character has unique properties:

- Visual appearance and animations
- Special abilities in games
- Unlock requirements (XP, level, badges)
- Customization options

## Game Architecture

- Each game is a separate module
- Shared game engine components
- Score calculation and XP earning system
- Progress tracking and achievements
