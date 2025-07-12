import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/game_activity.dart' as activity;
import '../../domain/entities/game.dart';

enum CardState { hidden, revealed, matched }

class GameCard {
  final int id;
  final String symbol;
  CardState state;

  GameCard({
    required this.id,
    required this.symbol,
    this.state = CardState.hidden,
  });
}

class MemoryCardsGame extends StatefulWidget {
  final GameDifficulty difficulty;

  const MemoryCardsGame({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<MemoryCardsGame> createState() => _MemoryCardsGameState();
}

class _MemoryCardsGameState extends State<MemoryCardsGame>
    with TickerProviderStateMixin {
  late List<GameCard> cards;
  late int gridSize;
  late int totalPairs;
  late int matchedPairs;
  late int moves;
  late int incorrectMoves;
  late bool gameCompleted;
  late DateTime gameStartTime;
  late Duration gameTime;
  late GameDifficulty selectedDifficulty;

  // Animation controllers
  late AnimationController _flipAnimationController;
  late AnimationController _matchAnimationController;
  late AnimationController _completionAnimationController;

  // Game state
  GameCard? firstSelectedCard;
  GameCard? secondSelectedCard;
  bool isProcessingMove = false;
  int? firstSelectedIndex;
  int? secondSelectedIndex;

  // Card symbols for different difficulty levels
  static const List<String> easySymbols = ['🎮', '🎯', '🎲', '🎪', '🎨', '🎭'];
  static const List<String> mediumSymbols = [
    '🎮',
    '🎯',
    '🎲',
    '🎪',
    '🎨',
    '🎭',
    '🎸',
    '🎺',
    '🎻',
    '🎹',
  ];
  static const List<String> hardSymbols = [
    '🎮',
    '🎯',
    '🎲',
    '🎪',
    '🎨',
    '🎭',
    '🎸',
    '🎺',
    '🎻',
    '🎹',
    '🎬',
    '🎤',
    '🎧',
    '🎼',
    '🎵',
  ];
  static const List<String> expertSymbols = [
    '🎮',
    '🎯',
    '🎲',
    '🎪',
    '🎨',
    '🎭',
    '🎸',
    '🎺',
    '🎻',
    '🎹',
    '🎬',
    '🎤',
    '🎧',
    '🎼',
    '🎵',
    '🎪',
    '🎊',
    '🎉',
  ];

  @override
  void initState() {
    super.initState();
    selectedDifficulty = widget.difficulty;
    _setupGame();
    _initializeAnimations();
    _startGame();
  }

  void _setupGame() {
    // Configure game based on difficulty
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        gridSize = 3; // 3x4 grid, 6 pairs
        totalPairs = 6;
        break;
      case GameDifficulty.medium:
        gridSize = 4; // 4x5 grid, 10 pairs
        totalPairs = 10;
        break;
      case GameDifficulty.hard:
        gridSize = 5; // 5x6 grid, 15 pairs
        totalPairs = 15;
        break;
      case GameDifficulty.expert:
        gridSize = 6; // 6x6 grid, 18 pairs
        totalPairs = 18;
        break;
    }
  }

  void _initializeAnimations() {
    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _completionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _startGame() {
    List<String> symbols;
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        symbols = easySymbols.take(totalPairs).toList();
        break;
      case GameDifficulty.medium:
        symbols = mediumSymbols.take(totalPairs).toList();
        break;
      case GameDifficulty.hard:
        symbols = hardSymbols.take(totalPairs).toList();
        break;
      case GameDifficulty.expert:
        symbols = expertSymbols.take(totalPairs).toList();
        break;
    }

    // Create pairs of cards
    List<GameCard> gameCards = [];
    for (int i = 0; i < symbols.length; i++) {
      gameCards.add(GameCard(id: i * 2, symbol: symbols[i]));
      gameCards.add(GameCard(id: i * 2 + 1, symbol: symbols[i]));
    }

    // Shuffle cards
    gameCards.shuffle();

    setState(() {
      cards = List.generate(
        gameCards.length,
        (i) => GameCard(
          id: gameCards[i].id,
          symbol: gameCards[i].symbol,
          state: CardState.revealed,
        ),
      );
      matchedPairs = 0;
      moves = 0;
      incorrectMoves = 0;
      gameCompleted = false;
      gameStartTime = DateTime.now();
      gameTime = Duration.zero;
      firstSelectedCard = null;
      secondSelectedCard = null;
      isProcessingMove = true;
      firstSelectedIndex = null;
      secondSelectedIndex = null;
    });

    // Force rebuild to trigger flip animation to revealed
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        cards = List.generate(
          cards.length,
          (i) => GameCard(
            id: cards[i].id,
            symbol: cards[i].symbol,
            state: CardState.revealed,
          ),
        );
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        cards = List.generate(
          cards.length,
          (i) => GameCard(
            id: cards[i].id,
            symbol: cards[i].symbol,
            state: CardState.hidden,
          ),
        );
        isProcessingMove = false;
      });
    });
  }

  void _onCardTapped(int index) {
    if (isProcessingMove ||
        cards[index].state != CardState.hidden ||
        index == firstSelectedIndex) {
      return;
    }

    setState(() {
      cards[index].state = CardState.revealed;
    });

    _flipAnimationController.forward().then((_) {
      _flipAnimationController.reset();
    });

    if (firstSelectedCard == null) {
      // First card selection
      firstSelectedCard = cards[index];
      firstSelectedIndex = index;
    } else {
      // Second card selection
      secondSelectedCard = cards[index];
      secondSelectedIndex = index;
      moves++;
      isProcessingMove = true;

      // Check for match after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _checkForMatch();
      });
    }
  }

  void _checkForMatch() {
    if (firstSelectedCard!.symbol == secondSelectedCard!.symbol) {
      // Match found!
      setState(() {
        cards[firstSelectedIndex!].state = CardState.matched;
        cards[secondSelectedIndex!].state = CardState.matched;
        matchedPairs++;
      });

      _matchAnimationController.forward().then((_) {
        _matchAnimationController.reset();
      });

      // Check if game is completed
      if (matchedPairs == totalPairs) {
        _completeGame();
      }
    } else {
      // No match
      setState(() {
        cards[firstSelectedIndex!].state = CardState.hidden;
        cards[secondSelectedIndex!].state = CardState.hidden;
        incorrectMoves++;
      });
    }

    // Reset selections
    setState(() {
      firstSelectedCard = null;
      secondSelectedCard = null;
      firstSelectedIndex = null;
      secondSelectedIndex = null;
      isProcessingMove = false;
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
      gameTime = DateTime.now().difference(gameStartTime);
    });

    _completionAnimationController.forward();

    final xpEarned = _calculateXP();
    Future.microtask(() async {
      await context.read<ProfileCubit>().addXP(xpEarned);
      context.read<ProfileCubit>().incrementGameWin('memoryCards');
      await context.read<ProfileCubit>().addGameActivity(
        type: activity.ActivityType.gameWin,
        gameType: activity.GameType.memoryCards,
        difficulty: selectedDifficulty.name,
        xpEarned: xpEarned,
        metadata: {
          'totalMoves': moves,
          'incorrectMoves': incorrectMoves,
          'accuracy': moves > 0
              ? ((moves - incorrectMoves) / moves * 100).round()
              : 100,
          'gameTimeSeconds': gameTime.inSeconds,
          'pairs': totalPairs,
          'efficiency': totalPairs > 0
              ? (totalPairs / moves * 100).round()
              : 100,
        },
      );
      _showCompletionDialog();
    });
  }

  int _calculateXP() {
    int baseXP = 20;
    int difficultyMultiplier = selectedDifficulty.index + 1;
    int accuracyBonus = incorrectMoves == 0
        ? 50
        : incorrectMoves <= 3
        ? 25
        : incorrectMoves <= 5
        ? 10
        : 0;
    int speedBonus = gameTime.inSeconds < 60
        ? 30
        : gameTime.inSeconds < 120
        ? 15
        : gameTime.inSeconds < 180
        ? 5
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
                  'Congratulations!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Game completed in ${moves} moves',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Time: ${gameTime.inMinutes}:${(gameTime.inSeconds % 60).toString().padLeft(2, '0')}',
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

  void _changeDifficulty(GameDifficulty newDifficulty) {
    setState(() {
      selectedDifficulty = newDifficulty;
    });
    _setupGame();
    _startGame();
  }

  @override
  void dispose() {
    _flipAnimationController.dispose();
    _matchAnimationController.dispose();
    _completionAnimationController.dispose();
    super.dispose();
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
                      child: GlassContainer(
                        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
                        blur: 1,
                        opacity: .0,

                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
                                    'Memory Cards',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Moves: $moves',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Pairs: $matchedPairs/$totalPairs',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
SizedBox( height: 8.h),
                // Game Stats
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
                              _buildStatItem(
                                'Moves',
                                moves.toString(),
                                Colors.blue,
                              ),
                              _buildStatItem(
                                'Matches',
                                matchedPairs.toString(),
                                Colors.green,
                              ),
                              _buildStatItem(
                                'Accuracy',
                                moves > 0
                                    ? '${((moves - incorrectMoves) / moves * 100).round()}%'
                                    : '100%',
                                Colors.orange,
                              ),
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
                        padding: EdgeInsets.symmetric(horizontal: 0,vertical: 16.h),
                        child: GlassCard(
                          padding:  EdgeInsets.symmetric(horizontal: 32.w,vertical: 16.h),
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


                // Game Board
                Expanded(
                  child: AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0.w),
                          child: GlassCard(
                            child: Padding(
                              padding: EdgeInsets.all(0.w),
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _getColumnCount(),
                                      crossAxisSpacing: 8.w,
                                      mainAxisSpacing: 8.h,
                                      // childAspectRatio:1.4,
                                    ),
                                itemCount: cards.length,
                                itemBuilder: (context, index) {
                                  return _buildGameCard(index);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Control Buttons
                AnimationConfiguration.staggeredList(
                    position: 3,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w,vertical: 8.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 0.h),
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
                        )))

              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getColumnCount() {
    switch (selectedDifficulty) {
      case GameDifficulty.easy:
        return 4;
      case GameDifficulty.medium:
        return 5;
      case GameDifficulty.hard:
        return 6;
      case GameDifficulty.expert:
        return 6;
    }
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

  Widget _buildGameCard(int index) {
    final card = cards[index];
    return _AnimatedGameCard(
      key: ValueKey(card.id),
      card: card,
      onTap: () => _onCardTapped(index),
    );
  }
}

class _AnimatedGameCard extends StatefulWidget {
  final GameCard card;
  final VoidCallback onTap;

  const _AnimatedGameCard({Key? key, required this.card, required this.onTap})
    : super(key: key);

  @override
  State<_AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<_AnimatedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  CardState? _lastState;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _lastState = widget.card.state;
  }

  @override
  void didUpdateWidget(covariant _AnimatedGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastState != widget.card.state) {
      if (widget.card.state == CardState.revealed ||
          widget.card.state == CardState.matched) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _lastState = widget.card.state;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRevealed =
        widget.card.state == CardState.revealed ||
        widget.card.state == CardState.matched;
    final isMatched = widget.card.state == CardState.matched;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFront = angle <= 3.14159 / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              decoration: BoxDecoration(
                color: isMatched
                    ? Colors.green.withOpacity(0.3)
                    : isRevealed
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isMatched
                      ? Colors.green
                      : isRevealed
                      ? Colors.blue.withOpacity(0.6)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isMatched
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isFront
                    ? Icon(
                        Icons.question_mark,
                        size: 24.sp,
                        color: Colors.white.withOpacity(0.5),
                      )
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: Text(
                          widget.card.symbol,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
