class DoctorProfile {
  const DoctorProfile({
    required this.doctorId,
    required this.specialization,
    required this.licenseNo,
    required this.hospitalName,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarPhoto,
  });

  final String doctorId;
  final String specialization;
  final String licenseNo;
  final String hospitalName;
  final DateTime? createdAt;
  final String firstName;
  final String lastName;
  final String email;
  final String avatarPhoto;

  String get fullName => '$firstName $lastName'.trim();

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      specialization: (json['specialization'] ?? '').toString(),
      licenseNo: (json['license_no'] ?? json['licenseNo'] ?? '').toString(),
      hospitalName:
          (json['hospital_name'] ?? json['hospitalName'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      firstName: (json['first_name'] ?? json['firstName'] ?? '').toString(),
      lastName: (json['last_name'] ?? json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarPhoto:
          (json['avatar_photo'] ?? json['avatarPhoto'] ?? '').toString(),
    );
  }
}
