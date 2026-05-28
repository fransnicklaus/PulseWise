import 'package:pulsewise/core/constants/app_roles.dart';

class AdminManagedRoles {
  AdminManagedRoles._();

  static const patient = AppRoles.patient;
  static const doctor = AppRoles.doctor;
  static const admin = AppRoles.admin;

  static const all = [
    patient,
    doctor,
    admin,
  ];
}

class AdminAccountStatuses {
  AdminAccountStatuses._();

  static const pendingVerification = 'pending_verification';
  static const pendingAdminVerification = 'pending_admin_verification';
  static const active = 'active';
  static const rejected = 'rejected';
  static const suspended = 'suspended';

  static const userFilterOptions = [
    pendingVerification,
    pendingAdminVerification,
    active,
    rejected,
    suspended,
  ];

  static const doctorReviewOptions = [
    pendingAdminVerification,
    active,
    rejected,
    suspended,
  ];
}

class AdminOverview {
  const AdminOverview({
    required this.totalUsers,
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAdmins,
    required this.pendingDoctors,
    required this.suspendedUsers,
  });

  final int totalUsers;
  final int totalDoctors;
  final int totalPatients;
  final int totalAdmins;
  final int pendingDoctors;
  final int suspendedUsers;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return AdminOverview(
      totalUsers: readInt('totalUsers'),
      totalDoctors: readInt('totalDoctors'),
      totalPatients: readInt('totalPatients'),
      totalAdmins: readInt('totalAdmins'),
      pendingDoctors: readInt('pendingDoctors'),
      suspendedUsers: readInt('suspendedUsers'),
    );
  }
}

