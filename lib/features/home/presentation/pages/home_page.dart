import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/pages/activity_history_page.dart';
import '../../../games/presentation/cubit/game_cubit.dart';
import '../../../games/domain/entities/game.dart';
import '../widgets/game_card.dart';
import '../widgets/character_selector.dart';
import '../widgets/profile_header.dart';
import '../widgets/daily_challenges.dart';
import '../widgets/difficulty_selection_dialog.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              const HomePageContent(),
              const GamesPageContent(),
              const _LeaderboardPage(),
              const ProfilePage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlassBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          GlassBottomNavigationBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          GlassBottomNavigationBarItem(
            icon: Icons.games_outlined,
            activeIcon: Icons.games,
            label: 'Games',
          ),
          // GlassBottomNavigationBarItem(
          //   icon: Icons.people_outline,
          //   activeIcon: Icons.people,
          //   label: 'Characters',
          // ),
          GlassBottomNavigationBarItem(
            icon: Icons.leaderboard_outlined,
            activeIcon: Icons.leaderboard,
            label: 'Leaderboard',
          ),
          GlassBottomNavigationBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 196.h,
          floating: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: const ProfileHeader(),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Section
              AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Welcome Section with Integrated Level Progress
                      BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, state) {
                          if (state is ProfileLoaded) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome to GameX',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.displayMedium,
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Choose your adventure and start gaming!',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Testing Menu
                                  ],
                                ),
                                SizedBox(height: 16.h),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to GameX',
                                style: Theme.of(
                                  context,
                                ).textTheme.displayMedium,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Choose your adventure and start gaming!',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Daily Challenges
                      const DailyChallenges(),
                      SizedBox(height: 24.h),

                      // Featured Games
                      Text(
                        'Featured Games',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16.h),

                      BlocBuilder<GameCubit, GameState>(
                        builder: (context, state) {
                          if (state is GameLoaded) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16.w,
                                    mainAxisSpacing: 16.h,
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: state.games.take(4).length,
                              itemBuilder: (context, index) {
                                final game = state.games.reversed.toList()[index];
                                return GameCard(
                                  game: game,
                                  onTap: () => _startGame(context, game),
                                );
                              },
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Character Selection
                      Text(
                        'Your Character',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16.h),
                      const CharacterSelector(),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _startGame(BuildContext context, GameMetadata game) {
    // Show difficulty selection dialog first
    showDialog(
      context: context,
      builder: (context) => DifficultySelectionDialog(
        game: game,
        onDifficultySelected: (difficulty) {
          Navigator.pop(context);
          _navigateToGame(context, game, difficulty);
        },
      ),
    );
  }

  void _navigateToGame(
      BuildContext context,
      GameMetadata game,
      GameDifficulty difficulty,
      ) {
    switch (game.type) {
      case GameType.rockPaperScissors:
        Navigator.pushNamed(
          context,
          '/rock-paper-scissors',
          arguments: difficulty,
        );
        break;
      case GameType.ticTacToe:
        Navigator.pushNamed(context, '/tic-tac-toe', arguments: difficulty);
        break;
      case GameType.memoryCards:
        Navigator.pushNamed(context, '/memory-cards', arguments: difficulty);
        break;
      case GameType.ballBlaster:
        Navigator.pushNamed(context, '/ball-blaster', arguments: difficulty);
        break;
      case GameType.carRacing:
        Navigator.pushNamed(context, '/car-racing', arguments: difficulty);
        break;
      case GameType.droneFlight:
        Navigator.pushNamed(context, '/drone-flight', arguments: difficulty);
        break;
      case GameType.puzzleMania:
        Navigator.pushNamed(context, '/puzzle-mania', arguments: difficulty);
        break;
      case GameType.droneShooter:
        Navigator.pushNamed(context, '/drone-shooter', arguments: difficulty);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.name} is coming soon!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
    }
  }
}

class GamesPageContent extends StatelessWidget {
  const GamesPageContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Games'),
          backgroundColor: Colors.transparent,
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: BlocBuilder<GameCubit, GameState>(
            builder: (context, state) {
              if (state is GameLoaded) {
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = state.games[index];
                    return GameCard(
                      game: game,
                      onTap: () => _startGame(context, game),
                    );
                  }, childCount: state.games.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.7,
                  ),
                );
              } else if (state is GameCompleted) {
                // When game is completed, automatically return to games list
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<GameCubit>().returnToGamesList();
                });
                // Show games while transitioning
                final games = GameRepository.getAllGames();
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = games[index];
                    return GameCard(
                      game: game,
                      onTap: () => _startGame(context, game),
                    );
                  }, childCount: games.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.7,
                  ),
                );
              } else if (state is GamePlaying) {
                // Show games list even when a game is playing
                final games = GameRepository.getAllGames();
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = games[index];
                    return GameCard(
                      game: game,
                      onTap: () => _startGame(context, game),
                    );
                  }, childCount: games.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.7,
                  ),
                );
              } else if (state is GameError) {
                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load games',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<GameCubit>().reloadGames(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              // Loading state or initial state
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ],
    );
  }

  void _startGame(BuildContext context, GameMetadata game) {
    // Show difficulty selection dialog first
    showDialog(
      context: context,
      builder: (context) => DifficultySelectionDialog(
        game: game,
        onDifficultySelected: (difficulty) {
          Navigator.pop(context);
          _navigateToGame(context, game, difficulty);
        },
      ),
    );
  }

  void _navigateToGame(
    BuildContext context,
    GameMetadata game,
    GameDifficulty difficulty,
  ) {
    switch (game.type) {
      case GameType.rockPaperScissors:
        Navigator.pushNamed(
          context,
          '/rock-paper-scissors',
          arguments: difficulty,
        );
        break;
      case GameType.ticTacToe:
        Navigator.pushNamed(context, '/tic-tac-toe', arguments: difficulty);
        break;
      case GameType.memoryCards:
        Navigator.pushNamed(context, '/memory-cards', arguments: difficulty);
        break;
      case GameType.ballBlaster:
        Navigator.pushNamed(context, '/ball-blaster', arguments: difficulty);
        break;
      case GameType.carRacing:
        Navigator.pushNamed(context, '/car-racing', arguments: difficulty);
        break;
      case GameType.droneFlight:
        Navigator.pushNamed(context, '/drone-flight', arguments: difficulty);
        break;
      case GameType.puzzleMania:
        Navigator.pushNamed(context, '/puzzle-mania', arguments: difficulty);
        break;
      case GameType.droneShooter:
        Navigator.pushNamed(context, '/drone-shooter', arguments: difficulty);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.name} is coming soon!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
    }
  }
}

class _LeaderboardPage extends StatelessWidget {
  const _LeaderboardPage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Leaderboard'),
          backgroundColor: Colors.transparent,
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: SliverToBoxAdapter(
            child: GlassCard(
              child: Column(
                children: [
                  Text(
                    'Global Rankings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Compete with players worldwide',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

