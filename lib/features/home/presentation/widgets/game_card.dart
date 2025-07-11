import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../games/domain/entities/game.dart';

class GameCard extends StatelessWidget {
  final GameMetadata game;
  final VoidCallback onTap;

  const GameCard({Key? key, required this.game, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = !game.isUnlocked;

    return GlassCard(
      onTap: isLocked ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Icon/Image
          Container(
            height: 80.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: AppTheme.primaryGradient,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getGameIcon(game.type),
                    size: 40.w,
                    color: Colors.white,
                  ),
                ),
                if (isLocked)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock_outline,
                        size: 32.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Game Title
          Text(
            game.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.h),

          // Game Description
          Text(
            game.description,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 12.h),

          // Unlock Level or Play Button
          if (isLocked) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Text(
                'Level ${game.unlockLevel} Required',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        'Play',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: theme.colorScheme.surface.withOpacity(0.5),
                  ),
                  child: Icon(
                    Icons.star_outline,
                    size: 16.w,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getGameIcon(GameType type) {
    switch (type) {
      case GameType.cardShooter:
        return Icons.style_outlined;
      case GameType.ballBlaster:
        return Icons.sports_baseball_outlined;
      case GameType.racingRush:
        return Icons.directions_car_outlined;
      case GameType.puzzleMania:
        return Icons.extension_outlined;
      case GameType.droneFlight:
        return Icons.flight_outlined;
    }
  }
}
