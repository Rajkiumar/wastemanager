import 'package:flutter/material.dart';
import 'app_theme.dart';

/// WasteWise Logo Widget - Reusable across the app
class WasteWiseLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final bool isCompact;

  const WasteWiseLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.isDark = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white, Colors.white70]
                  : [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primary).withOpacity(
                  0.3,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Recycling icon
              Icon(
                Icons.recycling,
                size: size * 0.55,
                color: isDark ? AppColors.primary : Colors.white,
              ),
              // Leaf accent
              Positioned(
                top: size * 0.12,
                right: size * 0.12,
                child: Icon(
                  Icons.eco,
                  size: size * 0.22,
                  color: isDark
                      ? AppColors.accent
                      : AppColors.accentLight.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        if (showText && !isCompact) ...[
          SizedBox(height: size * 0.2),
          // App Name
          Text(
            'WasteWise',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'CONNECT',
            style: TextStyle(
              fontSize: size * 0.14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              letterSpacing: 4,
            ),
          ),
        ],

        if (showText && isCompact) ...[
          SizedBox(height: size * 0.15),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WasteWise',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Small logo for AppBar
class WasteWiseLogoSmall extends StatelessWidget {
  const WasteWiseLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.recycling, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WasteWise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Connect',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated Logo for splash screens
class WasteWiseLogoAnimated extends StatefulWidget {
  final double size;
  final bool isDark;

  const WasteWiseLogoAnimated({
    super.key,
    this.size = 120,
    this.isDark = false,
  });

  @override
  State<WasteWiseLogoAnimated> createState() => _WasteWiseLogoAnimatedState();
}

class _WasteWiseLogoAnimatedState extends State<WasteWiseLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 0.1,
            child: WasteWiseLogo(size: widget.size, isDark: widget.isDark),
          ),
        );
      },
    );
  }
}
