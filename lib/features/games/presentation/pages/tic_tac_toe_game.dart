import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import '../../domain/entities/game.dart';

enum Player { human, ai, none }

enum GameResult { win, lose, draw }

class TicTacToeGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const TicTacToeGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame>
    with TickerProviderStateMixin {
  late List<List<Player>> board;
  late Player currentPlayer;
  late bool gameEnded;
  late GameResult? gameResult;
  late int humanWins;
  late int aiWins;
  late int draws;
  late DateTime gameStartTime;
  late AnimationController _winAnimationController;
  late AnimationController _cellAnimationController;
  late Animation<double> _scaleAnimation;
  late GameDifficulty selectedDifficulty;

  // AI difficulty settings
  late int aiDepth;
  late double aiMistakeChance;

  // Winning line tracking
  List<List<int>>? winningLine;

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    humanWins = 0;
    aiWins = 0;
    draws = 0;
    _initializeGame();
    _setupAnimations();
    _configureAI();
  }

  void _initializeGame() {
    board = List.generate(3, (_) => List.generate(3, (_) => Player.none));
    currentPlayer = Player.human;
    gameEnded = false;
    gameResult = null;
    winningLine = null;
    gameStartTime = DateTime.now();
  }

  void _setupAnimations() {
    _winAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cellAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _configureAI() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        aiDepth = 1;
        aiMistakeChance = 0.4; // 40% chance of suboptimal move
        break;
      case GameDifficulty.medium:
        aiDepth = 3;
        aiMistakeChance = 0.2; // 20% chance of mistake
        break;
      case GameDifficulty.hard:
        aiDepth = 5;
        aiMistakeChance = 0.1; // 10% chance of mistake
        break;
      case GameDifficulty.expert:
        aiDepth = 9; // Perfect play
        aiMistakeChance = 0.0; // No mistakes
        break;
    }
  }

  @override
  void dispose() {
    _winAnimationController.dispose();
    _cellAnimationController.dispose();
    super.dispose();
  }

  void _makeMove(int row, int col) {
    if (board[row][col] != Player.none || gameEnded) return;

    setState(() {
      board[row][col] = currentPlayer;
      _cellAnimationController.forward().then((_) {
        _cellAnimationController.reset();
      });
    });

    if (_checkWinner() != Player.none || _isBoardFull()) {
      _endGame();
    } else {
      _switchPlayer();
      if (currentPlayer == Player.ai) {
        Future.delayed(const Duration(milliseconds: 500), _makeAIMove);
      }
    }
  }

  void _makeAIMove() {
    if (gameEnded) return;

    final move = _getBestMove();
    if (move != null) {
      _makeMove(move['row']!, move['col']!);
    }
  }

  Map<String, int>? _getBestMove() {
    // Add some randomness for easier difficulties
    if (aiMistakeChance > 0 &&
        (DateTime.now().millisecond / 1000.0) < aiMistakeChance) {
      return _getRandomMove();
    }

    final bestMove = _minimax(board, aiDepth, true, Player.ai);
    final moveData = bestMove['move'];
    if (moveData != null && moveData is Map) {
      return {'row': moveData['row'] as int, 'col': moveData['col'] as int};
    }
    return null;
  }

  Map<String, int>? _getRandomMove() {
    final availableMoves = <Map<String, int>>[];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == Player.none) {
          availableMoves.add({'row': i, 'col': j});
        }
      }
    }
    if (availableMoves.isNotEmpty) {
      return availableMoves[DateTime.now().millisecond % availableMoves.length];
    }
    return null;
  }

  Map<String, dynamic> _minimax(
    List<List<Player>> currentBoard,
    int depth,
    bool isMaximizing,
    Player player,
  ) {
    final winner = _checkWinner(board: currentBoard);

    if (winner == Player.ai) return {'score': 10 - (9 - depth)};
    if (winner == Player.human) return {'score': -10 + (9 - depth)};
    if (_isBoardFull(board: currentBoard) || depth == 0) return {'score': 0};

    final moves = <Map<String, dynamic>>[];

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (currentBoard[i][j] == Player.none) {
          currentBoard[i][j] = player;

          final result = _minimax(
            currentBoard,
            depth - 1,
            !isMaximizing,
            player == Player.ai ? Player.human : Player.ai,
          );

          moves.add({'row': i, 'col': j, 'score': result['score']});

          currentBoard[i][j] = Player.none;
        }
      }
    }

    if (moves.isEmpty) return {'score': 0};

    if (isMaximizing) {
      moves.sort((a, b) => b['score'].compareTo(a['score']));
    } else {
      moves.sort((a, b) => a['score'].compareTo(b['score']));
    }

    return {
      'score': moves.first['score'],
      'move': {'row': moves.first['row'], 'col': moves.first['col']},
    };
  }

  Player _checkWinner({List<List<Player>>? board}) {
    final currentBoard = board ?? this.board;

    // Check rows
    for (int i = 0; i < 3; i++) {
      if (currentBoard[i][0] == currentBoard[i][1] &&
          currentBoard[i][1] == currentBoard[i][2] &&
          currentBoard[i][0] != Player.none) {
        if (board == null) {
          // Only set winning line for actual game board
          winningLine = [
            [i, 0],
            [i, 1],
            [i, 2],
          ];
        }
        return currentBoard[i][0];
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (currentBoard[0][i] == currentBoard[1][i] &&
          currentBoard[1][i] == currentBoard[2][i] &&
          currentBoard[0][i] != Player.none) {
        if (board == null) {
          // Only set winning line for actual game board
          winningLine = [
            [0, i],
            [1, i],
            [2, i],
          ];
        }
        return currentBoard[0][i];
      }
    }

    // Check diagonals
    if (currentBoard[0][0] == currentBoard[1][1] &&
        currentBoard[1][1] == currentBoard[2][2] &&
        currentBoard[0][0] != Player.none) {
      if (board == null) {
        // Only set winning line for actual game board
        winningLine = [
          [0, 0],
          [1, 1],
          [2, 2],
        ];
      }
      return currentBoard[0][0];
    }

    if (currentBoard[0][2] == currentBoard[1][1] &&
        currentBoard[1][1] == currentBoard[2][0] &&
        currentBoard[0][2] != Player.none) {
      if (board == null) {
        // Only set winning line for actual game board
        winningLine = [
          [0, 2],
          [1, 1],
          [2, 0],
        ];
      }
      return currentBoard[0][2];
    }

    return Player.none;
  }

  bool _isWinningCell(int row, int col) {
    if (winningLine == null) return false;
    return winningLine!.any((cell) => cell[0] == row && cell[1] == col);
  }

  bool _isBoardFull({List<List<Player>>? board}) {
    final currentBoard = board ?? this.board;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (currentBoard[i][j] == Player.none) return false;
      }
    }
    return true;
  }

  void _switchPlayer() {
    currentPlayer = currentPlayer == Player.human ? Player.ai : Player.human;
  }

  void _endGame() {
    final winner = _checkWinner();
    setState(() {
      gameEnded = true;
      if (winner == Player.human) {
        gameResult = GameResult.win;
        humanWins++;
        // Award XP based on difficulty
        final xpEarned = _calculateXP();
        context.read<ProfileCubit>().addXP(xpEarned);
        context.read<ProfileCubit>().incrementGameWin('ticTacToe');

        // Add game activity
        context.read<ProfileCubit>().addGameActivity(
          type: activity.ActivityType.gameWin,
          gameType: activity.GameType.ticTacToe,
          difficulty: selectedDifficulty.name,
          xpEarned: xpEarned,
          metadata: {
            'moves': _countPlayerMoves(),
            'gameTime': DateTime.now().difference(gameStartTime).inSeconds,
          },
        );
      } else if (winner == Player.ai) {
        gameResult = GameResult.lose;
        aiWins++;

        // Add game activity for loss
        context.read<ProfileCubit>().addGameActivity(
          type: activity.ActivityType.gameLoss,
          gameType: activity.GameType.ticTacToe,
          difficulty: selectedDifficulty.name,
          metadata: {
            'moves': _countPlayerMoves(),
            'gameTime': DateTime.now().difference(gameStartTime).inSeconds,
          },
        );
      } else {
        gameResult = GameResult.draw;
        draws++;
        // Award small XP for draw
        context.read<ProfileCubit>().addXP(5);

        // Add game activity for draw
        context.read<ProfileCubit>().addGameActivity(
          type: activity.ActivityType.gameDraw,
          gameType: activity.GameType.ticTacToe,
          difficulty: selectedDifficulty.name,
          xpEarned: 5,
          metadata: {
            'moves': _countPlayerMoves(),
            'gameTime': DateTime.now().difference(gameStartTime).inSeconds,
          },
        );
      }
    });

    _winAnimationController.forward();
  }

  int _countPlayerMoves() {
    int moves = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == Player.human) {
          moves++;
        }
      }
    }
    return moves;
  }

  int _calculateXP() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        return 10;
      case GameDifficulty.medium:
        return 25;
      case GameDifficulty.hard:
        return 50;
      case GameDifficulty.expert:
        return 100;
    }
  }

  void _resetGame() {
    setState(() {
      board = List.generate(3, (_) => List.generate(3, (_) => Player.none));
      currentPlayer = Player.human;
      gameEnded = false;
      gameResult = null;
      winningLine = null;
      gameStartTime = DateTime.now();
    });
    _winAnimationController.reset();
  }

  void _changeDifficulty(GameDifficulty newDifficulty) {
    setState(() {
      selectedDifficulty = newDifficulty;
    });
    _configureAI();
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          child: AnimationLimiter(
            child: Column(
              children: [
                // Header
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: -50.0,
                    child: FadeInAnimation(
                      child: Padding(
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
                                    'Tic Tac Toe',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                            Text(
                              currentPlayer == Player.human
                                  ? 'Your Turn'
                                  : 'AI Turn',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: currentPlayer == Player.human
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Score Board
                AnimationConfiguration.staggeredList(
                  position: 1,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: GlassCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildScoreItem('You', humanWins, Colors.green),
                              _buildScoreItem('Draws', draws, Colors.orange),
                              _buildScoreItem('AI', aiWins, Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Difficulty Selector
                AnimationConfiguration.staggeredList(
                  position: 2,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Difficulty Settings',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                children: GameDifficulty.values.map((
                                  difficulty,
                                ) {
                                  final isSelected =
                                      difficulty == selectedDifficulty;
                                  return GestureDetector(
                                    onTap: () => _changeDifficulty(difficulty),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        difficulty.name.toUpperCase(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Game Board
                Expanded(
                  child: AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Center(
                          child: Container(
                            width: 300.w,
                            height: 300.w,
                            child: AnimatedBuilder(
                              animation: _winAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale:
                                      1.0 +
                                      (_winAnimationController.value * 0.1),
                                  child: GlassCard(
                                    child: GridView.builder(
                                      padding: EdgeInsets.all(8.w),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                      itemCount: 9,
                                      itemBuilder: (context, index) {
                                        final row = index ~/ 3;
                                        final col = index % 3;
                                        final player = board[row][col];

                                        return GestureDetector(
                                          onTap: () => _makeMove(row, col),
                                          child: AnimatedBuilder(
                                            animation: _scaleAnimation,
                                            builder: (context, child) {
                                              final isWinning = _isWinningCell(
                                                row,
                                                col,
                                              );
                                              return Transform.scale(
                                                scale: player == Player.none
                                                    ? 1.0
                                                    : _scaleAnimation.value,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: player == Player.none
                                                        ? Colors.white
                                                              .withOpacity(0.05)
                                                        : (player ==
                                                                  Player.human
                                                              ? Colors.blue
                                                                    .withOpacity(
                                                                      isWinning
                                                                          ? 0.4
                                                                          : 0.2,
                                                                    )
                                                              : Colors.red
                                                                    .withOpacity(
                                                                      isWinning
                                                                          ? 0.4
                                                                          : 0.2,
                                                                    )),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16.r,
                                                        ),
                                                    border: Border.all(
                                                      color: isWinning
                                                          ? Colors.amber
                                                          : (player ==
                                                                    Player.none
                                                                ? Colors.white
                                                                      .withOpacity(
                                                                        0.3,
                                                                      )
                                                                : (player ==
                                                                          Player
                                                                              .human
                                                                      ? Colors
                                                                            .blue
                                                                            .withOpacity(
                                                                              0.6,
                                                                            )
                                                                      : Colors
                                                                            .red
                                                                            .withOpacity(
                                                                              0.6,
                                                                            ))),
                                                      width: isWinning ? 4 : 2,
                                                    ),
                                                    boxShadow: isWinning
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .amber
                                                                  .withOpacity(
                                                                    0.6,
                                                                  ),
                                                              blurRadius: 12,
                                                              spreadRadius: 2,
                                                            ),
                                                          ]
                                                        : (player != Player.none
                                                              ? [
                                                                  BoxShadow(
                                                                    color:
                                                                        (player ==
                                                                                    Player.human
                                                                                ? Colors.blue
                                                                                : Colors.red)
                                                                            .withOpacity(
                                                                              0.3,
                                                                            ),
                                                                    blurRadius:
                                                                        8,
                                                                    spreadRadius:
                                                                        1,
                                                                  ),
                                                                ]
                                                              : null),
                                                  ),
                                                  child: Center(
                                                    child: _buildPlayerSymbol(
                                                      player,
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
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Game Controls
                AnimationConfiguration.staggeredList(
                  position: 3,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
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
                                onPressed: _resetGame,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildPlayerSymbol(Player player) {
    switch (player) {
      case Player.human:
        return Container(
          padding: EdgeInsets.all(8.w),
          child: Icon(
            Icons.close,
            size: 48.sp,
            color: Colors.blue,
            shadows: [
              Shadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10),
            ],
          ),
        );
      case Player.ai:
        return Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 6.w),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      case Player.none:
        return Container(
          width: 48.w,
          height: 48.w,
          child: Icon(
            Icons.add,
            size: 24.sp,
            color: Colors.white.withOpacity(0.3),
          ),
        );
    }
  }
}
