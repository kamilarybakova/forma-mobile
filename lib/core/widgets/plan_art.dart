import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// FNV-1a. `String.hashCode` is not stable between runs or platforms, and a
/// project must keep the same drawing everywhere.
int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// A decorative floor plan generated from [seed]. It identifies a project at a
/// glance; it is not derived from the project's real geometry.
class FloorPlan extends StatelessWidget {
  final String seed;
  final Color color;
  final double strokeWidth;
  const FloorPlan({
    super.key,
    required this.seed,
    this.color = blue,
    this.strokeWidth = 1.6,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FloorPlanPainter(seed, color, strokeWidth),
      ),
    ),
  );
}

class _FloorPlanPainter extends CustomPainter {
  final String seed;
  final Color color;
  final double stroke;
  _FloorPlanPainter(this.seed, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = Random(_stableHash(seed));
    final margin = min(size.width, size.height) * .1;
    final available = Rect.fromLTRB(
      margin,
      margin,
      size.width - margin,
      size.height - margin,
    );
    final ratio = 1.05 + random.nextDouble() * .5;
    var width = available.width, height = width / ratio;
    if (height > available.height) {
      height = available.height;
      width = height * ratio;
    }
    final outer = Rect.fromCenter(
      center: available.center,
      width: width,
      height: height,
    );
    final thin = Paint()
      ..color = color.withValues(alpha: color.a * .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(.7, stroke * .5);
    final wall = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = stroke;
    final heavy = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = stroke * 1.9;

    final unit = min(width, height);
    final doorSize = unit * .11;
    final rooms = <Rect>[];

    void split(Rect room, int depth) {
      final tooSmall = min(room.width, room.height) < unit * .3;
      if (depth == 0 || tooSmall) {
        rooms.add(room);
        return;
      }
      final vertical =
          room.width > room.height * (.85 + random.nextDouble() * .3);
      final t = .36 + random.nextDouble() * .28;
      final Rect first, second;
      final Offset a, b;
      if (vertical) {
        final x = room.left + room.width * t;
        a = Offset(x, room.top);
        b = Offset(x, room.bottom);
        first = Rect.fromLTRB(room.left, room.top, x, room.bottom);
        second = Rect.fromLTRB(x, room.top, room.right, room.bottom);
      } else {
        final y = room.top + room.height * t;
        a = Offset(room.left, y);
        b = Offset(room.right, y);
        first = Rect.fromLTRB(room.left, room.top, room.right, y);
        second = Rect.fromLTRB(room.left, y, room.right, room.bottom);
      }
      _wallWithDoor(canvas, a, b, doorSize, random, wall, thin);
      split(first, depth - 1);
      split(second, depth - 1);
    }

    split(outer, 3);
    for (final room in rooms) {
      _furniture(canvas, room, random, thin);
    }
    _outerWalls(canvas, outer, doorSize, random, heavy, thin);
  }

  void _wallWithDoor(
    Canvas canvas,
    Offset a,
    Offset b,
    double door,
    Random random,
    Paint wall,
    Paint thin,
  ) {
    final length = (b - a).distance;
    if (length < door * 2.4) {
      canvas.drawLine(a, b, wall);
      return;
    }
    final direction = (b - a) / length;
    final start = door * .4 + random.nextDouble() * (length - door * 1.8);
    final gapA = a + direction * start;
    final gapB = gapA + direction * door;
    canvas.drawLine(a, gapA, wall);
    canvas.drawLine(gapB, b, wall);
    // Door leaf and its swing, as on a real plan.
    final normal = Offset(-direction.dy, direction.dx);
    final side = random.nextBool() ? 1.0 : -1.0;
    final tip = gapA + normal * side * door;
    canvas.drawLine(gapA, tip, thin);
    final arc = Path()
      ..moveTo(tip.dx, tip.dy)
      ..arcToPoint(
        gapB,
        radius: Radius.circular(door),
        clockwise: side * direction.dx - side * direction.dy < 0,
      );
    canvas.drawPath(arc, thin);
  }

  void _furniture(Canvas canvas, Rect room, Random random, Paint thin) {
    final kind = random.nextInt(4);
    final inner = room.deflate(min(room.width, room.height) * .22);
    if (inner.shortestSide < 8) return;
    if (kind == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(1.5)),
        thin,
      );
      canvas.drawLine(
        inner.topLeft + Offset(0, inner.height * .28),
        inner.topRight + Offset(0, inner.height * .28),
        thin,
      );
    } else if (kind == 1) {
      canvas.drawCircle(inner.center, inner.shortestSide * .32, thin);
    }
  }

  void _outerWalls(
    Canvas canvas,
    Rect outer,
    double door,
    Random random,
    Paint heavy,
    Paint thin,
  ) {
    final corners = [
      outer.topLeft,
      outer.topRight,
      outer.bottomRight,
      outer.bottomLeft,
      outer.topLeft,
    ];
    for (var i = 0; i < 4; i++) {
      final a = corners[i], b = corners[i + 1];
      final length = (b - a).distance;
      final direction = (b - a) / length;
      final normal = Offset(-direction.dy, direction.dx);
      final window = door * (1.2 + random.nextDouble() * .8);
      final start = length * (.15 + random.nextDouble() * .5);
      final gapA = a + direction * start;
      final gapB = gapA + direction * window;
      canvas.drawLine(a, gapA, heavy);
      canvas.drawLine(gapB, b, heavy);
      // A window: two thin parallel lines bridging the gap in the wall.
      final offset = normal * (heavy.strokeWidth * .55);
      canvas.drawLine(gapA + offset, gapB + offset, thin);
      canvas.drawLine(gapA - offset, gapB - offset, thin);
    }
  }

  @override
  bool shouldRepaint(_FloorPlanPainter old) =>
      old.seed != seed || old.color != color || old.stroke != stroke;
}

