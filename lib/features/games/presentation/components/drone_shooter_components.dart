import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/drone_shooter_entities.dart';
import '../pages/drone_flight_game/drone_shooter_game_engine.dart';

class DroneComponent extends RectangleComponent
    with HasGameRef<DroneShooterGame> {
  late DroneStats stats;
  final double _speed;
  Vector2 velocity = Vector2.zero();
  double _lastShot = 0;
  bool _isShooting = false;
  final Function(Vector2 position, Vector2 direction) onShoot;

  DroneComponent({
    required this.onShoot,
    required Vector2 position,
    DroneStats? initialStats,
  }) : _speed = initialStats?.speed ?? 200 {
    stats = initialStats ?? DroneStats();
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    // Create B-2 stealth bomber shape
    size = Vector2(45, 35);
    paint = Paint()..color = Colors.grey.shade900;
  }

  @override
  void render(Canvas canvas) {
    // Draw defensive effects first (behind the drone)
    if (stats.currentDefense != DefenseType.none) {
      _renderDefenseEffect(canvas);
    }

    // Futuristic drone: add blue neon outline and cockpit
    final bodyPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;
    final neonPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Main body: stylized diamond/arrow shape
    final path = Path();
    path.moveTo(size.x / 2, 0); // Nose
    path.lineTo(size.x, size.y * 0.4); // Right front
    path.lineTo(size.x * 0.8, size.y); // Right tail
    path.lineTo(size.x * 0.2, size.y); // Left tail
    path.lineTo(0, size.y * 0.4); // Left front
    path.close();

    // Draw neon outline
    canvas.drawPath(path, neonPaint);
    // Draw main body
    canvas.drawPath(path, bodyPaint);

    // Cockpit
    final cockpitPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.35),
        width: 12,
        height: 6,
      ),
      cockpitPaint,
    );

    // Engine glow when shooting
    if (_isShooting) {
      final exhaustPaint = Paint()
        ..color = Colors.orange.withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.95), 5, exhaustPaint);
    }

    // Futuristic lights
    final lightPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x * 0.25, size.y * 0.7), 2, lightPaint);
    canvas.drawCircle(Offset(size.x * 0.75, size.y * 0.7), 2, lightPaint);
  }

  void _renderDefenseEffect(Canvas canvas) {
    if (stats.currentDefense == DefenseType.none) return;

    switch (stats.currentDefense) {
      case DefenseType.block:
        // Shield effect
        final shieldPaint = Paint()
          ..color = Colors.blue.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2 + 5,
          shieldPaint,
        );
        break;

      case DefenseType.dodge:
        // Afterimage effect
        final afterimagePaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(size.x / 2 - i * 2, size.y / 2),
            size.x / 4,
            afterimagePaint,
          );
        }
        break;

      case DefenseType.parry:
        // Energy aura effect
        final parryPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2 + 3,
          parryPaint,
        );
        break;

      case DefenseType.none:
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update defensive timers
    stats.updateDefense(dt);

    // Update position based on velocity
    position.add(velocity * dt);

    // Keep drone within bounds
    final gameSize = gameRef.size;
    position.x = position.x.clamp(0, gameSize.x - size.x);
    position.y = position.y.clamp(0, gameSize.y - size.y);

    // Handle shooting
    if (_isShooting) {
      _lastShot += dt;
      if (_lastShot >= stats.fireRate) {
        _shoot();
        _lastShot = 0;
      }
    }

    // Reset velocity (will be set by input handlers)
    velocity.setZero();
  }

  void moveUp() => velocity.y = -_speed * 1.8;
  void moveDown() => velocity.y = _speed * 1.8;
  void moveLeft() => velocity.x = -_speed * 1.8;
  void moveRight() => velocity.x = _speed * 1.8;

  // Enhanced movement with defensive capabilities
  void dodge() {
    if (stats.canDefend) {
      stats.activateDefense(DefenseType.dodge);
      // Quick dodge movement
      velocity.x += (velocity.x > 0 ? 1 : -1) * _speed * 0.5;
      velocity.y += (velocity.y > 0 ? 1 : -1) * _speed * 0.5;
    }
  }

  void activateShield() {
    if (stats.canDefend) {
      stats.activateDefense(DefenseType.block);
    }
  }

  void attemptParry() {
    if (stats.canDefend) {
      stats.activateDefense(DefenseType.parry);
    }
  }

  void startShooting() => _isShooting = true;
  void stopShooting() => _isShooting = false;

  void _shoot() {
    final bulletStart = Vector2(position.x + size.x / 2, position.y);
    onShoot(bulletStart, Vector2(0, -1)); // Shoot upward

    if (stats.multiShot) {
      onShoot(bulletStart, Vector2(-0.3, -1)); // Left diagonal
      onShoot(bulletStart, Vector2(0.3, -1)); // Right diagonal
    }
  }

  void takeDamage(int damage) {
    stats.takeDamage(damage);
    // Simple visual feedback - scale effect
    scale = Vector2.all(1.2);
    Future.delayed(const Duration(milliseconds: 100), () {
      scale = Vector2.all(1.0);
    });
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.health:
        stats.heal(30);
        break;
      case PowerUpType.speed:
        stats.speed += 20;
        break;
      case PowerUpType.fireRate:
        stats.fireRate = (stats.fireRate * 0.8).clamp(0.1, 1.0);
        break;
      case PowerUpType.damage:
        stats.damage++;
        break;
      case PowerUpType.multiShot:
        stats.multiShot = true;
        break;
      case PowerUpType.shield:
        stats.addShield(25);
        break;
      case PowerUpType.dodge:
        // Temporarily reduce defense cooldown
        stats.defenseCooldown = 0.0;
        break;
    }
  }
}

