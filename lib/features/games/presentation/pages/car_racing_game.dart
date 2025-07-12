import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import '../../domain/entities/game.dart';

class CarRacingGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const CarRacingGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<CarRacingGame> createState() => _CarRacingGameState();
}

class _CarRacingGameState extends State<CarRacingGame>
    with TickerProviderStateMixin {
  int score = 0;
  int distance = 0;
  int lap = 1;
  int maxLaps = 3;
  bool gameCompleted = false;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Car state
  double carX = 0.5; // Position from 0.0 to 1.0 across screen width
  double carY = 0.8; // Fixed position from top
  double carSpeed = 0.0;
  late Size boardSize;

  // Obstacles
  List<Obstacle> obstacles = [];
  double obstacleSpeed = 2.0;
  int obstaclesAvoided = 0;

  // Game mechanics
  late AnimationController _gameAnimationController;
  late AnimationController _explosionController;
  late Timer _gameTimer;
  bool isGameRunning = false;
  bool crashed = false;
  double roadOffset = 0.0;

  // Controls
  double steeringInput = 0.0;
  bool accelerating = false;

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
        obstacleSpeed = 1.5;
        maxLaps = 2;
        break;
      case GameDifficulty.medium:
        obstacleSpeed = 2.0;
        maxLaps = 3;
        break;
      case GameDifficulty.hard:
        obstacleSpeed = 2.5;
        maxLaps = 4;
        break;
      case GameDifficulty.expert:
        obstacleSpeed = 3.0;
        maxLaps = 5;
        break;
    }
  }

  void _initializeAnimations() {
    _gameAnimationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _gameAnimationController.dispose();
    _explosionController.dispose();
    _gameTimer.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      score = 0;
      distance = 0;
      lap = 1;
      gameCompleted = false;
      crashed = false;
      carX = 0.5;
      carSpeed = 0.0;
      obstacles.clear();
      obstaclesAvoided = 0;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      isGameRunning = true;
      roadOffset = 0.0;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), _updateGame);
    _gameAnimationController.repeat();
  }

  void _updateGame(Timer timer) {
    if (!isGameRunning || crashed || gameCompleted) return;

    setState(() {
      // Update road animation
      roadOffset += obstacleSpeed * 0.5;
      if (roadOffset > 100) roadOffset = 0;

      // Update car physics
      if (accelerating) {
        carSpeed = math.min(carSpeed + 0.02, 1.0);
      } else {
        carSpeed = math.max(carSpeed - 0.05, 0.0);
      }

      // Apply steering
      carX += steeringInput * 0.03;
      carX = math.max(0.1, math.min(0.9, carX));

      // Update distance and score
      distance += (carSpeed * 10).round();
      score = distance ~/ 10;

      // Check lap completion
      if (distance >= 1000 * lap) {
        lap++;
        if (lap > maxLaps) {
          _completeGame();
          return;
        }
      }

      // Spawn obstacles
      if (math.Random().nextDouble() < 0.05) {
        _spawnObstacle();
      }

      // Update obstacles
      for (int i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].y += obstacleSpeed * 0.02;

        if (obstacles[i].y > 1.0) {
          obstacles.removeAt(i);
          obstaclesAvoided++;
          score += 10;
        } else if (_checkCollision(obstacles[i])) {
          _crashCar();
          return;
        }
      }

      gameTime = DateTime.now().difference(gameStartTime);
    });
  }

  void _spawnObstacle() {
    final rand = math.Random();
    obstacles.add(
      Obstacle(
        x: 0.2 + rand.nextDouble() * 0.6, // Stay within road bounds
        y: -0.1,
        type: ObstacleType.values[rand.nextInt(ObstacleType.values.length)],
      ),
    );
  }

  bool _checkCollision(Obstacle obstacle) {
    const carWidth = 0.08;
    const carHeight = 0.12;
    const obstacleSize = 0.06;

    return (carX - carWidth / 2 < obstacle.x + obstacleSize / 2) &&
        (carX + carWidth / 2 > obstacle.x - obstacleSize / 2) &&
        (carY - carHeight / 2 < obstacle.y + obstacleSize / 2) &&
        (carY + carHeight / 2 > obstacle.y - obstacleSize / 2);
  }

  void _crashCar() {
    setState(() {
      crashed = true;
      isGameRunning = false;
    });

    _explosionController.forward();
    _gameTimer.cancel();

    Future.delayed(const Duration(seconds: 2), () {
      _endGame();
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
      isGameRunning = false;
    });

    _gameTimer.cancel();
    _endGame();
  }

  void _endGame() {
    final xpEarned = _calculateXP();

    context.read<ProfileCubit>().addGameActivity(
      type: gameCompleted
          ? activity.ActivityType.gameWin
          : activity.ActivityType.gameLoss,
      gameType: activity.GameType.racingRush,
      difficulty: selectedDifficulty.name,
      xpEarned: xpEarned,
      metadata: {
        'score': score,
        'laps_completed': lap - 1,
        'max_laps': maxLaps,
        'obstacles_avoided': obstaclesAvoided,
        'distance': distance,
        'crashed': crashed,
        'completed': gameCompleted,
        'play_time_seconds': gameTime.inSeconds,
      },
    );

    if (mounted) {
      _showGameOverDialog();
    }
  }

  int _calculateXP() {
    int baseXP = 15;
    int difficultyMultiplier = selectedDifficulty.index + 1;
    int performanceBonus = (obstaclesAvoided * 2) + (lap - 1) * 10;

    if (gameCompleted) {
      performanceBonus += 25;
    }

    return (baseXP * difficultyMultiplier) + performanceBonus;
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          gameCompleted ? 'Race Complete!' : 'Race Over!',
          style: TextStyle(
            color: gameCompleted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gameCompleted) ...[
              Icon(Icons.emoji_events, color: Colors.orange, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Congratulations!',
                style: TextStyle(color: Colors.white),
              ),
            ] else ...[
              Icon(Icons.warning, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Better luck next time!',
                style: TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Final Score: $score',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Laps: ${lap - 1}/$maxLaps',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Obstacles Avoided: $obstaclesAvoided',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Time: ${gameTime.inMinutes}:${(gameTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'XP Earned: ${_calculateXP()}',
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
            child: const Text('Play Again'),
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
    boardSize = Size(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF1E3C72)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Racing Track
              Container(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(painter: RaceTrackPainter(roadOffset)),
              ),

              // Game content
              Positioned.fill(
                child: Column(
                  children: [
                    // Top UI
                    Container(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          GlassCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                'Lap: $lap/$maxLaps',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          GlassCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                'Speed: ${(carSpeed * 100).round()}',
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

                    // Game area
                    Expanded(
                      child: Stack(
                        children: [
                          // Player car
                          if (!crashed)
                            Positioned(
                              left: carX * boardSize.width - 20.w,
                              top: carY * (boardSize.height - 200.h),
                              child: Container(
                                width: 40.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          // Obstacles
                          ...obstacles.map(
                            (obstacle) => Positioned(
                              left: obstacle.x * boardSize.width - 15.w,
                              top: obstacle.y * (boardSize.height - 200.h),
                              child: Container(
                                width: 30.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: _getObstacleColor(obstacle.type),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  _getObstacleIcon(obstacle.type),
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                          ),

                          // Explosion effect
                          if (crashed)
                            Positioned(
                              left: carX * boardSize.width - 30.w,
                              top: carY * (boardSize.height - 200.h) - 10.h,
                              child: AnimatedBuilder(
                                animation: _explosionController,
                                builder: (context, child) {
                                  return Container(
                                    width:
                                        60.w * (1 + _explosionController.value),
                                    height:
                                        60.h * (1 + _explosionController.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.orange.withOpacity(
                                        1 - _explosionController.value,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.whatshot,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Controls
                    Container(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left steering
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => steeringInput = -1.0),
                            onTapUp: (_) => setState(() => steeringInput = 0.0),
                            onTapCancel: () =>
                                setState(() => steeringInput = 0.0),
                            child: GlassCard(
                              child: Container(
                                width: 60.w,
                                height: 60.h,
                                child: const Icon(
                                  Icons.arrow_left,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),

                          // Accelerate
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => accelerating = true),
                            onTapUp: (_) =>
                                setState(() => accelerating = false),
                            onTapCancel: () =>
                                setState(() => accelerating = false),
                            child: GlassCard(
                              child: Container(
                                width: 80.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  gradient: accelerating
                                      ? const LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.lightGreen,
                                          ],
                                        )
                                      : null,
                                ),
                                child: const Icon(
                                  Icons.speed,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),

                          // Right steering
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => steeringInput = 1.0),
                            onTapUp: (_) => setState(() => steeringInput = 0.0),
                            onTapCancel: () =>
                                setState(() => steeringInput = 0.0),
                            child: GlassCard(
                              child: Container(
                                width: 60.w,
                                height: 60.h,
                                child: const Icon(
                                  Icons.arrow_right,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Back button
              Positioned(
                top: 20.h,
                left: 20.w,
                child: GlassCard(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48.w,
                    height: 48.h,
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getObstacleColor(ObstacleType type) {
    switch (type) {
      case ObstacleType.car:
        return Colors.blue;
      case ObstacleType.truck:
        return Colors.grey;
      case ObstacleType.cone:
        return Colors.orange;
    }
  }

  IconData _getObstacleIcon(ObstacleType type) {
    switch (type) {
      case ObstacleType.car:
        return Icons.directions_car;
      case ObstacleType.truck:
        return Icons.local_shipping;
      case ObstacleType.cone:
        return Icons.traffic;
    }
  }
}

class Obstacle {
  double x;
  double y;
  final ObstacleType type;

  Obstacle({required this.x, required this.y, required this.type});
}

enum ObstacleType { car, truck, cone }

class RaceTrackPainter extends CustomPainter {
  final double roadOffset;

  RaceTrackPainter(this.roadOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw road
    paint.color = Colors.grey[800]!;
    final roadRect = Rect.fromLTWH(
      size.width * 0.15,
      0,
      size.width * 0.7,
      size.height,
    );
    canvas.drawRect(roadRect, paint);

    // Draw road sides
    paint.color = Colors.green[800]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.15, size.height), paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.85, 0, size.width * 0.15, size.height),
      paint,
    );

    // Draw center line
    paint.color = Colors.yellow;
    paint.strokeWidth = 3;
    final centerX = size.width * 0.5;
    final dashHeight = 20.0;
    final dashGap = 15.0;

    for (
      double y = -roadOffset;
      y < size.height + dashHeight;
      y += dashHeight + dashGap
    ) {
      canvas.drawLine(
        Offset(centerX, y),
        Offset(centerX, y + dashHeight),
        paint,
      );
    }

    // Draw road edges
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.15, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, 0),
      Offset(size.width * 0.85, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(RaceTrackPainter oldDelegate) {
    return oldDelegate.roadOffset != roadOffset;
  }
}
