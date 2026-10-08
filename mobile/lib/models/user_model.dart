class StudentModel {
  final int id;
  final String studentIdNumber;
  final String fullName;
  final String course;
  final String yearLevel;
  final String section;
  final String department;
  final String contactNumber;
  final String? profilePhotoUrl;

  StudentModel({
    required this.id,
    required this.studentIdNumber,
    required this.fullName,
    required this.course,
    required this.yearLevel,
    required this.section,
    required this.department,
    required this.contactNumber,
    this.profilePhotoUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? 0,
      studentIdNumber: json['student_id_number'] ?? '',
      fullName: json['full_name'] ?? '',
      course: json['course'] ?? '',
      yearLevel: json['year_level'] ?? '',
      section: json['section'] ?? '',
      department: json['department'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final String role;
  final String status;
  final StudentModel? studentProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.studentProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      studentProfile: json['student_profile'] != null
          ? StudentModel.fromJson(json['student_profile'])
          : null,
    );
  }
}
