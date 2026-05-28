import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin/data/datasources/admin_api.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_doctor_detail_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_user_detail_page.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';

void main() {
  group('Admin detail pages', () {
    testWidgets('renders non-doctor user status action', (tester) async {
      const userId = 'user-patient-1';

      final userDetail = AdminUserDetail(
        userId: userId,
        username: 'patientone',
        email: 'patient@pulsewise.local',
        firstName: 'Patient',
        lastName: 'One',
        avatarPhoto: null,
        accountStatus: AdminAccountStatuses.active,
        isActive: true,
        emailVerifiedAt: DateTime.parse('2026-05-28T10:00:00.000Z'),
        createdAt: DateTime.parse('2026-05-27T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-05-28T11:00:00.000Z'),
        role: AdminManagedRoles.patient,
        roles: const [AdminManagedRoles.patient],
        doctorProfile: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminApiProvider.overrideWithValue(
              _FakeAdminApi(userDetail: userDetail),
            ),
          ],
          child: const MaterialApp(
            home: AdminUserDetailPage(userId: userId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tangguhkan Akun'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Aksi Akun'), findsOneWidget);
      expect(find.text('Tangguhkan Akun'), findsOneWidget);
    });

    testWidgets('renders doctor user detail with review CTA', (tester) async {
      const userId = 'user-doctor-1';
      const doctorId = 'doctor-1';

      final userDetail = AdminUserDetail(
        userId: userId,
        username: 'drhouse',
        email: 'doctor@pulsewise.local',
        firstName: 'Gregory',
        lastName: 'House',
        avatarPhoto: null,
        accountStatus: AdminAccountStatuses.pendingAdminVerification,
        isActive: false,
        emailVerifiedAt: DateTime.parse('2026-05-28T10:00:00.000Z'),
        createdAt: DateTime.parse('2026-05-27T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-05-28T11:00:00.000Z'),
        role: AdminManagedRoles.doctor,
        roles: const [AdminManagedRoles.doctor],
        doctorProfile: AdminDoctorProfile(
          doctorId: doctorId,
          specialization: 'Cardiology',
          licenseNo: 'LIC-001',
          hospitalName: 'PulseWise Hospital',
          isVerified: false,
          verifiedAt: null,
          verifiedBy: null,
          verificationNote: null,
          rejectionReason: null,
          createdAt: DateTime.parse('2026-05-26T10:00:00.000Z'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminApiProvider.overrideWithValue(
              _FakeAdminApi(userDetail: userDetail),
            ),
          ],
          child: const MaterialApp(
            home: AdminUserDetailPage(userId: userId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Akun dokter dikelola lewat review dokter'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Akun dokter dikelola lewat review dokter'),
          findsOneWidget);
      expect(find.text('Buka Detail Review Dokter'), findsOneWidget);
      expect(find.text('Profil Dokter'), findsOneWidget);
      expect(find.text('Cardiology'), findsOneWidget);
    });

    testWidgets('renders doctor detail review metadata', (tester) async {
      const doctorId = 'doctor-7';

      final doctorDetail = AdminDoctorDetail(
        userId: 'user-doctor-7',
        username: 'drstrange',
        email: 'doctor7@pulsewise.local',
        firstName: 'Stephen',
        lastName: 'Strange',
        avatarPhoto: null,
        accountStatus: AdminAccountStatuses.active,
        isActive: true,
        emailVerifiedAt: DateTime.parse('2026-05-28T10:00:00.000Z'),
        createdAt: DateTime.parse('2026-05-20T10:00:00.000Z'),
        updatedAt: DateTime.parse('2026-05-28T11:00:00.000Z'),
        role: AdminManagedRoles.doctor,
        roles: const [AdminManagedRoles.doctor],
        doctorProfile: AdminDoctorProfile(
          doctorId: doctorId,
          specialization: 'Neurology',
          licenseNo: 'SIP-789',
          hospitalName: 'Metro Hospital',
          isVerified: true,
          verifiedAt: DateTime.parse('2026-05-28T12:00:00.000Z'),
          verifiedBy: 'admin-1',
          verificationNote: 'Dokumen SIP sudah diverifikasi',
          rejectionReason: 'Dokumen STR belum lengkap',
          createdAt: DateTime.parse('2026-05-18T10:00:00.000Z'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminApiProvider.overrideWithValue(
              _FakeAdminApi(doctorDetail: doctorDetail),
            ),
          ],
          child: const MaterialApp(
            home: AdminDoctorDetailPage(doctorId: doctorId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tangguhkan Dokter'),
        300,
      );
      await tester.pumpAndSettle();
      expect(find.text('Tangguhkan Dokter'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Catatan Admin'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Catatan Admin'), findsOneWidget);
      expect(find.text('Dokumen SIP sudah diverifikasi'), findsOneWidget);
      expect(find.text('Dokumen STR belum lengkap'), findsOneWidget);
    });
  });
}

class _FakeAdminApi extends AdminApi {
  _FakeAdminApi({
    this.userDetail,
    this.doctorDetail,
  }) : super(Dio());

  final AdminUserDetail? userDetail;
  final AdminDoctorDetail? doctorDetail;

  @override
  Future<AdminUserDetail> fetchUserDetail(String userId) async {
    return userDetail!;
  }

  @override
  Future<AdminDoctorDetail> fetchDoctorDetail(String doctorId) async {
    return doctorDetail!;
  }
}
