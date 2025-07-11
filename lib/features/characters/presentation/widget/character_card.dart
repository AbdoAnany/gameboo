import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gameboo/core/theme/app_theme.dart';
import 'package:gameboo/features/characters/domain/entities/character.dart';
import 'package:gameboo/shared/widgets/glass_widgets.dart';

class CharacterCard extends StatelessWidget {
  final Character character;

  const CharacterCard({required this.character, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: ClipOval(
              child: Image.network(
                character.imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 4.h),
                Text(
                  character.specialty,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8.h),
                if (!character.isUnlocked) ...[
                  Text(
                    character.unlockRequirement.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Level ${character.level}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!character.isUnlocked)
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
        ],
      ),
    );
  }
}
