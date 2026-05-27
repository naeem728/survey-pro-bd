// lib/core/utils/survey_math_engine.dart
import 'dart:math' as math;

/// ─── AREA RESULT ───────────────────────────────────────────────────────────
class AreaResult {
  final double squareFeet;
  final double decimal;   // শতাংশ/শতক
  final double katha;     // কাঠা
  final double bigha;     // বিঘা
  final double acre;      // একর
  final double link;      // লিঙ্ক

  const AreaResult({
    required this.squareFeet,
    required this.decimal,
    required this.katha,
    required this.bigha,
    required this.acre,
    required this.link,
  });

  @override
  String toString() =>
      'AreaResult(sqft: $squareFeet, decimal: $decimal, katha: $katha, bigha: $bigha)';
}

/// ─── POINT ─────────────────────────────────────────────────────────────────
class Point2D {
  final double x;
  final double y;
  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    return math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));
  }
}

/// ─── TRIANGLE RESULT ───────────────────────────────────────────────────────
class TriangleResult {
  final double area;
  final double semiPerimeter;
  final bool isValid;
  final String errorMessage;

  const TriangleResult({
    required this.area,
    required this.semiPerimeter,
    this.isValid = true,
    this.errorMessage = '',
  });
}

/// ─── MAIN ENGINE ───────────────────────────────────────────────────────────
class SurveyMathEngine {
  // ── Conversion constants (Bangladesh standard) ───────────────────────────
  static const double _sqFtPerDecimal = 435.6;       // 1 শতাংশ = 435.6 sq ft
  static const double _sqFtPerKatha = 720.0;         // 1 কাঠা = 720 sq ft
  static const double _sqFtPerBigha = 14400.0;       // 1 বিঘা = 14400 sq ft (20 কাঠা)
  static const double _sqFtPerAcre = 43560.0;        // 1 একর = 43560 sq ft
  static const double _sqFtPerLink = 0.4356;         // 1 লিঙ্ক = 0.4356 sq ft

  // ── Step 5: Heron's Formula ──────────────────────────────────────────────
  static TriangleResult heronFormula(double a, double b, double c) {
    if (a <= 0 || b <= 0 || c <= 0) {
      return const TriangleResult(
        area: 0,
        semiPerimeter: 0,
        isValid: false,
        errorMessage: 'ভুজের দৈর্ঘ্য অবশ্যই ধনাত্মক সংখ্যা হতে হবে।',
      );
    }
    // Triangle inequality check
    if (a + b <= c || b + c <= a || a + c <= b) {
      return const TriangleResult(
        area: 0,
        semiPerimeter: 0,
        isValid: false,
        errorMessage: 'এই তিনটি বাহু দিয়ে বৈধ ত্রিভুজ তৈরি সম্ভব নয়।',
      );
    }
    final double s = (a + b + c) / 2.0;
    final double areaSquared = s * (s - a) * (s - b) * (s - c);
    if (areaSquared < 0) {
      return const TriangleResult(
        area: 0,
        semiPerimeter: 0,
        isValid: false,
        errorMessage: 'গণনায় ত্রুটি: ক্ষেত্রফল ঋণাত্মক।',
      );
    }
    return TriangleResult(
      area: math.sqrt(areaSquared),
      semiPerimeter: s,
      isValid: true,
    );
  }

  // ── Step 6: Unit Converter ────────────────────────────────────────────────
  static AreaResult convertFromSqFt(double sqFt) {
    return AreaResult(
      squareFeet: _roundTo4(sqFt),
      decimal: _roundTo4(sqFt / _sqFtPerDecimal),
      katha: _roundTo4(sqFt / _sqFtPerKatha),
      bigha: _roundTo4(sqFt / _sqFtPerBigha),
      acre: _roundTo4(sqFt / _sqFtPerAcre),
      link: _roundTo4(sqFt / _sqFtPerLink),
    );
  }

  // ── Step 7: Quadrilateral (4 sides + 1 diagonal) ─────────────────────────
  static AreaResult? quadrilateralArea({
    required double a,
    required double b,
    required double c,
    required double d,
    required double diagonal,
  }) {
    // Triangle 1: a, b, diagonal
    final t1 = heronFormula(a, b, diagonal);
    if (!t1.isValid) return null;
    // Triangle 2: c, d, diagonal
    final t2 = heronFormula(c, d, diagonal);
    if (!t2.isValid) return null;
    final totalSqFt = t1.area + t2.area;
    return convertFromSqFt(totalSqFt);
  }

  // ── Step 7: N-sided polygon via triangulation ─────────────────────────────
  /// sides: all n side lengths
  /// diagonals: n-3 diagonals that triangulate the polygon
  /// Returns null if any triangle is invalid.
  static AreaResult? polygonArea({
    required List<double> sides,
    required List<double> diagonals,
  }) {
    final n = sides.length;
    if (n < 3) return null;
    if (n == 3) {
      final r = heronFormula(sides[0], sides[1], sides[2]);
      return r.isValid ? convertFromSqFt(r.area) : null;
    }
    if (n == 4) {
      if (diagonals.isEmpty) return null;
      return quadrilateralArea(
        a: sides[0],
        b: sides[1],
        c: sides[2],
        d: sides[3],
        diagonal: diagonals[0],
      );
    }

    // For n > 4, use fan triangulation from vertex 0
    // Triangles: (0,1,2), (0,2,3), ..., (0,n-2,n-1)
    // We need the polygon points to do this properly.
    // Use the coordinate-based approach.
    double totalArea = 0.0;
    // Build points from sides + diagonals using fan triangulation
    final points = _buildPolygonPoints(sides, diagonals);
    if (points == null || points.length < 3) return null;

    totalArea = _shoelaceArea(points).abs();
    return convertFromSqFt(totalArea);
  }

