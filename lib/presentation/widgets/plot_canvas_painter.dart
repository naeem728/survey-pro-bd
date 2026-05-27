// lib/presentation/widgets/plot_canvas_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/survey_math_engine.dart';

/// ─── CANVAS PAINTER (Steps 8, 10, 12) ──────────────────────────────────────
class PlotCanvasPainter extends CustomPainter {
  final List<Offset> points;
  final bool isClosed;
  final List<double> sideLengths;
  final List<double> diagonalLengths;
  final double northRotation; // degrees
  final bool showDimensions;
  final bool showDiagonals;
  final double scaledViewWidth;
  final double scaledViewHeight;

  PlotCanvasPainter({
    required this.points,
    required this.isClosed,
    required this.sideLengths,
    required this.diagonalLengths,
    required this.northRotation,
    this.showDimensions = true,
    this.showDiagonals = true,
    this.scaledViewWidth = 0,
    this.scaledViewHeight = 0,
  });

  // ── Paint objects ──────────────────────────────────────────────────────────
  final _boundaryPaint = Paint()
    ..color = AppColors.boundary
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final _dimensionPaint = Paint()
    ..color = AppColors.dimension
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final _diagonalPaint = Paint()
    ..color = AppColors.diagonal
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  final _vertexPaint = Paint()
    ..color = AppColors.vertex
    ..style = PaintingStyle.fill;

  final _firstVertexPaint = Paint()
    ..color = AppColors.vertexFirst
    ..style = PaintingStyle.fill;

  final _fillPaint = Paint()
    ..color = AppColors.primary.withOpacity(0.08)
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Draw grid
    _drawGrid(canvas, size);

    // Save state and rotate for north alignment
    canvas.save();
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.translate(cx, cy);
    canvas.rotate(northRotation * math.pi / 180.0);
    canvas.translate(-cx, -cy);

    // Draw filled polygon
    if (isClosed && points.length >= 3) {
      final fillPath = Path()..addPolygon(points, true);
      canvas.drawPath(fillPath, _fillPaint);
    }

