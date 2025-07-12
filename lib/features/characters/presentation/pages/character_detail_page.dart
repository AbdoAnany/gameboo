// Updated CharacterDetailPage with improved UI polish and styling

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../cubit/character_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/character.dart';

// The updated class focuses on better glass UI and visual enhancements
class CharacterDetailPage extends StatefulWidget {
  final Character character;
  const CharacterDetailPage({super.key, required this.character});

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  late CharacterType _selectedCharacter;
  Map<CharacterType, bool> _unlockStatus = {};

  @override
  void initState() {
    super.initState();
    _selectedCharacter = widget.character.type;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      final profile = profileState.profile;
      context.read<CharacterCubit>().updateUserProgress(
        level: profile.level,
        xp: profile.xp,
        badges: profile.earnedBadges.length,
        wins: profile.totalWins,
      );
      final unlockStatus = context.read<CharacterCubit>().getAllUnlockStatus();
      setState(() {
        _unlockStatus = unlockStatus;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.lightBackgroundGradient,
        ),
        child: Column(
          children: [
            // _buildHeader(context),
            Expanded(flex: 3, child: _buildCharacterDisplay()),
            // Expanded(
            //   flex: 2,
            //   child: Padding(
            //     padding: EdgeInsets.symmetric(horizontal: 16.w),
            //     child: _buildCharacterGrid(),
            //   ),
            // ),
            // _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterDisplay() {
    final character = CharacterRepository.getCharacterByType(
      _selectedCharacter,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: character.color.map((c) => Color(int.parse(c))).toList(),
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/monstor_bg.png',),
          fit: BoxFit.fill,
        ),
      ),
      // margin: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          character.imagePath.isNotEmpty
              ? ClipOval(
                  child: Image.asset(
                    character.imagePath,
                    fit: BoxFit.contain,
                    width: 300.w,
                    height: 300.w,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _getCharacterColor(_selectedCharacter),
                        _getCharacterColor(_selectedCharacter).withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.person, size: 100.w, color: Colors.white),
                  ),
                ),
          SizedBox(height: 24.h),
          Text(
            character.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




  Color _getCharacterColor(CharacterType character) {
    switch (character) {
      case CharacterType.nova:
        return const Color(0xFF00E5FF); // Cyan
      case CharacterType.blitz:
        return const Color(0xFF76FF03); // Green
      case CharacterType.zink:
        return const Color(0xFFFF9800); // Orange
      case CharacterType.karma:
        return const Color(0xFFE91E63); // Red
      case CharacterType.rokk:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  String _getCharacterName(CharacterType character) {
    switch (character) {
      case CharacterType.nova:
        return 'Fuzzy';
      case CharacterType.blitz:
        return 'Spike';
      case CharacterType.zink:
        return 'Sunny';
      case CharacterType.karma:
        return 'Flame';
      case CharacterType.rokk:
        return 'Nova';
    }
  }

  String _getCharacterDescription(CharacterType character) {
    switch (character) {
      case CharacterType.nova:
        return 'A friendly blue monster with spiky fur and floating eyeballs. Loves making new friends!';
      case CharacterType.blitz:
        return 'A grumpy green monster with one eye and sharp claws. Don\'t let the frown fool you!';
      case CharacterType.zink:
        return 'A cheerful orange monster with fluffy fur and big smile. Always ready for adventure!';
      case CharacterType.karma:
        return 'A fierce red monster with horns and attitude. Brings the heat to every battle!';
      case CharacterType.rokk:
        return 'A mysterious purple monster with cosmic powers. Master of space and time!';
    }
  }

  Map<String, int> _getCharacterStats(CharacterType character) {
    switch (character) {
      case CharacterType.nova:
        return {'power': 3, 'speed': 4, 'defense': 5};
      case CharacterType.blitz:
        return {'power': 5, 'speed': 3, 'defense': 4};
      case CharacterType.zink:
        return {'power': 4, 'speed': 5, 'defense': 3};
      case CharacterType.karma:
        return {'power': 5, 'speed': 4, 'defense': 3};
      case CharacterType.rokk:
        return {'power': 4, 'speed': 3, 'defense': 5};
    }
  }
}

// Custom painter for the main character display
class CharacterPainter extends CustomPainter {
  final CharacterType character;
  final double animationValue;

  CharacterPainter(this.character, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw character based on type
    switch (character) {
      case CharacterType.nova:
        _drawFuzzyMonster(canvas, center, radius);
        break;
      case CharacterType.blitz:
        _drawSpikeMonster(canvas, center, radius);
        break;
      case CharacterType.zink:
        _drawSunnyMonster(canvas, center, radius);
        break;
      case CharacterType.karma:
        _drawFlameMonster(canvas, center, radius);
        break;
      case CharacterType.rokk:
        _drawNovaMonster(canvas, center, radius);
        break;
    }
  }

  void _drawFuzzyMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    // Main body
    canvas.drawCircle(center, radius, paint);

    // Spiky fur effect
    for (int i = 0; i < 20; i++) {
      final angle = (i * 18) * (pi / 180) + animationValue * 0.1;
      final x = center.dx + (radius + 10) * cos(angle);
      final y = center.dy + (radius + 10) * sin(angle);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.3, eyePaint);

    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, radius * 0.15, pupilPaint);

    // Floating eyeballs
    for (int i = 0; i < 2; i++) {
      final eyeAngle = (i * 90) * (pi / 180) + animationValue * 0.2;
      final eyeX = center.dx + radius * 1.5 * cos(eyeAngle);
      final eyeY = center.dy + radius * 1.5 * sin(eyeAngle);

      canvas.drawCircle(Offset(eyeX, eyeY), 15, eyePaint);
      canvas.drawCircle(Offset(eyeX, eyeY), 8, pupilPaint);
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final mouthPath = Path();
    mouthPath.addArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.2),
        width: radius * 0.6,
        height: radius * 0.3,
      ),
      0,
      pi,
    );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawSpikeMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF76FF03)
      ..style = PaintingStyle.fill;

    // Main body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 2),
      paint,
    );

