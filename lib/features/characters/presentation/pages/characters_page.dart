import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gameboo/features/characters/presentation/widget/character_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../cubit/character_cubit.dart';
import '../../domain/entities/character.dart';
import 'character_detail_page.dart';

class CharactersPage extends StatelessWidget {
  const CharactersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Characters'),
          backgroundColor: Colors.transparent,
          floating: true,
        ),
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: BlocBuilder<CharacterCubit, CharacterState>(
            builder: (context, state) {
              if (state is CharacterLoaded) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final character = state.characters[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CharacterDetailPage(character: character),
                            ),
                          );
                          (context as Element).markNeedsBuild();
                        },
                        child: CharacterCard(character: character),
                      ),
                    );
                  }, childCount: state.characters.length),
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

