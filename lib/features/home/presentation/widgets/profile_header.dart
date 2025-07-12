import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../characters/presentation/cubit/character_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState is ProfileLoaded) {
          final profile = profileState.profile;
          final progress = profile.progressModel;

          return GlassCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildProfileAvatar(context, rank: profile.rank),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Rank: ${profile.rank.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // if(kIsDebugMode)
                    // PopupMenuButton<String>(
                    //   icon: Icon(Icons.more_vert,
                    //       color: theme.colorScheme.primary),
                    //   onSelected: (value) {
                    //     final cubit = context.read<ProfileCubit>();
                    //     switch (value) {
                    //       case 'add_xp':
                    //         cubit.addXP(100);
                    //         break;
                    //       case 'level_up':
                    //         cubit.levelUp();
                    //         break;
                    //       case 'reset':
                    //         cubit.resetProgress();
                    //         break;
                    //     }
                    //   },
                    //   itemBuilder: (context) => [
                    //     const PopupMenuItem(
                    //       value: 'add_xp',
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.add),
                    //           SizedBox(width: 8),
                    //           Text('Add 100 XP'),
                    //         ],
                    //       ),
                    //     ),
                    //     const PopupMenuItem(
                    //       value: 'level_up',
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.trending_up),
                    //           SizedBox(width: 8),
                    //           Text('Level Up'),
                    //         ],
                    //       ),
                    //     ),
                    //     const PopupMenuItem(
                    //       value: 'reset',
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.refresh),
                    //           SizedBox(width: 8),
                    //           Text('Reset Progress'),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                SizedBox(height: 12.h),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOutCubic,
                  tween: Tween<double>(begin: 0, end: progress.progressPercent),
                  builder: (context, animatedPercent, child) {
                    return GlassXPProgressBar(
                      currentXP:
                          (progress.previousLevelXP +
                                  (progress.nextLevelXP -
                                          progress.previousLevelXP) *
                                      animatedPercent)
                              .round(),
                      maxXP: progress.nextLevelXP,
                      level: profile.level,
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
        }

        // Loading skeleton
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

  Widget _buildProfileAvatar(
    BuildContext context, {
    required UserRankType rank,
  }) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: 
          AssetImage(  getBadgeAsset(rank),)
        ),
        // gradient: AppTheme.primaryGradient,
      ),
      // child: Icon(Icons.person, size: 25.w, color: Colors.white),
    );
  }
}

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

            // Calculate XP range for this level
            final currentLevelXP = _calculateLevelXP(currentLevel);
            final previousLevelXP = currentLevel > 1
                ? _calculateLevelXP(currentLevel - 1)
                : 0;
            final levelProgress = currentXP - previousLevelXP;
            final xpForThisLevel = currentLevelXP - previousLevelXP;

            // Get badge rank
            final UserRankType userRank = _parseRank(
              profileState.profile.rank.name,
            );

            return GlassCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildProfileAvatar(context, rank: userRank),
                      SizedBox(width: 12.w),
                      // User info
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
                              'Rank: ${profileState.profile.rank}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action button
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.primary,
                        ),
                        onSelected: (value) {
                          final cubit = context.read<ProfileCubit>();
                          switch (value) {
                            case 'add_xp':
                              cubit.addXP(100);
                              break;
                            case 'level_up':
                              cubit.levelUp();
                              break;
                            case 'reset':
                              cubit.resetProgress();
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

                  // XP progress bar
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

      // Skeleton loading
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

// Avatar with badge overlay
Widget _buildProfileAvatar(BuildContext context, {required UserRankType rank}) {
  return Stack(
    alignment: Alignment.bottomRight,
    children: [
      Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
        ),
        child: Icon(Icons.person, size: 25.w, color: Colors.white),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Image.asset(getBadgeAsset(rank), width: 20.w, height: 20.w),
      ),
    ],
  );
}

int _calculateLevelXP(int level) {
  if (level <= 1) return 1000;
  int n = level - 1;
  return 1000 + n * (1000 + 200) + (n * (n - 1) * 200) ~/ 2;
}

// Convert string rank to enum safely
UserRankType _parseRank(String value) {
  switch (value.toLowerCase()) {
    case 'basic':
      return UserRankType.basic;
    case 'advance':
      return UserRankType.advance;
    case 'pro':
      return UserRankType.pro;
    case 'premium':
      return UserRankType.premium;
    default:
      return UserRankType.basic;
  }
}
