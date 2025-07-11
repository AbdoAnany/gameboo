import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../shared/widgets/glass_widgets.dart';
import '../../presentation/cubit/profile_cubit.dart';
import '../../domain/entities/game_activity.dart';
import '../../domain/entities/user_profile.dart';

class ActivityHistoryPage extends StatelessWidget {
  const ActivityHistoryPage({Key? key}) : super(key: key);

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
          child: Column(
            children: [
              // Header
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
                            'Activity History',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your gaming journey',
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

              // Activity List
              Expanded(
                child: BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoaded) {
                      final activities = state.profile.activityHistory;

                      if (activities.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64.sp,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No activities yet',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Start playing games to see your history!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return AnimationLimiter(
                        child: ListView.separated(
                          padding: EdgeInsets.all(20.w),
                          itemCount: activities.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: ActivityCard(activity: activity),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else if (state is ProfileLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ProfileError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64.sp, color: Colors.red),
                            SizedBox(height: 16.h),
                            Text(
                              'Error loading activities',
                              style: theme.textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              state.message,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () {
                                // Reload profile by calling a simple method
                                Navigator.pop(context);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final GameActivity activity;

  const ActivityCard({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      child: Row(
        children: [
          // Activity Icon
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _getActivityColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _getActivityColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                ActivityHelper.getActivityIcon(activity.type),
                style: TextStyle(fontSize: 24.sp),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Activity Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (activity.xpEarned > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '+${activity.xpEarned} XP',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  activity.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatTimestamp(activity.timestamp),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (activity.metadata.containsKey('gameTime')) ...[
                      SizedBox(width: 12.w),
                      Icon(Icons.timer, size: 12.sp, color: Colors.grey[400]),
                      SizedBox(width: 4.w),
                      Text(
                        '${activity.metadata['gameTime']}s',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                    if (activity.metadata.containsKey('moves')) ...[
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.touch_app,
                        size: 12.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${activity.metadata['moves']} moves',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.gameWin:
        return Colors.green;
      case ActivityType.gameLoss:
        return Colors.red;
      case ActivityType.gameDraw:
        return Colors.orange;
      case ActivityType.levelUp:
        return Colors.purple;
      case ActivityType.badgeEarned:
        return Colors.blue;
      case ActivityType.xpGained:
        return Colors.amber;
      case ActivityType.characterUnlocked:
        return Colors.pink;
      case ActivityType.shopPurchase:
        return Colors.cyan;
      case ActivityType.challengeCompleted:
        return Colors.teal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
