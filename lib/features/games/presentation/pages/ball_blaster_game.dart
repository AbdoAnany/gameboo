import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import '../../domain/entities/game.dart';

class BallBlasterGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const BallBlasterGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<BallBlasterGame> createState() => _BallBlasterGameState();
}

class _BallBlasterGameState extends State<BallBlasterGame>
    with TickerProviderStateMixin {
  int score = 0;
  int shots = 0;
  int missed = 0;
  bool gameCompleted = false;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Ball state
  Offset? ballPosition;
  double ballRadius = 28.0;
  bool ballVisible = false;
  bool isAnimating = false;
  late Size boardSize;
  late int maxShots;

  // Enhanced mechanics
  late AnimationController _ballAnimationController;
  late AnimationController _hitAnimationController;
  late AnimationController _missAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _ballScaleAnimation;
  late Animation<double> _ballOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  bool _showHitEffect = false;
  bool _showMissEffect = false;
  Offset? _hitEffectPosition;
  int _ballSpeed = 1000; // milliseconds
  double _ballScale = 1.0;

  // Target preview and performance tracking
  bool _showTargetPreview = true;
  Offset? _nextBallPosition;
  List<Offset> _stars = [];
  double _accuracyRate = 1.0;
  int _recentHits = 0;
  int _recentShots = 0;
  DateTime _lastPerformanceCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    maxShots = 20 + selectedDifficulty.index * 5;
    _initializeAnimations();
    _configureDifficulty();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }

  void _initializeAnimations() {
    _ballAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _missAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _ballScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ballAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _ballOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_ballAnimationController);

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    // Generate star field
    _generateStars();
  }

  void _generateStars() {
    _stars.clear();
    final rand = math.Random();
    for (int i = 0; i < 50; i++) {
      _stars.add(
        Offset(
          rand.nextDouble() * 800.0, // Use larger canvas for stars
          rand.nextDouble() * 1000.0,
        ),
      );
    }
  }

  void _configureDifficulty() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        _ballSpeed = 5000; // 5 seconds - extremely slow
        ballRadius = 50.0; // Very large targets
        _showTargetPreview = true;
        break;
      case GameDifficulty.medium:
        _ballSpeed = 3500; // 3.5 seconds
        ballRadius = 40.0; // Large targets
        _showTargetPreview = true;
        break;
      case GameDifficulty.hard:
        _ballSpeed = 2500; // 2.5 seconds
        ballRadius = 32.0; // Medium targets
        _showTargetPreview = true;
        break;
      case GameDifficulty.expert:
        _ballSpeed = 2000; // 2 seconds
        ballRadius = 28.0; // Smaller targets
        _showTargetPreview = false;
        break;
    }
  }

  @override
  void dispose() {
    _ballAnimationController.dispose();
    _hitAnimationController.dispose();
    _missAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      score = 0;
      shots = 0;
      missed = 0;
      gameCompleted = false;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      ballVisible = false;
      isAnimating = false;
      _showHitEffect = false;
      _showMissEffect = false;
      _recentHits = 0;
      _recentShots = 0;
      _accuracyRate = 1.0;
      _lastPerformanceCheck = DateTime.now();
      _nextBallPosition = null;
    });
    Future.delayed(const Duration(milliseconds: 1500), _spawnBall);
  }

  void _spawnBall() {
    if (gameCompleted) return;

    // First, show target preview if enabled
    if (_showTargetPreview) {
      final rand = math.Random();
      // Ensure targets stay well within screen bounds with larger margins
      final margin = ballRadius + 50.0; // Much larger margin for safety
      final w = math.max(100.0, boardSize.width - (margin * 2));
      final h = math.max(100.0, boardSize.height - (margin * 2));
      final x = margin + rand.nextDouble() * w;
      final y = margin + rand.nextDouble() * h;

      setState(() {
        _nextBallPosition = Offset(x, y);
        ballVisible = false; // Keep ball invisible during preview
      });

      // Show preview for 3 seconds (much longer and more stable)
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!gameCompleted) {
          _showBallAfterPreview();
        }
      });
    } else {
      // No preview mode - show ball immediately
      _showBallAfterPreview();
    }
  }

  void _showBallAfterPreview() {
    // If we have a preview position, use it; otherwise generate a new safe position
    if (_nextBallPosition == null) {
      final rand = math.Random();
      final margin = ballRadius + 50.0; // Large margin for safety
      final w = math.max(100.0, boardSize.width - (margin * 2));
      final h = math.max(100.0, boardSize.height - (margin * 2));
      final x = margin + rand.nextDouble() * w;
      final y = margin + rand.nextDouble() * h;
      _nextBallPosition = Offset(x, y);
    }

    setState(() {
      ballPosition = _nextBallPosition!;
      ballVisible = true;
      isAnimating = true;
      _ballScale = 1.0;
    });

    // Animate ball appearance
    _ballAnimationController.forward();

    // Adaptive timing based on performance
    _updatePerformanceMetrics();
    final adaptiveTiming = _calculateAdaptiveTiming();

    Future.delayed(Duration(milliseconds: adaptiveTiming), () {
      if (!gameCompleted && ballVisible) {
        _onBallMiss();
      }
    });
  }

  void _updatePerformanceMetrics() {
    final now = DateTime.now();
    if (now.difference(_lastPerformanceCheck).inSeconds >= 10) {
      // Calculate accuracy rate over last 10 seconds
      if (_recentShots > 0) {
        _accuracyRate = _recentHits / _recentShots;
      }

      // Reset counters
      _recentHits = 0;
      _recentShots = 0;
      _lastPerformanceCheck = now;
    }
  }

  int _calculateAdaptiveTiming() {
    // Base timing from difficulty
    double baseTiming = _ballSpeed.toDouble();

    // Adjust based on accuracy - if player is struggling, make it much easier
    if (_accuracyRate < 0.5 && shots > 2) {
      baseTiming *= 2.5; // 150% slower if accuracy is low
    } else if (_accuracyRate < 0.7 && shots > 4) {
      baseTiming *= 1.8; // 80% slower if accuracy is medium-low
    } else if (_accuracyRate > 0.9) {
      baseTiming *= 0.95; // Only 5% faster if accuracy is very high
    }

    // No progressive difficulty - keep it consistent
    return baseTiming.round();
  }

  void _onBallMiss() {
    setState(() {
      _showMissEffect = true;
      ballVisible = false;
      isAnimating = false;
      _nextBallPosition = null; // Clear preview position
    });

    _missAnimationController.forward().then((_) {
      _missAnimationController.reset();
      setState(() {
        _showMissEffect = false;
      });
    });

    _ballAnimationController.reset();
    _onBallHit(false); // Missed
    Future.delayed(const Duration(milliseconds: 1500), _spawnBall);
  }

  void _onTapDown(TapDownDetails details) {
    if (gameCompleted) return;

    final tap = details.localPosition;

    // Handle tap during target preview phase
    if (_showTargetPreview && _nextBallPosition != null && !ballVisible) {
      final distance = (tap - _nextBallPosition!).distance;
      final hitRadius = ballRadius + 40; // Very forgiving for preview

      if (distance <= hitRadius) {
        // Hit the preview target! Show immediate success
        _onBallHit(true);
        _recentHits++;
        _recentShots++;

        setState(() {
          _hitEffectPosition = _nextBallPosition;
          _showHitEffect = true;
          _nextBallPosition = null;
        });

        // Hit effect animation
        _hitAnimationController.forward().then((_) {
          _hitAnimationController.reset();
          setState(() {
            _showHitEffect = false;
          });
        });

        Future.delayed(const Duration(milliseconds: 1500), _spawnBall);
      } else {
        // Miss during preview
        _recentShots++;
      }
      return;
    }

    // Handle tap during normal ball phase
    if (!ballVisible) return;

    final distance = (tap - ballPosition!).distance;
    final hitRadius = ballRadius + 40; // Very forgiving hit detection

    if (distance <= hitRadius) {
      _onBallHit(true);
      _recentHits++;
      _recentShots++;

      setState(() {
        _hitEffectPosition = ballPosition;
        _showHitEffect = true;
        ballVisible = false;
        isAnimating = false;
        _nextBallPosition = null;
      });

      // Hit effect animation
      _hitAnimationController.forward().then((_) {
        _hitAnimationController.reset();
        setState(() {
          _showHitEffect = false;
        });
      });

      _ballAnimationController.reset();
      Future.delayed(const Duration(milliseconds: 1000), _spawnBall);
    } else {
      _recentShots++;
      // Provide feedback for near misses - much more generous
      if (distance <= hitRadius + 50) {
        // Near miss - show visual feedback
        setState(() {
          _ballScale = 1.5;
        });
        Future.delayed(const Duration(milliseconds: 250), () {
          setState(() {
            _ballScale = 1.0;
          });
        });
      }
    }
  }

  void _onBallHit(bool hit) {
    setState(() {
      shots++;
      if (hit) {
        score++;
      } else {
        missed++;
      }
      if (shots >= maxShots) {
        _completeGame();
      }
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
      gameTime = DateTime.now().difference(gameStartTime);
      ballVisible = false;
      isAnimating = false;
    });
    final xpEarned = _calculateXP();
    Future.microtask(() async {
      await context.read<ProfileCubit>().addXP(xpEarned);
      context.read<ProfileCubit>().incrementGameWin('ballBlaster');
      await context.read<ProfileCubit>().addGameActivity(
        type: activity.ActivityType.gameWin,
        gameType: activity.GameType.ballBlaster,
        difficulty: selectedDifficulty.name,
        xpEarned: xpEarned,
        metadata: {
          'score': score,
          'shots': shots,
          'missed': missed,
          'gameTimeSeconds': gameTime.inSeconds,
        },
      );
      _showCompletionDialog();
    });
  }

  int _calculateXP() {
    int baseXP = 15;
    int difficultyMultiplier = selectedDifficulty.index + 1;
    int accuracyBonus = missed == 0
        ? 30
        : missed <= 3
        ? 15
        : missed <= 5
        ? 5
        : 0;
    int speedBonus = gameTime.inSeconds < 30
        ? 20
        : gameTime.inSeconds < 60
        ? 10
        : 0;
    return (baseXP + accuracyBonus + speedBonus) * difficultyMultiplier;
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassCard(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration, size: 64.sp, color: Colors.amber),
                SizedBox(height: 16.h),
                Text(
                  'Ball Blaster Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Score: $score / $shots',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Missed: $missed',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                SizedBox(height: 8.h),
                Text(
                  'XP Earned: ${_calculateXP()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text('Play Again'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text('Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        boardSize = Size(
          constraints.maxWidth,
          constraints.maxHeight - 150.h,
        ); // Reduced from 220.h
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1a1a2e),
                        Color(0xFF16213e),
                        Color(0xFF0f3460),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFf8f9fa),
                        Color(0xFFe9ecef),
                        Color(0xFFdee2e6),
                      ],
                    ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ball Blaster',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Difficulty: ${selectedDifficulty.name.toUpperCase()}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (_showTargetPreview &&
                                  _nextBallPosition != null &&
                                  !ballVisible)
                                Text(
                                  '🎯 Target Preview Active',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.yellowAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Score',
                            score.toString(),
                            Colors.green,
                          ),
                          _buildStatItem(
                            'Shots',
                            shots.toString(),
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Missed',
                            missed.toString(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.indigo.shade900,
                              Colors.purple.shade900,
                              Colors.black,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Animated starfield background
                            AnimatedBuilder(
                              animation: _backgroundAnimationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: StarFieldPainter(
                                    _stars,
                                    _backgroundAnimation.value,
                                  ),
                                  size: Size.infinite,
                                );
                              },
                            ),

                            // Target preview (next ball position)
                            if (_showTargetPreview &&
                                _nextBallPosition != null &&
                                !ballVisible)
                              AnimatedBuilder(
                                animation: _backgroundAnimationController,
                                builder: (context, child) {
                                  return Positioned(
                                    left: _nextBallPosition!.dx - ballRadius,
                                    top: _nextBallPosition!.dy - ballRadius,
                                    child: Opacity(
                                      opacity:
                                          0.6 +
                                          (0.2 *
                                              (1 +
                                                  math.sin(
                                                    _backgroundAnimation.value *
                                                        2 *
                                                        math.pi,
                                                  ))), // More stable, brighter opacity
                                      child: Container(
                                        width: ballRadius * 2,
                                        height: ballRadius * 2,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.yellowAccent,
                                            width: 4, // Thicker border
                                          ),
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.yellowAccent.withOpacity(
                                                0.5,
                                              ), // More visible
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.gps_fixed,
                                            color: Colors.yellowAccent,
                                            size: ballRadius * 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Main ball
                            if (ballVisible && ballPosition != null)
                              AnimatedBuilder(
                                animation: _ballAnimationController,
                                builder: (context, child) {
                                  return Positioned(
                                    left: ballPosition!.dx - ballRadius,
                                    top: ballPosition!.dy - ballRadius,
                                    child: Transform.scale(
                                      scale:
                                          _ballScaleAnimation.value *
                                          _ballScale,
                                      child: Opacity(
                                        opacity: _ballOpacityAnimation.value,
                                        child: Container(
                                          width: ballRadius * 2,
                                          height: ballRadius * 2,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.cyanAccent,
                                                Colors.lightBlueAccent,
                                                Colors.blueAccent,
                                                Colors.blue.shade800,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent
                                                    .withOpacity(0.8),
                                                blurRadius: 20,
                                                spreadRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.blur_circular,
                                              color: Colors.white,
                                              size: ballRadius * 0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Hit effect
                            if (_showHitEffect && _hitEffectPosition != null)
                              AnimatedBuilder(
                                animation: _hitAnimationController,
                                builder: (context, child) {
                                  return Positioned(
                                    left: _hitEffectPosition!.dx - 40,
                                    top: _hitEffectPosition!.dy - 40,
                                    child: Transform.scale(
                                      scale:
                                          _hitAnimationController.value * 2.5,
                                      child: Opacity(
                                        opacity:
                                            1 - _hitAnimationController.value,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.greenAccent.withOpacity(
                                                  0.8,
                                                ),
                                                Colors.green.withOpacity(0.4),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.star_border,
                                              color: Colors.yellowAccent,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Miss effect
                            if (_showMissEffect && ballPosition != null)
                              AnimatedBuilder(
                                animation: _missAnimationController,
                                builder: (context, child) {
                                  return Positioned(
                                    left: ballPosition!.dx - 50,
                                    top: ballPosition!.dy - 50,
                                    child: Transform.scale(
                                      scale: _missAnimationController.value * 2,
                                      child: Opacity(
                                        opacity:
                                            1 - _missAnimationController.value,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                Colors.redAccent.withOpacity(
                                                  0.8,
                                                ),
                                                Colors.red.withOpacity(0.4),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.redAccent,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Game completed celebration
                            if (gameCompleted)
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(32.w),
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.amber.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.celebration,
                                        size: 64.sp,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'Galaxy Conquered!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Score: $score/$shots',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Colors.cyanAccent,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[400]),
        ),
      ],
    );
  }
}

class StarFieldPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;

  StarFieldPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final opacity =
          (0.3 + 0.7 * math.sin(animationValue * 2 * math.pi + i * 0.5)).clamp(
            0.0,
            1.0,
          );
      final twinkle =
          0.8 + 0.2 * math.sin(animationValue * 6 * math.pi + i * 1.2);

      paint.color = Colors.white.withOpacity(opacity);

      // Different star sizes for depth effect
      final starSize = (i % 3 == 0) ? 2.0 * twinkle : 1.0 * twinkle;

      canvas.drawCircle(star, starSize, paint);

      // Add some larger bright stars
      if (i % 20 == 0) {
        paint.color = Colors.cyanAccent.withOpacity(opacity * 0.6);
        canvas.drawCircle(star, starSize * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
