import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/drone_shooter_components.dart';
import '../../domain/entities/drone_shooter_entities.dart';

class DroneShooterGame extends FlameGame<World> with HasCollisionDetection {
  late DroneComponent drone;
  late DroneStats droneStats;
  late DroneShooterConfig config;

  DroneShooterGameState gameState = DroneShooterGameState.menu;

  final List<BulletComponent> bullets = [];
  final List<EnemyBulletComponent> enemyBullets = [];
  final List<EnemyComponent> enemies = [];
  final List<PowerUpComponent> powerUps = [];

  // Game progression
  double enemySpawnTimer = 0;
  double powerUpSpawnTimer = 0;
  double difficultyTimer = 0;
  double currentDifficulty = 1.0;
  double sectionTimer = 0;
  bool isPaused = false;

  // Spawn rates
  double enemySpawnRate = 2.0; // seconds between spawns
  double powerUpSpawnRate = 10.0; // seconds between power-up spawns

  final Random random = Random();

  // UI callback for stats updates
  Function(DroneStats)? onStatsUpdate;
  Function(DroneShooterGameState)? onGameStateChange;

  @override
  Future<void> onLoad() async {
    config = const DroneShooterConfig();

    // Add background
    add(BackgroundComponent());

    _initializeGame();
  }

  void _initializeGame() {
    droneStats = DroneStats();

    // Create drone
    drone = DroneComponent(
      onShoot: _createBullet,
      position: Vector2(50, size.y / 2 - 15),
      initialStats: droneStats,
    );

    add(drone);

    gameState = DroneShooterGameState.playing;
    onGameStateChange?.call(gameState);
    onStatsUpdate?.call(droneStats);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != DroneShooterGameState.playing || isPaused) return;

    // Check if drone is dead
    if (droneStats.isDead) {
      _gameOver();
      return;
    }

    // Update section timer
    sectionTimer += dt;
    droneStats.sectionTimeRemaining = config.sectionDuration - sectionTimer;

    // Check if section is complete
    if (sectionTimer >= config.sectionDuration) {
      _completeSection();
      return;
    }

    // Update timers
    enemySpawnTimer += dt;
    powerUpSpawnTimer += dt;
    difficultyTimer += dt;
    droneStats.weaponUpgradeTimer += dt;

    // Weapon upgrade system - cycle through bullet types
    if (droneStats.weaponUpgradeTimer >= 15.0) {
      // Upgrade every 15 seconds
      _upgradeWeapon();
      droneStats.weaponUpgradeTimer = 0.0;
    }

    // Increase difficulty over time
    if (difficultyTimer > 30) {
      // Every 30 seconds
      currentDifficulty += 0.2;
      enemySpawnRate = (enemySpawnRate * 0.9).clamp(0.5, 3.0);
      difficultyTimer = 0;
    }

    // Spawn enemies
    if (enemySpawnTimer > enemySpawnRate / currentDifficulty) {
      _spawnEnemy();
      enemySpawnTimer = 0;
    }

    // Spawn power-ups
    if (powerUpSpawnTimer > powerUpSpawnRate) {
      _spawnPowerUp();
      powerUpSpawnTimer = 0;
    }

    // Check collisions
    _checkCollisions();

    // Clean up off-screen enemy bullets
    enemyBullets.removeWhere((bullet) => bullet.parent == null);