/// Drafting-paper grid: fine lines with a heavier line every fifth cell.
class DraftingGrid extends StatelessWidget {
  final Color color;
  final double cell;
  const DraftingGrid({super.key, required this.color, this.cell = 18});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(color, cell),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double cell;
  _GridPainter(this.color, this.cell);
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = color
      ..strokeWidth = .5;
    final major = Paint()
      ..color = color.withValues(alpha: min(1, color.a * 2.2))
      ..strokeWidth = .7;
    var index = 0;
    for (double x = 0; x <= size.width; x += cell, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 5 == 0 ? major : minor,
      );
    }
    index = 0;
    for (double y = 0; y <= size.height; y += cell, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 5 == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.cell != cell;
}

/// Deep-blue hero surface with a grid and, optionally, a plan bleeding off the
/// right edge. Its size comes from [child].
class BlueprintPanel extends StatelessWidget {
  final Widget child;
  final String? planSeed;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  const BlueprintPanel({
    super.key,
    required this.child,
    this.planSeed,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: ColoredBox(
      color: blueprint,
      child: Stack(
        children: [
          const Positioned.fill(child: DraftingGrid(color: Color(0x12FFFFFF))),
          if (planSeed != null)
            Positioned(
              top: -14,
              bottom: -14,
              right: -18,
              width: min(MediaQuery.sizeOf(context).width * .62, 420),
              child: FloorPlan(seed: planSeed!, color: const Color(0x4DFFFFFF)),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    ),
  );
}

/// An architect's dimension line: `/—— 84 м² ——/`.
class DimensionLine extends StatelessWidget {
  final String label;
  final Color color;
  const DimensionLine(this.label, {super.key, this.color = muted});
  @override
  Widget build(BuildContext context) {
    final rule = Expanded(child: Container(height: 1, color: color));
    final tick = Transform.rotate(
      angle: pi / 4,
      child: Container(width: 1, height: 9, color: color),
    );
    return Row(
      children: [
        tick,
        rule,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
              color: color,
            ),
          ),
        ),
        rule,
        tick,
      ],
    );
  }
}