class BulletComponent extends RectangleComponent
    with HasCollisionDetection, HasGameRef<DroneShooterGame> {
  final Vector2 direction;
  final BulletData bulletData;

  BulletComponent({
    required Vector2 position,
    required this.direction,
    required this.bulletData,
  }) : super(size: Vector2(4, 8), position: position);

  @override
  Future<void> onLoad() async {
    // Set bullet color based on type
    paint = Paint()..color = bulletData.color;
  }

  @override
  void render(Canvas canvas) {
    switch (bulletData.type) {
      case BulletType.normal:
        // Simple rectangular bullet
        super.render(canvas);
        break;
      case BulletType.rapid:
        // Smaller, faster bullet
        final rapidPaint = Paint()..color = bulletData.color;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x * 0.7, size.y * 0.7),
          rapidPaint,
        );
        break;
      case BulletType.heavy:
        // Larger, slower bullet with trail
        final heavyPaint = Paint()..color = bulletData.color;
        final trailPaint = Paint()
          ..color = bulletData.color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2 + 2),
          size.x / 2 + 1,
          trailPaint,
        );
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 2,
          heavyPaint,
        );
        break;
      case BulletType.spread:
        // Multiple small projectiles
        final spreadPaint = Paint()..color = bulletData.color;
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(size.x / 2 + (i - 1) * 2, size.y / 2),
            1,
            spreadPaint,
          );
        }
        break;
      case BulletType.piercing:
        // Sharp, pointed bullet
        final piercingPaint = Paint()..color = bulletData.color;
        final path = Path();
        path.moveTo(size.x / 2, 0);
        path.lineTo(size.x, size.y);
        path.lineTo(0, size.y);
        path.close();
        canvas.drawPath(path, piercingPaint);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(direction * bulletData.speed * dt);

    // Remove bullet if it goes off-screen
    if (position.y < -10 ||
        position.y > gameRef.size.y + 10 ||
        position.x < -10 ||
        position.x > gameRef.size.x + 10) {
      removeFromParent();
    }
  }
}

