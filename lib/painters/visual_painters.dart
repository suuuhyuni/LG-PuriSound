part of hrgg_app;

class AnimatedNoiseBlob extends StatefulWidget {
  const AnimatedNoiseBlob({required this.db, required this.color, super.key});

  final double db;
  final Color color;

  @override
  State<AnimatedNoiseBlob> createState() => _AnimatedNoiseBlobState();
}

class _AnimatedNoiseBlobState extends State<AnimatedNoiseBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: NoiseBlobPainter(
          color: widget.color,
          db: widget.db,
          phase: controller.value,
          glow: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class NoiseBlobPainter extends CustomPainter {
  NoiseBlobPainter({
    required this.color,
    required this.db,
    required this.phase,
    required this.glow,
  });

  final Color color;
  final double db;
  final double phase;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final level = (db.clamp(20, 90) - 20) / 70;
    final baseRadius = math.min(size.width, size.height) * (0.27 + level * 0.1);
    final deformation = baseRadius * (0.08 + level * 0.12);
    final path = Path();

    for (var i = 0; i <= 160; i++) {
      final angle = math.pi * 2 * i / 160;
      final wave = math.sin(angle * 5 + phase * math.pi * 2) * 0.58 +
          math.sin(angle * 7 - phase * math.pi * 2 * 0.7) * 0.28 +
          math.sin(angle * 3 + phase * math.pi * 2 * 0.45) * 0.14;
      final radius = baseRadius + deformation * wave;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: glow ? 0.12 : 0.07),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: glow ? 0.28 : 0.16),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant NoiseBlobPainter oldDelegate) =>
      db != oldDelegate.db ||
      color != oldDelegate.color ||
      phase != oldDelegate.phase ||
      glow != oldDelegate.glow;
}

class AnimatedWaveform extends StatefulWidget {
  const AnimatedWaveform({required this.color, required this.dense, super.key});

  final Color color;
  final bool dense;

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
          painter:
              WaveformPainter(widget.color, controller.value, widget.dense)),
    );
  }
}

class WaveformPainter extends CustomPainter {
  WaveformPainter(this.color, this.phase, this.dense);

  final Color color;
  final double phase;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dense ? 2 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final amp = size.height *
        (dense ? 0.24 : 0.34) *
        (0.82 + math.sin(phase * math.pi * 2) * 0.18);
    final freq = dense ? 5.5 : 2.2;
    for (var x = 0.0; x <= size.width; x += 2) {
      final y = size.height / 2 +
          math.sin(
                  (x / size.width * math.pi * 2 * freq) + phase * math.pi * 2) *
              amp;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(
        path,
        paint
          ..color = color.withValues(alpha: 0.16)
          ..strokeWidth = dense ? 8 : 12);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      phase != oldDelegate.phase || color != oldDelegate.color;
}

class GaugePainter extends CustomPainter {
  GaugePainter(this.context, this.db);

  final BuildContext context;
  final double db;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.36;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = context.c.border;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi,
        math.pi, false, stroke);
    final zones = [
      (HrggColors.active, 0.42),
      (HrggColors.warning, 0.32),
      (HrggColors.error, 0.26)
    ];
    var start = math.pi;
    for (final zone in zones) {
      stroke.color = zone.$1;
      final sweep = math.pi * zone.$2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep, false, stroke);
      start += sweep;
    }
    final angle = math.pi + math.pi * (db.clamp(0, 100) / 100);
    final needleEnd = Offset(center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72);
    canvas.drawLine(
        center,
        needleEnd,
        Paint()
          ..color = context.c.textPrimary
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, 6, Paint()..color = HrggColors.primary);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      db != oldDelegate.db;
}
