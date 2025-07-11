import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/characters/presentation/cubit/character_cubit.dart';
import 'features/games/presentation/cubit/game_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/shop/presentation/cubit/shop_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
              );
            },
          ),
        );
      },
    );
  }
}
