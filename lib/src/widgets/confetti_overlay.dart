import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final ConfettiController controller;
  final Widget child;

  const ConfettiOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_update);
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void play() {
    _particles.clear();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(_rnd));
    }
    _anim.forward(from: 0);
  }

  void _update() {
    for (final p in _particles) {
      p.update(_anim.value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_anim.isAnimating)
          IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles),
              size: Size.infinite,
            ),
          ),
      ],
    );
  }
}

class ConfettiController {
  _ConfettiOverlayState? _state;
  void _attach(_ConfettiOverlayState s) => _state = s;
  void play() => _state?.play();
}

class _Particle {
  double x;
  double y;
  double speed;
  double angle;
  double spin;
  Color color;
  double size;

  _Particle(Random rnd)
      : x = rnd.nextDouble() * 400, // Random start X
        y = -20 - rnd.nextDouble() * 50, // Start above screen
        speed = 2 + rnd.nextDouble() * 4,
        angle = rnd.nextDouble() * pi / 4 - pi / 8, // Slight spread
        spin = rnd.nextDouble() * pi * 2,
        color = Colors.primaries[rnd.nextInt(Colors.primaries.length)],
        size = 4 + rnd.nextDouble() * 4;

  void update(double t) {
    y += speed;
    x += sin(angle) * 0.5;
    spin += 0.1;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.spin);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
