import 'package:flutter/material.dart';

enum DroneShooterGameState { menu, playing, paused, gameOver }

enum EnemyType { basic, fast, heavy, boss }

enum PowerUpType { health, speed, fireRate, damage, multiShot, shield, dodge }

enum BulletType {
  normal, // Basic bullet
  rapid, // Fast firing, less damage
  heavy, // Slow, high damage
  spread, // Multiple bullets
  piercing, // Goes through enemies
}

// New defensive mechanics
enum DefenseType { none, block, dodge, parry }

enum EnemyBehavior {
  aggressive, // Rushes player, high damage
  defensive, // Focuses on blocking, counter-attacks
  balanced, // Mix of offense and defense
  adaptive, // Changes behavior based on player actions
}

class DefenseData {
  final DefenseType type;
  final double duration;
  final double cooldown;
  final double damageReduction;
  final bool grantsInvincibility;
  final Color effectColor;

  const DefenseData({
    required this.type,
    required this.duration,
    required this.cooldown,
    required this.damageReduction,
    this.grantsInvincibility = false,
    this.effectColor = Colors.blue,
  });

  static const Map<DefenseType, DefenseData> data = {
    DefenseType.none: DefenseData(
      type: DefenseType.none,
      duration: 0,
      cooldown: 0,
      damageReduction: 0,
    ),
    DefenseType.block: DefenseData(
      type: DefenseType.block,
      duration: 2.0,
      cooldown: 5.0,
      damageReduction: 0.5, // 50% damage reduction
      effectColor: Colors.blue,
    ),
    DefenseType.dodge: DefenseData(
      type: DefenseType.dodge,
      duration: 0.5,
      cooldown: 3.0,
      damageReduction: 0,
      grantsInvincibility: true,
      effectColor: Colors.green,
    ),
    DefenseType.parry: DefenseData(
      type: DefenseType.parry,
      duration: 0.3,
      cooldown: 4.0,
      damageReduction: 1.0, // 100% damage reduction + counterattack
      effectColor: Colors.orange,
    ),
  };
}

class BulletData {
  final BulletType type;
  final int damage;
  final double speed;
  final Color color;
  final double size;
  final bool piercing;
  final int multiCount;

  const BulletData({
    required this.type,
    required this.damage,
    required this.speed,
    required this.color,
    required this.size,
    this.piercing = false,
    this.multiCount = 1,
  });

  static const Map<BulletType, BulletData> data = {
    BulletType.normal: BulletData(
      type: BulletType.normal,
      damage: 1,
      speed: 400,
      color: Colors.yellow,
      size: 3,
    ),
    BulletType.rapid: BulletData(
      type: BulletType.rapid,
      damage: 1,
      speed: 500,
      color: Colors.orange,
      size: 2,
    ),
    BulletType.heavy: BulletData(
      type: BulletType.heavy,
      damage: 3,
      speed: 300,
      color: Colors.red,
      size: 5,
    ),
    BulletType.spread: BulletData(
      type: BulletType.spread,
      damage: 1,
      speed: 350,
      color: Colors.cyan,
      size: 3,
      multiCount: 3,
    ),
    BulletType.piercing: BulletData(
      type: BulletType.piercing,
      damage: 2,
      speed: 450,
      color: Colors.purple,
      size: 4,
      piercing: true,
    ),
  };
}

class DroneShooterConfig {
  final double worldWidth;
  final double worldHeight;
  final double droneSpeed;
  final double bulletSpeed;
  final double enemySpeed;
  final int initialHealth;
  final double fireRate;
  final double sectionDuration; // Duration of each game section in seconds
  final int totalSections; // Total number of sections to complete

  const DroneShooterConfig({
    this.worldWidth = 800,
    this.worldHeight = 600,
    this.droneSpeed = 300, // Increased from 200
    this.bulletSpeed = 400, // Increased from 300
    this.enemySpeed = 120, // Increased from 100
    this.initialHealth = 100,
    this.fireRate = 0.2, // Faster firing (decreased from 0.3)
    this.sectionDuration = 30.0, // 30 seconds per section
    this.totalSections = 5, // 5 sections total
  });
}

class DroneStats {
  int health;
  int maxHealth;
  double speed;
  double fireRate;
  int damage;
  int level;
  int xp;
  int xpToNext;
  bool multiShot;
  int score;
  int enemiesDestroyed;
  int currentSection;
  double sectionTimeRemaining;
  BulletType currentBulletType; // Added bullet type
  double weaponUpgradeTimer; // Timer for weapon upgrades

