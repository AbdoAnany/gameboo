import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final LinearGradient? gradient;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(opacity),
                            Colors.white.withOpacity(opacity * 0.5),
                          ]
                        : [
                            Colors.white.withOpacity(opacity + 0.1),
                            Colors.white.withOpacity(opacity * 0.8),
                          ],
                  ),
              border: Border.all(
                color:
                    borderColor?.withOpacity(0.5) ??
                    (isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.4)),
                width: borderWidth,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Container(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        margin: margin,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const GlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        width: width,
        height: height ?? 56,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        opacity: 0.2,
        blur: 15,
        gradient: color != null
            ? LinearGradient(
                colors: [color!.withOpacity(0.3), color!.withOpacity(0.1)],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.onSurface, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style:
                  textStyle ??
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? theme.colorScheme.onSurface.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: AppBar(
            title: Text(title),
            centerTitle: centerTitle,
            backgroundColor: Colors.transparent,
            elevation: elevation ?? 0,
            actions: actions,
            leading: leading,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GlassBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomNavigationBarItem> items;

  const GlassBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? theme.colorScheme.onSurface.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class GlassBottomNavigationBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const GlassBottomNavigationBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class GlassXPProgressBar extends StatefulWidget {
  final int currentXP;
  final int maxXP;
  final int level;
  final String? title;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showXPNumbers;
  final bool showLevel;
  final Duration animationDuration;

  const GlassXPProgressBar({
    Key? key,
    required this.currentXP,
    required this.maxXP,
    required this.level,
    this.title,
    this.height = 60.0,
    this.primaryColor,
    this.secondaryColor,
    this.showXPNumbers = true,
    this.showLevel = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<GlassXPProgressBar> createState() => _GlassXPProgressBarState();
}

class _GlassXPProgressBarState extends State<GlassXPProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _levelUpController;
  late Animation<double> _progressAnimation;
  late Animation<double> _levelUpAnimation;
  late Animation<double> _scaleAnimation;
  int _previousLevel = 0;

  @override
  void initState() {
    super.initState();
    _previousLevel = widget.level;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.currentXP / widget.maxXP).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _levelUpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.bounceOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(GlassXPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if level changed for celebration animation
    if (oldWidget.level != widget.level && widget.level > _previousLevel) {
      _levelUpController.forward().then((_) {
        _levelUpController.reverse();
      });
    }
    _previousLevel = widget.level;

    if (oldWidget.currentXP != widget.currentXP ||
        oldWidget.maxXP != widget.maxXP) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.currentXP / widget.maxXP,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOutCubic,
            ),
          );
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = widget.primaryColor ?? theme.colorScheme.primary;
    final backgroundColor =
        widget.secondaryColor ??
        (isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            height: widget.height,
            // padding: const EdgeInsets.all(16),
            // opacity: 0.15,
            // blur: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Level Row
                if (widget.title != null || widget.showLevel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.title != null)
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _levelUpAnimation,
                            builder: (context, child) {
                              return Row(
                                children: [
                                  Text(
                                    widget.title!,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (_levelUpAnimation.value > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Opacity(
                                        opacity: _levelUpAnimation.value,
                                        child: Icon(
                                          Icons.celebration,
                                          size: 16,
                                          color: progressColor,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      if (widget.showLevel)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                progressColor.withOpacity(0.2),
                                progressColor.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: progressColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Level ${widget.level}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                if (widget.title != null || widget.showLevel)
                  const SizedBox(height: 8),

                // Progress Bar
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: backgroundColor,
                          ),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: backgroundColor,
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _progressAnimation.value.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        gradient: LinearGradient(
                                          colors: [
                                            progressColor,
                                            progressColor.withOpacity(0.7),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: progressColor.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      // XP Numbers
                      if (widget.showXPNumbers) ...[
                        const SizedBox(width: 12),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            final animatedXP =
                                (_progressAnimation.value * widget.maxXP)
                                    .round();
                            return Text(
                              '$animatedXP/${widget.maxXP} XP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
