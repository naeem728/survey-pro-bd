// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/project_repository.dart';
import 'project_form_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ProjectRepository();
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.getAllProjects();
    setState(() {
      _projects = all;
      _filtered = all;
      _loading = false;
    });
  }

  void _search(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = _projects;
      } else {
        final lower = q.toLowerCase();
        _filtered = _projects
            .where((p) =>
                p.projectName.toLowerCase().contains(lower) ||
                p.mouza.toLowerCase().contains(lower) ||
                p.dagNo.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  Future<void> _delete(ProjectModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('মুছে ফেলবেন?',
            style: AppTextStyles.banglaHeading),
        content: Text(
          '"${p.projectName}" প্রজেক্টটি স্থায়ীভাবে মুছে যাবে।',
          style: AppTextStyles.banglaBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল',
                style: TextStyle(fontFamily: 'Kalpurush')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('মুছে ফেলুন',
                style: AppTextStyles.banglaButton),
          ),
        ],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
    if (confirm == true) {
      await _repo.deleteProject(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'সার্ভে প্রো বিডি',
              style: TextStyle(
                  fontFamily: 'Kalpurush',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${_projects.length}টি প্রজেক্ট সংরক্ষিত',
              style: const TextStyle(
                  fontFamily: 'Kalpurush',
                  color: Colors.white60,
                  fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: const TextStyle(
                  fontFamily: 'Kalpurush', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'প্রজেক্ট খুঁজুন...',
                hintStyle: const TextStyle(
                    fontFamily: 'Kalpurush', color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _projectCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProjectFormScreen()),
          );
          _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('নতুন প্রজেক্ট',
            style: AppTextStyles.banglaButton),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 80, color: AppColors.primary.withOpacity(0.25)),
            const SizedBox(height: 16),
            const Text(
              'কোনো প্রজেক্ট নেই',
              style: TextStyle(
                  fontFamily: 'Kalpurush',
                  fontSize: 18,
                  color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            const Text(
              '"নতুন প্রজেক্ট" বাটনে ক্লিক করে শুরু করুন',
              style: AppTextStyles.banglaCaption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _projectCard(ProjectModel p) {
    final area = p.plot;
    final dateStr = DateFormat('dd/MM/yyyy').format(p.createdAt);
    return Dismissible(
      key: Key(p.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _delete(p),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SurveyScreen(project: p)),
            );
            _load();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.map,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.projectName.isNotEmpty
                            ? p.projectName
                            : '(নামহীন প্রজেক্ট)',
                        style: AppTextStyles.banglaLabel
                            .copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'মৌজা: ${p.mouza}  •  দাগ: ${p.dagNo}',
                        style: AppTextStyles.banglaCaption,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (area != null && area.totalAreaSqFt > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${area.totalAreaDecimal.toStringAsFixed(2)} শতাংশ',
                                style: const TextStyle(
                                  fontFamily: 'Kalpurush',
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(dateStr,
                              style: AppTextStyles.banglaCaption
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textLight),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectFormScreen(existingProject: p),
                        ),
                      );
                      _load();
                    } else if (v == 'delete') {
                      await _delete(p);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('সম্পাদনা',
                            style: TextStyle(fontFamily: 'Kalpurush')),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('মুছে ফেলুন',
                            style: TextStyle(
                                fontFamily: 'Kalpurush',
                                color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
