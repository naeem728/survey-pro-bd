// lib/presentation/screens/pdf_preview_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/pdf_generator_service.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';

class PdfPreviewScreen extends StatefulWidget {
  final ProjectModel project;
  final List<Offset> drawnPoints;
  final List<double> sides;
  final List<double> diagonals;
  final double northRotation;

  const PdfPreviewScreen({
    super.key,
    required this.project,
    required this.drawnPoints,
    required this.sides,
    required this.diagonals,
    required this.northRotation,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _generating = false;
  File? _pdfFile;
  Uint8List? _mouzaMapImage;
  String? _errorMsg;
  final _repo = ProjectRepository();

  Future<void> _pickMouzaMap() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() => _mouzaMapImage = bytes);

    // Save path to project
    widget.project.mouzaMapPath = xFile.path;
    await _repo.updateProject(widget.project);
  }

  Future<void> _generatePdf() async {
    setState(() {
      _generating = true;
      _errorMsg = null;
    });
    try {
      final coords = widget.drawnPoints
          .map((p) => CoordinatePoint(x: p.dx, y: p.dy))
          .toList();

      final file = await PdfGeneratorService.generateReport(
        project: widget.project,
        coordinates: coords,
        sides: widget.sides,
        diagonals: widget.diagonals,
        northRotation: widget.northRotation,
        mouzaMapImage: _mouzaMapImage,
      );
      setState(() {
        _pdfFile = file;
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'PDF তৈরিতে সমস্যা: $e';
        _generating = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) return;
    await Share.shareXFiles(
      [XFile(_pdfFile!.path)],
      text: 'Survey Pro BD - ${widget.project.projectName} রিপোর্ট',
    );
  }

  // Step 16: Export DXF for AutoCAD
  Future<void> _exportDxf() async {
    if (widget.drawnPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DXF এক্সপোর্টের জন্য জমির আকৃতি আঁকুন',
              style: TextStyle(fontFamily: 'Kalpurush')),
        ),
      );
      return;
    }
    try {
      final dxf = _buildDxfString(widget.drawnPoints);
      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.project.projectName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final path = '${dir.path}/SurveyProBD_${safeName}.dxf';
      await File(path).writeAsString(dxf);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Survey Pro BD - DXF ফাইল (AutoCAD)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DXF এক্সপোর্ট ব্যর্থ: $e')),
        );
      }
    }
  }

  String _buildDxfString(List<Offset> pts) {
    final buf = StringBuffer();
    // DXF header
    buf.writeln('0\nSECTION\n2\nHEADER\n0\nENDSEC');
    buf.writeln('0\nSECTION\n2\nENTITIES');

    // LWPOLYLINE entity
    buf.writeln('0\nLWPOLYLINE');
    buf.writeln('8\n0'); // layer 0
    buf.writeln('90\n${pts.length}'); // vertex count
    buf.writeln('70\n1'); // closed flag
    buf.writeln('43\n0.0'); // constant width

    for (final p in pts) {
      buf.writeln('10\n${p.dx.toStringAsFixed(4)}');
      buf.writeln('20\n${(-p.dy).toStringAsFixed(4)}'); // flip Y for CAD
    }

    // Side length text entities
    for (int i = 0; i < pts.length && i < widget.sides.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      final mx = (p1.dx + p2.dx) / 2;
      final my = -(p1.dy + p2.dy) / 2;
      buf.writeln('0\nTEXT');
      buf.writeln('8\nDIMENSIONS');
      buf.writeln('10\n${mx.toStringAsFixed(4)}');
      buf.writeln('20\n${my.toStringAsFixed(4)}');
      buf.writeln('30\n0.0');
      buf.writeln('40\n5.0'); // height
      buf.writeln('1\n${widget.sides[i].toStringAsFixed(2)} ft');
    }

    buf.writeln('0\nENDSEC\n0\nEOF');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('PDF রিপোর্ট',
            style: TextStyle(
                fontFamily: 'Kalpurush', color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pdfFile != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePdf,
              tooltip: 'শেয়ার করুন',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Project info card
          _infoCard(),
          const SizedBox(height: 16),

          // Mouza map picker (Step 16)
          _mouzaMapCard(),
          const SizedBox(height: 16),

          // Error message
          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(_errorMsg!,
                  style: const TextStyle(
                      fontFamily: 'Kalpurush', color: AppColors.error)),
            ),

          // Generate PDF button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generatePdf,
              icon: _generating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                _generating ? 'তৈরি হচ্ছে...' : 'PDF তৈরি করুন',
                style: AppTextStyles.banglaButton,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Success + share
          if (_pdfFile != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('PDF সফলভাবে তৈরি হয়েছে!',
                          style: TextStyle(
                              fontFamily: 'Kalpurush',
                              color: AppColors.success,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share,
                              color: AppColors.primary, size: 18),
                          label: const Text('শেয়ার / সেভ',
                              style: TextStyle(
                                  fontFamily: 'Kalpurush',
                                  color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // DXF Export (Step 16)
          OutlinedButton.icon(
            onPressed: _exportDxf,
            icon: const Icon(Icons.architecture, color: AppColors.primary),
            label: const Text('AutoCAD DXF এক্সপোর্ট',
                style: TextStyle(
                    fontFamily: 'Kalpurush', color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final area = widget.project.plot;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 প্রজেক্ট সারসংক্ষেপ',
              style: AppTextStyles.banglaLabel),
          const Divider(),
          _row('প্রজেক্ট', widget.project.projectName),
          _row('মৌজা', widget.project.mouza),
          _row('দাগ নং', widget.project.dagNo),
          _row('সার্ভেয়ার', widget.project.surveyorName),
          if (area != null && area.totalAreaSqFt > 0) ...[
            const Divider(),
            _row('ক্ষেত্রফল',
                '${area.totalAreaSqFt.toStringAsFixed(2)} বর্গফুট'),
            _row('শতাংশ',
                '${area.totalAreaDecimal.toStringAsFixed(4)} শতাংশ'),
          ],
        ],
      ),
    );
  }

  Widget _mouzaMapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('মৌজা ম্যাপ (ঐচ্ছিক)',
                  style: AppTextStyles.banglaLabel),
            ],
          ),
          const SizedBox(height: 4),
          const Text('PDF-এ ইনসেট মিনি-ম্যাপ যোগ করতে ছবি বেছে নিন',
              style: AppTextStyles.banglaCaption),
          const SizedBox(height: 10),
          if (_mouzaMapImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_mouzaMapImage!,
                  height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _pickMouzaMap,
            icon: const Icon(Icons.add_photo_alternate,
                color: AppColors.primary),
            label: Text(
              _mouzaMapImage == null
                  ? 'মৌজা ম্যাপের ছবি যোগ করুন'
                  : 'ছবি পরিবর্তন করুন',
              style: const TextStyle(
                  fontFamily: 'Kalpurush', color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.banglaCaption),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: AppTextStyles.banglaBody
                      .copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}
