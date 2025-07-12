# Drone Shooter Game 🚁

## Overview

A complete 2D side-scrolling shooter game built with Flutter and Flame engine, featuring classic arcade-style gameplay with modern mobile controls.

## Features

### Core Gameplay

- **Side-scrolling Action**: Classic horizontal shooter with smooth scrolling background
- **Touch Controls**: Mobile-optimized directional pad and shoot button
- **Progressive Difficulty**: Enemy spawn rate and difficulty increase over time
- **Power-up System**: Collectible upgrades that enhance drone capabilities

### Drone Mechanics

- **Movement**: 360-degree movement with touch-based directional pad
- **Combat**: Rapid-fire shooting with damage and fire rate upgrades
- **Health System**: Health bar with visual feedback on damage
- **Upgrades**: Multi-shot, speed boost, damage increase, and more

### Enemy System

- **Enemy Types**:
  - **Basic**: Standard red enemies with simple movement
  - **Fast**: Orange enemies with quick, erratic movement
  - **Heavy**: Purple enemies with high health and slow movement
  - **Boss**: Large dark red enemies with complex movement patterns

### Power-ups

- **Health Boost**: Restore 30 health points
- **Speed Boost**: Increase movement speed
- **Rapid Fire**: Faster shooting rate
- **Damage Boost**: Increase bullet damage
- **Multi Shot**: Fire multiple bullets simultaneously

### Visual Effects

- **Particle Systems**: Explosion effects on enemy destruction
- **Hit Feedback**: Visual feedback for damage and power-up collection
- **Background**: Animated starfield with parallax scrolling
- **UI Overlays**: Real-time health, level, score, and XP tracking

## Technical Implementation

### Architecture

```
lib/features/games/
├── domain/entities/
│   └── drone_shooter_entities.dart     # Game data models
├── presentation/
│   ├── components/
│   │   └── drone_shooter_components.dart # Flame game components
│   └── pages/
│       ├── drone_shooter_game.dart      # UI wrapper
│       └── drone_shooter_game_engine.dart # Flame game engine
```

### Game Components

#### DroneComponent

- Handles player drone movement and shooting
- Manages health and stats
- Processes power-up applications

#### EnemyComponent

- Four enemy types with different behaviors
- Health system with visual damage feedback
- Reward system (XP and score on destruction)

#### BulletComponent

- Player projectiles with collision detection
- Configurable damage and speed
- Automatic cleanup when off-screen

#### PowerUpComponent

- Collectible items with different effects
- Animated floating movement
- Visual collection effects

#### ParticleEffectComponent

- Explosion and hit effects
- Particle-based visual feedback
- Automatic cleanup system

### Game Engine (DroneShooterGame)

- **Collision Detection**: Bullet vs enemy, drone vs enemy/power-up
- **Spawn Management**: Dynamic enemy and power-up spawning
- **Difficulty Scaling**: Progressive challenge increase
- **State Management**: Menu, playing, paused, game over states
- **XP Integration**: Profile system integration with rewards

### Controls

- **Directional Pad**: Four-direction movement control
- **Shoot Button**: Continuous firing while pressed
- **Pause Button**: Game state management
- **Touch Feedback**: Visual button press indicators

## Game Flow

### 1. Game Start

- Initialize drone stats (health: 100, level: 1, speed: 200)
- Display game instructions overlay
- Start background star animation

### 2. Gameplay Loop

- Spawn enemies based on difficulty timer
- Handle player input for movement and shooting
- Check collisions (bullets vs enemies, drone vs enemies/power-ups)
- Update UI with current stats
- Apply power-ups when collected

### 3. Progression System

- **XP Gain**: Destroy enemies to earn experience points
- **Level Up**: Automatic upgrades when XP threshold reached
- **Score Tracking**: Points awarded for enemy destruction
- **Difficulty Scaling**: Enemy spawn rate increases over time

### 4. Win/Lose Conditions

- **Win**: Reach level 5 or survive for extended period
- **Lose**: Drone health reaches zero
- **Rewards**: XP and profile integration based on performance

## Configuration

### Difficulty Settings

```dart
enum GameDifficulty { easy, medium, hard, expert }
```

- **Easy**: Slower enemy spawns, more forgiving
- **Medium**: Balanced gameplay
- **Hard**: Faster enemies, higher damage
- **Expert**: Maximum challenge with rapid spawns

### Game Constants

```dart
class DroneShooterConfig {
  static const double worldWidth = 800;
  static const double worldHeight = 600;
  static const double droneSpeed = 200;
  static const double bulletSpeed = 300;
  static const double enemySpeed = 100;
  static const int initialHealth = 100;
  static const double fireRate = 0.3;
}
```

## Integration

### Profile System

- XP rewards based on performance and difficulty
- Game completion tracking
- Statistics logging (score, level, enemies destroyed)

### Navigation

- Integrated into main game selection screen
- Route: `/drone-shooter`
- Requires GameDifficulty parameter

### Assets

- Self-contained visual components using Flutter's Paint system
- No external image dependencies
- Scalable vector-based graphics

## Performance Optimizations

### Memory Management

- Automatic component cleanup when off-screen
- Limited particle count (max 100 stars)
- Efficient collision detection with bounds checking

### Rendering

- Simple geometric shapes for optimal performance
- Minimal texture usage
- Hardware-accelerated Canvas drawing

### Game Loop

- 60 FPS target with smooth animation
- Efficient update cycles
- Background processing for non-critical operations

## Future Enhancements

### Potential Additions

1. **Boss Battles**: Large enemies with unique attack patterns
2. **Weapon Types**: Different bullet types and special weapons
3. **Levels/Stages**: Multiple environments with themes
4. **Sound Effects**: Audio feedback for actions and events
5. **Leaderboards**: High score tracking and comparison
6. **Achievements**: Special objectives and rewards
7. **Multiplayer**: Cooperative or competitive modes

### Technical Improvements

1. **Advanced Physics**: Gravity and momentum effects
2. **Particle Effects**: More sophisticated visual effects
3. **Procedural Generation**: Random level layouts
4. **Save System**: Game state persistence
5. **Performance Metrics**: FPS monitoring and optimization

## Usage Example

```dart
// Navigate to drone shooter game
Navigator.pushNamed(
  context,
  '/drone-shooter',
  arguments: GameDifficulty.medium
);

// Game initialization
final game = DroneShooterGame();
game.onStatsUpdate = (stats) => updateUI(stats);
game.onGameStateChange = (state) => handleStateChange(state);

// Controls
game.moveDrone(Vector2(1, 0)); // Move right
game.startShooting();          // Begin firing
game.pauseGame();             // Pause gameplay
```

## Dependencies

- `flame: ^1.15.0` - Game engine
- `flutter/material.dart` - UI components
- `flutter_screenutil` - Responsive design
- `flutter_bloc` - State management

This implementation provides a complete, production-ready 2D shooter game that integrates seamlessly with the existing GameX application architecture while offering engaging gameplay and smooth performance on mobile devices.
