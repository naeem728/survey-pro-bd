// lib/presentation/widgets/dimension_input_dialog.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/survey_math_engine.dart';

class DimensionInputDialog extends StatefulWidget {
  final int sideCount;
  final List<double> initialSides;
  final List<double> initialDiagonals;
  final Function(List<double> sides, List<double> diagonals) onConfirm;

  const DimensionInputDialog({
    super.key,
    required this.sideCount,
    required this.onConfirm,
    this.initialSides = const [],
    this.initialDiagonals = const [],
  });

  @override
  State<DimensionInputDialog> createState() => _DimensionInputDialogState();
}

class _DimensionInputDialogState extends State<DimensionInputDialog> {
  late List<TextEditingController> _sideControllers;
  late List<TextEditingController> _diagControllers;
  AreaResult? _previewArea;
  String? _errorMsg;

  int get _diagCount => widget.sideCount >= 4 ? widget.sideCount - 3 : 0;

  @override
  void initState() {
    super.initState();
    _sideControllers = List.generate(
      widget.sideCount,
      (i) => TextEditingController(
        text: i < widget.initialSides.length
            ? widget.initialSides[i].toString()
            : '',
      ),
    );
    _diagControllers = List.generate(
      _diagCount,
      (i) => TextEditingController(
        text: i < widget.initialDiagonals.length
            ? widget.initialDiagonals[i].toString()
            : '',
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _sideControllers) c.dispose();
    for (final c in _diagControllers) c.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMsg = null);
    final sides = <double>[];
    final diags = <double>[];

    for (int i = 0; i < _sideControllers.length; i++) {
      final v = double.tryParse(_sideControllers[i].text.trim());
      if (v == null || v <= 0) {
        setState(() => _errorMsg = '${i + 1} নং বাহুর মাপ সঠিকভাবে লিখুন।');
        return;
      }
      sides.add(v);
    }
    for (int i = 0; i < _diagControllers.length; i++) {
      final v = double.tryParse(_diagControllers[i].text.trim());
      if (v == null || v <= 0) {
        setState(() => _errorMsg = '${i + 1} নং কর্ণের মাপ সঠিকভাবে লিখুন।');
        return;
      }
      diags.add(v);
    }

    AreaResult? result;
    if (widget.sideCount == 3) {
      final r = SurveyMathEngine.heronFormula(sides[0], sides[1], sides[2]);
      if (!r.isValid) {
        setState(() => _errorMsg = r.errorMessage);
        return;
      }
      result = SurveyMathEngine.convertFromSqFt(r.area);
    } else {
      result = SurveyMathEngine.polygonArea(sides: sides, diagonals: diags);
      if (result == null) {
        setState(() => _errorMsg = 'পরিমাপগুলো দিয়ে বৈধ আকৃতি তৈরি সম্ভব নয়।');
        return;
      }
    }
    setState(() => _previewArea = result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.straighten, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'জমির পরিমাপ লিখুন',
                    style: AppTextStyles.banglaHeading,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  // Side length inputs
                  Text('বাহুর দৈর্ঘ্য (ফুটে)',
                      style: AppTextStyles.banglaLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 12),
                  ...List.generate(widget.sideCount, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _sideControllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: _inputDecoration(
                                  '${i + 1} নং বাহু (ফুট)', Colors.black),
                              onChanged: (_) => setState(() => _previewArea = null),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Diagonal inputs
                  if (_diagCount > 0) ...[
                    const SizedBox(height: 8),
                    Text('কর্ণের দৈর্ঘ্য (ফুটে)',
                        style: AppTextStyles.banglaLabel.copyWith(
                          color: AppColors.dimension,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 12),
                    ...List.generate(_diagCount, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.dimension,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _diagControllers[i],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: _inputDecoration(
                                    '${i + 1} নং কর্ণ (ফুট)',
                                    AppColors.dimension),
                                onChanged: (_) =>
                                    setState(() => _previewArea = null),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  // Error
                  if (_errorMsg != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                            fontFamily: 'Kalpurush',
                            color: AppColors.error,
                          )),
                    ),
                  // Preview area result
                  if (_previewArea != null) _buildAreaPreview(_previewArea!),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _calculate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('হিসাব করুন',
                              style: TextStyle(
                                fontFamily: 'Kalpurush',
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _previewArea == null
                              ? null
                              : () {
                                  final sides = _sideControllers
                                      .map((c) =>
                                          double.tryParse(c.text.trim()) ?? 0)
                                      .toList();
                                  final diags = _diagControllers
                                      .map((c) =>
                                          double.tryParse(c.text.trim()) ?? 0)
                                      .toList();
                                  widget.onConfirm(sides, diags);
                                  Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('নিশ্চিত করুন',
                              style: AppTextStyles.banglaButton),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaPreview(AreaResult r) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📐 হিসাবকৃত ক্ষেত্রফল',
              style: AppTextStyles.banglaLabel),
          const Divider(),
          _areaRow('বর্গফুট', '${r.squareFeet.toStringAsFixed(2)} বর্গফুট'),
          _areaRow('শতাংশ', '${r.decimal.toStringAsFixed(4)} শতাংশ'),
          _areaRow('কাঠা', '${r.katha.toStringAsFixed(4)} কাঠা'),
          _areaRow('বিঘা', '${r.bigha.toStringAsFixed(4)} বিঘা'),
          _areaRow('একর', '${r.acre.toStringAsFixed(4)} একর'),
          _areaRow('লিঙ্ক', '${r.link.toStringAsFixed(2)} লিঙ্ক'),
        ],
      ),
    );
  }

  Widget _areaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.banglaCaption
                    .copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value,
                style: AppTextStyles.banglaBody
                    .copyWith(color: AppColors.primary, fontSize: 15)),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint, Color borderColor) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Kalpurush', fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        suffixText: 'ফুট',
        suffixStyle: const TextStyle(
            fontFamily: 'Kalpurush',
            color: AppColors.textLight,
            fontSize: 13),
      );
}
