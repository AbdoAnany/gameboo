import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../characters/presentation/cubit/character_cubit.dart';

class CharacterSelector extends StatelessWidget {
  const CharacterSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, state) {
        if (state is CharacterLoaded) {
          return GlassCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Character Display
                Row(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.selectedCharacter.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            state.selectedCharacter.specialty,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.selectedCharacter.description,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Character List
                Text(
                  'Choose Character',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),

                SizedBox(
                  height: 80.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.characters.length,
                    itemBuilder: (context, index) {
                      final character = state.characters[index];
                      final isSelected =
                          character.type == state.selectedCharacter.type;

                      return Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: GestureDetector(
                          onTap: () {
                            if (character.isUnlocked) {
                              context.read<CharacterCubit>().selectCharacter(
                                character.type,
                              );
                            }
                          },
                          child: Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
//                               image: DecorationImage(image: AssetImage(
//
// character.imagePath,
//                               ),fit: BoxFit.cover
//                               ),
                              gradient: LinearGradient(
                                      colors: character.color.map((color) => Color(
                                        int.parse(color),
                                      )).toList(),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                    ),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2.w,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [

                                ClipOval(
                                  child: Image.asset(
                                    character.imagePath,
                                    fit: BoxFit.cover,
                                    width: 64.w,
                                    height: 64.w,
                                  ),
                                ),
                                // Center(
                                //   child: Icon(
                                //     Icons.person,
                                //     size: 24.w,
                                //     color: isSelected
                                //         ? Colors.white
                                //         : theme.colorScheme.onSurface,
                                //   ),
                                // ),
                                if (!character.isUnlocked)
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 16.w,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 12.h),

                // Character Abilities
                Text(
                  'Abilities',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),

                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: state.selectedCharacter.abilities.entries.map((
                    entry,
                  ) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}x',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }

        return GlassCard(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: 120.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