class EnemyComponent extends RectangleComponent
    with HasCollisionDetection, HasGameRef<DroneShooterGame> {
  late EnemyData enemyData;
  EnemyData get data => enemyData; // Getter for compatibility
  double _lastShot = 0;
  double _directionTimer = 0;
  Vector2 velocity = Vector2.zero();
  final Function(Vector2 position, Vector2 direction, BulletType type)
  onEnemyShoot;
  final Function(EnemyComponent enemy)? onDestroyed;
  late int health;

  EnemyComponent({
    required Vector2 position,
    required this.enemyData,
    required this.onEnemyShoot,
    this.onDestroyed,
    EnemyType? type, // For backward compatibility
  }) : super(position: position, size: Vector2(30, 25)) {
    if (type != null) {
      enemyData = EnemyData.data[type]!;
    }
    health = enemyData.health;
  }

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = enemyData.color;
  }

  @override
  void render(Canvas canvas) {
    // Enhanced enemy graphics based on behavior
    switch (enemyData.behavior) {
      case EnemyBehavior.aggressive:
        _renderAggressiveEnemy(canvas);
        break;
      case EnemyBehavior.defensive:
        _renderDefensiveEnemy(canvas);
        break;
      case EnemyBehavior.balanced:
        _renderBalancedEnemy(canvas);
        break;
      case EnemyBehavior.adaptive:
        _renderAdaptiveEnemy(canvas);
        break;
    }
  }

  void _renderAggressiveEnemy(Canvas canvas) {
    // Sharp, angular design for aggressive enemies
    final aggressivePaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.x / 2, 0);
    path.lineTo(size.x, size.y * 0.7);
    path.lineTo(size.x * 0.8, size.y);
    path.lineTo(size.x * 0.2, size.y);
    path.lineTo(0, size.y * 0.7);
    path.close();

    canvas.drawPath(path, aggressivePaint);

    // Add aggressive markings
    final markingPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.x * 0.3, size.y * 0.3),
      Offset(size.x * 0.7, size.y * 0.3),
      markingPaint,
    );
  }

  void _renderDefensiveEnemy(Canvas canvas) {
    // Rounded, shield-like design for defensive enemies
    final defensivePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromLTWH(0, 0, size.x, size.y), defensivePaint);

    // Add shield pattern
    final shieldPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 3, shieldPaint);
  }

  void _renderBalancedEnemy(Canvas canvas) {
    // Standard hexagonal design for balanced enemies
    final balancedPaint = Paint()
      ..color = Colors.purple.shade700
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 3;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, balancedPaint);
  }

  void _renderAdaptiveEnemy(Canvas canvas) {
    // Dynamic, shifting design for adaptive enemies
    final adaptivePaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;

    // Create a morphing diamond shape
    final path = Path();
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final morph = sin(time * 2) * 0.2;

    path.moveTo(size.x / 2, morph * size.y);
    path.lineTo(size.x - morph * size.x, size.y / 2);
    path.lineTo(size.x / 2, size.y - morph * size.y);
    path.lineTo(morph * size.x, size.y / 2);
    path.close();

    canvas.drawPath(path, adaptivePaint);

    // Add adaptive glow
    final glowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _directionTimer += dt;
    _lastShot += dt;

    // Update movement based on behavior
    _updateMovement(dt);

    // Update shooting
    if (_lastShot >= enemyData.shootInterval) {
      _shoot();
      _lastShot = 0;
    }

    position.add(velocity * dt);

    // Keep enemy on screen
    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    if (position.y > gameRef.size.y + 50) {
      removeFromParent();
    }
  }

  void _updateMovement(double dt) {
    switch (enemyData.behavior) {
      case EnemyBehavior.aggressive:
        // Move straight down aggressively
        velocity.y = enemyData.speed * 1.5;
        velocity.x = sin(_directionTimer * 3) * 50;
        break;
      case EnemyBehavior.defensive:
        // Slow, cautious movement
        velocity.y = enemyData.speed * 0.8;
        velocity.x = sin(_directionTimer) * 30;
        break;
      case EnemyBehavior.balanced:
        // Standard movement
        velocity.y = enemyData.speed;
        velocity.x = sin(_directionTimer * 2) * 40;
        break;
      case EnemyBehavior.adaptive:
        // Unpredictable movement
        velocity.y = enemyData.speed * (1 + sin(_directionTimer * 4) * 0.3);
        velocity.x = sin(_directionTimer * 5) * 60;
        break;
    }
  }

  void _shoot() {
    final bulletPosition = Vector2(
      position.x + size.x / 2,
      position.y + size.y,
    );

    // Choose bullet type based on behavior
    BulletType bulletType;
    switch (enemyData.behavior) {
      case EnemyBehavior.aggressive:
        bulletType = BulletType.rapid;
        break;
      case EnemyBehavior.defensive:
        bulletType = BulletType.heavy;
        break;
      case EnemyBehavior.balanced:
        bulletType = BulletType.normal;
        break;
      case EnemyBehavior.adaptive:
        bulletType =
            BulletType.values[Random().nextInt(BulletType.values.length)];
        break;
    }

    onEnemyShoot(bulletPosition, Vector2(0, 1), bulletType);
  }

  void takeDamage(int damage) {
    health -= damage;

    // Visual feedback
    scale = Vector2.all(1.3);
    Future.delayed(const Duration(milliseconds: 100), () {
      scale = Vector2.all(1.0);
    });

    if (health <= 0) {
      // Call onDestroyed callback so game engine removes from list and triggers effects
      onDestroyed?.call(this);
      removeFromParent();
    }
  }
}