class AdminPagination {
  const AdminPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  factory AdminPagination.fromJson(Map<String, dynamic> json) {
    return AdminPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class AdminDoctorProfile {
  const AdminDoctorProfile({
    required this.doctorId,
    required this.specialization,
    required this.licenseNo,
    required this.hospitalName,
    required this.isVerified,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.verificationNote,
    required this.rejectionReason,
    required this.createdAt,
  });

  final String doctorId;
  final String? specialization;
  final String? licenseNo;
  final String? hospitalName;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? verificationNote;
  final String? rejectionReason;
  final DateTime? createdAt;

  factory AdminDoctorProfile.fromJson(Map<String, dynamic> json) {
    return AdminDoctorProfile(
      doctorId: _readString(
        json,
        keys: const ['doctorId', 'doctor_id'],
      ),
      specialization: _readNullableString(
        json,
        keys: const ['specialization'],
      ),
      licenseNo: _readNullableString(
        json,
        keys: const ['licenseNo', 'license_no'],
      ),
      hospitalName: _readNullableString(
        json,
        keys: const ['hospitalName', 'hospital_name'],
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: DateTime.tryParse((json['verifiedAt'] ?? '').toString()),
      verifiedBy: _readNullableString(
        json,
        keys: const ['verifiedBy'],
      ),
      verificationNote: _readNullableString(
        json,
        keys: const ['verificationNote'],
      ),
      rejectionReason: _readNullableString(
        json,
        keys: const ['rejectionReason'],
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarPhoto,
    required this.accountStatus,
    required this.isActive,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
    required this.roles,
  });

  final String userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarPhoto;
  final String accountStatus;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String role;
  final List<String> roles;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;
    return 'Pengguna';
  }

  bool get isDoctorUser =>
      role == AppRoles.doctor || roles.contains(AppRoles.doctor);

  bool get isAdminUser =>
      role == AppRoles.admin || roles.contains(AppRoles.admin);

  bool get isPatientUser =>
      role == AppRoles.patient || roles.contains(AppRoles.patient);
}

class AdminUserListItem extends AdminUserRecord {
  const AdminUserListItem({
    required super.userId,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.avatarPhoto,
    required super.accountStatus,
    required super.isActive,
    required super.emailVerifiedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.role,
    required super.roles,
  });

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    return AdminUserListItem(
      userId: _readString(json, keys: const ['userId', 'user_id']),
      username: _readString(json, keys: const ['username']),
      email: _readString(json, keys: const ['email']),
      firstName: _readString(json, keys: const ['firstName', 'first_name']),
      lastName: _readString(json, keys: const ['lastName', 'last_name']),
      avatarPhoto: _readNullableString(
        json,
        keys: const ['avatarPhoto', 'avatar_photo'],
      ),
      accountStatus: _readString(
        json,
        keys: const ['accountStatus', 'account_status'],
      ),
      isActive: json['isActive'] as bool? ??
          _readString(
                json,
                keys: const ['accountStatus', 'account_status'],
              ) ==
              AdminAccountStatuses.active,
      emailVerifiedAt: DateTime.tryParse(
        (json['emailVerifiedAt'] ?? '').toString(),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      role: _readString(json, keys: const ['role']),
      roles: _readStringList(json['roles'],
          fallback: _readString(
            json,
            keys: const ['role'],
          )),
    );
  }
}

class AdminUserDetail extends AdminUserRecord {
  const AdminUserDetail({
    required super.userId,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.avatarPhoto,
    required super.accountStatus,
    required super.isActive,
    required super.emailVerifiedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.role,
    required super.roles,
    required this.doctorProfile,
  });

  final AdminDoctorProfile? doctorProfile;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserDetail(
      userId: _readString(json, keys: const ['userId', 'user_id']),
      username: _readString(json, keys: const ['username']),
      email: _readString(json, keys: const ['email']),
      firstName: _readString(json, keys: const ['firstName', 'first_name']),
      lastName: _readString(json, keys: const ['lastName', 'last_name']),
      avatarPhoto: _readNullableString(
        json,
        keys: const ['avatarPhoto', 'avatar_photo'],
      ),
      accountStatus: _readString(
        json,
        keys: const ['accountStatus', 'account_status'],
      ),
      isActive: json['isActive'] as bool? ??
          _readString(
                json,
                keys: const ['accountStatus', 'account_status'],
              ) ==
              AdminAccountStatuses.active,
      emailVerifiedAt: DateTime.tryParse(
        (json['emailVerifiedAt'] ?? '').toString(),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      role: _readString(json, keys: const ['role']),
      roles: _readStringList(json['roles'],
          fallback: _readString(
            json,
            keys: const ['role'],
          )),
      doctorProfile: json['doctorProfile'] is Map<String, dynamic>
          ? AdminDoctorProfile.fromJson(
              json['doctorProfile'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AdminDoctorReviewItem extends AdminUserRecord {
  const AdminDoctorReviewItem({
    required super.userId,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.avatarPhoto,
    required super.accountStatus,
    required super.isActive,
    required super.emailVerifiedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.role,
    required super.roles,
    required this.doctorProfile,
  });

  final AdminDoctorProfile doctorProfile;

  String get doctorId => doctorProfile.doctorId;

  factory AdminDoctorReviewItem.fromJson(Map<String, dynamic> json) {
    return AdminDoctorReviewItem(
      userId: _readString(json, keys: const ['userId', 'user_id']),
      username: _readString(json, keys: const ['username']),
      email: _readString(json, keys: const ['email']),
      firstName: _readString(json, keys: const ['firstName', 'first_name']),
      lastName: _readString(json, keys: const ['lastName', 'last_name']),
      avatarPhoto: _readNullableString(
        json,
        keys: const ['avatarPhoto', 'avatar_photo'],
      ),
      accountStatus: _readString(
        json,
        keys: const ['accountStatus', 'account_status'],
      ),
      isActive: json['isActive'] as bool? ??
          _readString(
                json,
                keys: const ['accountStatus', 'account_status'],
              ) ==
              AdminAccountStatuses.active,
      emailVerifiedAt: DateTime.tryParse(
        (json['emailVerifiedAt'] ?? '').toString(),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      role: _readString(json, keys: const ['role']),
      roles: _readStringList(json['roles'],
          fallback: _readString(
            json,
            keys: const ['role'],
          )),
      doctorProfile: AdminDoctorProfile.fromJson(
        (json['doctorProfile'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class AdminDoctorDetail extends AdminDoctorReviewItem {
  const AdminDoctorDetail({
    required super.userId,
    required super.username,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.avatarPhoto,
    required super.accountStatus,
    required super.isActive,
    required super.emailVerifiedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.role,
    required super.roles,
    required super.doctorProfile,
  });

  factory AdminDoctorDetail.fromJson(Map<String, dynamic> json) {
    return AdminDoctorDetail(
      userId: _readString(json, keys: const ['userId', 'user_id']),
      username: _readString(json, keys: const ['username']),
      email: _readString(json, keys: const ['email']),
      firstName: _readString(json, keys: const ['firstName', 'first_name']),
      lastName: _readString(json, keys: const ['lastName', 'last_name']),
      avatarPhoto: _readNullableString(
        json,
        keys: const ['avatarPhoto', 'avatar_photo'],
      ),
      accountStatus: _readString(
        json,
        keys: const ['accountStatus', 'account_status'],
      ),
      isActive: json['isActive'] as bool? ??
          _readString(
                json,
                keys: const ['accountStatus', 'account_status'],
              ) ==
              AdminAccountStatuses.active,
      emailVerifiedAt: DateTime.tryParse(
        (json['emailVerifiedAt'] ?? '').toString(),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      role: _readString(json, keys: const ['role']),
      roles: _readStringList(json['roles'],
          fallback: _readString(
            json,
            keys: const ['role'],
          )),
      doctorProfile: AdminDoctorProfile.fromJson(
        (json['doctorProfile'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class AdminUsersPageData {
  const AdminUsersPageData({
    required this.items,
    required this.pagination,
  });

  final List<AdminUserListItem> items;
  final AdminPagination pagination;

  factory AdminUsersPageData.fromJson(Map<String, dynamic> json) {
    return AdminUsersPageData(
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => AdminUserListItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      pagination: AdminPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class AdminMutationResult {
  const AdminMutationResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory AdminMutationResult.fromJson(Map<String, dynamic> json) {
    return AdminMutationResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class AdminUpdateUserStatusRequest {
  const AdminUpdateUserStatusRequest({
    required this.accountStatus,
  });

  final String accountStatus;

  Map<String, dynamic> toJson() {
    return {
      'accountStatus': accountStatus,
    };
  }
}

class AdminApproveDoctorRequest {
  const AdminApproveDoctorRequest({
    required this.verificationNote,
  });

  final String verificationNote;

  Map<String, dynamic> toJson() {
    return {
      'verificationNote': verificationNote,
    };
  }
}

class AdminRejectDoctorRequest {
  const AdminRejectDoctorRequest({
    required this.rejectionReason,
  });

  final String rejectionReason;

  Map<String, dynamic> toJson() {
    return {
      'rejectionReason': rejectionReason,
    };
  }
}

class AdminSuspendDoctorRequest {
  const AdminSuspendDoctorRequest({
    required this.verificationNote,
  });

  final String verificationNote;

  Map<String, dynamic> toJson() {
    return {
      'verificationNote': verificationNote,
    };
  }
}

String _readString(
  Map<String, dynamic> json, {
  required List<String> keys,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String? _readNullableString(
  Map<String, dynamic> json, {
  required List<String> keys,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

List<String> _readStringList(
  dynamic raw, {
  String? fallback,
}) {
  final values = <String>[];
  if (raw is List) {
    for (final value in raw) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) values.add(text);
    }
  }

  if (values.isEmpty) {
    final normalizedFallback = fallback?.trim() ?? '';
    if (normalizedFallback.isNotEmpty) {
      return [normalizedFallback];
    }
  }

  return values;
}
