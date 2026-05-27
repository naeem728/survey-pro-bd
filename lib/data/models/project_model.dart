// lib/data/models/project_model.dart
// ignore_for_file: unused_import
import 'package:isar/isar.dart';

part 'project_model.g.dart';

@embedded
class CoordinatePoint {
  late double x;
  late double y;

  CoordinatePoint({this.x = 0.0, this.y = 0.0});
}

@embedded
class PlotModel {
  late List<CoordinatePoint> coordinates;
  late List<double> sideLengths;
  late List<double> diagonalLengths;
  late double totalAreaSqFt;
  late double totalAreaDecimal;
  late double totalAreaKatha;
  late double totalAreaBigha;
  late double totalAreaAcre;

  PlotModel({
    List<CoordinatePoint>? coordinates,
    List<double>? sideLengths,
    List<double>? diagonalLengths,
    this.totalAreaSqFt = 0.0,
    this.totalAreaDecimal = 0.0,
    this.totalAreaKatha = 0.0,
    this.totalAreaBigha = 0.0,
    this.totalAreaAcre = 0.0,
  })  : coordinates = coordinates ?? [],
        sideLengths = sideLengths ?? [],
        diagonalLengths = diagonalLengths ?? [];
}

@embedded
class ShareholderModel {
  late String name;
  late int anna;
  late int gonda;
  late int kora;
  late int kranti;
  late int til;
  late double shareAreaSqFt;
  late double shareAreaDecimal;

  ShareholderModel({
    this.name = '',
    this.anna = 0,
    this.gonda = 0,
    this.kora = 0,
    this.kranti = 0,
    this.til = 0,
    this.shareAreaSqFt = 0.0,
    this.shareAreaDecimal = 0.0,
  });
}

@collection
class ProjectModel {
  Id id = Isar.autoIncrement;

  late String projectName;
  late String mouza;
  late String khatianNo;
  late String dagNo;
  late String jlNo;
  late String sheetNo;
  late String district;
  late String surveyorName;
  late String surveyorPhone;
  late String notes;
  late String scalePreset;
  late String customScale;
  late DateTime createdAt;
  late DateTime updatedAt;

  PlotModel? plot;
  List<ShareholderModel> shareholders = [];

  // North arrow rotation
  late double northRotation;
  // Mouza map image path (for inset)
  late String mouzaMapPath;

  ProjectModel({
    this.projectName = '',
    this.mouza = '',
    this.khatianNo = '',
    this.dagNo = '',
    this.jlNo = '',
    this.sheetNo = '',
    this.district = '',
    this.surveyorName = '',
    this.surveyorPhone = '',
    this.notes = '',
    this.scalePreset = '১৬" = ১ মাইল',
    this.customScale = '',
    this.northRotation = 0.0,
    this.mouzaMapPath = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
