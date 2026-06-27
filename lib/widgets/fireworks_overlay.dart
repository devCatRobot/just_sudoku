import 'dart:math';

import 'package:flutter/material.dart';

class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _Particle {
  const _Particle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.delay,
  });

  final Offset origin;
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double delay;
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _burstDuration = Duration(milliseconds: 2500);
  static const List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.lightBlue,
    Colors.purple,
    Colors.pink,
  ];

  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = _createParticles();
    _controller = AnimationController(
      vsync: this,
      duration: _burstDuration,
    )..repeat();
  }

  List<_Particle> _createParticles() {
    final particles = <_Particle>[];

    for (var burst = 0; burst < 5; burst++) {
      final origin = Offset(
        0.15 + _random.nextDouble() * 0.7,
        0.1 + _random.nextDouble() * 0.35,
      );
      final delay = burst * 0.1;

      for (var i = 0; i < 22; i++) {
        particles.add(
          _Particle(
            origin: origin,
            angle: _random.nextDouble() * 2 * pi,
            speed: 70 + _random.nextDouble() * 110,
            color: _colors[_random.nextInt(_colors.length)],
            size: 2.5 + _random.nextDouble() * 3.5,
            delay: delay,
          ),
        );
      }
    }

    return particles;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _messageStyle(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade700,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messageStyle = _messageStyle(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _FireworksPainter(
              progress: _controller.value,
              particles: _particles,
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Puzzle complete!', style: messageStyle),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to start a new puzzle',
                        style: messageStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (progress <= particle.delay) {
        continue;
      }

      final burstProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      final distance = particle.speed * burstProgress;
      final x = particle.origin.dx * size.width +
          cos(particle.angle) * distance;
      final y = particle.origin.dy * size.height +
          sin(particle.angle) * distance +
          35 * burstProgress * burstProgress;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - burstProgress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - burstProgress * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
