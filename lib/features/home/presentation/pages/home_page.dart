import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../characters/presentation/cubit/character_cubit.dart';
import '../../../games/presentation/cubit/game_cubit.dart';
import '../../../games/domain/entities/game.dart';
import '../../../characters/domain/entities/character.dart';
import '../widgets/game_card.dart';
import '../widgets/character_selector.dart';
import '../widgets/profile_header.dart';
import '../widgets/daily_challenges.dart';
import '../../../characters/presentation/pages/characters_page.dart';

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
              CharactersPage(),
              const _LeaderboardPage(),
              const _ProfilePage(),
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
          GlassBottomNavigationBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Characters',
          ),
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
                                final game = state.games[index];
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
    // Navigate to game screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${game.name}...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
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
              }
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
    // Navigate to game screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${game.name}...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
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

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    GlassCard(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40.w,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Icon(
                              Icons.person,
                              size: 40.w,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            state.profile.username,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Level ${state.profile.level}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ProfileStat(
                                label: 'XP',
                                value: state.profile.xp.toString(),
                              ),
                              _ProfileStat(
                                label: 'Wins',
                                value: state.profile.totalWins.toString(),
                              ),
                              _ProfileStat(
                                label: 'Badges',
                                value: state.profile.earnedBadges.length
                                    .toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: 16.h),
                          _SettingsItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          BlocBuilder<ThemeCubit, ThemeState>(
                            builder: (context, themeState) {
                              final currentTheme = themeState is ThemeChanged
                                  ? themeState.themeMode
                                  : ThemeMode.system;

                              final isDarkMode =
                                  currentTheme == ThemeMode.dark ||
                                  (currentTheme == ThemeMode.system &&
                                      Theme.of(context).brightness ==
                                          Brightness.dark);

                              return _SettingsItem(
                                icon: isDarkMode
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                title: isDarkMode
                                    ? 'Switch to Light Mode'
                                    : 'Switch to Dark Mode',
                                onTap: () {
                                  context.read<ThemeCubit>().toggleTheme();
                                },
                              );
                            },
                          ),
                          _SettingsItem(
                            icon: Icons.share_outlined,
                            title: 'Share Profile',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ]),
                );
              }
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
