import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../domain/entities/game.dart';
import '../cubit/game_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import 'dart:math';

enum RPSChoice { rock, paper, scissors }

class RockPaperScissorsGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const RockPaperScissorsGame({Key? key, required this.difficulty})
    : super(key: key);

  @override
  State<RockPaperScissorsGame> createState() => _RockPaperScissorsGameState();
}

class _RockPaperScissorsGameState extends State<RockPaperScissorsGame>
    with TickerProviderStateMixin {
  RPSChoice? playerChoice;
  RPSChoice? aiChoice;
  String? roundResult;
  int playerScore = 0;
  int aiScore = 0;
  int currentRound = 1;
  final int maxRounds = 5;
  bool isGameActive = false;
  bool isRoundInProgress = false;
  String? currentSessionId;
  late DateTime gameStartTime;

  late AnimationController _shakeController;
  late AnimationController _resultController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _resultAnimation;

  final Random _random = Random();
  List<RPSChoice> _aiHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startGame();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _resultAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
  }

  void _startGame() {
    // Start a new game session
    context.read<GameCubit>().startGame(
      GameType.rockPaperScissors,
      widget.difficulty,
    );

    // Get the current session ID from the state
    final gameState = context.read<GameCubit>().state;
    if (gameState is GamePlaying) {
      currentSessionId = gameState.currentSession.id;
    }

    setState(() {
      isGameActive = true;
      playerScore = 0;
      aiScore = 0;
      currentRound = 1;
      gameStartTime = DateTime.now();
      _aiHistory.clear();
    });
  }

  void _makeChoice(RPSChoice choice) {
    if (!isGameActive || isRoundInProgress) return;

    setState(() {
      playerChoice = choice;
      isRoundInProgress = true;
    });

    // Start shake animation
    _shakeController.forward().then((_) {
      _generateAIChoice();
      _determineWinner();
      _shakeController.reset();
      _resultController.forward().then((_) {
        _resultController.reset();

        if (currentRound >= maxRounds) {
          _endGame();
        } else {
          setState(() {
            currentRound++;
            isRoundInProgress = false;
            playerChoice = null;
            aiChoice = null;
            roundResult = null;
          });
        }
      });
    });
  }

  void _generateAIChoice() {
    RPSChoice choice;

    switch (widget.difficulty) {
      case GameDifficulty.easy:
        // Random choice
        choice = RPSChoice.values[_random.nextInt(3)];
        break;

      case GameDifficulty.medium:
        // Slightly predictable pattern
        if (_aiHistory.length >= 2 && _random.nextDouble() < 0.3) {
          choice = _getCounterChoice(_aiHistory.last);
        } else {
          choice = RPSChoice.values[_random.nextInt(3)];
        }
        break;

      case GameDifficulty.hard:
        // Adaptive strategy based on player history
        if (currentRound > 2 && _random.nextDouble() < 0.6) {
          choice = _getAdaptiveChoice();
        } else {
          choice = RPSChoice.values[_random.nextInt(3)];
        }
        break;

      case GameDifficulty.expert:
        // Very adaptive and defensive
        if (currentRound > 1 && _random.nextDouble() < 0.8) {
          choice = _getCounterChoice(playerChoice!);
        } else {
          choice = _getAdaptiveChoice();
        }
        break;
    }

    _aiHistory.add(choice);
    setState(() {
      aiChoice = choice;
    });
  }

  RPSChoice _getCounterChoice(RPSChoice choice) {
    switch (choice) {
      case RPSChoice.rock:
        return RPSChoice.paper;
      case RPSChoice.paper:
        return RPSChoice.scissors;
      case RPSChoice.scissors:
        return RPSChoice.rock;
    }
  }

  RPSChoice _getAdaptiveChoice() {
    // Simple pattern recognition
    if (_aiHistory.length >= 2) {
      final lastTwo = _aiHistory.skip(_aiHistory.length - 2).toList();
      if (lastTwo[0] == lastTwo[1]) {
        return _getCounterChoice(lastTwo[1]);
      }
    }
    return RPSChoice.values[_random.nextInt(3)];
  }

  void _determineWinner() {
    if (playerChoice == aiChoice) {
      roundResult = 'Draw';
    } else if (_playerWins(playerChoice!, aiChoice!)) {
      roundResult = 'You Win!';
      playerScore++;
    } else {
      roundResult = 'AI Wins!';
      aiScore++;
    }
  }

  bool _playerWins(RPSChoice player, RPSChoice ai) {
    return (player == RPSChoice.rock && ai == RPSChoice.scissors) ||
        (player == RPSChoice.paper && ai == RPSChoice.rock) ||
        (player == RPSChoice.scissors && ai == RPSChoice.paper);
  }

  void _endGame() {
    final isWin = playerScore > aiScore;
    final finalScore = playerScore * 100 + (isWin ? 500 : 0);
    final xpEarned = _calculateXP(finalScore, isWin);

    if (currentSessionId != null) {
      context.read<GameCubit>().completeGame(
        currentSessionId!,
        finalScore,
        xpEarned,
      );
    }

    // Update Profile with XP and game stats
    context.read<ProfileCubit>().addXP(xpEarned);
    if (isWin) {
      context.read<ProfileCubit>().incrementGameWin('rock_paper_scissors');
    }

    // Add game activity tracking
    final gameResult = isWin
        ? activity.ActivityType.gameWin
        : (playerScore == aiScore
              ? activity.ActivityType.gameDraw
              : activity.ActivityType.gameLoss);

    context.read<ProfileCubit>().addGameActivity(
      type: gameResult,
      gameType: activity.GameType.rockPaperScissors,
      difficulty: widget.difficulty.name,
      xpEarned: isWin ? xpEarned : (playerScore == aiScore ? 5 : 0),
      metadata: {
        'finalScore': finalScore,
        'playerScore': playerScore,
        'aiScore': aiScore,
        'rounds': currentRound - 1,
        'gameTime': DateTime.now().difference(gameStartTime).inSeconds,
      },
    );

    setState(() {
      isGameActive = false;
      isRoundInProgress = false;
    });

    _showGameOverDialog(isWin, finalScore);
  }

  int _calculateXP(int score, bool isWin) {
    int baseXP = 10;
    int scoreBonus = (score / 100).floor() * 5;
    int difficultyMultiplier = widget.difficulty.index + 1;
    int winBonus = isWin ? 25 : 5;

    return (baseXP + scoreBonus) * difficultyMultiplier + winBonus;
  }

  void _showGameOverDialog(bool isWin, int finalScore) {
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
                Icon(
                  isWin ? Icons.emoji_events : Icons.sentiment_neutral,
                  size: 60.r,
                  color: isWin ? Colors.amber : Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  isWin ? 'Victory!' : 'Game Over',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Final Score: $playerScore - $aiScore',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                ),
                Text(
                  'Points: $finalScore',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text('Back to Games'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetGame();
                      },
                      child: Text('Play Again'),
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

  void _resetGame() {
    setState(() {
      playerChoice = null;
      aiChoice = null;
      roundResult = null;
      playerScore = 0;
      aiScore = 0;
      currentRound = 1;
      isGameActive = false;
      isRoundInProgress = false;
      _aiHistory.clear();
    });
    _startGame();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.blue.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGameArea()),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
                Text(
                  'Rock Paper Scissors',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    widget.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'You',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                    ),
                    Text(
                      '$playerScore',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Round $currentRound/$maxRounds',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 100.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: currentRound / maxRounds,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'AI',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                    ),
                    Text(
                      '$aiScore',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // AI Choice
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AI Choice',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                ),
                SizedBox(height: 16.h),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            10 *
                            sin(_shakeAnimation.value * 10),
                        0,
                      ),
                      child: _buildChoiceDisplay(aiChoice, isAI: true),
                    );
                  },
                ),
              ],
            ),
          ),

          // Result
          AnimatedBuilder(
            animation: _resultAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _resultAnimation.value,
                child: Container(
                  height: 60.h,
                  child: roundResult != null
                      ? Text(
                          roundResult!,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(),
                          ),
                        )
                      : SizedBox(),
                ),
              );
            },
          ),

          // Player Choice
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Choice',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                ),
                SizedBox(height: 16.h),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            10 *
                            sin(_shakeAnimation.value * 10),
                        0,
                      ),
                      child: _buildChoiceDisplay(playerChoice),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceDisplay(RPSChoice? choice, {bool isAI = false}) {
    if (choice == null) {
      return Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: Colors.white30,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.help_outline, size: 40.r, color: Colors.white70),
      );
    }

    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: _getChoiceColor(choice),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(_getChoiceEmoji(choice), style: TextStyle(fontSize: 40.sp)),
      ),
    );
  }

  Widget _buildControls() {
    return GlassCard(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              isRoundInProgress ? 'Round in progress...' : 'Make your choice:',
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceButton(RPSChoice.rock),
                _buildChoiceButton(RPSChoice.paper),
                _buildChoiceButton(RPSChoice.scissors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(RPSChoice choice) {
    final isSelected = playerChoice == choice;
    final isDisabled = !isGameActive || isRoundInProgress;

    return GestureDetector(
      onTap: isDisabled ? null : () => _makeChoice(choice),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: isSelected ? _getChoiceColor(choice) : Colors.white30,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getChoiceEmoji(choice), style: TextStyle(fontSize: 24.sp)),
              Text(
                choice.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.medium:
        return Colors.orange;
      case GameDifficulty.hard:
        return Colors.red;
      case GameDifficulty.expert:
        return Colors.purple;
    }
  }

  Color _getChoiceColor(RPSChoice choice) {
    switch (choice) {
      case RPSChoice.rock:
        return Colors.grey;
      case RPSChoice.paper:
        return Colors.blue;
      case RPSChoice.scissors:
        return Colors.red;
    }
  }

  String _getChoiceEmoji(RPSChoice choice) {
    switch (choice) {
      case RPSChoice.rock:
        return '🪨';
      case RPSChoice.paper:
        return '📄';
      case RPSChoice.scissors:
        return '✂️';
    }
  }

  Color _getResultColor() {
    if (roundResult == null) return Colors.white;
    if (roundResult!.contains('You Win')) return Colors.green;
    if (roundResult!.contains('AI Wins')) return Colors.red;
    return Colors.orange;
  }
}