    // Draw boundary lines (Solid Black)
    if (points.length >= 2) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (isClosed) path.close();
      canvas.drawPath(path, _boundaryPaint);
    }

    // Draw diagonals (Dashed Red)
    if (showDiagonals && isClosed && points.length >= 4) {
      _drawDiagonals(canvas);
    }

    // Draw vertices
    for (int i = 0; i < points.length; i++) {
      final paint = i == 0 ? _firstVertexPaint : _vertexPaint;
      canvas.drawCircle(points[i], i == 0 ? 8 : 6, paint);
      canvas.drawCircle(points[i], i == 0 ? 8 : 6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      // Vertex label
      _drawText(canvas, '${i + 1}', points[i] - const Offset(4, 14),
          12, Colors.white, bold: true);
    }

    // Draw dimension labels (Solid Red, rotated with lines)
    if (showDimensions && sideLengths.isNotEmpty) {
      _drawDimensionLabels(canvas);
    }

    canvas.restore();

    // Draw North Arrow (fixed, not rotated)
    _drawNorthArrow(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawDiagonals(Canvas canvas) {
    // For n-sided polygon, draw fan diagonals from vertex 0
    for (int i = 2; i < points.length - 1; i++) {
      _drawDashedLine(canvas, points[0], points[i], _diagonalPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 8.0;
    const gapLen = 5.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final nx = dx / dist;
    final ny = dy / dist;
    double drawn = 0;
    bool drawing = true;
    while (drawn < dist) {
      final segLen = drawing ? dashLen : gapLen;
      final end = math.min(drawn + segLen, dist);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + nx * drawn, p1.dy + ny * drawn),
          Offset(p1.dx + nx * end, p1.dy + ny * end),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  void _drawDimensionLabels(Canvas canvas) {
    final n = isClosed ? points.length : points.length - 1;
    for (int i = 0; i < n && i < sideLengths.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
      final label = '${sideLengths[i].toStringAsFixed(2)} ফুট';

      canvas.save();
      canvas.translate(mid.dx, mid.dy);
      // Keep text readable (flip if upside down)
      double a = angle;
      if (a > math.pi / 2 || a < -math.pi / 2) a += math.pi;
      canvas.rotate(a);
      _drawTextCentered(canvas, label, const Offset(0, -10),
          12, AppColors.dimension, bold: false);
      canvas.restore();
    }
  }

  void _drawNorthArrow(Canvas canvas, Size size) {
    final cx = size.width - 36;
    final cy = 60.0;
    final arrowPaint = Paint()
      ..color = AppColors.northArrow
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(northRotation * math.pi / 180.0);

    // Arrow up (North - filled)
    final upPath = Path()
      ..moveTo(0, -22)
      ..lineTo(-8, 4)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(upPath, arrowPaint);

    // Arrow down (South - outline)
    final downPath = Path()
      ..moveTo(0, 22)
      ..lineTo(8, -4)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(downPath,
        Paint()
          ..color = AppColors.northArrow.withOpacity(0.3)
          ..style = PaintingStyle.fill);

    canvas.restore();

    // "N" label
    _drawText(canvas, 'N', Offset(cx - 5, cy - 40), 14,
        AppColors.northArrow, bold: true);

    // Circle
    canvas.drawCircle(Offset(cx, cy), 26,
        Paint()
          ..color = AppColors.northArrow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Kalpurush',
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawTextCentered(Canvas canvas, String text, Offset pos,
      double fontSize, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Kalpurush',
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(PlotCanvasPainter old) =>
      old.points != points ||
      old.isClosed != isClosed ||
      old.sideLengths != sideLengths ||
      old.northRotation != northRotation;
}

/// ─── CANVAS SCREEN (Step 8) ─────────────────────────────────────────────────
class DrawingCanvasScreen extends StatefulWidget {
  final List<double> confirmedSides;
  final List<double> confirmedDiagonals;
  final double northRotation;
  final Function(List<Offset>, bool)? onPointsChanged;

  const DrawingCanvasScreen({
    super.key,
    this.confirmedSides = const [],
    this.confirmedDiagonals = const [],
    this.northRotation = 0,
    this.onPointsChanged,
  });

  @override
  State<DrawingCanvasScreen> createState() => DrawingCanvasScreenState();
}

class DrawingCanvasScreenState extends State<DrawingCanvasScreen> {
  final List<Offset> _points = [];
  bool _isClosed = false;
  static const double _snapRadius = 24.0;

  void resetCanvas() {
    setState(() {
      _points.clear();
      _isClosed = false;
    });
  }

  List<Offset> get points => List.unmodifiable(_points);
  bool get isClosed => _isClosed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top toolbar ──────────────────────────────────────────────────
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _toolbarBtn(
                icon: Icons.undo,
                label: 'পূর্বাবস্থায়',
                onTap: _isClosed
                    ? null
                    : () {
                        if (_points.isNotEmpty) {
                          setState(() => _points.removeLast());
                          widget.onPointsChanged?.call(_points, _isClosed);
                        }
                      },
              ),
              const SizedBox(width: 8),
              _toolbarBtn(
                icon: Icons.clear,
                label: 'মুছে ফেলুন',
                onTap: () {
                  setState(() {
                    _points.clear();
                    _isClosed = false;
                  });
                  widget.onPointsChanged?.call(_points, _isClosed);
                },
              ),
              const Spacer(),
              if (_points.length >= 3 && !_isClosed)
                _toolbarBtn(
                  icon: Icons.close,
                  label: 'বন্ধ করুন',
                  onTap: () {
                    setState(() => _isClosed = true);
                    widget.onPointsChanged?.call(_points, true);
                  },
                ),
              const SizedBox(width: 4),
              Text(
                '${_points.length} বিন্দু',
                style: const TextStyle(
                  fontFamily: 'Kalpurush',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // ── Canvas ────────────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTapUp: _isClosed ? null : _onTap,
            child: Container(
              color: AppColors.canvasBg,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: PlotCanvasPainter(
                  points: _points,
                  isClosed: _isClosed,
                  sideLengths: widget.confirmedSides,
                  diagonalLengths: widget.confirmedDiagonals,
                  northRotation: widget.northRotation,
                ),
              ),
            ),
          ),
        ),
        // ── Hint ─────────────────────────────────────────────────────────
        Container(
          color: AppColors.primary.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            _isClosed
                ? '✓ জমির আকৃতি আঁকা সম্পন্ন'
                : _points.isEmpty
                    ? 'স্ক্রিনে ট্যাপ করে জমির কোণগুলো চিহ্নিত করুন'
                    : 'প্রথম বিন্দুর কাছে ট্যাপ করলে স্বয়ংক্রিয়ভাবে বন্ধ হবে',
            style: const TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 13,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _onTap(TapUpDetails details) {
    final pos = details.localPosition;
    // Snap to first point?
    if (_points.length >= 3) {
      final d = (pos - _points.first).distance;
      if (d < _snapRadius) {
        setState(() => _isClosed = true);
        widget.onPointsChanged?.call(_points, true);
        return;
      }
    }
    setState(() => _points.add(pos));
    widget.onPointsChanged?.call(_points, false);
  }

  Widget _toolbarBtn({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Kalpurush',
                  color: Colors.white,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}
