import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import '../../domain/entities/game.dart';

class PuzzleManiaGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const PuzzleManiaGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<PuzzleManiaGame> createState() => _PuzzleManiaGameState();
}

class _PuzzleManiaGameState extends State<PuzzleManiaGame>
    with TickerProviderStateMixin {
  int score = 0;
  int moves = 0;
  int level = 1;
  bool gameCompleted = false;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Puzzle state
  List<List<PuzzlePiece>> grid = [];
  int gridSize = 4;
  PuzzlePiece? selectedPiece;
  PuzzleType currentPuzzleType = PuzzleType.match3;
  int targetScore = 100;

  // Animation controllers
  late AnimationController _matchAnimationController;
  late AnimationController _levelUpController;
  late AnimationController _backgroundController;
  late Timer _gameTimer;

  // Game mechanics
  List<Offset> _matchedPositions = [];
  bool _isProcessingMatches = false;
  int _combo = 0;
  Duration _timeLimit = const Duration(minutes: 3);
  Duration _remainingTime = const Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    _configureDifficulty();
    _initializeAnimations();
    _startGame(); // Initialize game immediately
  }

  void _configureDifficulty() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        gridSize = 6;
        targetScore = 50;
        _timeLimit = const Duration(minutes: 5);
        break;
      case GameDifficulty.medium:
        gridSize = 7;
        targetScore = 100;
        _timeLimit = const Duration(minutes: 4);
        break;
      case GameDifficulty.hard:
        gridSize = 8;
        targetScore = 150;
        _timeLimit = const Duration(minutes: 3);
        break;
      case GameDifficulty.expert:
        gridSize = 9;
        targetScore = 200;
        _timeLimit = const Duration(minutes: 2);
        break;
    }
    _remainingTime = _timeLimit;
  }

  void _initializeAnimations() {
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _matchAnimationController.dispose();
    _levelUpController.dispose();
    _backgroundController.dispose();
    _gameTimer.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      score = 0;
      moves = 0;
      level = 1;
      gameCompleted = false;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      selectedPiece = null;
      _matchedPositions.clear();
      _isProcessingMatches = false;
      _combo = 0;
      _remainingTime = _timeLimit;
    });

    _generatePuzzle();
    _startTimer();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          gameTime = DateTime.now().difference(gameStartTime);
        } else {
          _endGame(false);
        }
      });
    });
  }

  void _generatePuzzle() {
    final rand = math.Random();

    // Clear existing grid
    grid.clear();

    // Generate new grid
    grid = List.generate(
      gridSize,
      (row) => List.generate(
        gridSize,
        (col) => PuzzlePiece(
          color: PuzzleColor.values[rand.nextInt(5)], // 5 different colors
          type: PuzzlePieceType.normal,
          row: row,
          col: col,
        ),
      ),
    );

    // Ensure there are some initial matches for easier start
    _ensureInitialMatches();
  }

  void _ensureInitialMatches() {
    final rand = math.Random();
    for (int i = 0; i < 3; i++) {
      int row = rand.nextInt(gridSize - 2);
      int col = rand.nextInt(gridSize - 2);
      PuzzleColor color = PuzzleColor.values[rand.nextInt(5)];

      // Create horizontal match
      grid[row][col].color = color;
      grid[row][col + 1].color = color;
      grid[row][col + 2].color = color;
    }
  }

  void _onPieceTap(int row, int col) {
    if (_isProcessingMatches || gameCompleted) return;

    setState(() {
      if (selectedPiece == null) {
        selectedPiece = grid[row][col];
      } else {
        if (selectedPiece!.row == row && selectedPiece!.col == col) {
          // Deselect
          selectedPiece = null;
        } else if (_areAdjacent(selectedPiece!, grid[row][col])) {
          // Swap pieces
          _swapPieces(selectedPiece!, grid[row][col]);
          selectedPiece = null;
          moves++;
          _checkForMatches();
        } else {
          selectedPiece = grid[row][col];
        }
      }
    });
  }

  bool _areAdjacent(PuzzlePiece piece1, PuzzlePiece piece2) {
    int rowDiff = (piece1.row - piece2.row).abs();
    int colDiff = (piece1.col - piece2.col).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  void _swapPieces(PuzzlePiece piece1, PuzzlePiece piece2) {
    // Swap colors
    PuzzleColor tempColor = piece1.color;
    piece1.color = piece2.color;
    piece2.color = tempColor;
  }

  void _checkForMatches() {
    _isProcessingMatches = true;
    List<List<bool>> toRemove = List.generate(
      gridSize,
      (index) => List.generate(gridSize, (index) => false),
    );

    bool foundMatches = false;

    // Check horizontal matches
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize - 2; col++) {
        if (grid[row][col].color == grid[row][col + 1].color &&
            grid[row][col].color == grid[row][col + 2].color) {
          toRemove[row][col] = true;
          toRemove[row][col + 1] = true;
          toRemove[row][col + 2] = true;
          foundMatches = true;

          // Check for longer matches
          int extraMatches = 0;
          while (col + 3 + extraMatches < gridSize &&
              grid[row][col].color == grid[row][col + 3 + extraMatches].color) {
            toRemove[row][col + 3 + extraMatches] = true;
            extraMatches++;
          }
        }
      }
    }

    // Check vertical matches
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize - 2; row++) {
        if (grid[row][col].color == grid[row + 1][col].color &&
            grid[row][col].color == grid[row + 2][col].color) {
          toRemove[row][col] = true;
          toRemove[row + 1][col] = true;
          toRemove[row + 2][col] = true;
          foundMatches = true;

          // Check for longer matches
          int extraMatches = 0;
          while (row + 3 + extraMatches < gridSize &&
              grid[row][col].color == grid[row + 3 + extraMatches][col].color) {
            toRemove[row + 3 + extraMatches][col] = true;
            extraMatches++;
          }
        }
      }
    }

    if (foundMatches) {
      _processMatches(toRemove);
    } else {
      _isProcessingMatches = false;
    }
  }

  void _processMatches(List<List<bool>> toRemove) {
    _matchedPositions.clear();
    int matchCount = 0;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (toRemove[row][col]) {
          _matchedPositions.add(Offset(col.toDouble(), row.toDouble()));
          matchCount++;
        }
      }
    }

    _combo++;
    int points = matchCount * 10 * _combo;
    setState(() {
      score += points;
    });

    _matchAnimationController.forward().then((_) {
      _matchAnimationController.reset();
      _removeMatchedPieces(toRemove);
      _dropPieces();
      _fillEmpty();

      // Check for new matches after dropping
      Future.delayed(const Duration(milliseconds: 200), () {
        _checkForMatches();
      });
    });

    // Check win condition
    if (score >= targetScore) {
      _levelUp();
    }
  }

  void _removeMatchedPieces(List<List<bool>> toRemove) {
    final rand = math.Random();
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (toRemove[row][col]) {
          grid[row][col] = PuzzlePiece(
            color: PuzzleColor.values[rand.nextInt(5)],
            type: PuzzlePieceType.normal,
            row: row,
            col: col,
          );
        }
      }
    }
  }

  void _dropPieces() {
    for (int col = 0; col < gridSize; col++) {
      // Collect non-empty pieces from bottom to top
      List<PuzzlePiece> column = [];
      for (int row = gridSize - 1; row >= 0; row--) {
        column.add(grid[row][col]);
      }

      // Place them back from bottom
      for (int i = 0; i < column.length; i++) {
        grid[gridSize - 1 - i][col] = column[i];
        grid[gridSize - 1 - i][col].row = gridSize - 1 - i;
        grid[gridSize - 1 - i][col].col = col;
      }
    }
  }

  void _fillEmpty() {
    final rand = math.Random();
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        grid[row][col] = PuzzlePiece(
          color: PuzzleColor.values[rand.nextInt(5)],
          type: PuzzlePieceType.normal,
          row: row,
          col: col,
        );
      }
    }
  }

  void _levelUp() {
    setState(() {
      level++;
      targetScore += 50 + (level * 25);
      _combo = 0;
    });

    _levelUpController.forward().then((_) {
      _levelUpController.reset();
    });

    if (level >= 5) {
      _endGame(true);
    }
  }

  void _endGame(bool won) async{
    setState(() {
      gameCompleted = true;
      gameTime = DateTime.now().difference(gameStartTime);
    });

    _gameTimer.cancel();

    final xpEarned = _calculateXP(won);

    await context.read<ProfileCubit>().addGameActivity(
      type: won
          ? activity.ActivityType.gameWin
          : activity.ActivityType.gameLoss,
      gameType: activity.GameType.puzzleMania,
      difficulty: selectedDifficulty.name,
      xpEarned: xpEarned,
      metadata: {
        'score': score,
        'moves': moves,
        'level': level,
        'time_seconds': gameTime.inSeconds,
        'completed': won,
      },
    );

    if (mounted) {
      _showGameOverDialog(won);
    }
  }

  int _calculateXP(bool won) {
    int baseXP = won ? 25 : 10;
    int difficultyMultiplier = selectedDifficulty.index + 1;
    int performanceBonus = (score ~/ 50) + (level * 5);

    if (won) {
      performanceBonus += 20;
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
          won ? 'Puzzle Mania Complete!' : 'Time\'s Up!',
          style: TextStyle(
            color: won ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won) ...[
              Icon(Icons.extension, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Amazing puzzle solving!',
                style: TextStyle(color: Colors.white),
              ),
            ] else ...[
              Icon(Icons.timer_off, color: Colors.red, size: 48),
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
              'Level Reached: $level',
              style: const TextStyle(color: Colors.white),
            ),
            Text('Moves: $moves', style: const TextStyle(color: Colors.white)),
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

    // Show loading while grid is initializing
    if (grid.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Initializing Puzzle...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
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
                            'Puzzle Mania',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level $level - ${selectedDifficulty.name.toUpperCase()}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats panel
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: GlassCard(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Score', score.toString(), Colors.amber),
                        _buildStatItem(
                          'Target',
                          targetScore.toString(),
                          Colors.blue,
                        ),
                        _buildStatItem('Moves', moves.toString(), Colors.green),
                        _buildStatItem(
                          'Time',
                          '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Game grid
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16.w),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: gridSize * gridSize,
                      itemBuilder: (context, index) {
                        // Safety check to ensure grid is initialized
                        if (grid.isEmpty || grid.length < gridSize) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          );
                        }

                        int row = index ~/ gridSize;
                        int col = index % gridSize;

                        // Additional safety check for row bounds
                        if (row >= grid.length || col >= grid[row].length) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          );
                        }

                        PuzzlePiece piece = grid[row][col];
                        bool isSelected =
                            selectedPiece?.row == row &&
                            selectedPiece?.col == col;
                        bool isMatched = _matchedPositions.contains(
                          Offset(col.toDouble(), row.toDouble()),
                        );

                        return GestureDetector(
                          onTap: () => _onPieceTap(row, col),
                          child: AnimatedBuilder(
                            animation: _matchAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isMatched
                                    ? 1.0 - _matchAnimationController.value
                                    : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getPieceColor(piece.color),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getPieceIcon(piece.color),
                                      color: Colors.white,
                                      size: 20.w,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white70),
        ),
      ],
    );
  }

  Color _getPieceColor(PuzzleColor color) {
    switch (color) {
      case PuzzleColor.red:
        return Colors.red.shade400;
      case PuzzleColor.blue:
        return Colors.blue.shade400;
      case PuzzleColor.green:
        return Colors.green.shade400;
      case PuzzleColor.yellow:
        return Colors.yellow.shade400;
      case PuzzleColor.purple:
        return Colors.purple.shade400;
    }
  }

  IconData _getPieceIcon(PuzzleColor color) {
    switch (color) {
      case PuzzleColor.red:
        return Icons.favorite;
      case PuzzleColor.blue:
        return Icons.water_drop;
      case PuzzleColor.green:
        return Icons.eco;
      case PuzzleColor.yellow:
        return Icons.wb_sunny;
      case PuzzleColor.purple:
        return Icons.diamond;
    }
  }
}

class PuzzlePiece {
  PuzzleColor color;
  PuzzlePieceType type;
  int row;
  int col;

  PuzzlePiece({
    required this.color,
    required this.type,
    required this.row,
    required this.col,
  });
}

enum PuzzleColor { red, blue, green, yellow, purple }

enum PuzzlePieceType { normal, bomb, lightning }

enum PuzzleType { match3, tileSwap }