  // Defensive capabilities
  DefenseType currentDefense;
  double defenseTimer;
  double defenseCooldown;
  bool isInvincible;
  int shieldStrength;
  int maxShield;
  double comboMultiplier;
  int consecutiveHits;
  double lastHitTime;

  DroneStats({
    this.health = 100,
    this.maxHealth = 100,
    this.speed = 300, // Increased from 200
    this.fireRate = 0.25, // Reduced fire power (increased from 0.2)
    this.damage = 1,
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.multiShot = false,
    this.score = 0,
    this.enemiesDestroyed = 0,
    this.currentSection = 1,
    this.sectionTimeRemaining = 30.0,
    this.currentBulletType = BulletType.normal, // Start with normal bullets
    this.weaponUpgradeTimer = 0.0,
    this.currentDefense = DefenseType.none,
    this.defenseTimer = 0.0,
    this.defenseCooldown = 0.0,
    this.isInvincible = false,
    this.shieldStrength = 0,
    this.maxShield = 50,
    this.comboMultiplier = 1.0,
    this.consecutiveHits = 0,
    this.lastHitTime = 0.0,
  });

  void levelUp() {
    level++;
    xp = 0;
    xpToNext = level * 100;
    maxHealth += 20;
    health = maxHealth;
    speed += 10;
    damage++;
    if (level % 3 == 0) {
      multiShot = true;
    }
    if (level % 2 == 0) {
      fireRate = (fireRate * 0.9).clamp(0.1, 1.0);
    }
    // Increase shield capacity with level
    maxShield += 10;
    shieldStrength = maxShield;
  }

  void addXP(int amount) {
    xp += (amount * comboMultiplier).round();
    while (xp >= xpToNext) {
      levelUp();
    }
  }

  void takeDamage(int amount) {
    if (isInvincible) return;

    // Apply defense reduction
    double finalDamage = amount.toDouble();
    if (currentDefense != DefenseType.none) {
      final defenseData = DefenseData.data[currentDefense]!;
      finalDamage *= (1.0 - defenseData.damageReduction);
    }

    // Shield absorbs damage first
    if (shieldStrength > 0) {
      int shieldDamage = finalDamage.round();
      if (shieldDamage >= shieldStrength) {
        finalDamage -= shieldStrength;
        shieldStrength = 0;
      } else {
        shieldStrength -= shieldDamage;
        finalDamage = 0;
      }
    }

    health = (health - finalDamage.round()).clamp(0, maxHealth);

    // Reset combo on taking damage
    consecutiveHits = 0;
    comboMultiplier = 1.0;
  }

  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  void addShield(int amount) {
    shieldStrength = (shieldStrength + amount).clamp(0, maxShield);
  }

  void activateDefense(DefenseType type) {
    if (defenseCooldown > 0) return;

    currentDefense = type;
    final defenseData = DefenseData.data[type]!;
    defenseTimer = defenseData.duration;
    defenseCooldown = defenseData.cooldown;
    isInvincible = defenseData.grantsInvincibility;
  }

  void updateDefense(double dt) {
    if (defenseTimer > 0) {
      defenseTimer -= dt;
      if (defenseTimer <= 0) {
        currentDefense = DefenseType.none;
        isInvincible = false;
      }
    }

    if (defenseCooldown > 0) {
      defenseCooldown -= dt;
    }
  }

  void registerHit() {
    consecutiveHits++;
    comboMultiplier = 1.0 + (consecutiveHits * 0.1);
    lastHitTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  bool get isDead => health <= 0;
  double get healthPercentage => health / maxHealth;
  double get xpPercentage => xp / xpToNext;
  double get shieldPercentage => shieldStrength / maxShield;
  bool get canDefend => defenseCooldown <= 0;
}

class EnemyData {
  final EnemyType type;
  final int health;
  final int damage;
  final double speed;
  final int xpReward;
  final int scoreReward;
  final Color color;
  final double size;
  final bool canShoot; // Can this enemy shoot?
  final double shootInterval; // How often it shoots (seconds)
  final BulletType bulletType; // What type of bullets it fires
  final DefenseType defenseType; // Enemy's defense mechanism
  final double defenseStrength; // Strength of the defense (e.g., block amount)
  final double
  attackPatternFrequency; // How often the enemy changes attack patterns
  final EnemyBehavior behavior; // AI behavior pattern

  const EnemyData({
    required this.type,
    required this.health,
    required this.damage,
    required this.speed,
    required this.xpReward,
    required this.scoreReward,
    required this.color,
    required this.size,
    this.canShoot = false,
    this.shootInterval = 2.0, // Default 2 seconds between shots
    this.bulletType = BulletType.normal,
    this.defenseType = DefenseType.none,
    this.defenseStrength = 0.0,
    this.attackPatternFrequency = 0.0,
    this.behavior = EnemyBehavior.aggressive,
  });