    // Single large eye
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.3),
      radius * 0.4,
      eyePaint,
    );

    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.3),
      radius * 0.2,
      pupilPaint,
    );

    // Horns
    final hornPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 2; i++) {
      final hornX = center.dx + (i == 0 ? -radius * 0.3 : radius * 0.3);
      final hornY = center.dy - radius * 0.8;

      final hornPath = Path();
      hornPath.moveTo(hornX, hornY);
      hornPath.lineTo(hornX - 5, hornY - 20);
      hornPath.lineTo(hornX + 5, hornY - 20);
      hornPath.close();

      canvas.drawPath(hornPath, hornPaint);
    }

    // Frown mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final mouthPath = Path();
    mouthPath.addArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.4),
        width: radius * 0.8,
        height: radius * 0.4,
      ),
      pi,
      pi,
    );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawSunnyMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;

    // Main body
    canvas.drawCircle(center, radius, paint);

    // Fluffy texture
    for (int i = 0; i < 15; i++) {
      final angle = (i * 24) * (pi / 180);
      final x = center.dx + radius * 0.8 * cos(angle);
      final y = center.dy + radius * 0.8 * sin(angle);
      canvas.drawCircle(Offset(x, y), 8, paint);
    }

    // Two eyes
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    for (int i = 0; i < 2; i++) {
      final eyeX = center.dx + (i == 0 ? -radius * 0.3 : radius * 0.3);
      final eyeY = center.dy - radius * 0.2;

      canvas.drawCircle(Offset(eyeX, eyeY), radius * 0.15, eyePaint);
      canvas.drawCircle(Offset(eyeX, eyeY), radius * 0.08, pupilPaint);
    }

    // Happy mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final mouthPath = Path();
    mouthPath.addArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.1),
        width: radius * 0.8,
        height: radius * 0.4,
      ),
      0,
      pi,
    );
    canvas.drawPath(mouthPath, mouthPaint);

    // Teeth
    final toothPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 4; i++) {
      final toothX = center.dx - radius * 0.3 + (i * radius * 0.2);
      final toothY = center.dy + radius * 0.1;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(toothX, toothY), width: 8, height: 12),
        toothPaint,
      );
    }
  }

  void _drawFlameMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFE91E63)
      ..style = PaintingStyle.fill;

    // Main body
    canvas.drawCircle(center, radius, paint);

    // Horns
    final hornPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 2; i++) {
      final hornX = center.dx + (i == 0 ? -radius * 0.4 : radius * 0.4);
      final hornY = center.dy - radius * 0.6;

      final hornPath = Path();
      hornPath.moveTo(hornX, hornY);
      hornPath.lineTo(hornX - 8, hornY - 25);
      hornPath.lineTo(hornX + 8, hornY - 25);
      hornPath.close();

      canvas.drawPath(hornPath, hornPaint);
    }

    // Single eye with angry expression
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius * 0.2),
        width: radius * 0.6,
        height: radius * 0.4,
      ),
      eyePaint,
    );

    final pupilPaint = Paint()..color = Colors.green;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.2),
      radius * 0.15,
      pupilPaint,
    );

    // Angry mouth with fangs
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.3),
        width: radius * 0.6,
        height: radius * 0.3,
      ),
      mouthPaint,
    );

    // Fangs
    final fangPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 4; i++) {
      final fangX = center.dx - radius * 0.2 + (i * radius * 0.13);
      final fangY = center.dy + radius * 0.2;

      final fangPath = Path();
      fangPath.moveTo(fangX, fangY);
      fangPath.lineTo(fangX - 3, fangY + 10);
      fangPath.lineTo(fangX + 3, fangY + 10);
      fangPath.close();

      canvas.drawPath(fangPath, fangPaint);
    }
  }

  void _drawNovaMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..style = PaintingStyle.fill;

    // Main body with cosmic effect
    canvas.drawCircle(center, radius, paint);

    // Cosmic sparkles
    final sparkPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (pi / 180) + animationValue * 0.5;
      final x = center.dx + radius * 0.7 * cos(angle);
      final y = center.dy + radius * 0.7 * sin(angle);
      canvas.drawCircle(Offset(x, y), 2, sparkPaint);
    }

    // Multiple eyes
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    // Main eye
    canvas.drawCircle(center, radius * 0.25, eyePaint);
    canvas.drawCircle(center, radius * 0.12, pupilPaint);

    // Side eyes
    for (int i = 0; i < 2; i++) {
      final eyeX = center.dx + (i == 0 ? -radius * 0.6 : radius * 0.6);
      final eyeY = center.dy - radius * 0.3;

      canvas.drawCircle(Offset(eyeX, eyeY), radius * 0.12, eyePaint);
      canvas.drawCircle(Offset(eyeX, eyeY), radius * 0.06, pupilPaint);
    }

    // Mysterious aura
    final auraPaint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        radius + (i * 15) + (sin(animationValue * 2) * 5),
        auraPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Mini character painter for the grid
class MiniCharacterPainter extends CustomPainter {
  final CharacterType character;

  MiniCharacterPainter(this.character);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    final paint = Paint()..style = PaintingStyle.fill;

    switch (character) {
      case CharacterType.nova:
        paint.color = const Color(0xFF00E5FF);
        canvas.drawCircle(center, radius, paint);
        // Simple eye
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(center, radius * 0.5, eyePaint);
        final pupilPaint = Paint()..color = Colors.black;
        canvas.drawCircle(center, radius * 0.25, pupilPaint);
        break;

      case CharacterType.blitz:
        paint.color = const Color(0xFF76FF03);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 1.5,
            height: radius * 2,
          ),
          paint,
        );
        break;

      case CharacterType.zink:
        paint.color = const Color(0xFFFF9800);
        canvas.drawCircle(center, radius, paint);
        break;

      case CharacterType.karma:
        paint.color = const Color(0xFFE91E63);
        canvas.drawCircle(center, radius, paint);
        break;

      case CharacterType.rokk:
        paint.color = const Color(0xFF9C27B0);
        canvas.drawCircle(center, radius, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
