import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';

class ModernLoadingAnimation extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;

  const ModernLoadingAnimation({
    super.key,
    this.message,
    this.size = 60,
    this.color,
  });

  @override
  State<ModernLoadingAnimation> createState() => _ModernLoadingAnimationState();
}

class _ModernLoadingAnimationState extends State<ModernLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (widget.color ?? AppColors.primary).withOpacity(0.8),
                        (widget.color ?? AppColors.primary).withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? AppColors.primary).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      color: Colors.white,
                      size: widget.size * 0.4,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class ModernLoadingDots extends StatefulWidget {
  final String? message;
  final Color? color;

  const ModernLoadingDots({
    super.key,
    this.message,
    this.color,
  });

  @override
  State<ModernLoadingDots> createState() => _ModernLoadingDotsState();
}

class _ModernLoadingDotsState extends State<ModernLoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      );
    });
    
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _animations[index].value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.color ?? AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 