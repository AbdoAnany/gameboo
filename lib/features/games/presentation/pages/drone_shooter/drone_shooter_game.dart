import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flame/game.dart';

import '../../../../../shared/widgets/glass_widgets.dart';
import '../../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../profile/domain/entities/game_activity.dart' as activity;
import '../../../domain/entities/game.dart';
import '../../../domain/entities/drone_shooter_entities.dart';
import 'drone_shooter_game_engine.dart';

class DroneShooterGamePage extends StatefulWidget {
  final GameDifficulty difficulty;

  const DroneShooterGamePage({Key? key, required this.difficulty})
    : super(key: key);

  @override
  State<DroneShooterGamePage> createState() => _DroneShooterGamePageState();
}

class _DroneShooterGamePageState extends State<DroneShooterGamePage> {
  late DroneShooterGame game;
  DroneStats? currentStats;
  DroneShooterGameState gameState = DroneShooterGameState.menu;

  // Touch controls
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  bool _isMovingUp = false;
  bool _isMovingDown = false;
  bool _isShooting = false;

  // Movement timers for continuous movement
  Timer? _movementTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    game = DroneShooterGame();
    game.onStatsUpdate = (stats) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              currentStats = stats;
            });
          }
        });
      }
    };
    game.onGameStateChange = (state) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              gameState = state;
            });

            if (state == DroneShooterGameState.gameOver) {
              _handleGameOver();
            }
          }
        });
      }
    };
  }

  void _handleGameOver() async {
    if (currentStats == null) return;

    final bool won =
        currentStats!.currentSection >
        5; // Win condition: complete all 5 sections
    final xpEarned = _calculateXP(won);

    // Add XP to profile first
    await context.read<ProfileCubit>().addXP(xpEarned);

    // Then add the activity record
    await context.read<ProfileCubit>().addGameActivity(
      type: won
          ? activity.ActivityType.gameWin
          : activity.ActivityType.gameLoss,
      gameType: activity.GameType.droneShooter,
      difficulty: widget.difficulty.name,
      xpEarned: xpEarned,
      metadata: {
        'score': currentStats!.score,
        'level': currentStats!.level,
        'enemies_destroyed': currentStats!.enemiesDestroyed,
        'completed': won,
      },
    );

    _showGameOverDialog(won);
  }

  int _calculateXP(bool won) {
    if (currentStats == null) return 0;

    int baseXP = won ? 30 : 15;
    int difficultyMultiplier = widget.difficulty.index + 1;
    int performanceBonus =
        (currentStats!.score ~/ 100) + (currentStats!.level * 10);

    if (won) {
      performanceBonus += 50;
    }

    return (baseXP * difficultyMultiplier) + performanceBonus;
  }

  void _showGameOverDialog(bool won) {
    final xpEarned = currentStats != null ? _calculateXP(won) : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C5282), // Windows XP blue
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            title: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF2C5282)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    won ? Icons.flight_takeoff : Icons.warning,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    won ? 'Mission Complete!' : 'Game Over',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            content: Container(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // XP Gained Section (Windows XP style)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      border: Border.all(color: const Color(0xFF808080)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: const Color(0xFFFFD700),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Points Gained',
                              style: TextStyle(
                                color: const Color(0xFF333333),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+$xpEarned XP',
                          style: const TextStyle(
                            color: Color(0xFF008000),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        if (profileState is ProfileLoaded) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Level ${profileState.profile.level}',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            height: 20,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF808080),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1),
                              child: LinearProgressIndicator(
                                value: profileState.profile.levelProgress,
                                backgroundColor: const Color(0xFFFFFFFF),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${profileState.profile.xp} / ${profileState.profile.xpToNextLevel} XP',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Game Stats Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          won
                              ? 'Outstanding piloting!'
                              : 'Better luck next time!',
                          style: TextStyle(
                            color: won ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (currentStats != null) ...[
                          _buildStatRow(
                            'Final Score',
                            '${currentStats!.score}',
                          ),
                          _buildStatRow(
                            'Level Reached',
                            '${currentStats!.level}',
                          ),
                          _buildStatRow(
                            'Enemies Destroyed',
                            '${currentStats!.enemiesDestroyed}',
                          ),
                          _buildStatRow(
                            'Sections Completed',
                            '${currentStats!.currentSection - 1}/5',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6E6E6), Color(0xFFCCCCCC)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF808080)),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    game.restartGame();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6E6E6), Color(0xFFCCCCCC)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF808080)),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Exit'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _updateMovement() {
    if (gameState != DroneShooterGameState.playing) return;

    // Increased sensitivity for faster movement
    double x = 0, y = 0;
    if (_isMovingLeft) x -= 1.5; // Increased from 1
    if (_isMovingRight) x += 1.5; // Increased from 1
    if (_isMovingUp) y -= 1.5; // Increased from 1
    if (_isMovingDown) y += 1.5; // Increased from 1

    game.moveDrone(Vector2(x, y));

    if (_isShooting) {
      game.startShooting();
    } else {
      game.stopShooting();
    }

    // Start continuous movement if any direction is pressed
    if (x != 0 || y != 0 || _isShooting) {
      _startContinuousMovement();
    } else {
      _stopContinuousMovement();
    }
  }

  void _startContinuousMovement() {
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (gameState == DroneShooterGameState.playing) {
        double x = 0, y = 0;
        if (_isMovingLeft) x -= 1.5;
        if (_isMovingRight) x += 1.5;
        if (_isMovingUp) y -= 1.5;
        if (_isMovingDown) y += 1.5;

        if (x != 0 || y != 0) {
          game.moveDrone(Vector2(x, y));
        }

        if (_isShooting) {
          game.startShooting();
        }
      }
    });
  }

  void _stopContinuousMovement() {
    _movementTimer?.cancel();
    _movementTimer = null;
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Game Canvas
              Positioned.fill(
                child: GameWidget.controlled(gameFactory: () => game),
              ),

              // UI Overlay
              if (gameState == DroneShooterGameState.playing) ...[
                // Stats Panel
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: GlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Health',
                            currentStats?.health.toString() ?? '0',
                            Colors.red,
                            progress: currentStats?.healthPercentage ?? 0,
                          ),
                          _buildStatItem(
                            'Section',
                            '${currentStats?.currentSection ?? 1}/5',
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Time',
                            '${(currentStats?.sectionTimeRemaining ?? 30).toInt()}s',
                            Colors.orange,
                          ),
                          _buildStatItem(
                            'Score',
                            currentStats?.score.toString() ?? '0',
                            Colors.yellow,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Touch Controls
                Positioned(
                  bottom: 20.h,
                  left: 20.w,
                  child: _buildDirectionalPad(),
                ),

                Positioned(
                  bottom: 20.h,
                  right: 20.w,
                  child: _buildShootButton(),
                ),

                // Pause Button
                Positioned(
                  top: 80.h,
                  right: 16.w,
                  child: GestureDetector(
                    onTap: () => game.pauseGame(),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(Icons.pause, color: Colors.white),
                    ),
                  ),
                ),
              ],

              // Menu/Pause Overlay
              if (gameState == DroneShooterGameState.menu ||
                  gameState == DroneShooterGameState.paused) ...[
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              gameState == DroneShooterGameState.menu
                                  ? 'Drone Shooter'
                                  : 'Game Paused',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            if (gameState == DroneShooterGameState.menu) ...[
                              Text(
                                'Pilot your B-2 stealth bomber!\n\n'
                                '• Use directional pad to move\n'
                                '• Hold shoot button to fire continuously\n'
                                '• Collect power-ups to upgrade\n'
                                '• Complete all 5 sections to win!\n'
                                '• Each section lasts 30 seconds',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              ElevatedButton(
                                onPressed: () => game.resumeGame(),
                                child: const Text('Start Mission'),
                              ),
                            ] else ...[
                              ElevatedButton(
                                onPressed: () => game.resumeGame(),
                                child: const Text('Resume'),
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Exit'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color, {
    double? progress,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (progress != null) ...[
          SizedBox(height: 2.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 8.sp, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildDirectionalPad() {
    return Container(
      width: 160.w, // Increased from 120.w
      height: 160.w, // Increased from 120.w
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: 55.w, // Adjusted for larger size
            child: _buildDirectionButton(
              icon: Icons.keyboard_arrow_up,
              onPressed: () {
                setState(() => _isMovingUp = true);
                _updateMovement();
              },
              onReleased: () {
                setState(() => _isMovingUp = false);
                _updateMovement();
              },
            ),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: 55.w, // Adjusted for larger size
            child: _buildDirectionButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: () {
                setState(() => _isMovingDown = true);
                _updateMovement();
              },
              onReleased: () {
                setState(() => _isMovingDown = false);
                _updateMovement();
              },
            ),
          ),
          // Left
          Positioned(
            left: 0,
            top: 55.w, // Adjusted for larger size
            child: _buildDirectionButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: () {
                setState(() => _isMovingLeft = true);
                _updateMovement();
              },
              onReleased: () {
                setState(() => _isMovingLeft = false);
                _updateMovement();
              },
            ),
          ),
          // Right
          Positioned(
            right: 0,
            top: 55.w, // Adjusted for larger size
            child: _buildDirectionButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: () {
                setState(() => _isMovingRight = true);
                _updateMovement();
              },
              onReleased: () {
                setState(() => _isMovingRight = false);
                _updateMovement();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onReleased,
  }) {
    return GestureDetector(
      onPanStart: (_) {
        if (!mounted) return;
        onPressed();
      },
      onPanEnd: (_) {
        if (!mounted) return;
        onReleased();
      },
      onPanCancel: () {
        if (!mounted) return;
        onReleased();
      },
      onTapDown: (_) {
        if (!mounted) return;
        onPressed();
      },
      onTapUp: (_) {
        if (!mounted) return;
        onReleased();
      },
      onTapCancel: () {
        if (!mounted) return;
        onReleased();
      },
      child: Container(
        width: 50.w, // Increased from 40.w
        height: 50.w, // Increased from 40.w
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25.r), // Adjusted for larger size
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 32.w,
        ), // Increased from 24.w
      ),
    );
  }

  Widget _buildShootButton() {
    return GestureDetector(
      onPanStart: (_) {
        if (!mounted) return;
        setState(() => _isShooting = true);
        _updateMovement();
      },
      onPanEnd: (_) {
        if (!mounted) return;
        setState(() => _isShooting = false);
        _updateMovement();
      },
      onPanCancel: () {
        if (!mounted) return;
        setState(() => _isShooting = false);
        _updateMovement();
      },
      onTapDown: (_) {
        if (!mounted) return;
        setState(() => _isShooting = true);
        _updateMovement();
      },
      onTapUp: (_) {
        if (!mounted) return;
        setState(() => _isShooting = false);
        _updateMovement();
      },
      onTapCancel: () {
        if (!mounted) return;
        setState(() => _isShooting = false);
        _updateMovement();
      },
      child: Container(
        width: 80.w, // Increased from 70.w
        height: 80.w, // Increased from 70.w
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(40.r), // Adjusted for larger size
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.radio_button_checked,
          color: Colors.white,
          size: 35.w, // Increased from 30.w
        ),
      ),
    );
  }
}
