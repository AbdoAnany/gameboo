import 'package:flutter/material.dart';
import 'features/games/presentation/pages/ball_blaster_game.dart';
import 'features/games/presentation/pages/car_racing_game.dart';
import 'features/games/presentation/pages/puzzle_mania_game.dart';
import 'features/games/presentation/pages/drone_flight_game/drone_flight_game.dart';
import 'features/games/presentation/pages/drone_shooter/drone_shooter_game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/cache/cache_service.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/characters/presentation/cubit/character_cubit.dart';
import 'features/games/presentation/cubit/game_cubit.dart';
import 'features/games/presentation/pages/rock_paper_scissors_game.dart';
import 'features/games/presentation/pages/tic_tac_toe/tic_tac_toe_game.dart';
import 'features/games/presentation/pages/memory_cards_game.dart';
import 'features/games/domain/entities/game.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/shop/presentation/cubit/shop_cubit.dart';
import 'features/shop/presentation/pages/shop_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Cache Service
  await CacheService.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const GameBooApp());
}

class GameBooApp extends StatelessWidget {
  const GameBooApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ThemeCubit()),
            BlocProvider(create: (context) => AuthCubit()),
            BlocProvider(create: (context) => ProfileCubit()),
            BlocProvider(create: (context) => CharacterCubit()),
            BlocProvider(create: (context) => GameCubit()),
            BlocProvider(create: (context) => ShopCubit()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final themeMode = state is ThemeChanged
                  ? state.themeMode
                  : ThemeMode.system;

              return MaterialApp(
                title: 'GameBoo',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,

                home: const HomePage(),
                routes: {
                  '/shop': (context) => const ShopPage(),
                  '/rock-paper-scissors': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return RockPaperScissorsGame(difficulty: difficulty);
                  },
                  '/tic-tac-toe': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return TicTacToeGame(difficulty: difficulty);
                  },
                  '/memory-cards': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return MemoryCardsGame(difficulty: difficulty);
                  },
                  '/ball-blaster': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return BallBlasterGame(difficulty: difficulty);
                  },
                  '/car-racing': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return CarRacingGame(difficulty: difficulty);
                  },
                  '/puzzle-mania': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return PuzzleManiaGame(difficulty: difficulty);
                  },
                  '/drone-flight': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return DroneFlightGame(difficulty: difficulty);
                  },
                  '/drone-shooter': (context) {
                    final difficulty =
                        ModalRoute.of(context)!.settings.arguments
                            as GameDifficulty;
                    return DroneShooterGamePage(difficulty: difficulty);
                  },
                },
              );
            },
          ),
        );
      },
    );
  }
}
