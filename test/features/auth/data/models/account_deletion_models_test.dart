import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/auth/data/models/account_deletion_models.dart';

void main() {
  group('AccountDeletionRequestResult', () {
    test('parses deletion request payload with warning metadata', () {
      final result = AccountDeletionRequestResult.fromJson({
        'nextStep': 'confirm',
        'requiresReauth': true,
        'reauthMethod': ' OTP ',
        'availableReauthMethods': ['password', 'otp', 'otp', '', null],
        'deletionToken': 'delete-token',
        'delivery': ' email ',
        'expiresInMinutes': 15.8,
        'warning': {
          'permanent': true,
          'recoverable': false,
          'confirmationText': 'KONFIRMASI',
        },
      });

      expect(result.nextStep, 'confirm');
      expect(result.requiresReauth, isTrue);
      expect(result.reauthMethod, accountDeletionOtpMethod);
      expect(result.availableReauthMethods, [
        accountDeletionPasswordMethod,
        accountDeletionOtpMethod,
      ]);
      expect(result.deletionToken, 'delete-token');
      expect(result.delivery, 'email');
      expect(result.expiresInMinutes, 15);
      expect(result.isPermanent, isTrue);
      expect(result.isRecoverable, isFalse);
      expect(result.confirmationText, 'KONFIRMASI');
    });

    test('uses safe defaults when optional payload parts are absent', () {
      final result = AccountDeletionRequestResult.fromJson({});

      expect(result.nextStep, '');
      expect(result.requiresReauth, isFalse);
      expect(result.reauthMethod, '');
      expect(result.availableReauthMethods, isEmpty);
      expect(result.deletionToken, '');
      expect(result.delivery, isNull);
      expect(result.expiresInMinutes, isNull);
      expect(result.isPermanent, isFalse);
      expect(result.isRecoverable, isFalse);
      expect(result.confirmationText, accountDeletionConfirmationText);
    });
  });

  group('AccountDeletionConfirmResult', () {
    test('parses confirm payload and deletedAt date', () {
      final result = AccountDeletionConfirmResult.fromJson({
        'nextStep': 'done',
        'deleted': true,
        'reauthMethod': 'google',
        'sessionRevoked': true,
        'deletedAt': '2026-06-29T08:00:00.000Z',
      });

      expect(result.nextStep, 'done');
      expect(result.deleted, isTrue);
      expect(result.reauthMethod, accountDeletionGoogleMethod);
      expect(result.sessionRevoked, isTrue);
      expect(result.deletedAt, DateTime.parse('2026-06-29T08:00:00.000Z'));
    });

    test('uses safe defaults for incomplete payloads', () {
      final result = AccountDeletionConfirmResult.fromJson({
        'deletedAt': 'not-a-date',
      });

      expect(result.nextStep, '');
      expect(result.deleted, isFalse);
      expect(result.reauthMethod, '');
      expect(result.sessionRevoked, isFalse);
      expect(result.deletedAt, isNull);
    });
  });

  group('Account deletion helpers', () {
    test('normalizes method values and removes duplicate methods', () {
      expect(normalizeAccountDeletionMethod(' PASSWORD '), 'password');
      expect(normalizeAccountDeletionMethod('custom'), 'custom');
      expect(normalizeAccountDeletionMethod(null), '');
      expect(
        parseAccountDeletionMethods(['password', 'otp', 'password', null]),
        ['password', 'otp'],
      );
      expect(parseAccountDeletionMethods('password'), isEmpty);
    });

    test('parses field errors with list and scalar values', () {
      final errors = parseAccountDeletionFieldErrors({
        'fieldErrors': {
          'password': ['Password salah'],
          'otp': 'OTP invalid',
          10: ['Kode salah'],
          'empty': null,
        },
      });

      expect(errors['password'], ['Password salah']);
      expect(errors['otp'], ['OTP invalid']);
      expect(errors['10'], ['Kode salah']);
      expect(errors.containsKey('empty'), isFalse);
    });
  });

  group('AccountDeletionException', () {
    test('returns first field error and stringifies to message', () {
      const exception = AccountDeletionException(
        'Validasi gagal',
        fieldErrors: {
          'otp': ['OTP salah', 'OTP kedaluwarsa'],
        },
      );

      expect(exception.firstFieldError('otp'), 'OTP salah');
      expect(exception.firstFieldError('password'), isNull);
      expect(exception.toString(), 'Validasi gagal');
    });
  });
}