    // Update UI
    onStatsUpdate?.call(droneStats);
  }

  void _upgradeWeapon() {
    // Cycle through bullet types as upgrades
    switch (droneStats.currentBulletType) {
      case BulletType.normal:
        droneStats.currentBulletType = BulletType.rapid;
        break;
      case BulletType.rapid:
        droneStats.currentBulletType = BulletType.heavy;
        break;
      case BulletType.heavy:
        droneStats.currentBulletType = BulletType.spread;
        break;
      case BulletType.spread:
        droneStats.currentBulletType = BulletType.piercing;
        break;
      case BulletType.piercing:
        droneStats.currentBulletType = BulletType.normal; // Reset to normal
        break;
    }
  }

  // Method for enemies to register their bullets
  void addEnemyBullet(EnemyBulletComponent bullet) {
    enemyBullets.add(bullet);
  }

  void _createBullet(Vector2 position, Vector2 direction) {
    final bulletData = BulletData.data[droneStats.currentBulletType]!;

    if (bulletData.type == BulletType.spread) {
      // Create spread shot - 3 bullets
      _createSingleBullet(
        position.clone() + Vector2(-10, 0),
        Vector2(-0.3, -1).normalized(),
        bulletData,
      );
      _createSingleBullet(position.clone(), direction.normalized(), bulletData);
      _createSingleBullet(
        position.clone() + Vector2(10, 0),
        Vector2(0.3, -1).normalized(),
        bulletData,
      );
    } else if (droneStats.multiShot && bulletData.type != BulletType.spread) {
      // Multi-shot for other bullet types
      _createSingleBullet(
        position.clone() + Vector2(-8, 0),
        direction.normalized(),
        bulletData,
      );
      _createSingleBullet(
        position.clone() + Vector2(8, 0),
        direction.normalized(),
        bulletData,
      );
    } else {
      // Single shot
      _createSingleBullet(position.clone(), direction.normalized(), bulletData);
    }
  }

  void _createSingleBullet(
    Vector2 position,
    Vector2 direction,
    BulletData bulletData,
  ) {
    final bullet = BulletComponent(
      position: position,
      direction: direction,
      bulletData: bulletData,
    );
    add(bullet);
    bullets.add(bullet);
  }

  void _spawnEnemy() {
    EnemyType type;
    final roll = random.nextDouble();

    // Determine enemy type based on difficulty and random chance
    if (roll < 0.1 && currentDifficulty > 3) {
      type = EnemyType.boss;
    } else if (roll < 0.3 && currentDifficulty > 2) {
      type = EnemyType.heavy;
    } else if (roll < 0.6) {
      type = EnemyType.fast;
    } else {
      type = EnemyType.basic;
    }

    final enemy = EnemyComponent(
      position: Vector2(
        random.nextDouble() * (size.x - 60) + 30,
        -50, // Spawn from top of screen
      ),
      enemyData: EnemyData.data[type]!,
      onEnemyShoot: _onEnemyShoot,
      onDestroyed: _onEnemyDestroyed,
    );

    add(enemy);
    enemies.add(enemy);
  }

  void _onEnemyShoot(Vector2 position, Vector2 direction, BulletType type) {
    final bulletData = BulletData.data[type]!;
    final enemyBullet = EnemyBulletComponent(
      position: position,
      direction: direction,
      bulletData: bulletData,
    );
    add(enemyBullet);
    enemyBullets.add(enemyBullet);
  }

  void _spawnPowerUp() {
    final types = PowerUpType.values;
    final type = types[random.nextInt(types.length)];

    final powerUp = PowerUpComponent(
      position: Vector2(size.x + 20, random.nextDouble() * (size.y - 60) + 30),
      powerUpData: PowerUpData.data[type]!,
      onCollected: _onPowerUpCollected,
    );

    add(powerUp);
    powerUps.add(powerUp);
  }

  void _onEnemyDestroyed(EnemyComponent enemy) {
    enemies.remove(enemy);

    // Award XP and score
    droneStats.addXP(enemy.data.xpReward);
    droneStats.score += enemy.data.scoreReward;
    droneStats.enemiesDestroyed++;

    // Add explosion effect
    add(
      ParticleEffectComponent(
        startPosition: enemy.position.clone(),
        color: enemy.data.color,
      ),
    );
  }

  void _onPowerUpCollected(PowerUpType type) {
    drone.applyPowerUp(type);

    // Add collection effect
    add(
      ParticleEffectComponent(
        startPosition: drone.position.clone(),
        color: PowerUpData.data[type]!.color,
      ),
    );
  }

  void _checkCollisions() {
    // Player Bullet vs Enemy collisions
    for (final bullet in bullets.toList()) {
      for (final enemy in enemies.toList()) {
        if (_areColliding(bullet, enemy)) {
          enemy.takeDamage(bullet.bulletData.damage);

          // Only remove bullet if it's not piercing
          if (!bullet.bulletData.piercing) {
            bullet.removeFromParent();
            bullets.remove(bullet);
          }
          break;
        }
      }
    }

    // Enemy Bullet vs Player collisions
    for (final enemyBullet in enemyBullets.toList()) {
      if (_areColliding(drone, enemyBullet)) {
        drone.takeDamage(enemyBullet.bulletData.damage);
        enemyBullet.removeFromParent();
        enemyBullets.remove(enemyBullet);

        // Add hit effect
        add(
          ParticleEffectComponent(
            startPosition: drone.position.clone(),
            color: Colors.red,
          ),
        );
        break;
      }
    }

    // Drone vs Enemy collisions
    for (final enemy in enemies.toList()) {
      if (_areColliding(drone, enemy)) {
        drone.takeDamage(enemy.data.damage);
        enemy.removeFromParent();
        enemies.remove(enemy);

        // Add hit effect
        add(
          ParticleEffectComponent(
            startPosition: drone.position.clone(),
            color: Colors.red,
          ),
        );
      }
    }

    // Drone vs PowerUp collisions
    for (final powerUp in powerUps.toList()) {
      if (_areColliding(drone, powerUp)) {
        powerUp.collect();
        powerUps.remove(powerUp);
      }
    }
  }

  bool _areColliding(PositionComponent a, PositionComponent b) {
    return a.position.x < b.position.x + b.size.x &&
        a.position.x + a.size.x > b.position.x &&
        a.position.y < b.position.y + b.size.y &&
        a.position.y + a.size.y > b.position.y;
  }

  void _gameOver() {
    gameState = DroneShooterGameState.gameOver;
    onGameStateChange?.call(gameState);

    // Clear all game objects
    for (final bullet in bullets) {
      bullet.removeFromParent();
    }
    for (final enemyBullet in enemyBullets) {
      enemyBullet.removeFromParent();
    }
    for (final enemy in enemies) {
      enemy.removeFromParent();
    }
    for (final powerUp in powerUps) {
      powerUp.removeFromParent();
    }

    bullets.clear();
    enemyBullets.clear();
    enemies.clear();
    powerUps.clear();
  }

  void restartGame() {
    drone.removeFromParent();
    _initializeGame();
    enemySpawnTimer = 0;
    powerUpSpawnTimer = 0;
    difficultyTimer = 0;
    currentDifficulty = 1.0;
    enemySpawnRate = 2.0;
  }

  void pauseGame() {
    if (gameState == DroneShooterGameState.playing) {
      isPaused = true;
      gameState = DroneShooterGameState.paused;
      onGameStateChange?.call(gameState);
      pauseEngine();
    }
  }

  void resumeGame() {
    if (gameState == DroneShooterGameState.paused ||
        gameState == DroneShooterGameState.menu) {
      isPaused = false;
      gameState = DroneShooterGameState.playing;
      onGameStateChange?.call(gameState);
      resumeEngine();
    }
  }

  // Input handling
  void moveDrone(Vector2 direction) {
    if (gameState != DroneShooterGameState.playing) return;

    if (direction.x > 0) drone.moveRight();
    if (direction.x < 0) drone.moveLeft();
    if (direction.y > 0) drone.moveDown();
    if (direction.y < 0) drone.moveUp();
  }

  void startShooting() {
    if (gameState == DroneShooterGameState.playing) {
      drone.startShooting();
    }
  }

  void stopShooting() {
    drone.stopShooting();
  }

  void _completeSection() {
    droneStats.currentSection++;
    sectionTimer = 0;
    droneStats.sectionTimeRemaining = config.sectionDuration;

    // Bonus for completing section
    droneStats.score += 500;
    droneStats.xp += 25;

    // Check if all sections completed (win condition)
    if (droneStats.currentSection > config.totalSections) {
      _gameWin();
    } else {
      // Increase difficulty for next section
      currentDifficulty += 0.3;
      enemySpawnRate = (enemySpawnRate * 0.85).clamp(0.5, 3.0);

      onStatsUpdate?.call(droneStats);
    }
  }

  void _gameWin() {
    gameState = DroneShooterGameState.gameOver;
    onGameStateChange?.call(gameState);
  }
}