class PowerUpComponent extends RectangleComponent
    with HasCollisionDetection, HasGameRef<DroneShooterGame> {
  final PowerUpData powerUpData;
  final Function(PowerUpType type)? onCollected;
  double _animationTimer = 0;

  PowerUpComponent({
    required Vector2 position,
    required this.powerUpData,
    this.onCollected,
    PowerUpType? type, // For backward compatibility
  }) : super(position: position, size: Vector2(20, 20));

  void collect() {
    onCollected?.call(powerUpData.type);
    removeFromParent();
  }

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = powerUpData.color;
  }

  @override
  void render(Canvas canvas) {
    // Animated power-up with glow effect
    final glowPaint = Paint()
      ..color = powerUpData.color.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        3 + sin(_animationTimer * 4) * 2,
      );

    final corePaint = Paint()..color = powerUpData.color;

    // Draw glow
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5,
      glowPaint,
    );

    // Draw core based on type
    switch (powerUpData.type) {
      case PowerUpType.health:
        // Cross shape for health
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.x / 2, size.y / 2),
            width: size.x * 0.8,
            height: size.y * 0.3,
          ),
          corePaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(size.x / 2, size.y / 2),
            width: size.x * 0.3,
            height: size.y * 0.8,
          ),
          corePaint,
        );
        break;
      case PowerUpType.speed:
        // Triangle for speed
        final path = Path();
        path.moveTo(size.x / 2, size.y * 0.2);
        path.lineTo(size.x * 0.8, size.y * 0.8);
        path.lineTo(size.x * 0.2, size.y * 0.8);
        path.close();
        canvas.drawPath(path, corePaint);
        break;
      case PowerUpType.fireRate:
        // Lightning bolt for fire rate
        final path = Path();
        path.moveTo(size.x * 0.4, size.y * 0.2);
        path.lineTo(size.x * 0.7, size.y * 0.4);
        path.lineTo(size.x * 0.5, size.y * 0.4);
        path.lineTo(size.x * 0.6, size.y * 0.8);
        path.lineTo(size.x * 0.3, size.y * 0.6);
        path.lineTo(size.x * 0.5, size.y * 0.6);
        path.close();
        canvas.drawPath(path, corePaint);
        break;
      case PowerUpType.damage:
        // Star for damage
        final starPath = Path();
        final centerX = size.x / 2;
        final centerY = size.y / 2;
        final outerRadius = size.x / 3;
        final innerRadius = outerRadius / 2;

        for (int i = 0; i < 10; i++) {
          final angle = (i * 36) * (pi / 180);
          final radius = i % 2 == 0 ? outerRadius : innerRadius;
          final x = centerX + radius * cos(angle);
          final y = centerY + radius * sin(angle);

          if (i == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, corePaint);
        break;
      case PowerUpType.multiShot:
        // Multiple circles for multi-shot
        canvas.drawCircle(
          Offset(size.x * 0.3, size.y / 2),
          size.x / 6,
          corePaint,
        );
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          size.x / 6,
          corePaint,
        );
        canvas.drawCircle(
          Offset(size.x * 0.7, size.y / 2),
          size.x / 6,
          corePaint,
        );
        break;
      case PowerUpType.shield:
        // Hexagonal shield
        final shieldPath = Path();
        final centerX = size.x / 2;
        final centerY = size.y / 2;
        final radius = size.x / 3;

        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * (pi / 180);
          final x = centerX + radius * cos(angle);
          final y = centerY + radius * sin(angle);

          if (i == 0) {
            shieldPath.moveTo(x, y);
          } else {
            shieldPath.lineTo(x, y);
          }
        }
        shieldPath.close();
        canvas.drawPath(shieldPath, corePaint);
        break;
      case PowerUpType.dodge:
        // Motion lines for dodge
        final linePaint = Paint()
          ..color = corePaint.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(size.x * 0.2 + i * 5, size.y * 0.3),
            Offset(size.x * 0.5 + i * 5, size.y * 0.7),
            linePaint,
          );
        }
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animationTimer += dt;

    // Floating animation
    position.y += sin(_animationTimer * 3) * 0.5;

    // Slow downward drift
    position.y += 30 * dt;

    // Remove if off-screen
    if (position.y > gameRef.size.y + 20) {
      removeFromParent();
    }
  }
}

