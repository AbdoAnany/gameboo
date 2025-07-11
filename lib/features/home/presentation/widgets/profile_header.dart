import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../characters/presentation/cubit/character_cubit.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is ProfileLoaded) {
          return BlocBuilder<CharacterCubit, CharacterState>(
            builder: (context, characterState) {
              final currentXP = profileState.profile.xp;
              final currentLevel = profileState.profile.level;

              // Calculate XP needed for current level (progressive XP requirement)
              final currentLevelXP = _calculateLevelXP(currentLevel);
              final previousLevelXP = currentLevel > 1
                  ? _calculateLevelXP(currentLevel - 1)
                  : 0;
              final levelProgress = currentXP - previousLevelXP;
              final xpForThisLevel = currentLevelXP - previousLevelXP;

              return GlassCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 25.w,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: 12.w),

                        // Profile Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileState.profile.username,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Rank ${profileState.profile.rank}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notifications/Settings Button
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'add_xp':
                                context.read<ProfileCubit>().addXP(100);
                                break;
                              case 'level_up':
                                context.read<ProfileCubit>().levelUp();
                                break;
                              case 'reset':
                                context.read<ProfileCubit>().resetProgress();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'add_xp',
                              child: Row(
                                children: [
                                  Icon(Icons.add),
                                  SizedBox(width: 8),
                                  Text('Add 100 XP'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'level_up',
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up),
                                  SizedBox(width: 8),
                                  Text('Level Up'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh),
                                  SizedBox(width: 8),
                                  Text('Reset Progress'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Level Progress Bar with Animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOutCubic,
                      tween: Tween<double>(
                        begin: 0,
                        end: levelProgress.toDouble(),
                      ),
                      builder: (context, animatedProgress, child) {
                        return GlassXPProgressBar(
                          currentXP: animatedProgress.round(),
                          maxXP: xpForThisLevel,
                          level: currentLevel,
                          title: 'Progress',
                          height: 60.h,
                          showXPNumbers: true,
                          showLevel: true,
                          animationDuration: const Duration(milliseconds: 800),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
        return GlassCard(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Progressive XP calculation: Level 1 = 1000 XP, Level 2 = 2200 XP, Level 3 = 3600 XP, etc.
  int _calculateLevelXP(int level) {
    if (level <= 1) return 1000;
    return (level * 1000) + ((level - 1) * 200);
  }
}
