
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../../../shared/widgets/glass_widgets.dart';
import '../../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../profile/domain/entities/game_activity.dart' as activity;
import '../../../domain/entities/game.dart';

class DroneFlightGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const DroneFlightGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<DroneFlightGame> createState() => _DroneFlightGameState();
}

class _DroneFlightGameState extends State<DroneFlightGame>
    with TickerProviderStateMixin {
  int score = 0;
  int checkpointsCollected = 0;
  int totalCheckpoints = 5;
  bool gameCompleted = false;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Drone state
  Offset dronePosition = const Offset(0.1, 0.5);
  double droneVelocityX = 0.0;
  double droneVelocityY = 0.0;
  double droneRotation = 0.0;
  bool isDroneThrusting = false;
  late Size gameSize;

  // Game objects
  List<Obstacle> obstacles = [];
  List<Checkpoint> checkpoints = [];
  List<Particle> particles = [];

  // Physics
  double gravity = 0.0008;
  double thrust = 0.0015;
  double drag = 0.985;
  double maxSpeed = 0.01;

  // Animation controllers
  late AnimationController _gameAnimationController;
  late AnimationController _thrustController;
  late AnimationController _explosionController;
  late Timer _gameTimer;

  // Game state
  bool isGameRunning = false;
  bool crashed = false;
  double worldOffset = 0.0;
  double scrollSpeed = 0.002;

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    _configureDifficulty();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }

  void _configureDifficulty() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        gravity = 0.0005;
        scrollSpeed = 0.0015;
        totalCheckpoints = 3;
        break;
      case GameDifficulty.medium:
        gravity = 0.0008;
        scrollSpeed = 0.002;
        totalCheckpoints = 5;
        break;
      case GameDifficulty.hard:
        gravity = 0.001;
        scrollSpeed = 0.0025;
        totalCheckpoints = 7;
        break;
      case GameDifficulty.expert:
        gravity = 0.0012;
        scrollSpeed = 0.003;
        totalCheckpoints = 10;
        break;
    }
  }

  void _initializeAnimations() {
    _gameAnimationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _thrustController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _gameAnimationController.dispose();
    _thrustController.dispose();
    _explosionController.dispose();
    _gameTimer.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      score = 0;
      checkpointsCollected = 0;
      gameCompleted = false;
      crashed = false;
      dronePosition = const Offset(0.1, 0.5);
      droneVelocityX = 0.0;
      droneVelocityY = 0.0;
      droneRotation = 0.0;
      isDroneThrusting = false;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      isGameRunning = true;
      worldOffset = 0.0;
      obstacles.clear();
      checkpoints.clear();
      particles.clear();
    });

    _generateLevel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), _updateGame);
    _gameAnimationController.repeat();
  }

  void _generateLevel() {
    final rand = math.Random();

    // Generate obstacles
    for (int i = 0; i < 20; i++) {
      obstacles.add(
        Obstacle(
          position: Offset(
            0.3 + i * 0.4 + rand.nextDouble() * 0.2,
            rand.nextDouble() * 0.8 + 0.1,
          ),
          size: Size(
            0.05 + rand.nextDouble() * 0.05,
            0.1 + rand.nextDouble() * 0.1,
          ),
          type: ObstacleType.values[rand.nextInt(ObstacleType.values.length)],
        ),
      );
    }

    // Generate checkpoints
    for (int i = 0; i < totalCheckpoints; i++) {
      checkpoints.add(
        Checkpoint(
          position: Offset(0.5 + i * 1.5, 0.2 + rand.nextDouble() * 0.6),
          collected: false,
          id: i,
        ),
      );
    }
  }

  void _updateGame(Timer timer) {
    if (!isGameRunning || crashed || gameCompleted) return;

    setState(() {
      // Update world scrolling
      worldOffset += scrollSpeed;

      // Apply physics to drone
      if (isDroneThrusting) {
        droneVelocityY -= thrust;
        droneVelocityX += thrust * 0.3;
      }

      // Apply gravity
      droneVelocityY += gravity;

      // Apply drag
      droneVelocityX *= drag;
      droneVelocityY *= drag;

      // Limit speed
      droneVelocityX = droneVelocityX.clamp(-maxSpeed, maxSpeed);
      droneVelocityY = droneVelocityY.clamp(-maxSpeed, maxSpeed);

      // Update drone position
      dronePosition = Offset(
        dronePosition.dx + droneVelocityX,
        dronePosition.dy + droneVelocityY,
      );

      // Update drone rotation based on velocity
      droneRotation = math.atan2(droneVelocityY, droneVelocityX);

      // Check boundaries
      if (dronePosition.dy < 0 ||
          dronePosition.dy > 1 ||
          dronePosition.dx < 0 ||
          dronePosition.dx > 1) {
        _crashDrone();
        return;
      }

      // Check obstacle collisions
      for (Obstacle obstacle in obstacles) {
        if (_checkCollisionWithObstacle(obstacle)) {
          _crashDrone();
          return;
        }
      }

      // Check checkpoint collection
      for (Checkpoint checkpoint in checkpoints) {
        if (!checkpoint.collected &&
            _checkCollisionWithCheckpoint(checkpoint)) {
          checkpoint.collected = true;
          checkpointsCollected++;
          score += 100;

          // Add particle effect
          _addCheckpointParticles(checkpoint.position);
        }
      }

      // Update particles
      particles.removeWhere((particle) => particle.life <= 0);
      for (Particle particle in particles) {
        particle.update();
      }

      // Add thrust particles
      if (isDroneThrusting) {
        _addThrustParticles();
      }

      // Check win condition
      if (checkpointsCollected >= totalCheckpoints) {
        _completeGame();
        return;
      }

      // Update score based on distance
      score += 1;
      gameTime = DateTime.now().difference(gameStartTime);
    });
  }

  bool _checkCollisionWithObstacle(Obstacle obstacle) {
    const droneSize = 0.04;
    return (dronePosition.dx < obstacle.position.dx + obstacle.size.width) &&
        (dronePosition.dx + droneSize > obstacle.position.dx) &&
        (dronePosition.dy < obstacle.position.dy + obstacle.size.height) &&
        (dronePosition.dy + droneSize > obstacle.position.dy);
  }

  bool _checkCollisionWithCheckpoint(Checkpoint checkpoint) {
    const droneSize = 0.04;
    const checkpointSize = 0.06;
    return (dronePosition.dx < checkpoint.position.dx + checkpointSize) &&
        (dronePosition.dx + droneSize > checkpoint.position.dx) &&
        (dronePosition.dy < checkpoint.position.dy + checkpointSize) &&
        (dronePosition.dy + droneSize > checkpoint.position.dy);
  }

  void _addThrustParticles() {
    final rand = math.Random();
    for (int i = 0; i < 3; i++) {
      particles.add(
        Particle(
          position: Offset(
            dronePosition.dx - 0.02 + rand.nextDouble() * 0.01,
            dronePosition.dy + rand.nextDouble() * 0.02,
          ),
          velocity: Offset(
            -0.005 + rand.nextDouble() * 0.003,
            rand.nextDouble() * 0.004 - 0.002,
          ),
          color: Colors.orange,
          life: 30,
          maxLife: 30,
        ),
      );
    }
  }

  void _addCheckpointParticles(Offset position) {
    final rand = math.Random();
    for (int i = 0; i < 10; i++) {
      particles.add(
        Particle(
          position: position,
          velocity: Offset(
            rand.nextDouble() * 0.008 - 0.004,
            rand.nextDouble() * 0.008 - 0.004,
          ),
          color: Colors.green,
          life: 60,
          maxLife: 60,
        ),
      );
    }
  }

  void _addExplosionParticles() {
    final rand = math.Random();
    for (int i = 0; i < 20; i++) {
      particles.add(
        Particle(
          position: dronePosition,
          velocity: Offset(
            rand.nextDouble() * 0.01 - 0.005,
            rand.nextDouble() * 0.01 - 0.005,
          ),
          color: Colors.red,
          life: 80,
          maxLife: 80,
        ),
      );
    }
  }

  void _crashDrone() {
    setState(() {
      crashed = true;
      isGameRunning = false;
    });

    _addExplosionParticles();
    _explosionController.forward();
    _gameTimer.cancel();

    Future.delayed(const Duration(seconds: 2), () {
      _endGame(false);
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
      isGameRunning = false;
    });

    _gameTimer.cancel();
    _endGame(true);
  }

  void _endGame(bool won) async{
    final xpEarned = _calculateXP(won);

   await context.read<ProfileCubit>().addGameActivity(
      type: won
          ? activity.ActivityType.gameWin
          : activity.ActivityType.gameLoss,
      gameType: activity.GameType.droneFlight,
      difficulty: selectedDifficulty.name,
      xpEarned: xpEarned,
      metadata: {
        'score': score,
        'checkpoints_collected': checkpointsCollected,
        'total_checkpoints': totalCheckpoints,
        'time_seconds': gameTime.inSeconds,
        'crashed': crashed,
        'completed': won,
      },
    );

    if (mounted) {
      _showGameOverDialog(won);
    }
  }

  int _calculateXP(bool won) {
    int baseXP = won ? 30 : 15;
    int difficultyMultiplier = selectedDifficulty.index + 1;
    int performanceBonus = (checkpointsCollected * 10) + (score ~/ 100);

    if (won) {
      performanceBonus += 25;
    }

    return (baseXP * difficultyMultiplier) + performanceBonus;
  }

  void _showGameOverDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          won ? 'Mission Complete!' : 'Drone Crashed!',
          style: TextStyle(
            color: won ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won) ...[
              Icon(Icons.flight_takeoff, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Excellent piloting skills!',
                style: TextStyle(color: Colors.white),
              ),
            ] else ...[
              Icon(Icons.warning, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Practice makes perfect!',
                style: TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Final Score: $score',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Checkpoints: $checkpointsCollected/$totalCheckpoints',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Time: ${gameTime.inMinutes}:${(gameTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'XP Earned: ${_calculateXP(won)}',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Fly Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98D8E8), Color(0xFFB0E0E6)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              gameSize = Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                children: [
                  // Header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drone Flight',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${selectedDifficulty.name.toUpperCase()} - Checkpoints: $checkpointsCollected/$totalCheckpoints',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                'Score: $score',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Game area
                  Positioned(
                    top: 100.h,
                    left: 0,
                    right: 0,
                    bottom: 120.h,
                    child: CustomPaint(
                      painter: DroneGamePainter(
                        dronePosition: dronePosition,
                        droneRotation: droneRotation,
                        obstacles: obstacles,
                        checkpoints: checkpoints,
                        particles: particles,
                        worldOffset: worldOffset,
                        gameSize: gameSize,
                        crashed: crashed,
                        explosionAnimation: _explosionController.value,
                      ),
                      size: Size.infinite,
                    ),
                  ),

                  // Controls
                  Positioned(
                    bottom: 20.h,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Thrust control
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() => isDroneThrusting = true);
                              _thrustController.forward();
                            },
                            onTapUp: (_) {
                              setState(() => isDroneThrusting = false);
                              _thrustController.reverse();
                            },
                            onTapCancel: () {
                              setState(() => isDroneThrusting = false);
                              _thrustController.reverse();
                            },
                            child: AnimatedBuilder(
                              animation: _thrustController,
                              builder: (context, child) {
                                return GlassCard(
                                  child: Container(
                                    width: 120.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.r),
                                      gradient: isDroneThrusting
                                          ? const LinearGradient(
                                              colors: [
                                                Colors.orange,
                                                Colors.red,
                                              ],
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.rocket_launch,
                                            color: Colors.white,
                                            size: 24.w,
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'THRUST',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Game over overlay
                  if (crashed || gameCompleted)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                crashed ? Icons.warning : Icons.check_circle,
                                size: 64.sp,
                                color: crashed ? Colors.red : Colors.green,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                crashed ? 'Crashed!' : 'Mission Complete!',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class DroneGamePainter extends CustomPainter {
  final Offset dronePosition;
  final double droneRotation;
  final List<Obstacle> obstacles;
  final List<Checkpoint> checkpoints;
  final List<Particle> particles;
  final double worldOffset;
  final Size gameSize;
  final bool crashed;
  final double explosionAnimation;
  final double thrustPower; // For engine effects
  final double bankAngle; // For banking turns

  DroneGamePainter({
    required this.dronePosition,
    required this.droneRotation,
    required this.obstacles,
    required this.checkpoints,
    required this.particles,
    required this.worldOffset,
    required this.gameSize,
    required this.crashed,
    required this.explosionAnimation,
    this.thrustPower = 0.5,
    this.bankAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background clouds
    _drawClouds(canvas, size);

    // Draw obstacles
    for (Obstacle obstacle in obstacles) {
      _drawObstacle(canvas, size, obstacle);
    }

    // Draw checkpoints
    for (Checkpoint checkpoint in checkpoints) {
      _drawCheckpoint(canvas, size, checkpoint);
    }

    // Draw particles
    for (Particle particle in particles) {
      _drawParticle(canvas, size, particle);
    }

    // Draw drone
    if (!crashed) {
      _drawB2Drone(canvas, size);
    } else {
      _drawExplosion(canvas, size);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Simple cloud shapes
    for (int i = 0; i < 5; i++) {
      double x = (i * 0.3 - worldOffset * 0.5) % 1.2;
      double y = 0.1 + (i % 3) * 0.2;

      canvas.drawCircle(Offset(x * size.width, y * size.height), 30, paint);
    }
  }

  void _drawObstacle(Canvas canvas, Size size, Obstacle obstacle) {
    final paint = Paint()
      ..color = _getObstacleColor(obstacle.type)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
      obstacle.position.dx * size.width,
      obstacle.position.dy * size.height,
      obstacle.size.width * size.width,
      obstacle.size.height * size.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }

  void _drawCheckpoint(Canvas canvas, Size size, Checkpoint checkpoint) {
    if (checkpoint.collected) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(
      checkpoint.position.dx * size.width,
      checkpoint.position.dy * size.height,
    );

    canvas.drawCircle(center, 25, paint);

    // Draw inner circle
    paint.color = Colors.lightGreen.withOpacity(0.5);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, paint);
  }

  void _drawParticle(Canvas canvas, Size size, Particle particle) {
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.life / particle.maxLife)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height,
      ),
      2,
      paint,
    );
  }

  void _drawB2Drone(Canvas canvas, Size size) {
    final center = Offset(
      dronePosition.dx * size.width,
      dronePosition.dy * size.height,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(droneRotation);
    
    // Add banking effect
    canvas.scale(1.0, cos(bankAngle));

    // Draw engine exhaust trails
    _drawEngineExhaust(canvas);

    // Draw main body (B-2 Spirit shape)
    _drawB2Body(canvas);

    // Draw cockpit
    _drawCockpit(canvas);

    // Draw Air Force markings
    _drawAirForceMarkings(canvas);

    // Draw navigation lights
    _drawNavigationLights(canvas);

    canvas.restore();
  }

  void _drawEngineExhaust(Canvas canvas) {
    final exhaustPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6 * thrustPower)
      ..style = PaintingStyle.fill;

    final exhaustGradient = RadialGradient(
      colors: [
        Colors.blue.withOpacity(0.8 * thrustPower),
        Colors.cyan.withOpacity(0.4 * thrustPower),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // Engine positions for B-2 (4 engines)
    final enginePositions = [
      const Offset(-25, -5),
      const Offset(-15, -5),
      const Offset(15, -5),
      const Offset(25, -5),
    ];

    for (final pos in enginePositions) {
      final exhaustRect = Rect.fromCenter(
        center: pos,
        width: 8,
        height: 20 * thrustPower,
      );

      exhaustPaint.shader = exhaustGradient.createShader(exhaustRect);
      canvas.drawOval(exhaustRect, exhaustPaint);
    }
  }

  void _drawB2Body(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF2C3E50) // Dark gray like B-2
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw shadow first
    canvas.save();
    canvas.translate(2, 2);
    _drawB2Shape(canvas, shadowPaint);
    canvas.restore();

    // Draw main body
    _drawB2Shape(canvas, bodyPaint);

    // Add gradient shading
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF34495E),
          Color(0xFF2C3E50),
          Color(0xFF1B2631),
        ],
      ).createShader(const Rect.fromLTWH(-40, -20, 80, 40));

    _drawB2Shape(canvas, gradientPaint);
  }

  void _drawB2Shape(Canvas canvas, Paint paint) {
    final path = Path();
    
    // B-2 Spirit wing shape
    path.moveTo(0, -15); // Nose
    path.quadraticBezierTo(-10, -12, -30, -8); // Left wing leading edge
    path.quadraticBezierTo(-45, -5, -40, 5); // Left wing tip
    path.quadraticBezierTo(-35, 12, -20, 15); // Left wing trailing edge
    path.quadraticBezierTo(-10, 18, 0, 15); // Center trailing edge
    path.quadraticBezierTo(10, 18, 20, 15); // Right wing trailing edge
    path.quadraticBezierTo(35, 12, 40, 5); // Right wing tip
    path.quadraticBezierTo(45, -5, 30, -8); // Right wing leading edge
    path.quadraticBezierTo(10, -12, 0, -15); // Back to nose
    
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCockpit(Canvas canvas) {
    final cockpitPaint = Paint()
      ..color = const Color(0xFF1A252F)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Main cockpit
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -12, 16, 15),
        const Radius.circular(4),
      ),
      cockpitPaint,
    );

    // Cockpit glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -10, 12, 10),
        const Radius.circular(3),
      ),
      glowPaint,
    );
  }

  void _drawAirForceMarkings(Canvas canvas) {
    final markingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // US Air Force star (simplified)
    _drawStar(canvas, const Offset(-15, 0), 6, markingPaint);
    _drawStar(canvas, const Offset(15, 0), 6, markingPaint);

    // Text paint for USAF
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'USAF',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(-15, 8));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const int points = 5;
    final double angle = 2 * pi / points;
    
    for (int i = 0; i < points; i++) {
      final double x = center.dx + radius * cos(i * angle - pi / 2);
      final double y = center.dy + radius * sin(i * angle - pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final double innerX = center.dx + (radius * 0.4) * cos((i + 0.5) * angle - pi / 2);
      final double innerY = center.dy + (radius * 0.4) * sin((i + 0.5) * angle - pi / 2);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNavigationLights(Canvas canvas) {
    final redLight = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final greenLight = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final whiteLight = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Port (left) red light
    canvas.drawCircle(const Offset(-35, 0), 2, redLight);
    
    // Starboard (right) green light
    canvas.drawCircle(const Offset(35, 0), 2, greenLight);
    
    // Tail white light
    canvas.drawCircle(const Offset(0, 12), 2, whiteLight);
  }

  void _drawExplosion(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(1 - explosionAnimation)
      ..style = PaintingStyle.fill;

    final center = Offset(
      dronePosition.dx * size.width,
      dronePosition.dy * size.height,
    );

    // Multiple explosion rings
    for (int i = 0; i < 3; i++) {
      final radius = (20 + i * 15) * (1 + explosionAnimation);
      final opacity = (1 - explosionAnimation) * (1 - i * 0.3);
      
      paint.color = [Colors.orange, Colors.red, Colors.yellow][i]
          .withOpacity(max(0.0, opacity));
      
      canvas.drawCircle(center, radius, paint);
    }

    // Debris particles
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + explosionAnimation * pi;
      final distance = 30 * explosionAnimation;
      final debrisPos = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      
      paint.color = Colors.grey.withOpacity(1 - explosionAnimation);
      canvas.drawCircle(debrisPos, 3, paint);
    }
  }

  Color _getObstacleColor(ObstacleType type) {
    switch (type) {
      case ObstacleType.building:
        return Colors.grey.shade600;
      case ObstacleType.mountain:
        return Colors.brown.shade400;
      case ObstacleType.tower:
        return Colors.red.shade400;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced movement controller class
class DroneMovementController {
  double _velocity = 0.0;
  double _angularVelocity = 0.0;
  double _bankAngle = 0.0;
  double _thrustPower = 0.5;
  
  static const double maxSpeed = 0.008;
  static const double acceleration = 0.0002;
  static const double turnSpeed = 0.05;
  static const double bankSpeed = 0.02;
  static const double drag = 0.98;
  
  double get velocity => _velocity;
  double get angularVelocity => _angularVelocity;
  double get bankAngle => _bankAngle;
  double get thrustPower => _thrustPower;

  void update(bool thrustUp, bool turnLeft, bool turnRight) {
    // Thrust control
    if (thrustUp) {
      _velocity = min(maxSpeed, _velocity + acceleration);
      _thrustPower = min(1.0, _thrustPower + 0.02);
    } else {
      _velocity *= drag;
      _thrustPower = max(0.2, _thrustPower - 0.01);
    }

    // Turn control with realistic banking
    if (turnLeft) {
      _angularVelocity = max(-turnSpeed, _angularVelocity - 0.001);
      _bankAngle = max(-0.5, _bankAngle - bankSpeed);
    } else if (turnRight) {
      _angularVelocity = min(turnSpeed, _angularVelocity + 0.001);
      _bankAngle = min(0.5, _bankAngle + bankSpeed);
    } else {
      _angularVelocity *= 0.95; // Gradual stop
      _bankAngle *= 0.9; // Return to level
    }
  }

  Offset updatePosition(Offset currentPosition, double currentRotation) {
    final dx = cos(currentRotation) * _velocity;
    final dy = sin(currentRotation) * _velocity;
    
    return Offset(
      currentPosition.dx + dx,
      currentPosition.dy + dy,
    );
  }
}

// Existing classes remain the same
class Obstacle {
  final Offset position;
  final Size size;
  final ObstacleType type;

  Obstacle({required this.position, required this.size, required this.type});
}

class Checkpoint {
  final Offset position;
  bool collected;
  final int id;

  Checkpoint({
    required this.position,
    required this.collected,
    required this.id,
  });
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double life;
  double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.maxLife,
  });

  void update() {
    position = Offset(position.dx + velocity.dx, position.dy + velocity.dy);
    life--;
  }
}

enum ObstacleType { building, mountain, tower }