import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../games/domain/entities/game.dart';

class DifficultySelectionDialog extends StatelessWidget {
  final GameMetadata game;
  final Function(GameDifficulty) onDifficultySelected;

  const DifficultySelectionDialog({
    Key? key,
    required this.game,
    required this.onDifficultySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Difficulty',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                game.name,
                style: TextStyle(fontSize: 16.sp, color: Colors.white70),
              ),
              SizedBox(height: 20.h),
              ...game.availableDifficulties
                  .map(
                    (difficulty) => _buildDifficultyButton(context, difficulty),
                  )
                  .toList(),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    GameDifficulty difficulty,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ElevatedButton(
        onPressed: () => onDifficultySelected(difficulty),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getDifficultyColor(difficulty),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              difficulty.name.toUpperCase(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            Icon(_getDifficultyIcon(difficulty)),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
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

  IconData _getDifficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.star;
      case GameDifficulty.medium:
        return Icons.star_half;
      case GameDifficulty.hard:
        return Icons.star_border;
      case GameDifficulty.expert:
        return Icons.whatshot;
    }
  }
}
