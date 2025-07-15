import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DroneFlightGame extends StatefulWidget {
  final GameDifficulty difficulty;
  
  const DroneFlightGame({Key? key, required this.difficulty}) : super(key: key);
  
  @override
  State<DroneFlightGame> createState() => _DroneFlightGameState();
}

class _DroneFlightGameState extends State<DroneFlightGame>
    with TickerProviderStateMixin {
  late Size gameSize;
  
  // Game state
  bool isGameRunning = false;
  bool gameOver = false;
  bool won = false;
  
  // Scoring
  int score = 0;
  int checkpointsCollected = 0;
  int totalCheckpoints = 5;
  late DateTime gameStartTime;
  late Duration gameTime;
  
  // Physics parameters (adjusted for better control)
  double gravity = 0.001;
  double maxSpeed = 0.02;
  double drag = 0.98;
  double thrustPower=0;
  // Drone properties
  Offset dronePosition = const Offset(0.1, 0.5);
  double droneVelocityX =0.0;
  double droneVelocityY = 0.0;
  double droneRotation = 0.0;
  bool isThrusting = false;
  
  // Game elements
  List<Obstacle> obstacles = [];
  List<Checkpoint> checkpoints = [];
  List<Particle> particles = [];
  
  // Animation controllers
  late AnimationController _gameController;
 late AnimationController _thrustAnimationController;
  late AnimationController _explosionAnimationController;
  late Timer _gameTimer;
  
  // Difficulty settings
  late GameDifficulty selectedDifficulty;
  
  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    _configureDifficulty();
    
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
    
    _thrustAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _explosionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }
  
  void _configureDifficulty() {
    switch(selectedDifficulty) {
      case GameDifficulty.easy:
        gravity = 0.0008;
        thrustPower = 0.012;
        totalCheckpoints = 3;
        break;
      case GameDifficulty.medium:
        gravity = 0.001;
        thrustPower = 0.015;
        totalCheckpoints = 5;
        break;
      case GameDifficulty.hard:
        gravity = 0.0015;
        thrustPower = 0.018;
        totalCheckpoints = 7;
        break;
      case GameDifficulty.expert:
        gravity = 0.002;
        thrustPower = 0.02;
        totalCheckpoints = 10;
        break;
    }
  }
  
  void _startGame() {
    setState(() {
      score = 0;
      checkpointsCollected = 0;
      gameOver = false;
      won = false;
      dronePosition = const Offset(0.1, 0.5);
      droneVelocityX = 0.0;
      droneVelocityY = 0.0;
      droneRotation = 0.0;
      isThrusting = false;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      isGameRunning = true;
      obstacles.clear();
      checkpoints.clear();
      particles.clear();
    });
    
    _generateLevel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _updateGame);
    _gameController.repeat();
  }
  
  void _generateLevel() {
    final rand = math.Random();
    
    // Generate obstacles that move horizontally across the screen
    for (int i = 0; i < 15; i++) {
      final double xPosition = 0.3 + i * 0.5 + rand.nextDouble() * 0.2;
      final double yPosition = rand.nextDouble() * 0.8 + 0.1;
      
      obstacles.add(
        Obstacle(
          position: Offset(xPosition, yPosition),
          size: Size(
            0.06 + rand.nextDouble() * 0.04,
            0.1 + rand.nextDouble() * 0.1,
          ),
          type: ObstacleType.values[rand.nextInt(ObstacleType.values.length)],
          horizontalSpeed: -0.002 - (rand.nextDouble() * 0.003),
        ),
      );
    }
    
    // Generate checkpoints in a more challenging vertical pattern
    for (int i = 0; i < totalCheckpoints; i++) {
      final double xPosition = 0.5 + i * 1.2;
      final double yPosition = 0.3 + (sin(i * 0.8) + 1) / 4; // Sinusoidal path
      
      checkpoints.add(
        Checkpoint(
          position: Offset(xPosition, yPosition),
          collected: false,
          id: i,
        ),
      );
    }
  }
  
  void _updateGame(Timer timer) {
    if (!isGameRunning || gameOver) return;
    
    setState(() {
      // Apply thrust when active
      if (isThrusting) {
        droneVelocityY -= thrustPower;
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
      
      // Update obstacle positions
      for (var obstacle in obstacles) {
        obstacle.position = Offset(
          obstacle.position.dx + obstacle.horizontalSpeed,
          obstacle.position.dy,
        );
      }
      
      // Check boundaries
      if (dronePosition.dy < 0 || dronePosition.dy > 1) {
        _handleGameOver(false);
        return;
      }
      
      // Check obstacle collisions

      for (Obstacle obstacle in obstacles) {
        if (_checkCollisionWithObstacle(obstacle)) {
          _handleGameOver(false);
          return;
        }
      }
      
      // Check checkpoint collection
      for (Checkpoint checkpoint in checkpoints) {
        if (!checkpoint.collected && _checkCollisionWithCheckpoint(checkpoint)) {
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
      if (isThrusting) {
        _addThrustParticles();
      }
      
      // Check win condition
      if (checkpointsCollected >= totalCheckpoints) {
        _handleWin();
        return;
      }
      
      // Update score based on distance and time
      score += 1;
      gameTime = DateTime.now().difference(gameStartTime);
    });
  }
  
  void _handleGameOver(bool won) {
    setState(() {
      gameOver = true;
      this.won = won;
      isGameRunning = false;
    });
    
    _addExplosionParticles();
    _explosionAnimationController.forward();
    _gameTimer.cancel();
    
    Future.delayed(const Duration(seconds: 2), () {
      _showGameOverDialog(won);
    });
  }
  
  void _handleWin() {
    _handleGameOver(true);
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
  
  bool _checkCollisionWithObstacle(Obstacle obstacle) {
    const droneSize = 0.03; // Smaller drone size for better collision detection
    return (dronePosition.dx < obstacle.position.dx + obstacle.size.width) &&
        (dronePosition.dx + droneSize > obstacle.position.dx) &&
        (dronePosition.dy < obstacle.position.dy + obstacle.size.height) &&
        (dronePosition.dy + droneSize > obstacle.position.dy);
  }
  
  bool _checkCollisionWithCheckpoint(Checkpoint checkpoint) {
    const droneSize = 0.03;
    const checkpointSize = 0.05;
    return (dronePosition.dx < checkpoint.position.dx + checkpointSize) &&
        (dronePosition.dx + droneSize > checkpoint.position.dx) &&
        (dronePosition.dy < checkpoint.position.dy + checkpointSize) &&
        (dronePosition.dy + droneSize > checkpoint.position.dy);
  }
  
  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          'How to Play',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              'Tap and hold the screen to make the drone fly upward.\n\nRelease to let it fall due to gravity.\n\nCollect all $totalCheckpoints checkpoints to win!\n\nAvoid hitting any obstacles!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: Text('Start Game'),
          ),
        ],
      ),
    );
  }
  
  void _showGameOverDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          won ? 'Mission Complete!' : 'Game Over',
          style: TextStyle(
            color: won ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.check_circle : Icons.warning,
              size: 48,
              color: won ? Colors.green : Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              won 
                ? 'Excellent flying skills!' 
                : 'Better luck next time!',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text(
              'Final Score: $score',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Checkpoints: $checkpointsCollected/$totalCheckpoints',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'Time: ${gameTime.inMinutes}:${(gameTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Exit'),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.cyan.shade200, Colors.blue.shade300],
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
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
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
                                  'Sky Runner',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedDifficulty.name.toUpperCase()} - Collect All Checkpoints!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'Score: $score',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Status indicators
                  Positioned(
                    top: 80.h,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusIndicator(
                            context, 
                            'Time', 
                            '${gameTime.inMinutes}:${(gameTime.inSeconds % 60).toString().padLeft(2, '0')}',
                            Colors.blueAccent,
                          ),
                          _buildStatusIndicator(
                            context, 
                            'Altitude', 
                            '${(dronePosition.dy * 100).toInt()}m',
                            Colors.greenAccent,
                          ),
                          _buildStatusIndicator(
                            context, 
                            'Checkpoints', 
                            '$checkpointsCollected/$totalCheckpoints',
                            Colors.yellowAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Game area
                  Positioned(
                    top: 120.h,
                    left: 0,
                    right: 0,
                    bottom: 100.h,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (!isGameRunning || gameOver) return;
                        
                        if (details.delta.dy < 0) {
                          setState(() {
                            isThrusting = true;
                          });
                          _thrustAnimationController.forward();
                        } else {
                          setState(() {
                            isThrusting = false;
                          });
                          _thrustAnimationController.reverse();
                        }
                      },
                      onVerticalDragEnd: (details) {
                        setState(() {
                          isThrusting = false;
                        });
                        _thrustAnimationController.reverse();
                      },
                      child: CustomPaint(
                        painter: DroneGamePainter(
                          dronePosition: dronePosition,
                          droneRotation: droneRotation,
                          obstacles: obstacles,
                          checkpoints: checkpoints,
                          particles: particles,
                          gameSize: gameSize,
                          gameOver: gameOver,
                          explosionAnimation: _explosionAnimationController.value,
                          thrustPower: _thrustAnimationController.value,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  
                  // Controls instruction
                  Positioned(
                    bottom: 150.h,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(seconds: 1),
                      opacity: !isGameRunning ? 0 : 1,
                      child: Center(
                        child: Text(
                          'Swipe Up to Thrust\nSwipe Down to Descend',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Game over overlay
                  if (gameOver)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                won ? Icons.check_circle : Icons.warning,
                                size: 64.sp,
                                color: won ? Colors.green : Colors.red,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                won ? 'Mission Complete!' : 'Crashed!',
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
  
  Widget _buildStatusIndicator(BuildContext context, String title, String value, Color color) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
  final Size gameSize;
  final bool gameOver;
  final double explosionAnimation;
  final double thrustPower;
  
  DroneGamePainter({
   required this.dronePosition,
    required this.droneRotation,
    required this.obstacles,
    required this.checkpoints,
    required this.particles,
    required this.gameSize,
    required this.gameOver,
    required this.explosionAnimation,
    required this.thrustPower,
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
    if (!gameOver) {
      _drawDrone(canvas, size);
    } else {
      _drawExplosion(canvas, size);
    }
  }
  
  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // Simple cloud shapes with parallax effect
    for (int i = 0; i < 5; i++) {
      double x = (i * 0.3 - dronePosition.dx * 0.3) % 1.2;
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
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.01)),
      paint,
    );
  }
  
  void _drawCheckpoint(Canvas canvas, Size size, Checkpoint checkpoint) {
    if (checkpoint.collected) return;
    
    final center = Offset(
      checkpoint.position.dx * size.width,
      checkpoint.position.dy * size.height,
    );
    
    // Pulsing glow effect
    final double pulseFactor = 0.5 + 0.5 * sin(2 * pi * (DateTime.now().millisecondsSinceEpoch / 1000));
    
    final outerPaint = Paint()
      ..color = Colors.green.withOpacity(0.4 * pulseFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
    final innerPaint = Paint()
      ..color = Colors.lightGreen.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 25, outerPaint);
    canvas.drawCircle(center, 15, innerPaint);
    
    // Draw rotating check mark
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(2 * pi * (DateTime.now().millisecondsSinceEpoch / 3000));
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final path = Path();
    path.moveTo(-5, 0);
    path.lineTo(0, 5);
    path.lineTo(7, -5);
    canvas.drawPath(path, checkPaint);
    canvas.restore();
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
  
  void _drawDrone(Canvas canvas, Size size) {
    final center = Offset(
      dronePosition.dx * size.width,
      dronePosition.dy * size.height,
    );
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(droneRotation);
    
    // Draw engine exhaust trails
    _drawEngineExhaust(canvas, size);
    
    // Draw main body
    _drawDroneBody(canvas, size);
    
    // Draw propellers
    _drawPropellers(canvas);
    
    canvas.restore();
  }
  
  void _drawEngineExhaust(Canvas canvas, Size size) {
    final exhaustPaint = Paint()
      ..color = Colors.orange.withOpacity(0.6 * thrustPower)
      ..style = PaintingStyle.fill;
    
    final exhaustGradient = RadialGradient(
      colors: [
        Colors.orange.withOpacity(0.8 * thrustPower),
        Colors.red.withOpacity(0.4 * thrustPower),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    // Engine positions (underneath the drone)
    final enginePositions = [
      const Offset(-10, 15),
      const Offset(10, 15),
    ];
    
    for (final pos in enginePositions) {
      final exhaustRect = Rect.fromCenter(
        center: pos,
        width: 6,
        height: 20 * thrustPower,
      );
      exhaustPaint.shader = exhaustGradient.createShader(exhaustRect);
      canvas.drawOval(exhaustRect, exhaustPaint);
    }
  }
  
  void _drawDroneBody(Canvas canvas, Size size) {
    // Main body (smaller and more aerodynamic)
    final bodyPaint = Paint()
      ..color = const Color(0xFF34495E)
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Shadow
    canvas.save();
    canvas.translate(2, 2);
    final shadowPath = Path();
    shadowPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 20),
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ));
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
    
    // Main body
    final bodyPath = Path();
    bodyPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 20),
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ));
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Cockpit window
    final cockpitPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 12),
      cockpitPaint,
    );
  }
  
  void _drawPropellers(Canvas canvas) {
    final bladePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Propeller positions
    final propellerPositions = [
      const Offset(-15, -10),
      const Offset(15, -10),
    ];
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final rotationAngle = (now % 1000) / 1000 * 2 * pi;
    
    for (final pos in propellerPositions) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotationAngle);
      
      // Draw propeller hub
      canvas.drawCircle(Offset.zero, 3, bladePaint);
      
      // Draw blades
      for (int i = 0; i < 2; i++) {
        canvas.rotate(pi);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 16, height: 2),
          bladePaint,
        );
      }
      
      canvas.restore();
    }
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

// Existing classes remain unchanged
class Obstacle {
  late final Offset position;
  final Size size;
  final ObstacleType type;
  final double horizontalSpeed;
  
  Obstacle({
    required this.position,
    required this.size,
    required this.type,
    required this.horizontalSpeed,
  });
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

enum GameDifficulty { easy, medium, hard, expert }