// Additional Components for the game engine

class EnemyBulletComponent extends RectangleComponent
    with HasCollisionDetection, HasGameRef<DroneShooterGame> {
  final Vector2 direction;
  final BulletData bulletData;

  EnemyBulletComponent({
    required Vector2 position,
    required this.direction,
    required this.bulletData,
  }) : super(size: Vector2(3, 6), position: position);

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = bulletData.color.withOpacity(0.8);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(direction * bulletData.speed * dt);

    // Remove bullet if it goes off-screen
    if (position.y < -10 ||
        position.y > gameRef.size.y + 10 ||
        position.x < -10 ||
        position.x > gameRef.size.x + 10) {
      removeFromParent();
    }
  }
}

class ParticleEffectComponent extends Component
    with HasGameRef<DroneShooterGame> {
  final Vector2 startPosition;
  final Color color;
  List<ParticleData> particles = [];
  double lifeTimer = 0;
  final double maxLife = 1.0;

  ParticleEffectComponent({required this.startPosition, required this.color});

  @override
  Future<void> onLoad() async {
    // Create particles
    for (int i = 0; i < 10; i++) {
      particles.add(
        ParticleData(
          position: startPosition.clone(),
          velocity: Vector2(
            (Random().nextDouble() - 0.5) * 200,
            (Random().nextDouble() - 0.5) * 200,
          ),
          life: Random().nextDouble() * maxLife,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    lifeTimer += dt;

    for (final particle in particles) {
      particle.position.add(particle.velocity * dt);
      particle.life -= dt;
    }

    particles.removeWhere((p) => p.life <= 0);

    if (lifeTimer >= maxLife || particles.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withOpacity(0.7);

    for (final particle in particles) {
      final alpha = (particle.life / maxLife).clamp(0.0, 1.0);
      paint.color = color.withOpacity(alpha * 0.7);

      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        2,
        paint,
      );
    }
  }
}

class ParticleData {
  Vector2 position;
  Vector2 velocity;
  double life;

  ParticleData({
    required this.position,
    required this.velocity,
    required this.life,
  });
}

class BackgroundComponent extends Component with HasGameRef<DroneShooterGame> {
  late List<Star> stars;

  @override
  Future<void> onLoad() async {
    stars = List.generate(
      100,
      (index) => Star(
        position: Vector2(
          Random().nextDouble() * gameRef.size.x,
          Random().nextDouble() * gameRef.size.y,
        ),
        speed: Random().nextDouble() * 50 + 10,
        brightness: Random().nextDouble(),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final star in stars) {
      star.position.y += star.speed * dt;

      // Reset star position when it goes off screen
      if (star.position.y > gameRef.size.y) {
        star.position.y = -10;
        star.position.x = Random().nextDouble() * gameRef.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;

    for (final star in stars) {
      paint.color = Colors.white.withOpacity(star.brightness);
      canvas.drawCircle(Offset(star.position.x, star.position.y), 1, paint);
    }
  }
}

class Star {
  Vector2 position;
  double speed;
  double brightness;

  Star({required this.position, required this.speed, required this.brightness});
}
