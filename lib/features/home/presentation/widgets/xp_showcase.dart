import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/widgets/glass_widgets.dart';

class XPShowcase extends StatefulWidget {
  const XPShowcase({Key? key}) : super(key: key);

  @override
  State<XPShowcase> createState() => _XPShowcaseState();
}

class _XPShowcaseState extends State<XPShowcase> {
  int _currentXP = 750;
  int _maxXP = 1000;
  int _level = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP Progress Showcase',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16.h),

        // Main XP Progress Bar
        GlassXPProgressBar(
          currentXP: _currentXP,
          maxXP: _maxXP,
          level: _level,
          title: 'Your Progress',
          height: 80.h,
          showXPNumbers: true,
          showLevel: true,
        ),

        SizedBox(height: 16.h),

        // Compact version without title
        GlassXPProgressBar(
          currentXP: 350,
          maxXP: 500,
          level: 3,
          height: 60.h,
          showXPNumbers: true,
          showLevel: true,
          primaryColor: Colors.green,
        ),

        SizedBox(height: 16.h),

        // Minimal version
        GlassXPProgressBar(
          currentXP: 200,
          maxXP: 300,
          level: 2,
          height: 50.h,
          showXPNumbers: false,
          showLevel: false,
          primaryColor: Colors.orange,
        ),

        SizedBox(height: 24.h),

        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GlassButton(
              text: 'Add XP',
              onPressed: () {
                setState(() {
                  _currentXP = (_currentXP + 100).clamp(0, _maxXP);
                });
              },
            ),
            GlassButton(
              text: 'Level Up',
              onPressed: () {
                setState(() {
                  _level++;
                  _currentXP = 0;
                });
              },
            ),
            GlassButton(
              text: 'Reset',
              onPressed: () {
                setState(() {
                  _currentXP = 0;
                  _level = 1;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
