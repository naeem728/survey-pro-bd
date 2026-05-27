// lib/presentation/screens/survey_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/survey_math_engine.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';
import '../widgets/plot_canvas_painter.dart';
import '../widgets/dimension_input_dialog.dart';
import 'shareholder_screen.dart';
import 'pdf_preview_screen.dart';

class SurveyScreen extends StatefulWidget {
  final ProjectModel project;
  const SurveyScreen({super.key, required this.project});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = ProjectRepository();
  final _canvasKey = GlobalKey<DrawingCanvasScreenState>();

  List<double> _sides = [];
  List<double> _diagonals = [];
  AreaResult? _areaResult;
  double _northRotation = 0.0;
  bool _hasDrawing = false;
  bool _isClosed = false;
  List<Offset> _drawnPoints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final plot = widget.project.plot;
    if (plot != null) {
      _sides = List<double>.from(plot.sideLengths);
      _diagonals = List<double>.from(plot.diagonalLengths);
      if (plot.totalAreaSqFt > 0) {
        _areaResult = SurveyMathEngine.convertFromSqFt(plot.totalAreaSqFt);
      }
    }
    _northRotation = widget.project.northRotation;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPointsChanged(List<Offset> pts, bool closed) {
    setState(() {
      _drawnPoints = pts;
      _isClosed = closed;
      _hasDrawing = pts.isNotEmpty;
    });
  }

