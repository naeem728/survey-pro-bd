// lib/presentation/screens/shareholder_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/survey_math_engine.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';

class ShareholderScreen extends StatefulWidget {
  final ProjectModel project;
  final double totalSqFt;
  final Function(ProjectModel)? onUpdated;

  const ShareholderScreen({
    super.key,
    required this.project,
    required this.totalSqFt,
    this.onUpdated,
  });

  @override
  State<ShareholderScreen> createState() => _ShareholderScreenState();
}

class _ShareholderScreenState extends State<ShareholderScreen> {
  final _repo = ProjectRepository();
  late List<_ShareEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.project.shareholders
        .map((s) => _ShareEntry(
              name: TextEditingController(text: s.name),
              anna: TextEditingController(text: s.anna.toString()),
              gonda: TextEditingController(text: s.gonda.toString()),
              kora: TextEditingController(text: s.kora.toString()),
              kranti: TextEditingController(text: s.kranti.toString()),
              til: TextEditingController(text: s.til.toString()),
            ))
        .toList();
    if (_entries.isEmpty) _addRow();
  }

  void _addRow() {
    setState(() => _entries.add(_ShareEntry.empty()));
  }

  void _removeRow(int i) {
    if (_entries.length > 1) {
      setState(() => _entries.removeAt(i));
    }
  }

  Future<void> _calculate() async {
    final raw = _entries
        .map((e) => {
              'name': e.name.text.trim().isEmpty ? 'অজ্ঞাত' : e.name.text.trim(),
              'anna': int.tryParse(e.anna.text) ?? 0,
              'gonda': int.tryParse(e.gonda.text) ?? 0,
              'kora': int.tryParse(e.kora.text) ?? 0,
              'kranti': int.tryParse(e.kranti.text) ?? 0,
              'til': int.tryParse(e.til.text) ?? 0,
            })
        .toList();

    final shares = SurveyMathEngine.calculateShares(
      shareholders: raw,
      totalSqFt: widget.totalSqFt,
    );

    // Check total shares = 16 anna
    double totalTil = 0;
    for (final s in raw) {
      totalTil += SurveyMathEngine.shareholderToTil(
        anna: s['anna'] as int,
        gonda: s['gonda'] as int,
        kora: s['kora'] as int,
        kranti: s['kranti'] as int,
        til: s['til'] as int,
      );
    }
    const maxTil = 16 * 384.0;
    if (totalTil > maxTil + 0.01) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'মোট অংশ ১৬ আনার বেশি হতে পারবে না!',
              style: TextStyle(fontFamily: 'Kalpurush'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Save to model
    final updatedShareholders = raw.asMap().entries.map((e) {
      final name = e.value['name'] as String;
      final sqFt = shares[name] ?? 0;
      return ShareholderModel(
        name: name,
        anna: e.value['anna'] as int,
        gonda: e.value['gonda'] as int,
        kora: e.value['kora'] as int,
        kranti: e.value['kranti'] as int,
        til: e.value['til'] as int,
        shareAreaSqFt: sqFt,
        shareAreaDecimal: sqFt / 435.6,
      );
    }).toList();

    widget.project.shareholders = updatedShareholders;
    await _repo.updateProject(widget.project);
    widget.onUpdated?.call(widget.project);

    if (mounted) {
      setState(() {});
      _showResultDialog(updatedShareholders);
    }
  }

  void _showResultDialog(List<ShareholderModel> results) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('অংশীদারিত্বের ফলাফল',
            style: AppTextStyles.banglaHeading),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.totalSqFt <= 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '⚠️ প্রথমে জমির ক্ষেত্রফল হিসাব করুন',
                    style: TextStyle(
                        fontFamily: 'Kalpurush', color: AppColors.warning),
                  ),
                ),
              ...results.map((r) => _shareResultTile(r)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন',
                style: TextStyle(fontFamily: 'Kalpurush')),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('মোট জমি',
                          style: AppTextStyles.banglaCaption),
                      Text(
                        widget.totalSqFt > 0
                            ? '${widget.totalSqFt.toStringAsFixed(2)} বর্গফুট  •  '
                                '${(widget.totalSqFt / 435.6).toStringAsFixed(4)} শতাংশ'
                            : 'এখনো হিসাব হয়নি',
                        style: AppTextStyles.banglaBody
                            .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: Text('নাম', style: AppTextStyles.banglaLabel)),
                const Expanded(
                    child: Text('আনা', style: AppTextStyles.banglaLabel)),
                const Expanded(
                    child: Text('গণ্ডা', style: AppTextStyles.banglaLabel)),
                const Expanded(
                    child: Text('কড়া', style: AppTextStyles.banglaLabel)),
                const Expanded(
                    child: Text('ক্রান্তি', style: AppTextStyles.banglaLabel)),
                const SizedBox(width: 32),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Rows
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _entries.length,
              itemBuilder: (_, i) => _buildRow(i),
            ),
          ),
          // Add row button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('নতুন অংশীদার',
                        style: TextStyle(
                            fontFamily: 'Kalpurush',
                            color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.totalSqFt > 0 ? _calculate : null,
                    icon: const Icon(Icons.calculate, color: Colors.white),
                    label: const Text('হিসাব করুন',
                        style: AppTextStyles.banglaButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results
          if (widget.project.shareholders.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('শেষ হিসাবের ফলাফল:',
                      style: AppTextStyles.banglaLabel),
                  const SizedBox(height: 8),
                  ...widget.project.shareholders
                      .map((s) => _shareResultTile(s)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(int i) {
    final e = _entries[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _miniField(e.name, '${i + 1}. নাম'),
            ),
            const SizedBox(width: 4),
            Expanded(child: _miniField(e.anna, '০-১৬')),
            const SizedBox(width: 4),
            Expanded(child: _miniField(e.gonda, '০-৫')),
            const SizedBox(width: 4),
            Expanded(child: _miniField(e.kora, '০-৩')),
            const SizedBox(width: 4),
            Expanded(child: _miniField(e.kranti, '০-৩')),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.error, size: 20),
              onPressed: () => _removeRow(i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniField(TextEditingController c, String hint) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontFamily: 'Kalpurush', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          isDense: true,
        ),
      );

  Widget _shareResultTile(ShareholderModel s) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(s.name, style: AppTextStyles.banglaLabel),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${s.shareAreaSqFt.toStringAsFixed(2)} বর্গফুট',
                    style: AppTextStyles.banglaCaption
                        .copyWith(fontWeight: FontWeight.bold)),
                Text('${s.shareAreaDecimal.toStringAsFixed(4)} শতাংশ',
                    style: AppTextStyles.banglaCaption
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ),
      );
}

class _ShareEntry {
  final TextEditingController name;
  final TextEditingController anna;
  final TextEditingController gonda;
  final TextEditingController kora;
  final TextEditingController kranti;
  final TextEditingController til;

  _ShareEntry({
    required this.name,
    required this.anna,
    required this.gonda,
    required this.kora,
    required this.kranti,
    required this.til,
  });

  factory _ShareEntry.empty() => _ShareEntry(
        name: TextEditingController(),
        anna: TextEditingController(text: '0'),
        gonda: TextEditingController(text: '0'),
        kora: TextEditingController(text: '0'),
        kranti: TextEditingController(text: '0'),
        til: TextEditingController(text: '0'),
      );
}
