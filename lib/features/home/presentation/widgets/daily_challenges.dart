import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/features/progression/domain/entities/progression.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/domain/entities/user_profile.dart';

class DailyChallenges extends StatelessWidget {
  const DailyChallenges({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock daily challenges data
    final challenges = [
      DailyChallenge(
        id: '1',
        title: 'Card Master',
        description: 'Score 1000 points in Card Shooter',
        targetScore: 1000,
        xpReward: 50,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      DailyChallenge(
        id: '2',
        title: 'Speed Demon',
        description: 'Complete Racing Rush in under 2 minutes',
        targetScore: 120,
        xpReward: 75,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
      DailyChallenge(
        id: '3',
        title: 'Puzzle Solver',
        description: 'Complete 5 puzzles in Puzzle Mania',
        targetScore: 5,
        xpReward: 60,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    ];

    return GlassCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: theme.colorScheme.primary,
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Daily Challenges',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Text(
                  'Resets in 12h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Challenges List
          ...challenges.map(
            (challenge) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _ChallengeItem(challenge: challenge),
            ),
          ),

          SizedBox(height: 8.h),

          // View All Button
          Center(
            child: GlassButton(
              text: 'View All Challenges',
              onPressed: () {
                // Navigate to challenges page
              },
              width: 200.w,
              height: 40.h,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeItem extends StatelessWidget {
  final DailyChallenge challenge;

  const _ChallengeItem({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: theme.colorScheme.surface.withOpacity(0.3),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Challenge Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Icon(
              _getChallengeIcon(
                challenge.title,
              ), // Updated to use title instead
              size: 20.w,
              color: Colors.white,
            ),
          ),

          SizedBox(width: 12.w),

          // Challenge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  challenge.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // XP Reward
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: Text(
              '+${challenge.xpReward} XP',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChallengeIcon(String gameType) {
    switch (gameType) {
      case 'cardShooter':
        return Icons.style_outlined;
      case 'ballBlaster':
        return Icons.sports_baseball_outlined;
      case 'racingRush':
        return Icons.directions_car_outlined;
      case 'puzzleMania':
        return Icons.extension_outlined;
      case 'droneFlight':
        return Icons.flight_outlined;
      default:
        return Icons.star_outline;
    }
  }
}
