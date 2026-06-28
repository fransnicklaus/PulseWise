import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/models/patient_share_models.dart';

void main() {
  group('PatientShare', () {
    test('parses camel case response and uses qr payload as qr data', () {
      final share = PatientShare.fromJson({
        'shareId': 'share-1',
        'patientId': 'patient-1',
        'shareCode': 'CODE123',
        'expiresAt': '2026-06-29T00:00:00.000Z',
        'qrPayload': 'pulsewise://share/CODE123',
      });

      expect(share.shareId, 'share-1');
      expect(share.patientId, 'patient-1');
      expect(share.shareCode, 'CODE123');
      expect(share.expiresAt, '2026-06-29T00:00:00.000Z');
      expect(share.qrData, 'pulsewise://share/CODE123');
    });

    test('parses snake case response and falls back qr data to share code', () {
      final share = PatientShare.fromJson({
        'share_id': 'share-2',
        'patient_id': 'patient-2',
        'share_code': 'CODE456',
        'expires_at': '2026-06-30T00:00:00.000Z',
        'qr_payload': ' ',
      });

      expect(share.shareId, 'share-2');
      expect(share.patientId, 'patient-2');
      expect(share.shareCode, 'CODE456');
      expect(share.expiresAt, '2026-06-30T00:00:00.000Z');
      expect(share.qrData, 'CODE456');
    });
  });
}
