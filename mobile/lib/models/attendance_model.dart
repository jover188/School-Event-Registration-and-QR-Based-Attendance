import 'student_model.dart';

class AttendanceModel {
  final int id;
  final String status;
  final String checkInTime;
  final String? checkOutTime;
  final StudentModel? student;

  AttendanceModel({
    required this.id,
    required this.status,
    required this.checkInTime,
    this.checkOutTime,
    this.student,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['attendance_id'] ?? json['id'] ?? 0,
      status: json['status'] ?? 'present',
      checkInTime: json['check_in_time'] ?? '',
      checkOutTime: json['check_out_time'],
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
    );
  }
}