  static const Map<EnemyType, EnemyData> data = {
    EnemyType.basic: EnemyData(
      type: EnemyType.basic,
      health: 3, // Increased from 1
      damage: 10,
      speed: 60, // Decreased from 80
      xpReward: 10,
      scoreReward: 100,
      color: Colors.red,
      size: 30,
      canShoot: false, // Basic enemies don't shoot
      defenseType: DefenseType.none, // No defense
      behavior: EnemyBehavior.aggressive,
    ),
    EnemyType.fast: EnemyData(
      type: EnemyType.fast,
      health: 4, // Increased from 1
      damage: 15,
      speed: 120, // Decreased from 150
      xpReward: 15,
      scoreReward: 150,
      color: Colors.orange,
      size: 25,
      canShoot: true, // Fast enemies can shoot
      shootInterval: 1.5, // Shoots every 1.5 seconds
      bulletType: BulletType.rapid,
      defenseType: DefenseType.dodge, // Dodge-type defense
      defenseStrength: 0.3, // 30% chance to dodge
      behavior: EnemyBehavior.balanced,
      attackPatternFrequency: 2.0, // Changes pattern every 2 seconds
    ),
    EnemyType.heavy: EnemyData(
      type: EnemyType.heavy,
      health: 8, // Increased from 3
      damage: 35, // Increased from 25
      speed: 40, // Decreased from 50
      xpReward: 40, // Increased from 30
      scoreReward: 400, // Increased from 300
      color: Colors.purple,
      size: 45, // Increased from 40
      canShoot: true, // Heavy enemies can shoot
      shootInterval: 2.5, // Shoots every 2.5 seconds
      bulletType: BulletType.heavy,
      defenseType: DefenseType.block, // Block-type defense
      defenseStrength: 0.5, // 50% damage reduction
      behavior: EnemyBehavior.defensive,
    ),
    EnemyType.boss: EnemyData(
      type: EnemyType.boss,
      health: 20, // Increased from 10
      damage: 60, // Increased from 50
      speed: 25, // Decreased from 30
      xpReward: 150, // Increased from 100
      scoreReward: 1500, // Increased from 1000
      color: const Color(0xFF8B0000),
      size: 70, // Increased from 60
      canShoot: true, // Boss enemies can shoot
      shootInterval: 1.0, // Shoots every second
      bulletType: BulletType.spread, // Boss uses spread shots
      defenseType: DefenseType.parry, // Parry-type defense
      defenseStrength: 1.0, // 100% damage reduction for a short time
      attackPatternFrequency: 1.0, // Changes attack pattern every second
      behavior: EnemyBehavior.adaptive,
    ),
  };
}

class PowerUpData {
  final PowerUpType type;
  final String name;
  final String description;
  final Color color;
  final IconData icon;

  const PowerUpData({
    required this.type,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });

  static const Map<PowerUpType, PowerUpData> data = {
    PowerUpType.health: PowerUpData(
      type: PowerUpType.health,
      name: 'Health Boost',
      description: 'Restore 30 health points',
      color: Colors.green,
      icon: Icons.favorite,
    ),
    PowerUpType.speed: PowerUpData(
      type: PowerUpType.speed,
      name: 'Speed Boost',
      description: 'Increase movement speed',
      color: Colors.blue,
      icon: Icons.speed,
    ),
    PowerUpType.fireRate: PowerUpData(
      type: PowerUpType.fireRate,
      name: 'Rapid Fire',
      description: 'Increase firing rate',
      color: Colors.yellow,
      icon: Icons.whatshot,
    ),
    PowerUpType.damage: PowerUpData(
      type: PowerUpType.damage,
      name: 'Damage Boost',
      description: 'Increase bullet damage',
      color: Colors.red,
      icon: Icons.flash_on,
    ),
    PowerUpType.multiShot: PowerUpData(
      type: PowerUpType.multiShot,
      name: 'Multi Shot',
      description: 'Fire multiple bullets',
      color: Colors.purple,
      icon: Icons.scatter_plot,
    ),
    PowerUpType.shield: PowerUpData(
      type: PowerUpType.shield,
      name: 'Shield',
      description: 'Absorb damage with energy shield',
      color: Colors.cyan,
      icon: Icons.security,
    ),
    PowerUpType.dodge: PowerUpData(
      type: PowerUpType.dodge,
      name: 'Dodge System',
      description: 'Grant brief invincibility',
      color: Colors.orange,
      icon: Icons.flash_auto,
    ),
  };
}
