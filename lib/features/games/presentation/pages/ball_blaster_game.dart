import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

class _BallBlasterGameState extends State<BallBlasterGame> {
  int score = 0;
  int shots = 0;
  int missed = 0;
  bool gameCompleted = false;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Ball state
  Offset? ballPosition;
  double ballRadius = 32.0;
  bool ballVisible = false;
  bool isAnimating = false;
  late Size boardSize;
  late int maxShots;

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    maxShots = 20 + selectedDifficulty.index * 5;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
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
    });
    Future.delayed(const Duration(milliseconds: 500), _spawnBall);
  }

  void _spawnBall() {
    if (gameCompleted) return;
    setState(() {
      final rand = UniqueKey().hashCode;
      final w = boardSize.width;
      final h = boardSize.height;
      final x = (ballRadius + (rand % (w - 2 * ballRadius))).toDouble();
      final y = (ballRadius + ((rand ~/ 1000) % (h - 2 * ballRadius)))
          .toDouble();
      ballPosition = Offset(x, y);
      ballVisible = true;
      isAnimating = true;
    });
    Future.delayed(
      Duration(milliseconds: 1200 - selectedDifficulty.index * 200),
      () {
        if (!gameCompleted && ballVisible) {
          _onBallHit(false); // Missed
          setState(() {
            ballVisible = false;
            isAnimating = false;
          });
          Future.delayed(const Duration(milliseconds: 400), _spawnBall);
        }
      },
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (!ballVisible || gameCompleted) return;
    final tap = details.localPosition;
    if ((tap - ballPosition!).distance <= ballRadius) {
      _onBallHit(true);
      setState(() {
        ballVisible = false;
        isAnimating = false;
      });
      Future.delayed(const Duration(milliseconds: 400), _spawnBall);
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
        boardSize = Size(constraints.maxWidth, constraints.maxHeight - 220.h);
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
                      child: Stack(
                        children: [
                          if (ballVisible && ballPosition != null)
                            AnimatedPositioned(
                              duration: isAnimating
                                  ? Duration(milliseconds: 300)
                                  : Duration.zero,
                              left: ballPosition!.dx - ballRadius,
                              top: ballPosition!.dy - ballRadius,
                              child: Container(
                                width: ballRadius * 2,
                                height: ballRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.sports_baseball,
                                    color: Colors.white,
                                    size: ballRadius,
                                  ),
                                ),
                              ),
                            ),
                          if (gameCompleted)
                            Center(
                              child: Icon(
                                Icons.celebration,
                                size: 64.sp,
                                color: Colors.amber,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: _startGame,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text('New Game'),
                              ],
                            ),
                          ),
                        ),
                      ],
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
