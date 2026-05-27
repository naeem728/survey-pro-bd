// lib/presentation/screens/project_form_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';
import 'survey_screen.dart';

class ProjectFormScreen extends StatefulWidget {
  final ProjectModel? existingProject;
  const ProjectFormScreen({super.key, this.existingProject});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProjectRepository();
  bool _saving = false;

  late TextEditingController _projectName;
  late TextEditingController _mouza;
  late TextEditingController _khatianNo;
  late TextEditingController _dagNo;
  late TextEditingController _jlNo;
  late TextEditingController _sheetNo;
  late TextEditingController _surveyorName;
  late TextEditingController _surveyorPhone;
  late TextEditingController _notes;
  late TextEditingController _customScale;
  String _selectedDistrict = 'ঢাকা';
  String _selectedScale = '১৬" = ১ মাইল';
  bool _isCustomScale = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _projectName = TextEditingController(text: p?.projectName ?? '');
    _mouza = TextEditingController(text: p?.mouza ?? '');
    _khatianNo = TextEditingController(text: p?.khatianNo ?? '');
    _dagNo = TextEditingController(text: p?.dagNo ?? '');
    _jlNo = TextEditingController(text: p?.jlNo ?? '');
    _sheetNo = TextEditingController(text: p?.sheetNo ?? '');
    _surveyorName = TextEditingController(text: p?.surveyorName ?? '');
    _surveyorPhone = TextEditingController(text: p?.surveyorPhone ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _customScale = TextEditingController(text: p?.customScale ?? '');
    if (p != null) {
      _selectedDistrict = p.district.isNotEmpty ? p.district : 'ঢাকা';
      _selectedScale = p.scalePreset;
      _isCustomScale = p.scalePreset == 'কাস্টম স্কেল';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _projectName, _mouza, _khatianNo, _dagNo, _jlNo,
      _sheetNo, _surveyorName, _surveyorPhone, _notes, _customScale
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final project = widget.existingProject ?? ProjectModel();
      project
        ..projectName = _projectName.text.trim()
        ..mouza = _mouza.text.trim()
        ..khatianNo = _khatianNo.text.trim()
        ..dagNo = _dagNo.text.trim()
        ..jlNo = _jlNo.text.trim()
        ..sheetNo = _sheetNo.text.trim()
        ..district = _selectedDistrict
        ..surveyorName = _surveyorName.text.trim()
        ..surveyorPhone = _surveyorPhone.text.trim()
        ..notes = _notes.text.trim()
        ..scalePreset = _selectedScale
        ..customScale = _customScale.text.trim();

      int id;
      if (widget.existingProject == null) {
        id = await _repo.saveProject(project);
        project.id = id;
      } else {
        await _repo.updateProject(project);
        id = project.id;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SurveyScreen(project: project),
        ),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('সংরক্ষণে সমস্যা: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProject != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEdit ? 'প্রজেক্ট সম্পাদনা' : 'নতুন প্রজেক্ট',
          style: AppTextStyles.banglaHeading.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('📋 প্রজেক্ট তথ্য'),
            _field(_projectName, 'প্রজেক্টের নাম *', required: true),
            const SizedBox(height: 12),

            _sectionHeader('🗺️ জমির তথ্য'),
            _field(_mouza, 'মৌজার নাম *', required: true),
            _row([
              _field(_khatianNo, 'খতিয়ান নং'),
              _field(_dagNo, 'দাগ নং'),
            ]),
            _row([
              _field(_jlNo, 'জে.এল. নং'),
              _field(_sheetNo, 'শীট নং'),
            ]),
            // District dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: _decoration('জেলা'),
                isExpanded: true,
                items: AppConstants.districts
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d,
                              style: const TextStyle(fontFamily: 'Kalpurush')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDistrict = v!),
              ),
            ),
            const SizedBox(height: 12),

            _sectionHeader('👷 সার্ভেয়ারের তথ্য'),
            _field(_surveyorName, 'সার্ভেয়ারের নাম *', required: true),
            _field(_surveyorPhone, 'মোবাইল নম্বর',
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),

            _sectionHeader('📏 ম্যাপ স্কেল'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _selectedScale,
                decoration: _decoration('স্কেল নির্বাচন করুন'),
                isExpanded: true,
                items: AppConstants.scalePresets
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: const TextStyle(fontFamily: 'Kalpurush')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedScale = v!;
                  _isCustomScale = v == 'কাস্টম স্কেল';
                }),
              ),
            ),
            if (_isCustomScale)
              _field(_customScale, 'কাস্টম স্কেল লিখুন (যেমন: ১:২০০০)'),
            const SizedBox(height: 12),

            _sectionHeader('📝 মন্তব্য'),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Kalpurush'),
              decoration: _decoration('অতিরিক্ত নোট বা মন্তব্য'),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  _saving ? 'সংরক্ষণ হচ্ছে...' : 'পরবর্তী ধাপ →',
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title,
            style: AppTextStyles.banglaLabel.copyWith(
              color: AppColors.primary,
              fontSize: 15,
            )),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontFamily: 'Kalpurush'),
          decoration: _decoration(label),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label আবশ্যক' : null
              : null,
        ),
      );

  Widget _row(List<Widget> children) => Row(
        children: children
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: c,
                  ),
                ))
            .toList(),
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Kalpurush', fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
