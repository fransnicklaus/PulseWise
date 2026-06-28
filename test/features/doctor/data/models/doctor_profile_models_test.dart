import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';

void main() {
  group('DoctorProfile', () {
    test('parses snake case API aliases and builds full name', () {
      final profile = DoctorProfile.fromJson({
        'doctor_id': 'doctor-1',
        'specialization': 'Cardiology',
        'license_no': 'LIC-001',
        'hospital_name': 'Pulse Hospital',
        'created_at': '2026-06-28T08:00:00.000Z',
        'first_name': 'Budi',
        'last_name': 'Santoso',
        'email': 'budi@example.com',
        'avatar_photo': 'avatar.png',
      });

      expect(profile.doctorId, 'doctor-1');
      expect(profile.licenseNo, 'LIC-001');
      expect(profile.hospitalName, 'Pulse Hospital');
      expect(profile.createdAt, DateTime.parse('2026-06-28T08:00:00.000Z'));
      expect(profile.fullName, 'Budi Santoso');
      expect(profile.avatarPhoto, 'avatar.png');
    });

    test('parses camel case aliases and tolerates invalid dates', () {
      final profile = DoctorProfile.fromJson({
        'doctorId': 'doctor-2',
        'licenseNo': 'LIC-002',
        'hospitalName': 'Care Clinic',
        'created_at': 'not-a-date',
        'firstName': 'Ayu',
        'lastName': '',
        'avatarPhoto': 'avatar-2.png',
      });

      expect(profile.doctorId, 'doctor-2');
      expect(profile.licenseNo, 'LIC-002');
      expect(profile.hospitalName, 'Care Clinic');
      expect(profile.createdAt, isNull);
      expect(profile.fullName, 'Ayu');
      expect(profile.email, '');
      expect(profile.avatarPhoto, 'avatar-2.png');
    });
  });
}
