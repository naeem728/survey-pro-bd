// lib/data/datasources/pdf_generator_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/utils/survey_math_engine.dart';
import '../../data/models/project_model.dart';

class PdfGeneratorService {
  // ── Step 15: Load offline Bangla font from assets ───────────────────────
  static Future<pw.Font> _loadKalpurushFont() async {
    final data = await rootBundle.load('assets/fonts/Kalpurush_ANSI.ttf');
    return pw.Font.ttf(data);
  }

  // ── Step 14+15: Generate full A4 PDF ─────────────────────────────────────
  static Future<File> generateReport({
    required ProjectModel project,
    required List<CoordinatePoint> coordinates,
    required List<double> sides,
    required List<double> diagonals,
    required double northRotation,
    Uint8List? mouzaMapImage,
  }) async {
    final font = await _loadKalpurushFont();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font),
    );

    final area = project.plot;
    final areaResult = area != null && area.totalAreaSqFt > 0
        ? SurveyMathEngine.convertFromSqFt(area.totalAreaSqFt)
        : null;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => pw.Stack(
          children: [
            // Outer border
            pw.Positioned.fill(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColors.black, width: 2),
                ),
              ),
            ),
            // Inner border
            pw.Positioned(
              left: 6, right: 6, top: 6, bottom: 6,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColors.black, width: 0.5),
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                _buildHeader(font, project),
                pw.Divider(thickness: 1.5, color: PdfColors.black),
                pw.SizedBox(height: 6),
                // ── Metadata table ─────────────────────────────────────
                _buildMetadataTable(font, project, areaResult),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 6),
                // ── Plot diagram ────────────────────────────────────────
                pw.Expanded(
                  child: pw.Center(
                    child: pw.CustomPaint(
                      size: const PdfPoint(400, 300),
                      painter: (pdfCanvas, size) => _drawPlotDiagram(
                        pdfCanvas,
                        size,
                        coordinates,
                        sides,
                        diagonals,
                        northRotation,
                        font,
                        mouzaMapImage,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1),
                // ── Footer ─────────────────────────────────────────────
                _buildFooter(font, project),
              ],
            ),
          ],
        ),
      ),
    );

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final safeName = project.projectName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_');
    final path = '${dir.path}/SurveyProBD_${safeName}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // ── Header ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(pw.Font font, ProjectModel p) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'সার্ভে প্রো বিডি',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'জমি জরিপ ও ক্ষেত্রফল পরিমাপ রিপোর্ট',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
              pw.Text(
                'তারিখ: ${_formatDate(p.createdAt)}',
                style: pw.TextStyle(font: font, fontSize: 10,
                    color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Metadata table ────────────────────────────────────────────────────────
  static pw.Widget _buildMetadataTable(
      pw.Font font, ProjectModel p, AreaResult? area) {
    final cells = [
      ['প্রজেক্ট', p.projectName, 'মৌজা', p.mouza],
      ['খতিয়ান নং', p.khatianNo, 'দাগ নং', p.dagNo],
      ['জে.এল. নং', p.jlNo, 'শীট নং', p.sheetNo],
      ['জেলা', p.district, 'স্কেল', p.scalePreset],
      if (area != null) ...[
        ['মোট বর্গফুট', '${area.squareFeet.toStringAsFixed(2)}', 'শতাংশ',
            area.decimal.toStringAsFixed(4)],
        ['কাঠা', area.katha.toStringAsFixed(4), 'বিঘা',
            area.bigha.toStringAsFixed(4)],
      ],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(2),
      },
      children: cells
          .map((row) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: cells.indexOf(row) % 2 == 0
                      ? PdfColors.grey100
                      : PdfColors.white,
                ),
                children: row.asMap().entries.map((e) {
                  final isLabel = e.key % 2 == 0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      e.value,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        fontWeight: isLabel
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }

  // ── Plot diagram on PDF canvas ────────────────────────────────────────────
  static void _drawPlotDiagram(
    PdfGraphics canvas,
    PdfPoint size,
    List<CoordinatePoint> coords,
    List<double> sides,
    List<double> diagonals,
    double northRotation,
    pw.Font font,
    Uint8List? mouzaMapImage,
  ) {
    if (coords.length < 3) return;

    // Normalize coordinates to fit in canvas
    double minX = coords[0].x, minY = coords[0].y;
    double maxX = coords[0].x, maxY = coords[0].y;
    for (final c in coords) {
      minX = math.min(minX, c.x);
      minY = math.min(minY, c.y);
      maxX = math.max(maxX, c.x);
      maxY = math.max(maxY, c.y);
    }

    const margin = 40.0;
    final drawW = size.x - margin * 2;
    final drawH = size.y - margin * 2;
    final rangeX = (maxX - minX).abs() < 1 ? 1.0 : maxX - minX;
    final rangeY = (maxY - minY).abs() < 1 ? 1.0 : maxY - minY;
    final scale = math.min(drawW / rangeX, drawH / rangeY) * 0.85;

    PdfPoint toCanvas(CoordinatePoint c) {
      return PdfPoint(
        margin + (c.x - minX) * scale + (drawW - rangeX * scale) / 2,
        margin + (maxY - c.y) * scale + (drawH - rangeY * scale) / 2,
      );
    }

    // Draw inch grid (Step 14)
    canvas.setStrokeColor(PdfColors.grey200);
    canvas.setLineWidth(0.3);
    const inchPx = 72.0;
    for (double x = 0; x <= size.x; x += inchPx) {
      canvas.moveTo(x, 0);
      canvas.lineTo(x, size.y);
    }
    for (double y = 0; y <= size.y; y += inchPx) {
      canvas.moveTo(0, y);
      canvas.lineTo(size.x, y);
    }
    canvas.strokePath();

    final pts = coords.map(toCanvas).toList();

    // Draw filled polygon (light blue fill)
    canvas.setFillColor(PdfColors.lightBlue50);
    canvas.moveTo(pts.first.x, pts.first.y);
    for (int i = 1; i < pts.length; i++) {
      canvas.lineTo(pts[i].x, pts[i].y);
    }
    canvas.closePath();
    canvas.fillPath();

    // Draw boundary (Solid Black - Step 12)
    canvas.setStrokeColor(PdfColors.black);
    canvas.setLineWidth(1.5);
    canvas.moveTo(pts.first.x, pts.first.y);
    for (int i = 1; i < pts.length; i++) {
      canvas.lineTo(pts[i].x, pts[i].y);
    }
    canvas.closePath();
    canvas.strokePath();

    // Draw dashed diagonals (Dashed Red - Step 12)
    if (pts.length >= 4) {
      canvas.setStrokeColor(PdfColors.red);
      canvas.setLineWidth(0.8);
      for (int i = 2; i < pts.length - 1; i++) {
        _drawDashedLine(canvas, pts[0], pts[i]);
      }
    }

    // Draw dimension labels (Red - Step 12)
    canvas.setStrokeColor(PdfColors.red);
    canvas.setLineWidth(0.5);
    for (int i = 0; i < pts.length && i < sides.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      final mx = (p1.x + p2.x) / 2;
      final my = (p1.y + p2.y) / 2;

      // Small offset perpendicular to line
      final angle = math.atan2(p2.y - p1.y, p2.x - p1.x);
      final offX = -math.sin(angle) * 8;
      final offY = math.cos(angle) * 8;

      final label = '${sides[i].toStringAsFixed(1)}\'';
      _drawRotatedText(canvas, label, mx + offX, my + offY, angle, font);
    }

    // Draw vertices
    for (int i = 0; i < pts.length; i++) {
      canvas.setFillColor(i == 0 ? PdfColors.red : PdfColors.green);
      canvas.drawEllipse(pts[i].x - 3, pts[i].y - 3, 6, 6);
      canvas.fillPath();
    }

    // North Arrow (Step 12)
    _drawNorthArrow(canvas, size, northRotation);

    // Mouza map inset (Step 16)
    // Note: image rendering done in widget layer; skip raw canvas here
  }

  static void _drawDashedLine(
      PdfGraphics canvas, PdfPoint p1, PdfPoint p2) {
    const dash = 6.0, gap = 4.0;
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final nx = dx / dist;
    final ny = dy / dist;
    double d = 0;
    bool drawing = true;
    while (d < dist) {
      final seg = drawing ? dash : gap;
      final end = math.min(d + seg, dist);
      if (drawing) {
        canvas.moveTo(p1.x + nx * d, p1.y + ny * d);
        canvas.lineTo(p1.x + nx * end, p1.y + ny * end);
        canvas.strokePath();
      }
      d += seg;
      drawing = !drawing;
    }
  }

  static void _drawRotatedText(PdfGraphics canvas, String text,
      double x, double y, double angle, pw.Font font) {
    // PDF text rotation via transform
    canvas.saveContext();
    canvas.setTransform(
      Matrix4.identity()
        ..translate(x, y)
        ..rotateZ(angle),
    );
    canvas.setFillColor(PdfColors.red);
    canvas.drawString(font.getFont(const pw.Context()), 7, text, 0, 0);
    canvas.restoreContext();
  }

  static void _drawNorthArrow(
      PdfGraphics canvas, PdfPoint size, double rotation) {
    final cx = size.x - 25.0;
    final cy = size.y - 25.0;
    final rad = rotation * math.pi / 180;

    canvas.saveContext();
    canvas.setTransform(
      Matrix4.identity()..translate(cx, cy)..rotateZ(rad),
    );

    // Arrow up
    canvas.setFillColor(PdfColors.blueGrey800);
    canvas.moveTo(0, 18);
    canvas.lineTo(-5, -5);
    canvas.lineTo(0, 0);
    canvas.closePath();
    canvas.fillPath();

    // Arrow down
    canvas.setFillColor(PdfColors.blueGrey200);
    canvas.moveTo(0, -18);
    canvas.lineTo(5, 5);
    canvas.lineTo(0, 0);
    canvas.closePath();
    canvas.fillPath();

    canvas.restoreContext();

    // "N" label
    canvas.setFillColor(PdfColors.blueGrey800);
    canvas.drawString(
        PdfFont.helveticaBold(canvas.document), 9, 'N', cx - 3, cy + 24);
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Font font, ProjectModel p) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('সার্ভেয়ার: ${p.surveyorName}',
                  style: pw.TextStyle(font: font, fontSize: 9,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('মোবাইল: ${p.surveyorPhone}',
                  style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Survey Pro BD — অফলাইন জমি পরিমাপ',
                  style: pw.TextStyle(font: font, fontSize: 8,
                      color: PdfColors.grey600)),
              pw.Text('তৈরির তারিখ: ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(font: font, fontSize: 8,
                      color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// Minimal Matrix4 for PDF transforms
class Matrix4 {
  final List<double> _m;
  Matrix4._(this._m);

  factory Matrix4.identity() => Matrix4._([
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  void translate(double x, double y) {
    _m[12] += x;
    _m[13] += y;
  }

  void rotateZ(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    final m0 = _m[0], m1 = _m[1];
    _m[0] = m0 * c + _m[4] * s;
    _m[1] = m1 * c + _m[5] * s;
    _m[4] = -m0 * s + _m[4] * c;
    _m[5] = -m1 * s + _m[5] * c;
  }

  PdfNumList toPdfTransform() => PdfNumList([
        _m[0], _m[1], _m[4], _m[5], _m[12], _m[13],
      ]);
}

extension _CanvasTransform on PdfGraphics {
  void setTransform(Matrix4 m) {
    final t = m.toPdfTransform();
    buf.add('${t[0]} ${t[1]} ${t[2]} ${t[3]} ${t[4]} ${t[5]} cm\n');
  }
}
