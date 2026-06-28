import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/emergency_contacts/data/models/emergency_contact_models.dart';

void main() {
  group('EmergencyContact', () {
    test('parses contact fields and boolean isPriority flag', () {
      final contact = EmergencyContact.fromJson({
        'emergencyContactId': 123,
        'userId': 'user-1',
        'contactLabel': 'Ibu',
        'contactNumber': '+62812345678',
        'createdAt': '2026-06-28T08:00:00.000Z',
        'isPriority': true,
      });

      expect(contact.emergencyContactId, '123');
      expect(contact.userId, 'user-1');
      expect(contact.contactLabel, 'Ibu');
      expect(contact.contactNumber, '+62812345678');
      expect(contact.createdAt, DateTime.parse('2026-06-28T08:00:00.000Z'));
      expect(contact.isPrioritas, isTrue);
    });

    test('parses legacy isPrioritas string flag', () {
      final contact = EmergencyContact.fromJson({
        'isPrioritas': 'TRUE',
      });

      expect(contact.isPrioritas, isTrue);
    });

    test('uses safe defaults for missing fields and invalid dates', () {
      final contact = EmergencyContact.fromJson({
        'createdAt': 'not-a-date',
      });

      expect(contact.emergencyContactId, '');
      expect(contact.userId, '');
      expect(contact.contactLabel, '');
      expect(contact.contactNumber, '');
      expect(contact.createdAt, isNull);
      expect(contact.isPrioritas, isFalse);
    });
  });
}