  // ── Coordinate builder from side lengths (fan from vertex 0) ─────────────
  static List<Point2D>? _buildPolygonPoints(
      List<double> sides, List<double> diagonals) {
    final n = sides.length;
    final points = <Point2D>[const Point2D(0, 0)];
    // Place second point along X axis
    points.add(Point2D(sides[0], 0));

    for (int i = 2; i < n; i++) {
      final double d1 = (i - 1 < diagonals.length)
          ? diagonals[i - 1]
          : sides[i - 1]; // fallback
      final double d2 = sides[i - 1];
      // Intersect circle from points[0] (radius = diagonals[i-2] if available)
      // and points[i-1] (radius = sides[i-1])
      final double diagLen = (i - 2 < diagonals.length)
          ? diagonals[i - 2]
          : _estimateDiagonal(points, i);
      final p = _circleIntersect(points[0], diagLen, points[i - 1], d2);
      if (p == null) return null;
      points.add(p);
    }
    return points;
  }

  static double _estimateDiagonal(List<Point2D> pts, int idx) {
    if (idx < pts.length) return pts[0].distanceTo(pts[idx]);
    return 100.0;
  }

  // ── Circle-circle intersection (upper point) ─────────────────────────────
  static Point2D? _circleIntersect(
      Point2D c1, double r1, Point2D c2, double r2) {
    final double dx = c2.x - c1.x;
    final double dy = c2.y - c1.y;
    final double d = math.sqrt(dx * dx + dy * dy);
    if (d > r1 + r2 || d < (r1 - r2).abs() || d == 0) return null;
    final double a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final double h = math.sqrt(math.max(0, r1 * r1 - a * a));
    final double mx = c1.x + a * dx / d;
    final double my = c1.y + a * dy / d;
    // Return upper intersection (positive y)
    final double px = mx + h * dy / d;
    final double py = my - h * dx / d;
    return Point2D(px, py);
  }

  // ── Shoelace formula ──────────────────────────────────────────────────────
  static double _shoelaceArea(List<Point2D> pts) {
    double sum = 0.0;
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      sum += pts[i].x * pts[j].y;
      sum -= pts[j].x * pts[i].y;
    }
    return sum / 2.0;
  }

  // ── Shoelace from raw points ──────────────────────────────────────────────
  static AreaResult shoelaceFromPoints(List<Point2D> points) {
    final area = _shoelaceArea(points).abs();
    return convertFromSqFt(area);
  }

  // ── Build scaled display points from side/diagonal lengths ───────────────
  static List<Point2D> buildDisplayPoints(
      List<double> sides, List<double> diagonals) {
    final pts = _buildPolygonPoints(sides, diagonals);
    return pts ?? [];
  }

  // ── Step 13: Anna-Gonda-Kora-Kranti-Til share calculator ─────────────────
  /// Returns total units in Til (smallest unit)
  /// 1 Anna = 6 Gonda = 24 Kora = 96 Kranti = 384 Til
  static double shareholderToTil({
    int anna = 0,
    int gonda = 0,
    int kora = 0,
    int kranti = 0,
    int til = 0,
  }) {
    return anna * 384.0 +
        gonda * 64.0 +
        kora * 16.0 +
        kranti * 4.0 +
        til * 1.0;
  }

  static Map<String, double> calculateShares({
    required List<Map<String, dynamic>> shareholders,
    required double totalSqFt,
  }) {
    // Total property = 16 Anna = 6144 Til
    const double totalTil = 16 * 384.0;
    final result = <String, double>{};
    for (final s in shareholders) {
      final til = shareholderToTil(
        anna: s['anna'] ?? 0,
        gonda: s['gonda'] ?? 0,
        kora: s['kora'] ?? 0,
        kranti: s['kranti'] ?? 0,
        til: s['til'] ?? 0,
      );
      final fraction = til / totalTil;
      result[s['name'] as String] = totalSqFt * fraction;
    }
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static double _roundTo4(double v) =>
      (v * 10000).round() / 10000;

  static String formatBanglaNumber(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // ── Scale conversion ──────────────────────────────────────────────────────
  static double getScaleFactor(String preset) {
    switch (preset) {
      case '১৬" = ১ মাইল': return 1.0 / (16.0 * 12 * 5280);
      case '৩২" = ১ মাইল': return 1.0 / (32.0 * 12 * 5280);
      case '৬৪" = ১ মাইল': return 1.0 / (64.0 * 12 * 5280);
      case '১:৩৯৬০':       return 1.0 / 3960.0;
      case '১:১৯৮০':       return 1.0 / 1980.0;
      default:              return 1.0 / 3960.0;
    }
  }

  // ── Side length label from two points ─────────────────────────────────────
  static double sideLengthBetween(Point2D a, Point2D b) {
    return a.distanceTo(b);
  }
}
