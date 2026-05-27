// lib/data/repositories/project_repository.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project_model.dart';

class ProjectRepository {
  static Isar? _isar;

  // ─── Singleton DB init ───────────────────────────────────────────────────
  static Future<Isar> get db async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ProjectModelSchema],
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }

  // ─── CREATE ──────────────────────────────────────────────────────────────
  Future<int> saveProject(ProjectModel project) async {
    final isar = await db;
    project.createdAt = DateTime.now();
    project.updatedAt = DateTime.now();
    return await isar.writeTxn(() async {
      return await isar.projectModels.put(project);
    });
  }

  // ─── READ ALL ────────────────────────────────────────────────────────────
  Future<List<ProjectModel>> getAllProjects() async {
    final isar = await db;
    return await isar.projectModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  // ─── READ SINGLE ─────────────────────────────────────────────────────────
  Future<ProjectModel?> getProjectById(int id) async {
    final isar = await db;
    return await isar.projectModels.get(id);
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────
  Future<void> updateProject(ProjectModel project) async {
    final isar = await db;
    project.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.projectModels.put(project);
    });
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────
  Future<bool> deleteProject(int id) async {
    final isar = await db;
    return await isar.writeTxn(() async {
      return await isar.projectModels.delete(id);
    });
  }

  // ─── SEARCH ──────────────────────────────────────────────────────────────
  Future<List<ProjectModel>> searchProjects(String query) async {
    final isar = await db;
    return await isar.projectModels
        .filter()
        .projectNameContains(query, caseSensitive: false)
        .or()
        .mouzaContains(query, caseSensitive: false)
        .or()
        .dagNoContains(query, caseSensitive: false)
        .findAll();
  }

  // ─── COUNT ───────────────────────────────────────────────────────────────
  Future<int> getProjectCount() async {
    final isar = await db;
    return await isar.projectModels.count();
  }

  // ─── CLOSE ───────────────────────────────────────────────────────────────
  Future<void> close() async {
    await _isar?.close();
  }
}
