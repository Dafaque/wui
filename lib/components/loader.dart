import 'package:flutter/material.dart';

class Loader extends StatefulWidget {
  const Loader({super.key});

  @override
  State<Loader> createState() => _LoaderState();
}

class _LoaderState extends State<Loader> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    // Адаптивный размер: 20% от ширины экрана, но не больше 120px и не меньше 60px
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.2).clamp(60.0, 120.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Внешнее кольцо
          _buildAnimatedRing(color, size, 0.0),
          // Среднее кольцо
          _buildAnimatedRing(color, size * 0.7, 0.3),
          // Внутреннее кольцо
          _buildAnimatedRing(color, size * 0.4, 0.6),
          // Центральная точка
          Container(
            width: size * 0.15,
            height: size * 0.15,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRing(Color color, double ringSize, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(ringSize, ringSize),
          painter: _WaveRingPainter(
            color: color,
            progress: (_controller.value + delay) % 1.0,
          ),
        );
      },
    );
  }
}

class _WaveRingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _WaveRingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 + (0.7 * (1 - progress)))
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3.0) / 2;

    // Рисуем дугу, которая "бегает" по кругу
    final startAngle = -90 + (progress * 360);
    final sweepAngle = 120; // 120 градусов дуга

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle * (3.14159 / 180), // конвертируем в радианы
      sweepAngle * (3.14159 / 180),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _WaveRingPainter && oldDelegate.progress != progress;
  }
}