  void _openDimensionInput() {
    if (_drawnPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কমপক্ষে ৩টি বিন্দু আঁকুন',
              style: TextStyle(fontFamily: 'Kalpurush')),
        ),
      );
      return;
    }
    final n = _drawnPoints.length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DimensionInputDialog(
        sideCount: n,
        initialSides: _sides,
        initialDiagonals: _diagonals,
        onConfirm: (sides, diags) async {
          setState(() {
            _sides = sides;
            _diagonals = diags;
          });
          AreaResult? result;
          if (n == 3) {
            final r = SurveyMathEngine.heronFormula(
                sides[0], sides[1], sides[2]);
            if (r.isValid) {
              result = SurveyMathEngine.convertFromSqFt(r.area);
            }
          } else {
            result = SurveyMathEngine.polygonArea(
                sides: sides, diagonals: diags);
          }
          setState(() => _areaResult = result);

          // Save to DB
          final plot = widget.project.plot ?? PlotModel();
          plot
            ..sideLengths = sides
            ..diagonalLengths = diags
            ..totalAreaSqFt = result?.squareFeet ?? 0
            ..totalAreaDecimal = result?.decimal ?? 0
            ..totalAreaKatha = result?.katha ?? 0
            ..totalAreaBigha = result?.bigha ?? 0
            ..totalAreaAcre = result?.acre ?? 0
            ..coordinates = _drawnPoints
                .map((p) => CoordinatePoint(x: p.dx, y: p.dy))
                .toList();
          widget.project.plot = plot;
          await _repo.updateProject(widget.project);
        },
      ),
    );
  }

  Future<void> _saveNorthRotation(double val) async {
    widget.project.northRotation = val;
    await _repo.updateProject(widget.project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.projectName.isNotEmpty
                  ? widget.project.projectName
                  : 'সার্ভে',
              style: AppTextStyles.banglaHeading
                  .copyWith(color: Colors.white, fontSize: 16),
            ),
            if (widget.project.mouza.isNotEmpty)
              Text(
                'মৌজা: ${widget.project.mouza}  |  দাগ: ${widget.project.dagNo}',
                style: const TextStyle(
                  fontFamily: 'Kalpurush',
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontFamily: 'Kalpurush', fontSize: 13),
          tabs: const [
            Tab(text: '✏️ আঁকুন'),
            Tab(text: '📊 ফলাফল'),
            Tab(text: '👥 অংশীদার'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'PDF তৈরি করুন',
            onPressed: _areaResult == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(
                          project: widget.project,
                          drawnPoints: _drawnPoints,
                          sides: _sides,
                          diagonals: _diagonals,
                          northRotation: _northRotation,
                        ),
                      ),
                    ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Tab 1: Canvas ─────────────────────────────────────────────
          _buildCanvasTab(),
          // ── Tab 2: Results ────────────────────────────────────────────
          _buildResultsTab(),
          // ── Tab 3: Shareholders ───────────────────────────────────────
          ShareholderScreen(
            project: widget.project,
            totalSqFt: _areaResult?.squareFeet ?? 0,
            onUpdated: (p) => setState(() {}),
          ),
        ],
      ),
      // FAB to open dimension input
      floatingActionButton: _tabController.index == 0 && _isClosed
          ? FloatingActionButton.extended(
              onPressed: _openDimensionInput,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.straighten, color: Colors.white),
              label: const Text('পরিমাপ লিখুন',
                  style: AppTextStyles.banglaButton),
            )
          : null,
    );
  }

  Widget _buildCanvasTab() {
    return Column(
      children: [
        Expanded(
          child: DrawingCanvasScreen(
            key: _canvasKey,
            confirmedSides: _sides,
            confirmedDiagonals: _diagonals,
            northRotation: _northRotation,
            onPointsChanged: _onPointsChanged,
          ),
        ),
        // North Arrow Rotation Slider (Step 12)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('উত্তর দিক ঘোরান',
                      style: TextStyle(
                          fontFamily: 'Kalpurush',
                          fontSize: 13,
                          color: AppColors.primary)),
                  const Spacer(),
                  Text('${_northRotation.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          fontFamily: 'Kalpurush',
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  thumbColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _northRotation,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  onChanged: (v) => setState(() => _northRotation = v),
                  onChangeEnd: _saveNorthRotation,
                ),
              ),
            ],
          ),
        ),
        if (!_isClosed && _drawnPoints.length >= 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openDimensionInput,
                icon: const Icon(Icons.straighten, color: Colors.white),
                label: const Text('পরিমাপ লিখুন',
                    style: AppTextStyles.banglaButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsTab() {
    if (_areaResult == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calculate_outlined,
                size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'প্রথমে জমির আকৃতি আঁকুন\nতারপর পরিমাপ লিখুন',
              style: AppTextStyles.banglaBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('আঁকতে যান',
                  style: AppTextStyles.banglaButton),
            ),
          ],
        ),
      );
    }

    final r = _areaResult!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _resultCard(
          icon: '📐',
          title: 'মোট ক্ষেত্রফল',
          items: [
            _ResultItem('বর্গফুট', '${r.squareFeet.toStringAsFixed(2)} বর্গফুট'),
            _ResultItem('শতাংশ (Decimal)', '${r.decimal.toStringAsFixed(4)} শতাংশ'),
            _ResultItem('কাঠা', '${r.katha.toStringAsFixed(4)} কাঠা'),
            _ResultItem('বিঘা', '${r.bigha.toStringAsFixed(4)} বিঘা'),
            _ResultItem('একর', '${r.acre.toStringAsFixed(6)} একর'),
            _ResultItem('লিঙ্ক', '${r.link.toStringAsFixed(2)} লিঙ্ক'),
          ],
          highlight: true,
        ),
        const SizedBox(height: 12),
        _resultCard(
          icon: '📋',
          title: 'প্রজেক্ট তথ্য',
          items: [
            _ResultItem('প্রজেক্ট', widget.project.projectName),
            _ResultItem('মৌজা', widget.project.mouza),
            _ResultItem('খতিয়ান', widget.project.khatianNo),
            _ResultItem('দাগ নং', widget.project.dagNo),
            _ResultItem('জে.এল. নং', widget.project.jlNo),
            _ResultItem('জেলা', widget.project.district),
            _ResultItem('স্কেল', widget.project.scalePreset),
          ],
        ),
        const SizedBox(height: 12),
        _resultCard(
          icon: '📏',
          title: 'পরিমাপের বিবরণ',
          items: [
            _ResultItem('বাহুর সংখ্যা', '${_sides.length} টি'),
            ..._sides.asMap().entries.map((e) =>
                _ResultItem('${e.key + 1} নং বাহু',
                    '${e.value.toStringAsFixed(2)} ফুট')),
            if (_diagonals.isNotEmpty)
              ..._diagonals.asMap().entries.map((e) =>
                  _ResultItem('${e.key + 1} নং কর্ণ',
                      '${e.value.toStringAsFixed(2)} ফুট')),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(
                project: widget.project,
                drawnPoints: _drawnPoints,
                sides: _sides,
                diagonals: _diagonals,
                northRotation: _northRotation,
              ),
            ),
          ),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('PDF রিপোর্ট তৈরি করুন',
              style: AppTextStyles.banglaButton),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required String icon,
    required String title,
    required List<_ResultItem> items,
    bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(title,
                    style: AppTextStyles.banglaLabel
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(item.label,
                        style: AppTextStyles.banglaCaption.copyWith(
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(item.value,
                        style: AppTextStyles.banglaBody.copyWith(
                          color: highlight
                              ? AppColors.primary
                              : AppColors.text,
                          fontWeight: highlight
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: highlight ? 15 : 14,
                        )),
                  ],
                ),
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ResultItem {
  final String label;
  final String value;
  const _ResultItem(this.label, this.value);
}
